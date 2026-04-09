// 文件路径: MapVista/Services/SearchService.swift
// 作用: 本地搜索服务，封装 POI 名称、简介、标签与分类过滤逻辑

import Foundation
import CoreLocation

// MARK: - 搜索服务协议
protocol SearchServiceProtocol {
    func search(
        keyword: String,
        category: POICategory?,
        center: CLLocationCoordinate2D?,
        in pois: [POIModel],
        limit: Int
    ) -> [SearchResult]
}

// MARK: - 本地搜索实现
final class LocalSearchService: SearchServiceProtocol {
    func search(
        keyword: String,
        category: POICategory?,
        center: CLLocationCoordinate2D?,
        in pois: [POIModel],
        limit: Int
    ) -> [SearchResult] {
        let normalizedKeyword = Self.normalize(keyword)
        let keywordTokens = Self.tokenize(normalizedKeyword)

        let rankedPOIs = pois.compactMap { poi -> RankedPOI? in
            let categoryMatched = category == nil || poi.category == category
            guard categoryMatched else { return nil }

            let score = Self.score(
                poi: poi,
                normalizedKeyword: normalizedKeyword,
                keywordTokens: keywordTokens
            )

            guard normalizedKeyword.isEmpty || score > 0 else { return nil }

            let distance = center.map { poi.coordinate.distance(to: $0) }
            return RankedPOI(poi: poi, score: score, distance: distance)
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }

            switch (lhs.distance, rhs.distance) {
            case let (left?, right?):
                if left != right { return left < right }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
            }

            return lhs.poi.name < rhs.poi.name
        }

        return rankedPOIs
            .prefix(limit)
            .map { ranked in
                SearchResult(poi: ranked.poi, distance: ranked.distance, source: .local)
            }
    }
}

// MARK: - 搜索辅助
private extension LocalSearchService {
    struct RankedPOI {
        let poi: POIModel
        let score: Int
        let distance: Double?
    }

    static func score(
        poi: POIModel,
        normalizedKeyword: String,
        keywordTokens: [String]
    ) -> Int {
        let searchableFields = searchableText(for: poi)

        if normalizedKeyword.isEmpty {
            return 1
        }

        var score = 0

        if searchableFields.normalizedName == normalizedKeyword {
            score += 1000
        } else if searchableFields.normalizedName.hasPrefix(normalizedKeyword) {
            score += 900
        } else if searchableFields.normalizedName.contains(normalizedKeyword) {
            score += 800
        }

        if searchableFields.normalizedAliases.contains(normalizedKeyword) {
            score += 780
        } else if searchableFields.normalizedAliases.contains(where: { $0.hasPrefix(normalizedKeyword) }) {
            score += 720
        } else if searchableFields.normalizedAliases.contains(where: { $0.contains(normalizedKeyword) }) {
            score += 680
        }

        if searchableFields.normalizedCombined.contains(normalizedKeyword) {
            score += 600
        }

        if !keywordTokens.isEmpty {
            let tokenHits = keywordTokens.reduce(into: 0) { partialResult, token in
                if searchableFields.normalizedCombined.contains(token) {
                    partialResult += 1
                }
            }
            if tokenHits == keywordTokens.count {
                score += 500
            } else {
                score += tokenHits * 60
            }
        }

        if score == 0, Self.fuzzyContains(text: searchableFields.normalizedCombined, pattern: normalizedKeyword) {
            score += 350
        }

        return score
    }

    static func searchableText(for poi: POIModel) -> SearchableFields {
        let combined = [
            poi.name,
            poi.intro,
            poi.detailDescription,
            poi.address,
            poi.tags.joined(separator: " "),
            poi.searchAliases.joined(separator: " ")
        ]
        .joined(separator: " ")

        return SearchableFields(
            normalizedName: normalize(poi.name),
            normalizedAliases: poi.searchAliases.map { normalize($0) },
            normalizedCombined: normalize(combined)
        )
    }

    static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let filteredScalars = folded.unicodeScalars.filter { scalar in
            let category = scalar.properties.generalCategory
            return category != .spaceSeparator &&
                category != .control &&
                category != .lineSeparator &&
                category != .paragraphSeparator &&
                category != .dashPunctuation &&
                category != .otherPunctuation
        }
        return String(String.UnicodeScalarView(filteredScalars)).lowercased()
    }

    static func tokenize(_ keyword: String) -> [String] {
        keyword
            .split { $0 == " " || $0 == "," || $0 == "，" || $0 == "/" || $0 == "|" }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func fuzzyContains(text: String, pattern: String) -> Bool {
        guard !pattern.isEmpty else { return true }

        if text.contains(pattern) {
            return true
        }

        var textIndex = text.startIndex
        for character in pattern {
            guard let matchIndex = text[textIndex...].firstIndex(of: character) else {
                return false
            }
            textIndex = text.index(after: matchIndex)
        }
        return true
    }

    struct SearchableFields {
        let normalizedName: String
        let normalizedAliases: [String]
        let normalizedCombined: String
    }
}
