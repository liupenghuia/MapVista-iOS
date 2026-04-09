// 文件路径: MapVista/Services/POIService.swift
// 作用: POI 本地数据仓库，提供 Mock 数据加载与基础查询能力

import Foundation

// MARK: - POI 数据仓库协议
protocol POIServiceProtocol {
    func loadAllPOIs() -> [POIModel]
    func poi(for id: String) -> POIModel?
    func featuredPOIs(limit: Int) -> [POIModel]
}

// MARK: - 本地 Mock 数据源
final class LocalMockPOIService: POIServiceProtocol {
    private let pois: [POIModel]

    init(pois: [POIModel] = POIModel.mockData) {
        self.pois = pois
    }

    func loadAllPOIs() -> [POIModel] {
        pois
    }

    func poi(for id: String) -> POIModel? {
        pois.first { $0.id == id }
    }

    func featuredPOIs(limit: Int) -> [POIModel] {
        Array(pois.prefix(limit))
    }
}
