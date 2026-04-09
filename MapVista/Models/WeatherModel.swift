import Foundation

// MARK: - API / 原始业务模型

/// 气象水文综合数据模型
public struct WeatherData: Codable {
    // 基础指标
    public var temperature: Double   // 当前气温 (摄氏度)
    public var windSpeed: Double     // 风速 (km/h)
    public var windDirection: String // 风向 (例如："东南风")
    public var pressure: Double      // 当前气压 (hPa)
    public var pressureTrend: PressureTrend // 气压趋势
    
    // 潮汐与月相
    public var tideStage: TideStage  // 潮汐阶段
    public var moonAge: Double       // 月龄 (0-29.5)
    public var moonPhase: MoonPhase  // 月相枚举
    
    // 降水与环境
    public var rainProbability: Double // 降雨概率 (0-1)
    public var waterTemp: Double?      // 水温 (若有数据)
    public var cloudCover: Double      // 云量 (0-1)
    
    public init(temperature: Double, windSpeed: Double, windDirection: String, pressure: Double, pressureTrend: PressureTrend, tideStage: TideStage, moonAge: Double, moonPhase: MoonPhase, rainProbability: Double, waterTemp: Double? = nil, cloudCover: Double = 0) {
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.pressure = pressure
        self.pressureTrend = pressureTrend
        self.tideStage = tideStage
        self.moonAge = moonAge
        self.moonPhase = moonPhase
        self.rainProbability = rainProbability
        self.waterTemp = waterTemp
        self.cloudCover = cloudCover
    }
}

public enum PressureTrend: String, Codable {
    case rising = "上升"
    case falling = "下降"
    case stable = "平稳"
}

public enum TideStage: String, Codable {
    case rising = "涨潮期"
    case falling = "退潮期"
    case high = "平潮(高)"
    case low = "停潮(低)"
}

public enum MoonPhase: String, Codable {
    case newMoon = "新月"
    case waxingCrescent = "蛾眉月"
    case firstQuarter = "上弦月"
    case waxingGibbous = "盈凸月"
    case fullMoon = "满月"
    case waningGibbous = "亏凸月"
    case thirdQuarter = "下弦月"
    case waningCrescent = "残月"
}

// MARK: - 计算得分模型

/// 钓鱼适宜指数分析结果
public struct FishingScoreResult {
    public let score: Int           // 0 ~ 100
    public let level: ScoreLevel    // 评级
    public let summary: String      // 一句话短评
    public let tips: [String]       // 具体的决策建议
}

public enum ScoreLevel: String {
    case excellent = "极佳" // 80 - 100
    case good = "适合"      // 60 - 79
    case fair = "一般"      // 40 - 59
    case poor = "不建议"     // < 40
}

// MARK: - API 专属结构体 (QWeather 和风天气)

public struct QWeatherNowResponse: Codable {
    public let code: String
    public let now: QWeatherNowData?
}

public struct QWeatherNowData: Codable {
    public let temp: String      // 温度
    public let windDir: String   // 风向
    public let windSpeed: String // 风速
    public let pressure: String  // 大气压
    public let precip: String    // 降水量
    public let cloud: String?    // 云量，可能为空
}

