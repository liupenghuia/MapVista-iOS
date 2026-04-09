// 文件路径: MapVista/ContentView.swift
// 作用: 调试与预览入口，直接挂载 AppRootView

import SwiftUI

struct ContentView: View {
    private let container = AppContainer()

    var body: some View {
        AppRootView(
            mapViewModel: container.mapViewModel,
            searchViewModel: container.searchViewModel
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
