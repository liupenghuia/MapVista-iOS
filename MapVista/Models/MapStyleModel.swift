// 文件路径: MapVista/Models/MapStyleModel.swift
// 作用: 地图样式枚举与地图相机状态模型，统一管理样式切换与默认镜头

import Foundation
import CoreLocation
import MapboxMaps

// MARK: - 地图样式
enum MapStyle: String, CaseIterable, Identifiable, Codable {
    case standard = "mapbox://styles/mapbox/streets-v12"
    case satellite = "mapbox://styles/mapbox/satellite-streets-v12"
    case terrain = "mapbox://styles/mapbox/outdoors-v12"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "标准"
        case .satellite: return "卫星"
        case .terrain: return "山水"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return "清晰路网与基础地形"
        case .satellite: return "卫星影像与地标更直观"
        case .terrain: return "山地、林地与自然纹理"
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "map.fill"
        case .satellite: return "globe.asia.australia.fill"
        case .terrain: return "mountain.2.fill"
        }
    }

    var styleURI: StyleURI {
        StyleURI(rawValue: rawValue) ?? .streets
    }
}

// MARK: - 地图 2D / 3D 模式
enum MapSceneMode: String, CaseIterable, Identifiable, Codable {
    case twoD
    case threeD

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twoD:
            return "2D"
        case .threeD:
            return "3D"
        }
    }

    var subtitle: String {
        switch self {
        case .twoD:
            return "平面浏览"
        case .threeD:
            return "地形透视"
        }
    }

    var iconName: String {
        switch self {
        case .twoD:
            return "square.grid.2x2"
        case .threeD:
            return "cube.fill"
        }
    }

    var cameraPitch: Double {
        switch self {
        case .twoD:
            return 0
        case .threeD:
            // 使用经典的 65 度以上大仰角，才能真正体现出高精度连绵起伏的山峰
            return 65
        }
    }
}

// MARK: - 地图镜头状态
struct MapCameraState: Equatable, Codable {
    var latitude: Double
    var longitude: Double
    var zoom: Double
    var bearing: Double
    var pitch: Double

    static let defaultState = MapCameraState(
        latitude: 30.1338,
        longitude: 118.1688,
        zoom: 8.5,
        bearing: 0,
        pitch: 0
    )

    static let terrainState = MapCameraState(
        latitude: 30.1338,
        longitude: 118.1688,
        zoom: 12.0,
        bearing: 0,
        pitch: 28
    )

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
