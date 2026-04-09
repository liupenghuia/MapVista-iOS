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
        var points: [TrackPoint] = []
        let baseLocation = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074) // 北京
        let now = Date()
        
        for i in 0..<50 {
            let offset = Double(i) * 0.0001
            let point = TrackPoint(
                latitude: baseLocation.latitude + offset,
                longitude: baseLocation.longitude + offset,
                altitude: 50.0 + Double.random(in: -5...5),
                timestamp: now.addingTimeInterval(Double(i) * 10),
                speed: 1.5 + Double.random(in: -0.5...0.5),
                course: 45.0
            )
            points.append(point)
        }
        
        let mockRecord = TrackRecord(
            name: "模拟调试轨迹-天安门探索",
            startTime: now,
            endTime: now.addingTimeInterval(500),
            points: points,
            totalDistance: 1200.5 // 米
        )
        
        historyRecords.append(mockRecord)
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
