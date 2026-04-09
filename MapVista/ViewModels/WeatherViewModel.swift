import Foundation
import Combine

public class WeatherViewModel: ObservableObject {
    @Published public var weatherData: WeatherData?
    @Published public var fishingScore: FishingScoreResult?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let weatherService = WeatherService.shared
    
    public init() {
        fetchData()
    }
    
    public func fetchData() {
        isLoading = true
        weatherService.fetchWeatherData()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] data in
                self?.weatherData = data
                self?.fishingScore = self?.calculateFishingScore(from: data)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 核心算法：钓鱼适宜指数
    private func calculateFishingScore(from data: WeatherData) -> FishingScoreResult {
        var totalScore = 0.0
        var tips: [String] = []
        var summaryTerms: [String] = []
        
        // 1. 气压打分 (权重 30%)
        // 气压在 1010-1020 hPa 时鱼最活跃，且“稳定上升”最佳。
        var pressureScore = 0.0
        if data.pressure >= 1010 && data.pressure <= 1025 {
            pressureScore = 20
        } else if data.pressure < 1000 {
            pressureScore = 0  // 气压太低，鱼潜水底不吃食
        } else {
            pressureScore = 15
        }
        
        if data.pressureTrend == .rising {
            pressureScore += 10
            summaryTerms.append("气压攀升")
            tips.append("气压上涨，水中溶氧量增加，鱼开口意愿极强")
        } else if data.pressureTrend == .stable {
            pressureScore += 8
            summaryTerms.append("气压稳定")
        } else {
            pressureScore -= 5
            summaryTerms.append("气压下降")
            tips.append("气压正在下降，建议钓底或寻找深水区")
        }
        totalScore += max(0, min(30, pressureScore)) // 封顶30
        
        // 2. 风力打分 (权重 20%)
        // 微风(3-15km/h)吹拂水面增加溶氧，太大的风影响抛竿及看漂。
        var windScore = 0.0
        if data.windSpeed > 3 && data.windSpeed <= 15 {
            windScore = 20
            summaryTerms.append("微风拂面")
        } else if data.windSpeed < 3 {
            windScore = 15
            tips.append("水面平静，警惕性高的鱼类不易咬钩，建议延长子线")
        } else if data.windSpeed <= 25 {
            windScore = 10
            tips.append("风力较大，建议使用大吃铅量浮漂")
        } else {
            windScore = 0
            summaryTerms.append("大风")
            tips.append("风浪过大，抛竿困难且不安全")
        }
        totalScore += windScore
        
        // 3. 潮汐打分 (权重 20%) 主要针对海钓或河口
        // 涨潮过程（初涨-满潮前）和退潮前三分之一是黄金窗口（俗称"抢潮头"）。
        var tideScore = 0.0
        switch data.tideStage {
        case .rising:
            tideScore = 20
            summaryTerms.append("正值涨潮")
            tips.append("活水带来丰富食物，是海钓的最佳时段")
        case .falling:
            tideScore = 12
            summaryTerms.append("开始退潮")
        case .high, .low:
            tideScore = 5
            tips.append("当前处于平潮期，水流趋缓，鱼口较差，适合休息")
        }
        totalScore += tideScore
        
        // 4. 降水及云量 (权重 20%)
        // 细雨或阴天(高云量)遮挡强光，鱼类敢于靠边。暴雨则非常不利。
        var rainScore = 0.0
        if data.rainProbability > 0.8 {
            rainScore = 0
            summaryTerms.append("暴雨预警")
            tips.append("大雨导致水体浑浊且危险，请停止作钓")
        } else if data.rainProbability > 0.2 && data.rainProbability <= 0.8 {
            rainScore = 20
            summaryTerms.append("蒙蒙细雨")
            tips.append("阵雨/细雨会带入昆虫和氧气，是上大鱼的绝佳时机")
        } else {
            // 没雨看云量 (阴天优于暴晒)
            if data.cloudCover > 0.6 {
                rainScore = 18
                summaryTerms.append("阴天")
                tips.append("阴天弱光环境，鱼类离开深水到浅滩觅食")
            } else {
                rainScore = 14
                summaryTerms.append("晴朗")
                tips.append("光线强烈，建议寻找水草区或树荫等避光处作钓")
            }
        }
        totalScore += rainScore
        
        // 5. 月相阶段 (权重 10%)
        // 满月影响夜间光水，对部分路亚有帮助，但如果白天钓，新月或上下弦月通常更好。
        var moonScore = 0.0
        if data.moonPhase == .newMoon || data.moonPhase == .firstQuarter {
            moonScore = 10
        } else if data.moonPhase == .fullMoon {
            moonScore = 5
            tips.append("正逢新月大潮或满月，注意引潮力变化")
        } else {
            moonScore = 8
        }
        totalScore += moonScore
        
        // -- 额外加减分项：水温 (极其重要，超出100分制的影响因子) --
        if let wTech = data.waterTemp {
            if wTech >= 15 && wTech <= 26 {
                // 水温极度舒适，总分 +5 (突破上限也可以)
                totalScore += 5
                tips.insert("水温(\(wTech)°C)位于目标鱼极佳舒适区，活性爆表！", at: 0)
            } else if wTech < 5 || wTech > 32 {
                totalScore -= 20
                tips.insert("水温过于极端(\(wTech)°C)，鱼类已进入休眠或避险状态", at: 0)
            }
        }
        
        // 构建最终结果
        let finalScore = Int(max(0, min(100, totalScore)))
        let level: ScoreLevel
        switch finalScore {
        case 80...100: level = .excellent
        case 60..<80:  level = .good
        case 40..<60:  level = .fair
        default:       level = .poor
        }
        
        let summary = summaryTerms.prefix(3).joined(separator: " + ")
        
        return FishingScoreResult(score: finalScore, level: level, summary: summary + "，\(level.rawValue)出钓", tips: tips)
    }
}
