// 文件路径: MapVista/Map/MapboxConfig.swift
// 作用: Mapbox Token、默认地图中心点、缩放范围与样式常量配置

import Foundation
import CoreLocation
import MapboxMaps

enum MapboxConfig {
    static let accessTokenKey = "MapboxAccessToken"
    static let fallbackAccessToken = "YOUR_MAPBOX_PUBLIC_TOKEN_HERE"

    static var accessToken: String {
        if let token = Bundle.main.object(forInfoDictionaryKey: accessTokenKey) as? String,
           token != fallbackAccessToken,
           !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return token
        }
        return fallbackAccessToken
    }

    static let defaultCenter = CLLocationCoordinate2D(latitude: 30.1338, longitude: 118.1688)
    static let defaultZoom: Double = 8.5
    static let defaultPitch: Double = 0
    static let defaultBearing: Double = 0

    static let defaultMinZoom: Double = 3
    static let defaultMaxZoom: Double = 20

    static func applyAccessToken() {
        ResourceOptionsManager.default.resourceOptions.accessToken = accessToken
    }
}
