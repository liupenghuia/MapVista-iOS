// 文件路径: MapVista/App/MapVistaSceneDelegate.swift
// 作用: 接收场景级别的外部文件打开事件，兼容微信等应用的文档打开流程

import UIKit

final class MapVistaSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        handle(connectionOptions: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            GPXImportStore.shared.importGPX(from: context.url)
        }
    }

    private func handle(connectionOptions: UIScene.ConnectionOptions) {
        for context in connectionOptions.urlContexts {
            GPXImportStore.shared.importGPX(from: context.url)
        }
    }
}
