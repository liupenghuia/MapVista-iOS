import Foundation
import CoreLocation

public struct TrackPoint: Codable, Identifiable, Equatable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let timestamp: Date
    public let speed: Double
    public let course: Double
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(id: UUID = UUID(), latitude: Double, longitude: Double, altitude: Double, timestamp: Date, speed: Double, course: Double) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speed = speed
        self.course = course
    }
}

public struct TrackRecord: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public let startTime: Date
    public var endTime: Date?
    public var points: [TrackPoint]
    public var totalDistance: Double // 单位：米
    
    public var totalDuration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    public init(id: UUID = UUID(), name: String, startTime: Date = Date(), endTime: Date? = nil, points: [TrackPoint] = [], totalDistance: Double = 0) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.points = points
        self.totalDistance = totalDistance
    }
}
