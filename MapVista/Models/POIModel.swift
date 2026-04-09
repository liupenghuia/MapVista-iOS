// 文件路径: MapVista/Models/POIModel.swift
// 作用: POI 数据模型，定义景点基础信息、展示信息与本地 mock 数据

import Foundation
import CoreLocation

// MARK: - POI 分类
enum POICategory: String, CaseIterable, Codable, Identifiable {
    case mountain
    case lake
    case forest
    case viewpoint
    case temple
    case scenicArea
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mountain: return "山峰"
        case .lake: return "湖泊"
        case .forest: return "森林"
        case .viewpoint: return "观景台"
        case .temple: return "寺庙"
        case .scenicArea: return "景区"
        case .custom: return "自定义"
        }
    }

    var iconName: String {
        switch self {
        case .mountain: return "mountain.2.fill"
        case .lake: return "drop.fill"
        case .forest: return "leaf.fill"
        case .viewpoint: return "binoculars.fill"
        case .temple: return "building.columns.fill"
        case .scenicArea: return "map.fill"
        case .custom: return "mappin.circle.fill"
        }
    }
}

// MARK: - POI 主模型
struct POIModel: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var intro: String
    var imageURL: String?
    var category: POICategory

    var detailDescription: String
    var address: String
    var altitude: Double?
    var rating: Double
    var tags: [String]
    var openHours: String?
    var phone: String?
    var website: String?
    var isOfflineAvailable: Bool
    /// 搜索别名，补充常见简称、风景区叫法，增强本地模糊搜索命中率
    var searchAliases: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var primaryImageURL: String? {
        imageURL
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double,
        intro: String,
        imageURL: String? = nil,
        category: POICategory,
        detailDescription: String = "",
        address: String = "",
        altitude: Double? = nil,
        rating: Double = 0,
        tags: [String] = [],
        openHours: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        isOfflineAvailable: Bool = false,
        searchAliases: [String] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.intro = intro
        self.imageURL = imageURL
        self.category = category
        self.detailDescription = detailDescription
        self.address = address
        self.altitude = altitude
        self.rating = rating
        self.tags = tags
        self.openHours = openHours
        self.phone = phone
        self.website = website
        self.isOfflineAvailable = isOfflineAvailable
        self.searchAliases = searchAliases
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case intro
        case imageURL
        case category
        case detailDescription
        case address
        case altitude
        case rating
        case tags
        case openHours
        case phone
        case website
        case isOfflineAvailable
        case searchAliases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        intro = try container.decodeIfPresent(String.self, forKey: .intro) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        category = try container.decodeIfPresent(POICategory.self, forKey: .category) ?? .custom
        detailDescription = try container.decodeIfPresent(String.self, forKey: .detailDescription) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        openHours = try container.decodeIfPresent(String.self, forKey: .openHours)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        isOfflineAvailable = try container.decodeIfPresent(Bool.self, forKey: .isOfflineAvailable) ?? false
        searchAliases = try container.decodeIfPresent([String].self, forKey: .searchAliases) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(intro, forKey: .intro)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(category, forKey: .category)
        try container.encode(detailDescription, forKey: .detailDescription)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encode(rating, forKey: .rating)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(openHours, forKey: .openHours)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encode(isOfflineAvailable, forKey: .isOfflineAvailable)
        try container.encode(searchAliases, forKey: .searchAliases)
    }
}

// MARK: - 本地 Mock 数据
extension POIModel {
    static let mockData: [POIModel] = [
        POIModel(
            id: "huangshan",
            name: "黄山",
            latitude: 30.1338,
            longitude: 118.1688,
            intro: "奇松、怪石、云海、温泉，四季皆有不同景致。",
            imageURL: "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80",
            category: .mountain,
            detailDescription: "黄山位于安徽省南部，以奇松、怪石、云海、温泉、冬雪闻名，是中国山水审美的代表性目的地之一。",
            address: "安徽省黄山市黄山区",
            altitude: 1864,
            rating: 4.9,
            tags: ["世界遗产", "奇松怪石", "云海", "摄影"],
            openHours: "全年开放，旺季 6:00 - 18:00",
            website: "https://www.chinahuangshan.com",
            isOfflineAvailable: true,
            searchAliases: ["黄山风景区", "安徽黄山", "黄山景区"]
        ),
        POIModel(
            id: "xihu",
            name: "西湖",
            latitude: 30.2433,
            longitude: 120.1522,
            intro: "湖光山色与城市肌理交织，适合慢行与观景。",
            imageURL: "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1200&q=80",
            category: .lake,
            detailDescription: "西湖位于杭州市西部，是极具代表性的江南山水景观，也是城市与自然融合的经典样板。",
            address: "浙江省杭州市西湖区",
            altitude: 5,
            rating: 4.8,
            tags: ["世界遗产", "断桥", "苏堤", "骑行"],
            openHours: "全天开放",
            website: "https://www.hangzhou.gov.cn",
            isOfflineAvailable: true,
            searchAliases: ["杭州西湖", "西湖风景区", "西子湖"]
        ),
        POIModel(
            id: "zhangjiajie",
            name: "张家界国家森林公园",
            latitude: 29.1170,
            longitude: 110.4790,
            intro: "峰林地貌极具视觉冲击，云雾天气尤其出片。",
            imageURL: "https://images.unsplash.com/photo-1500043357865-c6b8827edf7d?auto=format&fit=crop&w=1200&q=80",
            category: .forest,
            detailDescription: "张家界以石英砂岩峰林景观著称，是自然观景与户外徒步的热门目的地。",
            address: "湖南省张家界市武陵源区",
            altitude: 1334,
            rating: 4.9,
            tags: ["峰林", "云海", "徒步", "世界自然遗产"],
            openHours: "07:00 - 18:00",
            isOfflineAvailable: true,
            searchAliases: ["张家界森林公园", "武陵源", "张家界景区"]
        ),
        POIModel(
            id: "guilin",
            name: "桂林漓江",
            latitude: 25.2736,
            longitude: 110.2994,
            intro: "山水画卷般的江岸线，适合路线展示与观景停靠。",
            imageURL: "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=1200&q=80",
            category: .viewpoint,
            detailDescription: "漓江两岸奇峰耸立、江水清澈，是中国山水意境最具代表性的景观带之一。",
            address: "广西壮族自治区桂林市",
            altitude: 150,
            rating: 4.8,
            tags: ["山水画廊", "竹筏", "摄影"],
            openHours: "全天开放",
            isOfflineAvailable: true,
            searchAliases: ["桂林漓江风景区", "漓江景区"]
        ),
        POIModel(
            id: "emeishan",
            name: "峨眉山",
            latitude: 29.5150,
            longitude: 103.3350,
            intro: "佛教名山与高山云海并存，登高观景体验极强。",
            imageURL: "https://images.unsplash.com/photo-1511919884226-fd3cad34687c?auto=format&fit=crop&w=1200&q=80",
            category: .temple,
            detailDescription: "峨眉山是中国四大佛教名山之一，同时具备极高的山地景观价值。",
            address: "四川省乐山市峨眉山市",
            altitude: 3099,
            rating: 4.8,
            tags: ["佛教圣地", "金顶", "云海", "日出"],
            openHours: "全年开放，07:00 - 18:00",
            isOfflineAvailable: true,
            searchAliases: ["峨眉山景区", "乐山峨眉山", "峨眉"]
        )
    ]
}
