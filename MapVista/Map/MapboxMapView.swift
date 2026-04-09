// 文件路径: MapVista/Map/MapboxMapView.swift
// 作用: SwiftUI + UIViewRepresentable 的 Mapbox 地图桥接层，统一处理镜头、标注、路线与点击事件

import SwiftUI
import UIKit
import CoreLocation
import Combine
import MapboxMaps

private final class MapContainerView: UIView {
    let mapView: MapView

    init(mapView: MapView) {
        self.mapView = mapView
        super.init(frame: .zero)
        backgroundColor = UIColor(
            red: 0.07,
            green: 0.15,
            blue: 0.12,
            alpha: 1.0
        )
        clipsToBounds = true
        addSubview(mapView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mapView.frame = bounds
    }
}

struct MapboxMapView: UIViewRepresentable {
    @Binding var cameraState: MapCameraState
    @Binding var selectedStyle: MapStyle
    @Binding var sceneMode: MapSceneMode

    let pois: [POIModel]
    let selectedPOI: POIModel?
    let routeCoordinates: [CLLocationCoordinate2D]
    let currentTrackPoints: [CLLocationCoordinate2D]
    let currentLocation: CLLocation?
    let onPOITap: (POIModel) -> Void
    let onMapTap: (CLLocationCoordinate2D) -> Void
    let onMapLongPress: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let cameraOptions = CameraOptions(
            center: cameraState.centerCoordinate,
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: cameraState.pitch
        )

        let mapInitOptions = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: selectedStyle.styleURI
        )

        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        mapView.backgroundColor = .clear

        let containerView = MapContainerView(mapView: mapView)
        configureMapView(mapView)
        context.coordinator.attach(mapView: mapView)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.refresh()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Mapbox 配置
    private func configureMapView(_ mapView: MapView) {
        // 当前位置蓝点
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration(showsAccuracyRing: true))

        // 右上角指南针
        mapView.ornaments.options.compass.visibility = .visible
        mapView.ornaments.options.compass.position = .topRight
        
