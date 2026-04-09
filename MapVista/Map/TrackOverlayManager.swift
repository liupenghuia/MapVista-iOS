import Foundation
import CoreLocation
import MapboxMaps
import Turf
import UIKit

final class TrackOverlayManager {
    private let sourceID = "mapvista-track-source"
    private let layerID = "mapvista-track-layer"
    private var isInstalled = false

    func install(on mapView: MapView) {
        removeIfNeeded(on: mapView)

        var source = GeoJSONSource()
        source.data = .empty
        try? mapView.mapboxMap.style.addSource(source, id: sourceID)

        var layer = LineLayer(id: layerID)
        layer.source = sourceID
        layer.lineColor = Value.constant(StyleColor(UIColor.systemRed)) // 红色醒目
        layer.lineWidth = Value.constant(6)
        layer.lineOpacity = Value.constant(0.85)
        layer.lineCap = Value.constant(LineCap.round)
        layer.lineJoin = Value.constant(LineJoin.round)

        try? mapView.mapboxMap.style.addLayer(layer)
        isInstalled = true
    }

    func update(trackCoordinates: [CLLocationCoordinate2D], on mapView: MapView) {
        guard isInstalled else {
            install(on: mapView)
            update(trackCoordinates: trackCoordinates, on: mapView)
            return
        }

        // Mapbox 的线至少需要两个点
        if trackCoordinates.count < 2 {
            try? mapView.mapboxMap.style.updateGeoJSONSource(
                withId: sourceID,
                geoJSON: GeoJSONObject(FeatureCollection(features: []))
            )
        } else {
            let lineString = LineString(trackCoordinates)
            try? mapView.mapboxMap.style.updateGeoJSONSource(
                withId: sourceID,
                geoJSON: GeoJSONObject(Feature(geometry: Geometry(lineString)))
            )
        }
    }

    func clear(on mapView: MapView) {
        update(trackCoordinates: [], on: mapView)
    }

    func removeIfNeeded(on mapView: MapView) {
        try? mapView.mapboxMap.style.removeLayer(withId: layerID)
        try? mapView.mapboxMap.style.removeSource(withId: sourceID)
        isInstalled = false
    }
}
