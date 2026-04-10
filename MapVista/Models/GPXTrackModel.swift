// 文件路径: MapVista/Models/GPXTrackModel.swift
// 作用: GPX 导入后的轨迹包装模型，承载文件信息、轨迹点与统计数据

import Foundation
import CoreLocation

struct GPXTrackDocument: Identifiable, Equatable {
    let id = UUID()
    let sourceURL: URL
    let record: TrackRecord

    var name: String {
        record.name
    }

    var points: [TrackPoint] {
        record.points
    }

    var coordinates: [CLLocationCoordinate2D] {
        record.points.map { $0.coordinate }
    }

    var pointCount: Int {
        record.points.count
    }

    var distanceText: String {
        if record.totalDistance < 1000 {
            return String(format: "%.0f 米", record.totalDistance)
        }
        return String(format: "%.1f 公里", record.totalDistance / 1000.0)
    }

    var durationText: String {
        let minutes = max(1, Int(record.totalDuration / 60.0))
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        return "\(minutes / 60) 小时 \(minutes % 60) 分钟"
    }
}