        // 隐藏 Mapbox Logo 和 Info (Attribution)
        mapView.ornaments.logoView.isHidden = true
        mapView.ornaments.attributionButton.isHidden = true
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, AnnotationInteractionDelegate {
        var parent: MapboxMapView
        weak var mapView: MapView?

        private let routeOverlayManager = RouteOverlayManager()
        private let trackOverlayManager = TrackOverlayManager()
        private let terrainSourceID = "mapvista-terrain-source"
        private let hillshadeLayerID = "mapvista-hillshade-layer"
        private let skyLayerID = "mapvista-sky-layer"
        private var cancellables: [Cancelable] = []
        private var pointAnnotationManager: PointAnnotationManager?
        private var longPressGesture: UILongPressGestureRecognizer?
        private var lastAppliedCameraState: MapCameraState?
        private var lastAppliedStyleRawValue: String?
        private var lastAppliedSceneMode: MapSceneMode?
        private var lastPOITapTime: Date = .distantPast

        init(parent: MapboxMapView) {
            self.parent = parent
        }

        func attach(mapView: MapView) {
            self.mapView = mapView
            lastAppliedStyleRawValue = parent.selectedStyle.styleURI.rawValue
            lastAppliedSceneMode = nil
            installListeners(on: mapView)
            rebuildMapContent()
        }

        func refresh() {
            guard let mapView = mapView else { return }
            let desiredStyleRawValue = parent.selectedStyle.styleURI.rawValue
            if lastAppliedStyleRawValue != desiredStyleRawValue {
                lastAppliedSceneMode = nil
                mapView.mapboxMap.loadStyleURI(parent.selectedStyle.styleURI) { [weak self] _ in
                    self?.rebuildMapContent()
                }
                lastAppliedStyleRawValue = desiredStyleRawValue
                return
            }

            applyCameraIfNeeded(on: mapView)
            applySceneModeIfNeeded(on: mapView)
            refreshAnnotations()
            refreshRoute()
            refreshTrack()
        }

        private func installListeners(on mapView: MapView) {
            let styleLoadedCancelable = mapView.mapboxMap.onEvery(event: .styleLoaded) { [weak self] _ in
                self?.rebuildMapContent()
            }
            cancellables.append(styleLoadedCancelable)

            mapView.gestures.singleTapGestureRecognizer.removeTarget(self, action: #selector(handleMapSingleTap(_:)))
            mapView.gestures.singleTapGestureRecognizer.addTarget(self, action: #selector(handleMapSingleTap(_:)))

            if longPressGesture == nil {
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
                mapView.addGestureRecognizer(gesture)
                longPressGesture = gesture
            }
        }

        @objc
        private func handleMapSingleTap(_ recognizer: UIGestureRecognizer) {
            guard let mapView = mapView else { return }
            
            // 防抖处理：如果刚刚在 0.3 秒内触发过 POI 标注的点击事件，忽略本次底层地图空地点击
            // 否则会造成“选中后立刻被底图点击清空选中”的情况
            if Date().timeIntervalSince(lastPOITapTime) < 0.3 { return }
            
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            DispatchQueue.main.async { [weak self] in
                self?.parent.onMapTap(coordinate)
            }
        }

        @objc
        private func handleMapLongPress(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .began, let mapView = mapView else { return }
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            DispatchQueue.main.async { [weak self] in
                self?.parent.onMapLongPress?(coordinate)
            }
        }

        private func rebuildMapContent() {
            guard let mapView = mapView else { return }
            localizeBaseMapLabels(on: mapView)
            applySceneModeIfNeeded(on: mapView)
            routeOverlayManager.install(on: mapView)
            trackOverlayManager.install(on: mapView)
            rebuildPointAnnotationManager()
            applyCameraIfNeeded(on: mapView)
            refreshAnnotations()
            refreshRoute()
            refreshTrack()
        }

        private func rebuildPointAnnotationManager() {
            guard let mapView = mapView else { return }
            let manager = mapView.annotations.makePointAnnotationManager()
            manager.delegate = self
            pointAnnotationManager = manager
        }

        private func applyCameraIfNeeded(on mapView: MapView) {
            guard lastAppliedCameraState != parent.cameraState else { return }

            let cameraOptions = CameraOptions(
                center: parent.cameraState.centerCoordinate,
                zoom: parent.cameraState.zoom,
                bearing: parent.cameraState.bearing,
                pitch: parent.cameraState.pitch
            )

            if lastAppliedCameraState == nil {
                mapView.mapboxMap.setCamera(to: cameraOptions)
            } else {
                mapView.camera.fly(to: cameraOptions, duration: 1.2)
            }
            lastAppliedCameraState = parent.cameraState
        }

        private func applySceneModeIfNeeded(on mapView: MapView) {
            guard lastAppliedSceneMode != parent.sceneMode else { return }

            switch parent.sceneMode {
            case .threeD:
                installTerrainAndSky(on: mapView)
            case .twoD:
                removeTerrainAndSky(on: mapView)
            }

            lastAppliedSceneMode = parent.sceneMode
        }

        private func localizeBaseMapLabels(on mapView: MapView) {
            let zhHansLocale = Locale(identifier: "zh-Hans")
            try? mapView.mapboxMap.style.localizeLabels(into: zhHansLocale)
        }

        private func installTerrainAndSky(on mapView: MapView) {
            let style = mapView.mapboxMap.style

            // 3D 场景优先使用标准 atmosphere，避免天空区域发黑
            var atmosphere = Atmosphere()
            atmosphere.color = .constant(
                StyleColor(
                    UIColor(
                        red: 0.70,
                        green: 0.82,
                        blue: 0.95,
                        alpha: 0.92
                    )
                )
            )
            atmosphere.highColor = .constant(
                StyleColor(
                    UIColor(
                        red: 0.52,
                        green: 0.70,
                        blue: 0.91,
                        alpha: 0.96
                    )
                )
            )
            atmosphere.horizonBlend = .constant(0.1) // 降低地平线融合度，使天空边界更清晰
            atmosphere.range = .constant([2.0, 12.0]) // 调大起雾距离，避免全屏起雾而导致雾蒙蒙的感觉
            atmosphere.spaceColor = .constant(
                StyleColor(
                    UIColor(
                        red: 0.58,
                        green: 0.74,
                        blue: 0.93,
                        alpha: 1.0
                    )
                )
            )
            atmosphere.starIntensity = .constant(0.0)
            try? style.setAtmosphere(atmosphere)

            if !style.sourceExists(withId: terrainSourceID) {
                var demSource = RasterDemSource()
                demSource.url = "mapbox://mapbox.mapbox-terrain-dem-v1"
                // 究极精度开关：将 TileSize 强制降维到 256，这会强迫 Mapbox OpenGL 丢弃 512 的省流策略，直接按 4 倍网格密度抓取和构建多边形！
                demSource.tileSize = 256
                // 将深度贴图获取级别拉到极限 15.0（默认通常只准 14）
                demSource.maxzoom = 15.0
                try? style.addSource(demSource, id: terrainSourceID)
            }

            var terrain = Terrain(sourceId: terrainSourceID)
            // 将地形夸张度压实至 1.2，放弃刻意夸大的“假高差”，完全遵照军事级 1:1.2 现实比例还原
            terrain.exaggeration = .constant(1.2)
            try? style.setTerrain(terrain)

            if !style.layerExists(withId: hillshadeLayerID) {
                var hillshadeLayer = HillshadeLayer(id: hillshadeLayerID)
                hillshadeLayer.source = terrainSourceID
                hillshadeLayer.hillshadeExaggeration = .constant(0.9)
                hillshadeLayer.hillshadeIlluminationAnchor = .constant(.map)
                hillshadeLayer.hillshadeIlluminationDirection = .constant(325)
                hillshadeLayer.hillshadeHighlightColor = .constant(StyleColor(UIColor.white.withAlphaComponent(0.78)))
                hillshadeLayer.hillshadeShadowColor = .constant(StyleColor(UIColor.black.withAlphaComponent(0.48)))
                hillshadeLayer.hillshadeAccentColor = .constant(StyleColor(UIColor.systemGray.withAlphaComponent(0.12)))
                try? style.addLayer(hillshadeLayer)
            }

            if !style.layerExists(withId: skyLayerID) {
                var skyLayer = SkyLayer(id: skyLayerID)
                skyLayer.skyType = .constant(.atmosphere)
                skyLayer.skyAtmosphereColor = .constant(
                    StyleColor(
                        UIColor(
                            red: 0.53,
                            green: 0.71,
                            blue: 0.92,
                            alpha: 0.96
                        )
                    )
                )
                skyLayer.skyAtmosphereHaloColor = .constant(
                    StyleColor(
                        UIColor(
                            red: 1.0,
                            green: 1.0,
                            blue: 1.0,
                            alpha: 0.22
                        )
                    )
                )
                skyLayer.skyAtmosphereSun = .constant([0.0, 90.0])
                skyLayer.skyAtmosphereSunIntensity = .constant(8.0)
                try? style.addLayer(skyLayer)
            }

            var light = Light()
            light.anchor = .map
            light.color = StyleColor(UIColor.white)
            light.intensity = 0.55
            light.position = [1.5, 115.0, 25.0]
            try? style.setLight(light)

        }

        private func removeTerrainAndSky(on mapView: MapView) {
            let style = mapView.mapboxMap.style
            style.removeTerrain()
            try? style.removeAtmosphere()

            if style.layerExists(withId: hillshadeLayerID) {
                try? style.removeLayer(withId: hillshadeLayerID)
            }

            if style.layerExists(withId: skyLayerID) {
                try? style.removeLayer(withId: skyLayerID)
            }

            if style.sourceExists(withId: terrainSourceID) {
                try? style.removeSource(withId: terrainSourceID)
            }
        }

        private func refreshAnnotations() {
            guard pointAnnotationManager != nil else { return }

            var annotations = parent.pois.map { poi -> PointAnnotation in
                let isSelected = parent.selectedPOI?.id == poi.id
                let markerImage = makeMarkerImage(category: poi.category, selected: isSelected)

                var annotation = PointAnnotation(coordinate: poi.coordinate)
                annotation.image = PointAnnotation.Image(
                    image: markerImage,
                    name: "poi-\(poi.id)-\(isSelected ? "selected" : "normal")"
                )
                annotation.iconAnchor = .bottom
                annotation.userInfo = ["poiID": poi.id]
                return annotation
            }

            // 如果有选中的 POI，但它不在 visiblePOIs 中（例如来自网络搜索或未收藏的结果），强制为其绘制一个选中态的标记
            if let selectedPOI = parent.selectedPOI, !parent.pois.contains(where: { $0.id == selectedPOI.id }) {
                let markerImage = makeMarkerImage(category: selectedPOI.category, selected: true)
                var annotation = PointAnnotation(coordinate: selectedPOI.coordinate)
                annotation.image = PointAnnotation.Image(
                    image: markerImage,
                    name: "poi-\(selectedPOI.id)-selected"
                )
                annotation.iconAnchor = .bottom
                annotation.userInfo = ["poiID": selectedPOI.id]
                annotations.append(annotation)
            }

            pointAnnotationManager?.annotations = annotations
        }

        private func refreshRoute() {
            guard let mapView = mapView else { return }
            routeOverlayManager.update(routeCoordinates: parent.routeCoordinates, on: mapView)
        }

        private func refreshTrack() {
            guard let mapView = mapView else { return }
            trackOverlayManager.update(trackCoordinates: parent.currentTrackPoints, on: mapView)
        }

        private func makeMarkerImage(category: POICategory, selected: Bool) -> UIImage {
            let size: CGFloat = selected ? 54 : 44
            let iconSize: CGFloat = selected ? 24 : 20
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .bold)
            let symbol = UIImage(systemName: category.iconName, withConfiguration: symbolConfiguration) ??
                UIImage(systemName: "mappin.circle.fill", withConfiguration: symbolConfiguration) ??
                UIImage()

            let backgroundColor = selected ? UIColor.systemTeal : UIColor.white
            let iconColor = selected ? UIColor.white : UIColor.systemTeal

            return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { context in
                let rect = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)
                context.cgContext.setShadow(
                    offset: CGSize(width: 0, height: 2),
                    blur: 5,
                    color: UIColor.black.withAlphaComponent(0.25).cgColor
                )
                backgroundColor.setFill()
                UIBezierPath(ovalIn: rect).fill()

                let tinted = symbol.withTintColor(iconColor, renderingMode: .alwaysOriginal)
                let x = (size - iconSize) / 2
                let y = (size - iconSize) / 2
                tinted.draw(in: CGRect(x: x, y: y, width: iconSize, height: iconSize))
            }
        }
    }
}

// MARK: - 标注点击回调
extension MapboxMapView.Coordinator {
    func annotationManager(
        _ manager: AnnotationManager,
        didDetectTappedAnnotations annotations: [Annotation]
    ) {
        guard
            let first = annotations.first as? PointAnnotation,
            let poiID = first.userInfo?["poiID"] as? String
        else { return }

        // 先尝试从可见列表中找，如果找不到看是不是临时选中的搜索结果
        guard let poi = parent.pois.first(where: { $0.id == poiID }) ?? (parent.selectedPOI?.id == poiID ? parent.selectedPOI : nil) else {
            return
        }

        // 记录点击标记的时间戳，用于屏蔽底图点击
        lastPOITapTime = Date()

        DispatchQueue.main.async { [weak self] in
            self?.parent.onPOITap(poi)
        }
    }
}
