// 文件路径: MapVista/Map/RouteOverlayManager.swift
// 作用: 统一管理路线折线覆盖物，负责 source / layer 的创建、更新和清理

import Foundation
import CoreLocation
import MapboxMaps
import Turf
import UIKit

final class RouteOverlayManager {
    private let sourceID = "mapvista-route-source"
    private let layerID = "mapvista-route-layer"
    private var isInstalled = false

    func install(on mapView: MapView) {
        removeIfNeeded(on: mapView)

        var source = GeoJSONSource()
        source.data = .empty
        try? mapView.mapboxMap.style.addSource(source, id: sourceID)

        var layer = LineLayer(id: layerID)
        layer.source = sourceID
        layer.lineColor = Value.constant(StyleColor(UIColor.systemTeal))
        layer.lineWidth = Value.constant(4)
        layer.lineOpacity = Value.constant(0.9)
        layer.lineCap = Value.constant(LineCap.round)
        layer.lineJoin = Value.constant(LineJoin.round)

        try? mapView.mapboxMap.style.addLayer(layer)
        isInstalled = true
    }

    func update(routeCoordinates: [CLLocationCoordinate2D], on mapView: MapView) {
        guard isInstalled else {
            install(on: mapView)
            update(routeCoordinates: routeCoordinates, on: mapView)
            return
        }

        if routeCoordinates.isEmpty {
            try? mapView.mapboxMap.style.updateGeoJSONSource(
                withId: sourceID,
                geoJSON: GeoJSONObject(FeatureCollection(features: []))
            )
        } else {
            let lineString = LineString(routeCoordinates)
            try? mapView.mapboxMap.style.updateGeoJSONSource(
                withId: sourceID,
                geoJSON: GeoJSONObject(Feature(geometry: Geometry(lineString)))
            )
        }
    }

    func clear(on mapView: MapView) {
        update(routeCoordinates: [], on: mapView)
    }

    func removeIfNeeded(on mapView: MapView) {
        try? mapView.mapboxMap.style.removeLayer(withId: layerID)
        try? mapView.mapboxMap.style.removeSource(withId: sourceID)
        isInstalled = false
    }
}
