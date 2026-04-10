// 文件路径: MapVista/Views/MainMapView.swift
// 作用: 地图首页，负责地图展示、搜索入口、分类筛选、定位按钮、样式面板和底部 POI 卡片

import SwiftUI
import CoreLocation

struct BookmarkCoordinateWrapper: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MainMapView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var searchViewModel: SearchViewModel

    @State private var showSearchSheet = false
    @State private var showDetailSheet = false
    @State private var showStylePanel = false
    @State private var isImmersiveMode = false // 新增沉浸模式状态
    @State private var bookmarkWrapper: BookmarkCoordinateWrapper?

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                if let permissionMessage = mapViewModel.locationAuthorizationMessage() {
                    PermissionAlertView(message: permissionMessage, onSettingsTap: {
                        LocationPermissionBanner.openSettings()
                    })
                    .padding(.top, 2)
                }
                Spacer()
            }
            .padding(.top, 12)
            .offset(y: isImmersiveMode ? -200 : 0) // 顶部面板向上滑出屏幕
            .opacity(isImmersiveMode ? 0 : 1)
            
            // 轨迹记录看板
            if mapViewModel.isRecordingTrack {
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(String(format: "录制中 · 已存 %d 个点 · 距离 %.2f 公里", 
                                    mapViewModel.currentTrackPoints.count, 
                                    mapViewModel.currentTrackDistance / 1000.0))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.systemBackground).opacity(0.95))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    Spacer()
                }
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack {
                Spacer()
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        categoryMenuButton
                        
                        FloatingMapButton(
                            icon: mapViewModel.isRecordingTrack ? "stop.circle.fill" : "record.circle",
                            tintColor: .white,
                            backgroundColor: mapViewModel.isRecordingTrack ? .red : .pink
                        ) {
                            withAnimation(.spring()) {
                                if mapViewModel.isRecordingTrack {
                                    mapViewModel.trackService.stopRecording()
                                } else {
                                    mapViewModel.trackService.startRecording(name: "本次户外活动")
                                }
                            }
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    mapActionButtons
                        .padding(.trailing, 16)
                }
                .padding(.bottom, mapViewModel.selectedPOI == nil ? 96 : 260)
            }
            .offset(y: isImmersiveMode ? UIScreen.main.bounds.height / 2 : 0) // 侧边按钮向下滑出屏幕
            .opacity(isImmersiveMode ? 0 : 1)

            if let poi = mapViewModel.selectedPOI {
                VStack {
                    Spacer()
                    POIBottomCard(
                        poi: poi,
                        routeInfo: mapViewModel.routeInfo,
                        distanceText: mapViewModel.distanceText(to: poi),
                        onDetailTap: {
                            showDetailSheet = true
                        },
                        onNavigateTap: {
                            mapViewModel.startNavigation(to: poi)
                        },
                        onDismiss: {
                            showDetailSheet = false
                            mapViewModel.clearSelection()
                        }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showStylePanel {
                Color.black.opacity(0.24)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showStylePanel = false
                        }
                    }

                VStack {
                    Spacer()
                    MapStylePickerView(
                        selectedStyle: $mapViewModel.selectedStyle,
                        onDismiss: {
                            withAnimation {
                                showStylePanel = false
                            }
                        }
                    )
                }
                .transition(.move(edge: .bottom))
            }

            if mapViewModel.isLoadingPOIs {
                Color.black.opacity(0.12)
                    .edgesIgnoringSafeArea(.all)
                LoadingIndicatorView(style: .large, color: .systemTeal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSearchSheet) {
            SearchView(
                searchViewModel: searchViewModel,
                onResultSelected: { result in
                    mapViewModel.selectPOI(result.poi)
                    showSearchSheet = false
                }
            )
        }
        .sheet(isPresented: $showDetailSheet) {
            if let poi = mapViewModel.selectedPOI {
                POIDetailView(
                    poi: poi,
                    distanceText: mapViewModel.distanceText(to: poi),
                    onNavigateTap: {
                        mapViewModel.startNavigation(to: poi)
                    }
                )
            }
        }
        .sheet(item: $bookmarkWrapper) { wrapper in
            AddBookmarkSheet(
                coordinate: wrapper.coordinate,
                onConfirm: { remark, category in
                    mapViewModel.addCustomPOI(coordinate: wrapper.coordinate, remark: remark, category: category)
                    bookmarkWrapper = nil
                },
                onCancel: {
                    bookmarkWrapper = nil
                }
            )
        }
        .onAppear {
            searchViewModel.performSearch(keyword: searchViewModel.searchText)
        }
        .background(Color.mapCanvasBackground.ignoresSafeArea())
    }

    private var mapLayer: some View {
        MapboxMapView(
            cameraState: $mapViewModel.cameraState,
            locationRecenterToken: mapViewModel.locationRecenterToken,
            selectedStyle: $mapViewModel.selectedStyle,
            sceneMode: $mapViewModel.sceneMode,
            pois: mapViewModel.visiblePOIs,
            selectedPOI: mapViewModel.selectedPOI,
            routeCoordinates: mapViewModel.routeCoordinates,
            currentTrackPoints: mapViewModel.currentTrackPoints,
            currentLocation: mapViewModel.currentLocation,
            onPOITap: { poi in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    mapViewModel.selectPOI(poi)
                    searchViewModel.confirmSearch(poi.name)
                }
            },
            onMapTap: { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if mapViewModel.selectedPOI == nil {
                        // 强制：如果有选中的 POI，点击底图什么都不做，只能通过卡片右上角的 X 按钮关闭
                        // 如果没有选中的 POI，则可以切换全屏沉浸状态
                        isImmersiveMode.toggle()
                    }
                }
            },
            onMapLongPress: { coordinate in
                // 触发长按逻辑，记录经纬度并弹窗
                bookmarkWrapper = BookmarkCoordinateWrapper(coordinate: coordinate)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mapCanvasBackground)
        .clipped()
        .ignoresSafeArea()
    }




    private var categoryMenuButton: some View {
        Menu {
            Button(action: {
                mapViewModel.applyCategoryFilter(nil)
                searchViewModel.selectCategory(nil)
                searchViewModel.performSearch(keyword: searchViewModel.searchText)
            }) {
                Text("全部")
                Image(systemName: "square.grid.2x2.fill")
            }
            
            ForEach(POICategory.allCases) { category in
                Button(action: {
                    mapViewModel.applyCategoryFilter(category)
                    searchViewModel.selectCategory(category)
                    searchViewModel.performSearch(keyword: searchViewModel.searchText)
                }) {
                    Text(category.displayName)
                    Image(systemName: category.iconName)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mapViewModel.selectedCategory?.iconName ?? "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(mapViewModel.selectedCategory?.displayName ?? "全部")
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.systemTeal)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var mapActionButtons: some View {
        VStack(spacing: 10) {
            FloatingMapButton(
                icon: "magnifyingglass",
                tintColor: .white,
                backgroundColor: .systemOrange
            ) {
                showSearchSheet = true
            }

            FloatingMapButton(
                icon: mapViewModel.sceneMode == .threeD ? "cube.fill" : "square.grid.2x2",
                tintColor: .white,
                backgroundColor: mapViewModel.sceneMode == .threeD ? .systemGreen : .systemGray
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    mapViewModel.toggleSceneMode()
                }
            }

            FloatingMapButton(
                icon: "map.fill",
                tintColor: .white,
                backgroundColor: .systemTeal
            ) {
                withAnimation(.spring()) {
                    showStylePanel = true
                }
            }

            FloatingMapButton(
                icon: mapViewModel.locationManager.authorizationStatus == .denied ? "location.slash.fill" : "location.fill",
                tintColor: .white,
                backgroundColor: mapViewModel.locationManager.authorizationStatus == .denied ? .systemGray : .systemBlue
            ) {
                mapViewModel.moveToCurrentLocation()
            }
        }
    }

}



// MARK: - 悬浮按钮
private struct FloatingMapButton: View {
    let icon: String
    let tintColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tintColor)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(backgroundColor)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
