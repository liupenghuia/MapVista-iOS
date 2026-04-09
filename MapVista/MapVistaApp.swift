// 文件路径: MapVista/MapVistaApp.swift
// 作用: SwiftUI 应用入口，负责初始化依赖并挂载根视图

import SwiftUI

@main
struct MapVistaApp: App {
    private let container = AppContainer()

    init() {
        MapVistaAppBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                mapViewModel: container.mapViewModel,
                searchViewModel: container.searchViewModel
            )
        }
    }
}

enum MapVistaAppBootstrap {
    static func configure() {
        MapboxConfig.applyAccessToken()
    }
}
