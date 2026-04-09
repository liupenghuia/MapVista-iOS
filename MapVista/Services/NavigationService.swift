// 文件路径: MapVista/Services/NavigationService.swift
// 作用: 导航与路线计算服务，MVP 阶段实现当前位置到 POI 的直线路线，预留真实导航接入

import Foundation
import CoreLocation

// MARK: - 导航模式
enum NavigationMode: String, CaseIterable, Codable {
    case straight
    case walking
    case driving

    var displayName: String {
        switch self {
        case .straight: return "直线"
        case .walking: return "步行"
        case .driving: return "驾车"
        }
    }
}

// MARK: - 路线模型
struct RouteModel {
    var origin: CLLocationCoordinate2D
    var destination: CLLocationCoordinate2D
    var coordinates: [CLLocationCoordinate2D]
    var distance: Double
    var estimatedDuration: Double
    var mode: NavigationMode
    var instructions: [String]

    var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0f 米", distance)
        }
        return String(format: "%.1f 公里", distance / 1000.0)
    }

    var durationText: String {
        let minutes = max(1, Int(estimatedDuration / 60.0))
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        return "\(minutes / 60) 小时 \(minutes % 60) 分钟"
    }
}

// MARK: - 导航服务协议
protocol NavigationServiceProtocol {
    func fetchRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: NavigationMode,
        completion: @escaping (RouteModel?) -> Void
    )
}

// MARK: - API 驱动的真实地图路径规划
final class MapboxNetworkNavigationService: NavigationServiceProtocol {
    func fetchRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: NavigationMode,
        completion: @escaping (RouteModel?) -> Void
    ) {
        let profile: String
        switch mode {
        case .straight: profile = "driving" // 没有直线API，降级为驾车
        case .walking: profile = "walking"
        case .driving: profile = "driving"
        }
        
        // 核心：请求 Mapbox 真实验算路径 (使用 driving/walking 避开山水乱穿)
        let token = MapboxConfig.accessToken
        let urlString = "https://api.mapbox.com/directions/v5/mapbox/\(profile)/\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)?geometries=geojson&access_token=\(token)"
        
        guard let url = URL(string: urlString) else {
            completion(fallbackStraight(origin: origin, destination: destination, mode: mode))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(self.fallbackStraight(origin: origin, destination: destination, mode: mode)) }
                return
            }
            
            do {
                // 解析 Mapbox Directions API 返回的 GeoJSON
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let routes = json["routes"] as? [[String: Any]],
                   let firstRoute = routes.first,
                   let geometry = firstRoute["geometry"] as? [String: Any],
                   let coords = geometry["coordinates"] as? [[Double]],
                   let distance = firstRoute["distance"] as? Double,
                   let duration = firstRoute["duration"] as? Double {
                    
                    let routeCoords = coords.compactMap { point -> CLLocationCoordinate2D? in
                        guard point.count >= 2 else { return nil }
                        return CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                    }
                    
                    let routeModel = RouteModel(
                        origin: origin,
                        destination: destination,
                        coordinates: routeCoords,
                        distance: distance,
                        estimatedDuration: duration,
                        mode: mode,
                        instructions: ["沿高亮路线行驶"]
                    )
                    DispatchQueue.main.async { completion(routeModel) }
                } else {
                    DispatchQueue.main.async { completion(self.fallbackStraight(origin: origin, destination: destination, mode: mode)) }
                }
            } catch {
                DispatchQueue.main.async { completion(self.fallbackStraight(origin: origin, destination: destination, mode: mode)) }
            }
        }.resume()
    }
    
    private func fallbackStraight(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: NavigationMode) -> RouteModel {
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distance = originLocation.distance(from: destinationLocation)
        return RouteModel(
            origin: origin,
            destination: destination,
            coordinates: [origin, destination],
            distance: distance,
            estimatedDuration: distance / (5_000.0 / 3_600.0),
            mode: mode,
            instructions: ["无法规划路径，降级为预估距离"]
        )
    }
}
