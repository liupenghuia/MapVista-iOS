import Foundation
import AuthenticationServices
import Combine

class LoginViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let authService = AuthService.shared
    
    // 配置 Apple ID 请求
    func configureSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        // 请求全名和电子邮箱。注意：此信息往往仅在首次授权时返回
        request.requestedScopes = [.fullName, .email]
    }
    
    // 处理回调结果
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        // 可以加上Loading状态
        self.isLoading = true
        
        // 传递给服务层处理
        authService.handleAuthorization(result: result)
        
        // 简单模拟一下网络延时解除 Loading，实际中AuthService处理完会自动更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            if case .failure(let error) = result {
                self.errorMessage = "登录出错: \(error.localizedDescription)"
            }
        }
    }
}
