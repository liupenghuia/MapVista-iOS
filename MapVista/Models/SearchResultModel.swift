// 文件路径: MapVista/Models/SearchResultModel.swift
// 作用: 搜索结果模型，统一承载本地 POI 搜索命中与未来远程搜索结果

import Foundation
import CoreLocation

// MARK: - 搜索来源
enum SearchSource: String, Codable {
    case local
    case offline
    case remote
}

// MARK: - 搜索结果
struct SearchResult: Identifiable, Codable, Equatable {
    let poi: POIModel
    var distance: Double?
    var source: SearchSource

    var id: String { poi.id }
    var name: String { poi.name }
    var category: POICategory { poi.category }
    var coordinate: CLLocationCoordinate2D { poi.coordinate }
    var intro: String { poi.intro }

    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance < 1000 {
            return String(format: "%.0f 米", distance)
        }
        return String(format: "%.1f 公里", distance / 1000.0)
    }
}

// MARK: - 搜索请求
struct SearchRequest {
    var keyword: String
    var category: POICategory?
    var center: CLLocationCoordinate2D?
    var limit: Int

    init(
        keyword: String,
        category: POICategory? = nil,
        center: CLLocationCoordinate2D? = nil,
        limit: Int = 20
    ) {
        self.keyword = keyword
        self.category = category
        self.center = center
        self.limit = limit
    }
}
