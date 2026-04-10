import SwiftUI

public struct RootTabView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var gpxImportStore: GPXImportStore
    
    @State private var selection = 0
    
    public var body: some View {
        TabView(selection: $selection) {
            MainMapView(
                mapViewModel: mapViewModel,
                searchViewModel: searchViewModel,
                gpxImportStore: gpxImportStore
            )
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("首页")
                }
                .tag(0)
            
            DiscoveryView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("发现")
                }
                .tag(1)
            
            ProfileView(searchViewModel: searchViewModel)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("我的")
                }
                .tag(2)
        }
        .accentColor(.systemTeal)
    }
}
