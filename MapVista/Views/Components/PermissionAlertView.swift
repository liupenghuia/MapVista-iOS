// 文件路径: MapVista/Views/Components/PermissionAlertView.swift
// 作用: 定位权限状态提示条，提供跳转系统设置入口

import SwiftUI
import UIKit

struct PermissionAlertView: View {
    let message: String
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 18))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("需要定位权限")
                    .font(.system(size: 14, weight: .semibold))
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button("去开启") {
                onSettingsTap()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.orange)
            .cornerRadius(10)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

enum LocationPermissionBanner {
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
