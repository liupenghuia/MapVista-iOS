import SwiftUI

struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let iconColor: Color
    let viewDestination: AnyView?
}

public struct ProfileView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background Gradient Area (Matches the top texture/gradient from the design)
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.88, green: 0.98, blue: 0.94), Color(UIColor.systemGroupedBackground)]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // User Header Module
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 68, height: 68)
                                .foregroundColor(.gray.opacity(0.8))
                                .background(Circle().fill(Color.white))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("微信用户sYoo")
                                    .font(.system(size: 20, weight: .bold))
                                HStack(spacing: 4) {
                                    Text("ID: 93804")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                        
                        // VIP Black Card Module
                        VStack(alignment: .leading) {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                        .foregroundColor(Color(red: 0.98, green: 0.88, blue: 0.65))
                                    Text("你还未开通会员")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(Color(red: 0.98, green: 0.88, blue: 0.65))
                                }
                                Spacer()
                                Button(action: {}) {
                                    Text("立即解锁")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.15))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.98, green: 0.88, blue: 0.65))
                                        .cornerRadius(16)
                                }
                            }
                            Text("开通VIP，获取超多会员权益")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 2)
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.25, green: 0.28, blue: 0.25), Color(red: 0.15, green: 0.15, blue: 0.15)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.top, 30)
                        .zIndex(2)
                        
                        // White Box Menu Grid Module
                        VStack {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 28) {
                                ForEach(menuItems) { item in
                                    if let dest = item.viewDestination {
                                        NavigationLink(destination: dest) {
                                            menuItemView(item: item)
                                        }
                                    } else {
                                        Button(action: {}) {
                                            menuItemView(item: item)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 40)
                            .padding(.bottom, 30)
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, -20) // Create the overlapping effect with the VIP card
                        .zIndex(1)
                        
                        Spacer().frame(height: 60)
                        
                        // Bottom Version Text Module
                        Text("云上山水地图 V1.0.1")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // Force Navigation View to Stack style to prevent iPad split view layout behavior
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func menuItemView(item: ProfileMenuItem) -> some View {
        VStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(item.iconColor)
                .frame(width: 40, height: 40)
            Text(item.title)
                .font(.system(size: 12))
                .foregroundColor(Color.primary.opacity(0.9))
                .lineLimit(1)
        }
    }
    
    private var menuItems: [ProfileMenuItem] {
        [
            ProfileMenuItem(icon: "map", title: "地图设置", iconColor: .green, viewDestination: AnyView(SettingsView(searchViewModel: searchViewModel))),
            ProfileMenuItem(icon: "location.viewfinder", title: "我的轨迹", iconColor: .orange, viewDestination: AnyView(TrackListView())),
            ProfileMenuItem(icon: "person.crop.rectangle", title: "账户设置", iconColor: Color(UIColor.systemTeal), viewDestination: nil),
            ProfileMenuItem(icon: "star", title: "我的收藏", iconColor: .primary, viewDestination: nil),
            ProfileMenuItem(icon: "exclamationmark.bubble", title: "投诉反馈", iconColor: .green, viewDestination: nil),
            
            ProfileMenuItem(icon: "doc.text.viewfinder", title: "开具发票", iconColor: .primary, viewDestination: nil),
            ProfileMenuItem(icon: "book.pages", title: "帮助中心", iconColor: Color(UIColor.systemTeal), viewDestination: nil),
            ProfileMenuItem(icon: "checkmark.seal", title: "测绘资质", iconColor: .green, viewDestination: nil),
            ProfileMenuItem(icon: "person.2", title: "关于我们", iconColor: .green, viewDestination: nil),
            
            ProfileMenuItem(icon: "envelope.badge", title: "联系我们", iconColor: .green, viewDestination: nil),
            ProfileMenuItem(icon: "square.and.pencil", title: "用户协议", iconColor: .green, viewDestination: nil),
            ProfileMenuItem(icon: "lock.shield", title: "隐私政策", iconColor: .green, viewDestination: nil)
        ]
    }
}
