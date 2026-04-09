// 文件路径: MapVista/App/AppRootView.swift
// 作用: App 根视图，负责 Splash 与首页的切换

import SwiftUI

struct AppRootView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    
    @StateObject private var authService = AuthService.shared
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                RootTabView(
                    mapViewModel: mapViewModel,
                    searchViewModel: searchViewModel
                )
                .opacity(showSplash ? 0 : 1)
            } else {
                LoginView()
                    .opacity(showSplash ? 0 : 1)
            }

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
        .background(Color.mapCanvasBackground.ignoresSafeArea())
    }
}
