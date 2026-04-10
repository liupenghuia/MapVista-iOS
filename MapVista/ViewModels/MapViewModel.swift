// 文件路径: MapVista/ViewModels/MapViewModel.swift
// 作用: 地图首页核心状态管理，负责 POI 加载、选中状态、样式切换、路线绘制与定位联动

import Foundation
import CoreLocation
import Combine
import SwiftUI
import MapKit

final class MapViewModel: ObservableObject {
    @Published private(set) var allPOIs: [POIModel] = []
    @Published private(set) var visiblePOIs: [POIModel] = []
    @Published private(set) var currentLocation: CLLocation?
    @Published var selectedPOI: POIModel?
    @Published var cameraState: MapCameraState = .defaultState
    @Published var selectedStyle: MapStyle = .satellite
    @Published var sceneMode: MapSceneMode = .twoD
    @Published var selectedCategory: POICategory?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var routeInfo: RouteModel?
    @Published var isLoadingPOIs = false
    @Published var errorMessage: String?
    @Published private(set) var locationRecenterToken = 0
    @Published var importedTrackDocument: GPXTrackDocument?
    
    // 轨迹记录相关状态
    @Published var isRecordingTrack = false
    @Published var currentTrackPoints: [CLLocationCoordinate2D] = []
    @Published var currentTrackDistance: Double = 0

    let locationManager: LocationManager
    let trackService: TrackRecordingService

    private let poiService: POIServiceProtocol
    private let navigationService: NavigationServiceProtocol
    private let cacheService: OfflineCacheProviding
    private var cancellables = Set<AnyCancellable>()
    private var hasAutoCenteredOnCurrentLocation = false

    init(
        poiService: POIServiceProtocol = LocalMockPOIService(),
        navigationService: NavigationServiceProtocol = MapboxNetworkNavigationService(),
        locationManager: LocationManager = LocationManager(),
        cacheService: OfflineCacheProviding = MemoryOfflineCacheService(),
        trackService: TrackRecordingService = .shared
    ) {
        self.poiService = poiService
        self.navigationService = navigationService
        self.locationManager = locationManager
        self.cacheService = cacheService
        self.trackService = trackService

        setupBindings()
        loadInitialData()
        locationManager.requestAuthorizationIfNeeded()
        locationManager.startUpdatingLocation()
    }

