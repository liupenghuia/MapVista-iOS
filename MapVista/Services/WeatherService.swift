import Foundation
import Combine
import CoreLocation
import Moya
import Alamofire

/// 和风天气 API 路由枚举
public enum WeatherAPI {
    case now(longitude: Double, latitude: Double, apiKey: String)
}

extension WeatherAPI: TargetType {
    public var baseURL: URL {
        return URL(string: "https://pk5u9wwtcm.re.qweatherapi.com/v7")!
    }
    
    public var path: String {
        switch self {
        case .now:
            return "/weather/now"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }

    public var task: Task {
        switch self {
        case .now(let lon, let lat, let apiKey):
            return .requestParameters(
                parameters: [
                    "location": "\(lon),\(lat)",
                    "key": apiKey
                ],
                encoding: URLEncoding.default
            )
        }
    }

    public var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}

/// 负责聚合各类气象、水文API的数据服务
public class WeatherService {
    public static let shared = WeatherService()
    
    // 🪪 步骤 1: 在和风天气控制台获取 Key 后，替换这里的字符串
    private let qweatherAPIKey = "ca79bc610f704c4e98b98673ceb7baf7"
    
    // 返回 Publisher 以供 ViewModel 订阅
    public func fetchWeatherData(location: CLLocationCoordinate2D? = nil) -> AnyPublisher<WeatherData, Error> {
        
        let lon = location?.longitude ?? 116.40
        let lat = location?.latitude ?? 39.90
        
        let target = WeatherAPI.now(longitude: lon, latitude: lat, apiKey: qweatherAPIKey)
        
        // 使用封装好的 NetworkManager
        return NetworkManager.shared.request(target)
            .tryMap { (response: QWeatherNowResponse) -> WeatherData in
                guard response.code == "200", let now = response.now else {
                    // API 返回授权等业务错误，可以统一处理或抛出
                    if response.code == "403" {
                        throw URLError(.userAuthenticationRequired)
                    }
                    throw URLError(.badServerResponse)
                }
                
                let temp = Double(now.temp) ?? 0.0
                let windSpeed = Double(now.windSpeed) ?? 0.0
                let pressure = Double(now.pressure) ?? 1013.0
                let precip = Double(now.precip) ?? 0.0
                let cloud = Double(now.cloud ?? "0") ?? 0.0
                
                return WeatherData(
                    temperature: temp,
                    windSpeed: windSpeed,
                    windDirection: now.windDir,
                    pressure: pressure,
                    pressureTrend: .stable,
                    tideStage: .high,
                    moonAge: 14.5,
                    moonPhase: .fullMoon,
                    rainProbability: precip > 0 ? 0.8 : 0.0,
                    waterTemp: nil,
                    cloudCover: cloud / 100.0
                )
            }
            .eraseToAnyPublisher()
    }
    
    // 离线 Mock 备用数据 (当 API Key 没有被填写时触发)
    private func generateMockData() -> AnyPublisher<WeatherData, Error> {
        let mockData = WeatherData(
            temperature: 24.5,
            windSpeed: 12.0,      // 微风
            windDirection: "东南风(Mock)",
            pressure: 1013.2,     // 标准气压偏高，鱼进食活跃
            pressureTrend: .rising,
            tideStage: .rising,   // 涨潮，适合钓鱼
            moonAge: 14.5,
            moonPhase: .fullMoon,
            rainProbability: 0.1, // 降雨概率10%
            waterTemp: 21.0,      // 极佳水温
            cloudCover: 0.6       // 阴天
        )
        
        return Just(mockData)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
