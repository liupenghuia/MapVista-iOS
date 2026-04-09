import SwiftUI

struct SettingsView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("MapVista.UseMetricSystem") private var useMetricSystem = true
    
    @State private var showingClearAlert = false
    @State private var showingHistoryClearedToast = false
    @State private var cacheSize: String = "计算中..."
    
    var body: some View {
        Form {
                Section(header: Text("通用")) {
                    Toggle(isOn: $useMetricSystem) {
                        Label {
                            Text("使用公制单位 (公里/米)")
                        } icon: {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Label {
                            Text("版本信息")
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(UIColor.systemTeal))
                        }
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("存储与数据")) {
                    HStack {
                        Label {
                            Text("本地存储空间占用")
                        } icon: {
                            Image(systemName: "internaldrive.fill")
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text(cacheSize)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        searchViewModel.clearHistory()
                        withAnimation {
                            showingHistoryClearedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingHistoryClearedToast = false
                            }
                        }
                    }) {
                        HStack {
                            Label {
                                Text(showingHistoryClearedToast ? "已清空搜索历史" : "清空搜索历史记录")
                            } icon: {
                                Image(systemName: showingHistoryClearedToast ? "checkmark.circle.fill" : "clock.arrow.circlepath")
                                    .foregroundColor(showingHistoryClearedToast ? .green : .purple)
                            }
                        }
                        .foregroundColor(showingHistoryClearedToast ? .green : .primary)
                    }
                    
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Label {
                            Text("一键清理地图缓存与瓦片碎片")
                        } icon: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("帮助与支持")) {
                    Button(action: {
                        // 支持页面的预留，如直接调用 StoreKit 评分接口
                    }) {
                        Label {
                            Text("给 MapVista 评分")
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        // 预留跳转至开发者邮箱或支持中心的功能
                    }) {
                        Label {
                            Text("联系开发者")
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("关于应用")) {
                    NavigationLink(destination: 
                        ScrollView {
                            Text("MapVista 尊重您的隐私。\n\n您的自定义位置点与搜索记录只会保存在您的本地设备上，我们暂且不支持并且不会获取您的云同步信息。\n\n定位服务仅通过安全框架调用，并且所有的渲染轨迹与检索都是通过合法、合规的方式在苹果或第三方服务下属沙盒内执行。")
                                .lineSpacing(6)
                                .padding()
                        }
                        .navigationTitle("隐私政策")
                    ) {
                        Label {
                            Text("隐私政策与服务协议")
                        } icon: {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    NavigationLink(destination: 
                        VStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Color(UIColor.systemTeal))
                                .padding(.top, 60)
                            Text("MapVista")
                                .font(.largeTitle)
                                .fontWeight(.black)
                            Text("硬核的地形探索沙盒")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("MapVista 是一款专为户外极客、徒步爱好者与钓点发现者打造的专业地形探索工具，采用前沿的三维地形渲染引擎，提供绝佳的真实交互体验。")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 20)
                            Spacer()
                        }
                    ) {
                        Label {
                            Text("关于 MapVista")
                        } icon: {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(Color(UIColor.systemTeal))
                        }
                    }
                }
            }
            .navigationTitle("设置中心")
            .navigationBarTitleDisplayMode(.inline)
            // .navigationBarItems(trailing: Button("完成") {}) // 已由 NavigationView 原生侧滑退出接管
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("确认清理缓存？"),
                    message: Text("这将清除操作系统级的一切应用缓存以及所有已下载的离线地图瓦片碎片（不影响您的自定义地点收藏），下次浏览时将重新消耗网络流量。"),
                    primaryButton: .destructive(Text("立刻清理")) {
                        clearCache()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
            .onAppear {
                calculateCacheSize()
            }
    }
    
    private func getDirectorySize(url: URL) -> Int64 {
        var size: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
    
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalSize: Int64 = 0
            
            if let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                totalSize += self.getDirectorySize(url: cacheFolder)
            }
            
            let tmpPath = URL(fileURLWithPath: NSTemporaryDirectory())
            totalSize += self.getDirectorySize(url: tmpPath)
            
            let sizeInMB = Double(totalSize) / (1024 * 1024)
            
            DispatchQueue.main.async {
                self.cacheSize = String(format: "%.1f MB", sizeInMB)
            }
        }
    }
    
    private func clearCache() {
        self.cacheSize = "清理中..."
        DispatchQueue.global(qos: .background).async {
            URLCache.shared.removeAllCachedResponses()
            
            if let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                if let contents = try? FileManager.default.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil) {
                    for url in contents {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            }
            
            let tmpPath = NSTemporaryDirectory()
            if let tmpContents = try? FileManager.default.contentsOfDirectory(atPath: tmpPath) {
                for file in tmpContents {
                    let fullPath = (tmpPath as NSString).appendingPathComponent(file)
                    try? FileManager.default.removeItem(atPath: fullPath)
                }
            }
            
            DispatchQueue.main.async {
                self.cacheSize = "0.0 MB"
            }
        }
    }
}
