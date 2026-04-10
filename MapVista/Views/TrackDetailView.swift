import SwiftUI
import CoreLocation
import UIKit

struct TrackDetailView: View {
    let record: TrackRecord

    @ObservedObject private var trackService = TrackRecordingService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var cameraState: MapCameraState
    @State private var selectedStyle: MapStyle = .standard
    @State private var sceneMode: MapSceneMode = .twoD

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    init(record: TrackRecord) {
        self.record = record
        _cameraState = State(initialValue: Self.initialCameraState(for: record.points.map(\.coordinate)))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            MapboxMapView(
                cameraState: $cameraState,
                locationRecenterToken: 0,
                selectedStyle: $selectedStyle,
                sceneMode: $sceneMode,
                pois: [],
                selectedPOI: nil,
                routeCoordinates: [],
                currentTrackPoints: record.points.map(\.coordinate),
                currentLocation: nil,
                onPOITap: { _ in },
                onMapTap: { _ in },
                onMapLongPress: nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("轨迹详情")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: trailingActions)
        .background(Color.mapCanvasBackground.ignoresSafeArea())
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.systemTeal.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "location.viewfinder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.systemTeal)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(record.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(dateRangeText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                trackInfoChip(title: "点数", value: "\(record.points.count)", tint: .systemTeal)
                trackInfoChip(title: "距离", value: distanceText, tint: .systemBlue)
                trackInfoChip(title: "时长", value: durationText, tint: .systemOrange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var trailingActions: some View {
        HStack(spacing: 14) {
            Button {
                if let url = trackService.generateGPX(for: record) {
                    presentShareSheet(url: url)
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                trackService.deleteRecord(record)
                dismiss()
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private var dateRangeText: String {
        let start = dateFormatter.string(from: record.startTime)
        let end = dateFormatter.string(from: record.endTime ?? record.startTime)
        return "\(start) - \(end)"
    }

    private var distanceText: String {
        if record.totalDistance < 1000 {
            return String(format: "%.0f 米", record.totalDistance)
        }
        return String(format: "%.1f 公里", record.totalDistance / 1000.0)
    }

    private var durationText: String {
        let minutes = max(1, Int(record.totalDuration / 60.0))
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        return "\(minutes / 60) 小时 \(minutes % 60) 分钟"
    }

    private func trackInfoChip(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.10))
        )
    }

    private func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController,
           let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
        }
    }

    private static func initialCameraState(for coordinates: [CLLocationCoordinate2D]) -> MapCameraState {
        guard let center = centerCoordinate(for: coordinates) else {
            return .defaultState
        }

        return MapCameraState(
            latitude: center.latitude,
            longitude: center.longitude,
            zoom: zoomLevel(for: coordinates),
            bearing: 0,
            pitch: 0
        )
    }

    private static func centerCoordinate(for coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        return CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
    }

    private static func zoomLevel(for coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 14.0 }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let latSpan = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonSpan = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        let span = max(latSpan, lonSpan)

        switch span {
        case ..<0.005:
            return 15.0
        case ..<0.02:
            return 14.0
        case ..<0.08:
            return 12.5
        case ..<0.25:
            return 11.0
        case ..<1.0:
            return 9.5
        default:
            return 8.0
        }
    }
}
