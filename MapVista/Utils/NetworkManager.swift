import Foundation
import Combine
import Moya
import Alamofire

/// 基于 Moya + Alamofire 封装的可复用网络请求模块
public class NetworkManager {
    public static let shared = NetworkManager()

    /// Moya 的通用 Provider，接收 MultiTarget 从而支持所有的 TargetType 请求
    private let provider: MoyaProvider<MultiTarget>

    private init() {
        // 1. 基于 Alamofire 的 Session 进行底层配置
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 15 // 全局超时
        let session = Session(configuration: configuration)
        
        // 2. 集成 Moya 自带的网络日志插件
        let logger = NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
        
        // 3. 初始化 Moya Provider
        self.provider = MoyaProvider<MultiTarget>(session: session, plugins: [logger])
    }

    /// 发起泛型网路请求，通过 Combine 响应式返回并自动解析 JSON 到具体模型
    /// 纯基于 Moya 的 requestPublisher 扩展封装，不穿插原生 URLSession 代理
    /// 
    /// - Parameters:
    ///   - target: 符合 Moya TargetType 的请求目标路由
    /// - Returns: 解析出对应类型的 Combine Publisher
    public func request<T: Decodable, Target: TargetType>(_ target: Target) -> AnyPublisher<T, MoyaError> {
        return Future<T, MoyaError> { [weak self] promise in
            guard let self = self else { return }
            self.provider.request(MultiTarget(target)) { result in
                switch result {
                case .success(let response):
                    do {
                        let filteredResponse = try response.filterSuccessfulStatusCodes()
                        let mappedObject = try filteredResponse.map(T.self)
                        promise(.success(mappedObject))
                    } catch let moyaError as MoyaError {
                        promise(.failure(moyaError))
                    } catch {
                        promise(.failure(.underlying(error, response)))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

