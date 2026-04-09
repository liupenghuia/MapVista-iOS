// 文件路径: MapVista/Views/Components/LoadingIndicatorView.swift
// 作用: iOS 13 兼容的加载指示器，替代 ProgressView

import SwiftUI
import UIKit

struct LoadingIndicatorView: UIViewRepresentable {
    var style: UIActivityIndicatorView.Style = .medium
    var color: UIColor? = nil

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.hidesWhenStopped = true
        if let color = color {
            indicator.color = color
        }
        indicator.startAnimating()
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if let color = color {
            uiView.color = color
        }
        if !uiView.isAnimating {
            uiView.startAnimating()
        }
    }
}
