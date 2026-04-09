import Foundation
import AuthenticationServices
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: UserModel?
    @Published var isAuthenticated: Bool = false
    
    private let userKeychainKey = "com.mapvista.appleAuthUser"
    
    init() {
        // 在初始化时检查是否已经保存了用户信息
        checkExistingAuth()
    }
    
    func checkExistingAuth() {
        // 从 UserDefaults 或是 Keychain 中读取数据。
        if let data = UserDefaults.standard.data(forKey: userKeychainKey),
           let user = try? JSONDecoder().decode(UserModel.self, from: data) {
            
            // 如果是我们在模拟登录中分配的 "debug_user_id"，直接放行
            if user.id == "debug_user_id" {
                self.currentUser = user
                self.isAuthenticated = true
                return
            }
            
            // 验证 Apple ID 凭证是否仍有效
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: user.id) { (credentialState, error) in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        self.currentUser = user
                        self.isAuthenticated = true
                    case .revoked, .notFound:
                        self.logout()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// 当 Apple ID 授权成功后调用，处理授权凭证
    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                
                let email = appleIDCredential.email
                let firstName = appleIDCredential.fullName?.givenName
                let lastName = appleIDCredential.fullName?.familyName
                
                var user = UserModel(id: userID, firstName: firstName, lastName: lastName, email: email)
                
                if firstName == nil, email == nil {
                    if let data = UserDefaults.standard.data(forKey: userKeychainKey),
                       let existingUser = try? JSONDecoder().decode(UserModel.self, from: data) {
                        user.firstName = existingUser.firstName
                        user.lastName = existingUser.lastName
                        user.email = existingUser.email
                    }
                }
                
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: userKeychainKey)
                }
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            }
            
        case .failure(let error):
            print("Apple登录失败: \(error.localizedDescription)")
        }
    }
    
    /// [开发专用] 模拟登录，用于没有开发者账号时的本地预览和调试
    func mockLogin() {
        let debugUser = UserModel(id: "debug_user_id", firstName: "Apple", lastName: "Developer", email: "debug@mapvista.com")
        
        if let encoded = try? JSONEncoder().encode(debugUser) {
            UserDefaults.standard.set(encoded, forKey: userKeychainKey)
        }
        
        self.currentUser = debugUser
        self.isAuthenticated = true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: userKeychainKey)
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}
