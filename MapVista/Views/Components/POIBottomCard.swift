// 文件路径: MapVista/Views/Components/POIBottomCard.swift
// 作用: 首页底部 POI 卡片，展示当前选中景点的核心信息并提供查看详情与导航入口

import SwiftUI

struct POIBottomCard: View {
    let poi: POIModel
    let routeInfo: RouteModel?
    let distanceText: String?
    let onDetailTap: () -> Void
    let onNavigateTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 42, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                header
                
                if !poi.address.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                        Text(poi.address)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                metricsRow

                if let routeInfo = routeInfo {
                    routeSummary(routeInfo)
                }

                HStack(spacing: 12) {
                    secondaryAction(title: "查看详情", icon: "chevron.right", backgroundColor: Color(.secondarySystemBackground)) {
                        onDetailTap()
                    }

                    primaryAction(title: "导航到这里", icon: "location.fill") {
                        onNavigateTap()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: -2)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: poi.category.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.systemTeal)
                        .clipShape(Circle())

                    Text(poi.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text(poi.intro)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            InfoPill(icon: "star.fill", text: String(format: "%.1f", poi.rating), tintColor: .systemYellow)
            Spacer()
            InfoPill(icon: "location.fill", text: distanceText ?? "距离未知", tintColor: .systemBlue)
            Spacer()
            InfoPill(icon: "map.fill", text: poi.category.displayName, tintColor: .systemTeal)
        }
    }

    private func routeSummary(_ route: RouteModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .foregroundColor(.systemTeal)
            Text("直线 \(route.distanceText) · 约 \(route.durationText)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func primaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.systemTeal)
            .cornerRadius(16)
        }
    }

    private func secondaryAction(title: String, icon: String, backgroundColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: icon)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .cornerRadius(16)
        }
    }
}

private struct InfoPill: View {
    let icon: String
    let text: String
    let tintColor: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tintColor)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}
