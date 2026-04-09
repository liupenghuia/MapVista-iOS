// 文件路径: MapVista/ViewModels/SearchViewModel.swift
// 作用: 搜索页状态管理，负责关键词防抖、本地搜索过滤、历史记录与结果联动

import Foundation
import CoreLocation
import Combine
import MapKit

final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [SearchResult] = []
    @Published private(set) var searchHistory: [String] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var selectedCategory: POICategory?

    var currentLocation: CLLocation?

    private let poiService: POIServiceProtocol
    private let searchService: SearchServiceProtocol
    private let locationManager: LocationManager
    private var allPOIs: [POIModel] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        poiService: POIServiceProtocol = LocalMockPOIService(),
        searchService: SearchServiceProtocol = LocalSearchService(),
        locationManager: LocationManager = LocationManager()
    ) {
        self.poiService = poiService
        self.searchService = searchService
        self.locationManager = locationManager

        loadData()
        loadSearchHistory()
        bindSearchInput()
        bindLocationUpdates()
    }

    private func loadData() {
        allPOIs = poiService.loadAllPOIs()
    }

    private func bindSearchInput() {
        $searchText
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(keyword: text)
            }
            .store(in: &cancellables)

        $selectedCategory
            .sink { [weak self] _ in
                self?.performSearch(keyword: self?.searchText ?? "")
            }
            .store(in: &cancellables)
    }

    private func bindLocationUpdates() {
        locationManager.$currentLocation
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.performSearch(keyword: self?.searchText ?? "")
            }
            .store(in: &cancellables)
    }

    func performSearch(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let basePOIs = filteredSourcePOIs()

        if trimmed.isEmpty {
            searchResults = basePOIs.prefix(6).map { poi in
                SearchResult(poi: poi, distance: currentLocation.map { poi.coordinate.distance(to: $0.coordinate) }, source: .local)
            }
            isSearching = false
            return
        }

        isSearching = true
        // 1. 先检索本地收藏夹/打点的记录
        let localResults = searchService.search(
            keyword: trimmed,
            category: selectedCategory,
            center: currentLocation?.coordinate,
            in: basePOIs,
            limit: 5 // 限制本地结果条数
        )

        // 2. 融合 Apple 原生的在线地理检索引擎，以支持搜“保定”或“水库”
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let center = currentLocation?.coordinate {
            request.region = MKCoordinateRegion(center: center, latitudinalMeters: 100000, longitudinalMeters: 100000)
        }

        let mapSearch = MKLocalSearch(request: request)
        mapSearch.start { [weak self] response, error in
            guard let self = self else { return }
            
            var networkResults: [SearchResult] = []
            
            if let mapItems = response?.mapItems {
                networkResults = mapItems.prefix(15).map { item in
                    let poi = POIModel(
                        name: item.name ?? "未知地点",
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude,
                        intro: item.placemark.title ?? "地理位置",
                        category: .custom, // 使用自定义默认图标
                        detailDescription: "来自在线地图检索",
                        address: item.placemark.title ?? "",
                        rating: 0
                    )
                    let dist = self.currentLocation.map { poi.coordinate.distance(to: $0.coordinate) }
                    return SearchResult(poi: poi, distance: dist, source: .remote)
                }
            }
            
            DispatchQueue.main.async {
                self.searchResults = localResults + networkResults
                self.isSearching = false
            }
        }
    }

    func addToHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        searchHistory.removeAll { $0 == trimmed }
        searchHistory.insert(trimmed, at: 0)
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }
        UserDefaults.standard.set(searchHistory, forKey: Self.historyKey)
    }

    func removeHistoryItem(_ query: String) {
        searchHistory.removeAll { $0 == query }
        UserDefaults.standard.set(searchHistory, forKey: Self.historyKey)
    }

    func clearHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }

    func confirmSearch(_ query: String) {
        addToHistory(query)
        searchText = query
        performSearch(keyword: query)
    }

    func selectCategory(_ category: POICategory?) {
        selectedCategory = category
    }

    func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = filteredSourcePOIs().prefix(6).map { poi in
            SearchResult(poi: poi, distance: currentLocation.map { poi.coordinate.distance(to: $0.coordinate) }, source: .local)
        }
    }

    private func filteredSourcePOIs() -> [POIModel] {
        guard let selectedCategory = selectedCategory else { return allPOIs }
        return allPOIs.filter { $0.category == selectedCategory }
    }

    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
    }

    private static let historyKey = "MapVista.SearchHistory"
}
