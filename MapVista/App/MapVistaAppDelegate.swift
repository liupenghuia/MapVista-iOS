// 文件路径: MapVista/App/MapVistaAppDelegate.swift
// 作用: 接收系统通过“打开方式/分享”传入的 GPX 文件 URL

import UIKit

final class MapVistaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "MapVistaSceneConfiguration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = MapVistaSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GPXImportStore.shared.importGPX(from: url)
        return true
    }
}
