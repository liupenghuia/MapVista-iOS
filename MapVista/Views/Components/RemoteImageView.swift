// 文件路径: MapVista/Views/Components/RemoteImageView.swift
// 作用: iOS 13 兼容的远程图片视图，结合缓存加载器展示 POI 封面图

import SwiftUI
import UIKit

struct RemoteImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    @ObservedObject private var loader: RemoteImageLoader

    init(urlString: String, contentMode: ContentMode = .fill) {
        self.urlString = urlString
        self.contentMode = contentMode
        _loader = ObservedObject(wrappedValue: RemoteImageLoader())
    }

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                Color(.secondarySystemBackground)
                LoadingIndicatorView(style: .large, color: .systemTeal)
            } else {
                placeholderView
            }
        }
        .onAppear {
            loader.load(urlString: urlString)
        }
        .onDisappear {
            loader.cancel()
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}
