// 文件路径: MapVista/Services/ImageLoader.swift
// 作用: 兼容 iOS 13 的远程图片加载器，提供内存缓存、加载状态与取消能力

import Foundation
import UIKit
import Combine

// MARK: - 远程图片加载器
final class RemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private static let cache = NSCache<NSString, UIImage>()
    private var cancellable: AnyCancellable?

    deinit {
        cancel()
    }

    func load(urlString: String) {
        guard !urlString.isEmpty else { return }

        if let cached = Self.cache.object(forKey: urlString as NSString) {
            image = cached
            errorMessage = nil
            isLoading = false
            return
        }

        guard let url = URL(string: urlString) else {
            errorMessage = "图片地址无效"
            return
        }

        isLoading = true
        errorMessage = nil

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] loadedImage in
                guard let self = self, let loadedImage = loadedImage else { return }
                Self.cache.setObject(loadedImage, forKey: urlString as NSString)
                self.image = loadedImage
            }
    }

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
        isLoading = false
    }
}
