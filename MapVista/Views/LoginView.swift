import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 背景
            Color("ThemeBackground", bundle: nil) // 假设您有这一Color，如果没有可以改成Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo 或 App名称
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("MapVista")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    Text("探索、记录你的每一次旅程")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 登录错误提示
                if let errorMsg = viewModel.errorMessage {
                    Text(errorMsg)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    // Apple ID 登录按钮
                    SignInWithAppleButton(.signIn) { request in
                        // 配置请求
                        viewModel.configureSignInRequest(request)
                        
                    } onCompletion: { result in
                        // 处理结果回调
                        viewModel.handleSignInResult(result)
                    }
                    // 根据当前系统的外观设置按钮样式 (黑夜模式用白底按钮，白天模式用黑底按钮)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    
                    #if DEBUG
                    // 仅供开发调试的模拟登录按钮
                    Button(action: {
                        AuthService.shared.mockLogin()
                    }) {
                        Text("🛠 开发者模拟登录 (跳过Apple)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue.cornerRadius(8))
                            .padding(.horizontal, 40)
                    }
                    #endif
                }
                .padding(.bottom, 60)
            }
            
            // Loading 遮罩
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

// 预览
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
