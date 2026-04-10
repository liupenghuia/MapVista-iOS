import Foundation
import CoreLocation
import Combine

public protocol TrackRecordingProviding: ObservableObject {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var currentRecord: TrackRecord? { get }
    var historyRecords: [TrackRecord] { get }
    
    func startRecording(name: String)
    func pauseRecording()
    func resumeRecording()
    func stopRecording()
    func feedLocation(_ location: CLLocation)
    func deleteRecord(_ record: TrackRecord)
    func generateGPX(for record: TrackRecord) -> URL?
}

public final class TrackRecordingService: TrackRecordingProviding {
    public static let shared = TrackRecordingService()
    
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var currentRecord: TrackRecord?
    @Published public private(set) var historyRecords: [TrackRecord] = []
    
    private let minAccuracy: CLLocationAccuracy = 40.0
    private let minDistanceDelta: CLLocationDistance = 2.0 // 米
    
    private let storageKey = "com.mapvista.trackHistory"
    
    public init() {
        loadHistory()
        
        #if DEBUG
        // 如果没有历史记录，主动注入一条供开发调试验证 GPX 和 UI
        if historyRecords.isEmpty {
            injectMockData()
        }
        #endif
    }
    
    #if DEBUG
    private func injectMockData() {
        let now = Date()

        let cities: [(name: String, coordinate: CLLocationCoordinate2D)] = [
            ("北京", CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)),
            ("上海", CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)),
            ("广州", CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644)),
            ("深圳", CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579)),
            ("杭州", CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551)),
            ("南京", CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969)),
            ("苏州", CLLocationCoordinate2D(latitude: 31.2989, longitude: 120.5853)),
            ("成都", CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668)),
            ("武汉", CLLocationCoordinate2D(latitude: 30.5928, longitude: 114.3055)),
            ("西安", CLLocationCoordinate2D(latitude: 34.3416, longitude: 108.9398)),
            ("重庆", CLLocationCoordinate2D(latitude: 29.5630, longitude: 106.5516)),
            ("天津", CLLocationCoordinate2D(latitude: 39.3434, longitude: 117.3616)),
            ("青岛", CLLocationCoordinate2D(latitude: 36.0671, longitude: 120.3826)),
            ("长沙", CLLocationCoordinate2D(latitude: 28.2282, longitude: 112.9388)),
            ("厦门", CLLocationCoordinate2D(latitude: 24.4798, longitude: 118.0894)),
            ("福州", CLLocationCoordinate2D(latitude: 26.0745, longitude: 119.2965)),
            ("大连", CLLocationCoordinate2D(latitude: 38.9140, longitude: 121.6147)),
            ("昆明", CLLocationCoordinate2D(latitude: 25.0389, longitude: 102.7183)),
            ("哈尔滨", CLLocationCoordinate2D(latitude: 45.8038, longitude: 126.5349)),
            ("郑州", CLLocationCoordinate2D(latitude: 34.7473, longitude: 113.6249))
        ]

        historyRecords.removeAll()

        for (index, city) in cities.enumerated() {
            let startTime = now.addingTimeInterval(TimeInterval(-index * 3600))
            var points: [TrackPoint] = []

            for step in 0..<24 {
                let progress = Double(step)
                let latOffset = sin(progress / 5.0) * 0.0015 + Double(step) * 0.00006
                let lonOffset = cos(progress / 4.0) * 0.0015 + Double(step) * 0.00005
                let point = TrackPoint(
                    latitude: city.coordinate.latitude + latOffset,
                    longitude: city.coordinate.longitude + lonOffset,
                    altitude: 20.0 + Double.random(in: -8...18),
                    timestamp: startTime.addingTimeInterval(progress * 12),
                    speed: 1.2 + Double.random(in: 0...2.8),
                    course: Double((index * 17 + step * 11) % 360)
                )
                points.append(point)
            }

            let mockRecord = TrackRecord(
                name: "模拟调试轨迹-\(city.name)",
                startTime: startTime,
                endTime: startTime.addingTimeInterval(24 * 12),
                points: points,
                totalDistance: Double.random(in: 850...4200)
            )

            historyRecords.append(mockRecord)
        }

        saveHistory()
    }
    #endif
    
    public func startRecording(name: String) {
        currentRecord = TrackRecord(name: name, points: [], totalDistance: 0)
        isRecording = true
        isPaused = false
    }
    
    public func pauseRecording() {
        if isRecording {
            isPaused = true
        }
    }
    
    public func resumeRecording() {
        if isRecording {
            isPaused = false
        }
    }
    
    public func stopRecording() {
        isRecording = false
        isPaused = false
        currentRecord?.endTime = Date()
        
        if let rec = currentRecord, !rec.points.isEmpty {
            historyRecords.insert(rec, at: 0)
            saveHistory()
            print("【轨迹记录结束】: 共 \(rec.points.count) 个点，总距离 \(rec.totalDistance) 米。已归档。")
        }
        currentRecord = nil
    }
    
    public func feedLocation(_ location: CLLocation) {
        // 如果没有在记录中或处于暂停状态，直接丢弃
        guard isRecording, !isPaused, var record = currentRecord else { return }
        
        // 噪点过滤：必须大于 0 且在合理的 GPS 精度范围内
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy <= minAccuracy else { return }
        
        let newPoint = TrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp,
            speed: max(location.speed, 0),
            course: max(location.course, 0)
        )
        
        if let lastPoint = record.points.last {
            let lastLoc = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
            let distance = location.distance(from: lastLoc)
            
            // 防止原地站立导致的 GPS 麻点乱漂，用步幅过滤法过滤掉重复微小距离
            if distance >= minDistanceDelta {
                record.totalDistance += distance
                record.points.append(newPoint)
                currentRecord = record // 触发发布更新
            }
        } else {
            // 第一个点无条件收入
            record.points.append(newPoint)
            currentRecord = record
        }
    }
    
    // MARK: - History Management
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(historyRecords) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TrackRecord].self, from: data) {
            self.historyRecords = decoded
        }
    }
    
    public func deleteRecord(_ record: TrackRecord) {
        historyRecords.removeAll(where: { $0.id == record.id })
        saveHistory()
    }
    
    // MARK: - GPX Export
    
    public func generateGPX(for record: TrackRecord) -> URL? {
        let fileName = "\(record.name)_\(Int(Date().timeIntervalSince1970)).gpx"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="MapVista" xmlns="http://www.topografix.com/GPX/1/1">
            <metadata>
                <name>\(record.name)</name>
                <time>\(ISO8601DateFormatter().string(from: record.startTime))</time>
            </metadata>
            <trk>
                <name>\(record.name)</name>
                <trkseg>
        """
        
        for point in record.points {
            let timeStr = ISO8601DateFormatter().string(from: point.timestamp)
            gpxString += """
            
                    <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                        <ele>\(point.altitude)</ele>
                        <time>\(timeStr)</time>
                        <speed>\(point.speed)</speed>
                        <course>\(point.course)</course>
                    </trkpt>
            """
        }
        
        gpxString += """
        
                </trkseg>
            </trk>
        </gpx>
        """
        
        do {
            try gpxString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("GPX 生成失败: \(error)")
            return nil
        }
    }
}
