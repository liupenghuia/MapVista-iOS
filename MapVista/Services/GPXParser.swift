// 文件路径: MapVista/Services/GPXParser.swift
// 作用: 解析 GPX 文件并转换成 TrackRecord，供首页地图和轨迹列表复用

import Foundation
import CoreLocation

final class GPXParser: NSObject {
    enum ParseError: LocalizedError {
        case invalidFile
        case noTrackPoints
        case malformedXML

        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return "无法读取 GPX 文件。"
            case .noTrackPoints:
                return "GPX 文件中没有可用的轨迹点。"
            case .malformedXML:
                return "GPX 文件格式不正确。"
            }
        }
    }

    func parseTrack(from url: URL) throws -> TrackRecord {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url) else {
            throw ParseError.invalidFile
        }

        let delegate = GPXParserDelegate(sourceFileName: url.deletingPathExtension().lastPathComponent)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw parser.parserError.map { _ in ParseError.malformedXML } ?? ParseError.malformedXML
        }

        guard !delegate.points.isEmpty else {
            throw ParseError.noTrackPoints
        }

        let totalDistance = delegate.points.enumerated().reduce(0.0) { partialResult, entry in
            guard entry.offset > 0 else { return partialResult }
            let current = entry.element.coordinate
            let previous = delegate.points[entry.offset - 1].coordinate
            return partialResult + previous.distance(to: current)
        }

        let startTime = delegate.points.first?.timestamp ?? Date()
        let endTime = delegate.points.last?.timestamp ?? startTime
        let trackName = delegate.trackName.isEmpty ? delegate.sourceFileName : delegate.trackName

        return TrackRecord(
            name: trackName,
            startTime: startTime,
            endTime: endTime,
            points: delegate.points,
            totalDistance: totalDistance
        )
    }
}

private final class GPXParserDelegate: NSObject, XMLParserDelegate {
    struct PartialTrackPoint {
        let latitude: Double
        let longitude: Double
        var altitude: Double?
        var timestamp: Date?
        var speed: Double?
        var course: Double?
    }

    let sourceFileName: String
    var trackName: String = ""
    var points: [TrackPoint] = []

    private var currentPoint: PartialTrackPoint?
    private var currentText: String = ""
    private var shouldCaptureText = false

    init(sourceFileName: String) {
        self.sourceFileName = sourceFileName
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        currentText = ""

        switch elementName.lowercased() {
        case "trkpt":
            guard
                let latString = attributeDict["lat"],
                let lonString = attributeDict["lon"],
                let latitude = Double(latString),
                let longitude = Double(lonString)
            else { return }

            currentPoint = PartialTrackPoint(latitude: latitude, longitude: longitude)
        case "name", "ele", "time":
            shouldCaptureText = true
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        guard shouldCaptureText else { return }
        currentText.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName.lowercased() {
        case "name":
            if trackName.isEmpty, !trimmedText.isEmpty {
                trackName = trimmedText
            }
            shouldCaptureText = false
        case "ele":
            if var point = currentPoint, let elevation = Double(trimmedText) {
                point.altitude = elevation
                currentPoint = point
            }
            shouldCaptureText = false
        case "time":
            if var point = currentPoint {
                point.timestamp = Self.parseDate(trimmedText)
                currentPoint = point
            }
            shouldCaptureText = false
        case "trkpt":
            if let point = currentPoint {
                points.append(
                    TrackPoint(
                        latitude: point.latitude,
                        longitude: point.longitude,
                        altitude: point.altitude ?? 0,
                        timestamp: point.timestamp ?? Date(),
                        speed: point.speed ?? 0,
                        course: point.course ?? 0
                    )
                )
            }
            currentPoint = nil
        default:
            break
        }

        currentText = ""
    }

    private static func parseDate(_ text: String) -> Date? {
        guard !text.isEmpty else { return nil }

        let fractionFormatter = ISO8601DateFormatter()
        fractionFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionFormatter.date(from: text) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }
}
