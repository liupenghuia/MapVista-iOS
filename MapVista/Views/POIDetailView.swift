// 文件路径: MapVista/Views/POIDetailView.swift
// 作用: POI 详情页，展示大图、标题、分类、简介、经纬度和“导航到这里”按钮

import SwiftUI

struct POIDetailView: View {
    let poi: POIModel
    let distanceText: String?
    let onNavigateTap: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: closeButton)
        }
    }

    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 34, height: 34)
                .background(Color(.systemBackground).opacity(0.92))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = poi.primaryImageURL {
                RemoteImageView(urlString: imageURL, contentMode: .fill)
                    .frame(height: 320)
                    .clipped()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.systemTeal, Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 320)
                .overlay(
                    Image(systemName: poi.category.iconName)
                        .font(.system(size: 70, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                )
            }

            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.02), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 320)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(poi.category.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(18)

                    if poi.isOfflineAvailable {
                        Text("可离线")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.18))
                            .cornerRadius(18)
                    }
                }

                Text(poi.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                if !poi.intro.isEmpty {
                    Text(poi.intro)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(4)
                        .lineLimit(3)
                }
            }
            .padding(20)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            metricGrid

            infoCard(title: "景点介绍") {
                Text(poi.detailDescription.isEmpty ? poi.intro : poi.detailDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }

            infoCard(title: "坐标信息") {
                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "纬度", value: String(format: "%.6f", poi.latitude))
                    detailRow(label: "经度", value: String(format: "%.6f", poi.longitude))
                    if !poi.address.isEmpty {
                        detailRow(label: "地址", value: poi.address)
                    }
                    if let distanceText = distanceText {
                        detailRow(label: "距离", value: distanceText)
                    }
                }
            }

            if !poi.tags.isEmpty {
                infoCard(title: "标签") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(poi.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }

            actionButton
        }
        .padding(20)
    }

    private var metricGrid: some View {
        HStack(spacing: 12) {
            MetricCard(title: "评分", value: String(format: "%.1f", poi.rating), icon: "star.fill", tintColor: .systemYellow)
            MetricCard(title: "海拔", value: poi.altitude.map { String(format: "%.0f m", $0) } ?? "--", icon: "mountain.2.fill", tintColor: .systemOrange)
            MetricCard(title: "开放", value: poi.openHours ?? "全天", icon: "clock.fill", tintColor: .systemTeal)
        }
    }

    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            content()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            Spacer()
        }
    }

    private var actionButton: some View {
        Button(action: onNavigateTap) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                Text("导航到这里")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.systemTeal)
            .cornerRadius(18)
            .shadow(color: Color.systemTeal.opacity(0.25), radius: 14, x: 0, y: 8)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(tintColor)
                .font(.system(size: 16, weight: .semibold))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
