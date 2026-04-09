import Foundation

/// 表示当前登录的用户
struct UserModel: Codable, Identifiable {
    var id: String      // Apple提供的唯一用户ID
    var firstName: String?
    var lastName: String?
    var email: String?
    
    // 可能需要的其他属性
    var token: String? // 如果和自己的后端交互，可能会有一个后端生成的Token
}
