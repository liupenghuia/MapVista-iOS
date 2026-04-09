// 文件路径: MapVista/Views/SplashView.swift
// 作用: 启动画面，展示品牌视觉并在短暂停留后切换到首页

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.85

    var body: some View {
        ZStack {
            background
            content
        }
        .onAppear(perform: animate)
    }

    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.06, green: 0.20, blue: 0.14),
                Color(red: 0.10, green: 0.34, blue: 0.22),
                Color(red: 0.16, green: 0.48, blue: 0.30)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 132, height: 132)
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: "mountain.2.circle.fill")
                    .font(.system(size: 78, weight: .light))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("MapVista")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("发现高精度山水地图")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .tracking(3)
            }

            Spacer()

            VStack(spacing: 12) {
                LoadingIndicatorView(style: .whiteLarge, color: .white)
                Text("正在加载地图资源…")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.bottom, 54)
        }
        .opacity(opacity)
        .scaleEffect(scale)
    }

    private func animate() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            opacity = 1
            scale = 1
        }
        isAnimating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.35)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onFinished()
            }
        }
    }
}
