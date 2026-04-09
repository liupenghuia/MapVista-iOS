// 文件路径: MapVista/App/AppContainer.swift
// 作用: App 级依赖容器，统一持有可共享的服务与 ViewModel 实例

import Foundation

final class AppContainer {
    let locationManager: LocationManager
    let poiService: POIServiceProtocol
    let searchService: SearchServiceProtocol
    let navigationService: NavigationServiceProtocol
    let cacheService: OfflineCacheProviding

    lazy var mapViewModel: MapViewModel = {
        MapViewModel(
            poiService: poiService,
            navigationService: navigationService,
            locationManager: locationManager,
            cacheService: cacheService
        )
    }()

    lazy var searchViewModel: SearchViewModel = {
        SearchViewModel(
            poiService: poiService,
            searchService: searchService,
            locationManager: locationManager
        )
    }()

    init(
        locationManager: LocationManager = LocationManager(),
        poiService: POIServiceProtocol = LocalMockPOIService(),
        searchService: SearchServiceProtocol = LocalSearchService(),
        navigationService: NavigationServiceProtocol = MapboxNetworkNavigationService(),
        cacheService: OfflineCacheProviding = MemoryOfflineCacheService() 
    ) {
        self.locationManager = locationManager
        self.poiService = poiService
        self.searchService = searchService
        self.navigationService = navigationService
        self.cacheService = cacheService
    }
}
