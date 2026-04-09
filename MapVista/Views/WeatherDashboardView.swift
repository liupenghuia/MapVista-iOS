import SwiftUI

public struct WeatherDashboardView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("加载气象及水文数据...")
                        .padding(.top, 100)
                } else if let error = viewModel.errorMessage {
                    Text("获取失败: \(error)")
                        .foregroundColor(.red)
                } else if let data = viewModel.weatherData, let score = viewModel.fishingScore {
                    // 1. 顶部：综合评分区
                    TopScoreCard(scoreResult: score)
                    
                    // 2. 详细指标说明区
                    TipsCard(tips: score.tips)
                    
                    // 3. 中部：多维指标面板
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        IndicatorCard(icon: "thermometer", title: "当前气温", value: "\(data.temperature)°C", desc: "体感极佳")
                        IndicatorCard(icon: "wind", title: "风力风向", value: "\(data.windDirection) \(data.windSpeed)km/h", desc: "增加水面溶氧量")
                        IndicatorCard(icon: "barometer", title: "大气压", value: "\(data.pressure)hPa", desc: "趋势: \(data.pressureTrend.rawValue)")
                        IndicatorCard(icon: "cloud.rain", title: "降雨概率", value: "\(Int(data.rainProbability * 100))%", desc: "影响水文浊度")
                        IndicatorCard(icon: "cloud", title: "云量", value: "\(Int(data.cloudCover * 100))%", desc: "遮挡强紫外线")
                        IndicatorCard(icon: "thermometer.sun", title: "预估水温", value: data.waterTemp != nil ? "\(data.waterTemp!)°C" : "--", desc: "鱼类活性生命线")
                        IndicatorCard(icon: "water.waves", title: "潮汐流向", value: data.tideStage.rawValue, desc: "海钓极佳参考")
                        IndicatorCard(icon: "moon.stars", title: "月相", value: data.moonPhase.rawValue, desc: "月龄: \(data.moonAge)")
                    }
                    
                    // 4. 雷达与地图联动入口
                    VStack(alignment: .leading, spacing: 12) {
                        Text("环境雷达 & 趋势")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 140)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue.opacity(0.8))
                                Text("开启降雨雷达图层")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        // 预留关联到 MapViewModel 切换 Layer 的接口
                        .onTapGesture {
                            print("切换雷达图层...")
                        }
                    }
                    .padding(.top, 10)
                    
                }
            }
            .padding()
        }
        .background(Color(red: 0.1, green: 0.12, blue: 0.15).ignoresSafeArea()) // 户外高级深色风格
        .navigationTitle("气象水文分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 子视图组件
struct TopScoreCard: View {
    let scoreResult: FishingScoreResult
    
    var gradientColors: [Color] {
        switch scoreResult.level {
        case .excellent: return [Color.green, Color.blue]
        case .good: return [Color.blue, Color.purple]
        case .fair: return [Color.orange, Color.yellow]
        case .poor: return [Color.red, Color.orange]
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("钓鱼适宜指数")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(scoreResult.score)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundColor(.clear)
                .overlay(
                    LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .mask(Text("\(scoreResult.score)")
                                .font(.system(size: 72, weight: .black, design: .rounded)))
                )
            
            Text(scoreResult.summary)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LinearGradient(colors: gradientColors.map{$0.opacity(0.5)}, startPoint: .top, endPoint: .bottom), lineWidth: 1)
                )
        )
    }
}

struct IndicatorCard: View {
    let icon: String
    let title: String
    let value: String
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(UIColor.systemTeal))
                    .font(.system(size: 18))
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

struct TipsCard: View {
    let tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("大师作钓建议")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color(UIColor.systemTeal))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

struct WeatherDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDashboardView()
            .preferredColorScheme(.dark)
    }
}
