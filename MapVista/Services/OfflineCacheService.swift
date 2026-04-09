// 文件路径: MapVista/Services/OfflineCacheService.swift
// 作用: 预留离线缓存接口，当前提供内存实现，后续可替换为 SQLite/CoreData/文件缓存

import Foundation

// MARK: - 离线缓存协议
protocol OfflineCacheProviding {
    func cachePOIs(_ pois: [POIModel])
    func cachedPOIs() -> [POIModel]
    func cacheSelectedStyle(_ style: MapStyle)
    func cachedSelectedStyle() -> MapStyle?
    func clearAll()
}

// MARK: - 内存缓存实现
final class MemoryOfflineCacheService: OfflineCacheProviding {
    private var poiStorage: [POIModel] = []
    private var selectedStyleStorage: MapStyle?

    func cachePOIs(_ pois: [POIModel]) {
        poiStorage = pois
    }

    func cachedPOIs() -> [POIModel] {
        poiStorage
    }

    func cacheSelectedStyle(_ style: MapStyle) {
        selectedStyleStorage = style
    }

    func cachedSelectedStyle() -> MapStyle? {
        selectedStyleStorage
    }

    func clearAll() {
        poiStorage = []
        selectedStyleStorage = nil
    }
}
