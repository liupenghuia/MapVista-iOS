// 文件路径: MapVista/Views/Components/MapStylePickerView.swift
// 作用: 地图样式选择面板，提供标准、卫星、山水三种样式切换

import SwiftUI
import UIKit

struct MapStylePickerView: View {
    @Binding var selectedStyle: MapStyle
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            HStack(spacing: 12) {
                ForEach(MapStyle.allCases) { style in
                    StyleCard(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        selectedStyle = style
                        // 选择后自动隐藏面板
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDismiss()
                        }
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(22, corners: [.topLeft, .topRight])
    }

    private var header: some View {
        HStack {
            Text("地图样式")
                .font(.system(size: 17, weight: .semibold))
            Spacer()
            Button("完成", action: onDismiss)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.systemTeal)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct StyleCard: View {
    let style: MapStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                        .frame(height: 78)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.systemTeal : Color.clear, lineWidth: 3)
                        )

                    Image(systemName: style.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(spacing: 2) {
                    Text(style.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .systemTeal : .primary)
                    Text(style.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var backgroundColor: Color {
        switch style {
        case .standard:
            return Color(red: 0.95, green: 0.96, blue: 0.97)
        case .satellite:
            return Color.blue.opacity(0.15)
        case .terrain:
            return Color.green.opacity(0.15)
        }
    }

    private var iconColor: Color {
        switch style {
        case .standard:
            return .primary
        case .satellite:
            return .blue
        case .terrain:
            return .green
        }
    }
}

// MARK: - 指定圆角
private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