    private func setupBindings() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }
                self.currentLocation = location
                self.recalculateRouteIfNeeded()
                // 不断将定位点喂给轨迹记录大管家
                self.trackService.feedLocation(location)

                self.autoCenterOnCurrentLocationIfNeeded(with: location)
            }
            .store(in: &cancellables)
            
        // 绑定轨迹状态投射到 View 供 UI 展示
        trackService.$isRecording
            .assign(to: &$isRecordingTrack)
            
        trackService.$currentRecord
            .sink { [weak self] record in
                if let record = record {
                    self?.currentTrackPoints = record.points.map { $0.coordinate }
                    self?.currentTrackDistance = record.totalDistance
                } else {
                    self?.currentTrackPoints = []
                    self?.currentTrackDistance = 0
                }
            }
            .store(in: &cancellables)

        $selectedCategory
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        $selectedStyle
            .sink { [weak self] style in
                self?.cacheService.cacheSelectedStyle(style)
            }
            .store(in: &cancellables)

        $sceneMode
            .sink { [weak self] mode in
                self?.applySceneMode(mode)
            }
            .store(in: &cancellables)
    }

    var trackOverlayCoordinates: [CLLocationCoordinate2D] {
        if isRecordingTrack {
            return currentTrackPoints
        }
        return importedTrackDocument?.coordinates ?? []
    }

    var importedTrackSummaryText: String? {
        guard let importedTrackDocument else { return nil }
        return "\(importedTrackDocument.pointCount) 个点 · \(importedTrackDocument.distanceText) · \(importedTrackDocument.durationText)"
    }

    private func loadInitialData() {
        isLoadingPOIs = true
        if let cachedStyle = cacheService.cachedSelectedStyle() {
            selectedStyle = cachedStyle
        }

        let cachedPOIs = cacheService.cachedPOIs()
        if !cachedPOIs.isEmpty {
            allPOIs = cachedPOIs
            applyFilters()
            isLoadingPOIs = false
            return
        }

        let pois = poiService.loadAllPOIs()
        allPOIs = pois
        cacheService.cachePOIs(pois)
        applyFilters()
        isLoadingPOIs = false
    }

    private func applyFilters() {
        if let selectedCategory = selectedCategory {
            visiblePOIs = allPOIs.filter { $0.category == selectedCategory }
        } else {
            visiblePOIs = allPOIs
        }
    }

    func selectPOI(_ poi: POIModel) {
        selectedPOI = poi
        cameraState = MapCameraState(
            latitude: poi.latitude,
            longitude: poi.longitude,
            zoom: 13.5,
            bearing: 0,
            pitch: sceneMode.cameraPitch
        )
        recalculateRouteIfNeeded()
    }

    func clearSelection() {
        selectedPOI = nil
        routeCoordinates = []
        routeInfo = nil
    }

    func showImportedTrack(_ document: GPXTrackDocument) {
        importedTrackDocument = document
        selectedPOI = nil
        routeCoordinates = []
        routeInfo = nil

        if let center = centerCoordinate(for: document.coordinates) {
            cameraState = MapCameraState(
                latitude: center.latitude,
                longitude: center.longitude,
                zoom: zoomLevel(for: document.coordinates),
                bearing: 0,
                pitch: sceneMode.cameraPitch
            )
        }
    }

    func clearImportedTrack() {
        importedTrackDocument = nil

        if selectedPOI == nil, let currentLocation {
            centerCamera(on: currentLocation)
        }
    }

    func applyCategoryFilter(_ category: POICategory?) {
        selectedCategory = category
    }

    func switchStyle(_ style: MapStyle) {
        selectedStyle = style
        cacheService.cacheSelectedStyle(style)
    }

    func toggleSceneMode() {
        sceneMode = sceneMode == .threeD ? .twoD : .threeD
    }

    func moveToCurrentLocation() {
        locationRecenterToken += 1

        if let currentLocation = currentLocation {
            centerCamera(on: currentLocation)
        }

        locationManager.requestFreshLocation()
    }

    private func autoCenterOnCurrentLocationIfNeeded(with location: CLLocation) {
        guard !hasAutoCenteredOnCurrentLocation else { return }
        guard selectedPOI == nil else { return }

        hasAutoCenteredOnCurrentLocation = true
        locationRecenterToken += 1
        centerCamera(on: location)
    }

    private func centerCamera(on location: CLLocation) {
        cameraState = MapCameraState(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            zoom: 14.5,
            bearing: 0,
            pitch: sceneMode.cameraPitch
        )
    }

    private func centerCoordinate(for coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        return CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
    }

    private func zoomLevel(for coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 14.0 }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let latSpan = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonSpan = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        let span = max(latSpan, lonSpan)

        switch span {
        case ..<0.005:
            return 15.0
        case ..<0.02:
            return 14.0
        case ..<0.08:
            return 12.5
        case ..<0.25:
            return 11.0
        case ..<1.0:
            return 9.5
        default:
            return 8.0
        }
    }

    private var useMetricSystem: Bool {
        if UserDefaults.standard.object(forKey: "MapVista.UseMetricSystem") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "MapVista.UseMetricSystem")
    }

    func distanceText(to poi: POIModel) -> String? {
        guard let distance = locationManager.distance(to: poi.coordinate) else { return nil }
        if useMetricSystem {
            if distance < 1000 {
                return String(format: "距你 %.0f 米", distance)
            }
            return String(format: "距你 %.1f 公里", distance / 1000.0)
        } else {
            let miles = distance * 0.000621371
            if miles < 0.1 {
                return String(format: "距你 %.0f 英尺", distance * 3.28084)
            }
            return String(format: "距你 %.1f 英里", miles)
        }
    }

    func startNavigation(to poi: POIModel) {
        selectedPOI = poi
        guard let currentLocation = locationManager.currentLocation else {
            recalculateRouteIfNeeded()
            return
        }

        // 先在 App 里画出规划好的道路网实线
        if let route = routeInfo, !route.coordinates.isEmpty {
            routeCoordinates = route.coordinates
        } else {
            navigationService.fetchRoute(
                from: currentLocation.coordinate,
                to: poi.coordinate,
                mode: .driving
            ) { [weak self] route in
                self?.routeInfo = route
                self?.routeCoordinates = route?.coordinates ?? []
            }
        }
        
        // 第三方导航分发逻辑：优先高德地图 -> 降级 Apple Maps
        let poiname = poi.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "目的地"
        // 高德 scheme：dev=1 表示我们在传输国际标准 GPS 坐标（WGS-84），让高德自动转回国内纠偏坐标
        let amapURLString = "iosamap://navi?sourceApplication=MapVista&poiname=\(poiname)&lat=\(poi.coordinate.latitude)&lon=\(poi.coordinate.longitude)&dev=1&style=2"
        
        if let amapURL = URL(string: amapURLString) {
            UIApplication.shared.open(amapURL, options: [:]) { success in
                // 如果用户没有安装高德地图，则降级为 iPhone 默认系统地图
                if !success {
                    let placemark = MKPlacemark(coordinate: poi.coordinate)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = poi.name
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                }
            }
        }
    }

    private func recalculateRouteIfNeeded() {
        guard let selectedPOI, let currentLocation = locationManager.currentLocation else {
            routeCoordinates = []
            routeInfo = nil
            return
        }

        navigationService.fetchRoute(
            from: currentLocation.coordinate,
            to: selectedPOI.coordinate,
            mode: .driving
        ) { [weak self] route in
            self?.routeInfo = route
            // 置空路线坐标数组以防止在选中时强制在地图上粗暴绘制一条直观的线，除非用户真正点击“导航到这里”
            self?.routeCoordinates = []
        }
    }

    private func applySceneMode(_ mode: MapSceneMode) {
        cameraState = MapCameraState(
            latitude: cameraState.latitude,
            longitude: cameraState.longitude,
            zoom: cameraState.zoom,
            bearing: cameraState.bearing,
            pitch: mode.cameraPitch
        )
    }

    func locationAuthorizationMessage() -> String? {
        switch locationManager.authorizationStatus {
        case .denied:
            return "定位权限已关闭，开启后可显示当前位置和距离信息。"
        case .restricted:
            return "当前设备限制了定位服务。"
        case .notDetermined:
            return "需要定位权限以显示当前位置。"
        default:
            return nil
        }
    }

    func addCustomPOI(coordinate: CLLocationCoordinate2D, remark: String, category: POICategory) {
        let newPOI = POIModel(
            name: remark,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            intro: "自定义[\(category.displayName)]位置",
            category: category,
            detailDescription: "您在地图上长按标记的自定义位置。",
            address: String(format: "经度 %.5f, 纬度 %.5f", coordinate.longitude, coordinate.latitude),
            rating: 5.0
        )
        
        // 插入到首位或末尾，这里选择插入末尾
        allPOIs.append(newPOI)
        
        // 将所有 POI 重新持久化缓存，确保“下次进来”还能看到
        cacheService.cachePOIs(allPOIs)
        
        // 刷新地图可见列表
        applyFilters()
        
        // 直接变为选中状态，让刚添加的也弹出 bottom sheet 预览确认一下
        selectPOI(newPOI)
    }
}
