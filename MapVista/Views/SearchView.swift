// 文件路径: MapVista/Views/SearchView.swift
// 作用: 全屏搜索页，支持本地 POI 搜索、搜索历史管理和结果联动地图选中

import SwiftUI

struct SearchView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    let onResultSelected: (SearchResult) -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                Divider()

                if searchViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    historySection
                } else {
                    resultsSection
                }
            }
            .navigationBarTitle("搜索", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.systemTeal)
            )
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("输入景点、山峰、湖泊名称", text: $searchViewModel.searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !searchViewModel.searchText.isEmpty {
                Button(action: {
                    searchViewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var historySection: some View {
        Group {
            if searchViewModel.searchHistory.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.secondary)
                    Text("暂无搜索历史")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    Section(header: historyHeader) {
                        ForEach(searchViewModel.searchHistory, id: \.self) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text(item)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    searchViewModel.removeHistoryItem(item)
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                searchViewModel.confirmSearch(item)
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
        }
    }

    private var historyHeader: some View {
        HStack {
            Text("搜索历史")
            Spacer()
            Button("清除全部") {
                searchViewModel.clearHistory()
            }
            .foregroundColor(.systemTeal)
        }
    }

    private var resultsSection: some View {
        Group {
            if searchViewModel.isSearching {
                VStack {
                    Spacer()
                    LoadingIndicatorView(style: .large, color: .systemTeal)
                    Text("搜索中…")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if searchViewModel.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.secondary)
                    Text("未找到相关结果")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(searchViewModel.searchResults) { result in
                        Button(action: {
                            searchViewModel.addToHistory(result.name)
                            onResultSelected(result)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            SearchResultRow(result: result)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// MARK: - 搜索结果行
struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.category.iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.systemTeal)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(result.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    if let distanceText = result.formattedDistance {
                        Text(distanceText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Text(result.intro)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}
