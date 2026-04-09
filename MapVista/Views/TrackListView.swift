import SwiftUI

struct TrackListView: View {
    @ObservedObject private var trackService = TrackRecordingService.shared
    
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    // 自定义格式化
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        NavigationView {
            List {
                if trackService.historyRecords.isEmpty {
                    Text("暂无轨迹记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                        
                } else {
                    ForEach(trackService.historyRecords) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.name)
                                .font(.headline)
                            
                            HStack {
                                Label("\(String(format: "%.2f", record.totalDistance / 1000)) km", systemImage: "figure.walk")
                                Spacer()
                                Label(formatDuration(record.totalDuration), systemImage: "clock")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            Text(dateFormatter.string(from: record.startTime))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button {
                                if let url = trackService.generateGPX(for: record) {
                                    presentShareSheet(url: url)
                                }
                            } label: {
                                Label("导出 GPX", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                trackService.deleteRecord(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的轨迹")
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0秒"
    }
    
    private func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // 适配 iPad 避免崩溃
        if let popover = activityVC.popoverPresentationController,
           let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // 获取系统当前最顶层的 ViewController
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}

struct TrackListView_Previews: PreviewProvider {
    static var previews: some View {
        TrackListView()
    }
}
