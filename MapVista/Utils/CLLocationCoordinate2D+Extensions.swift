// 文件路径: MapVista/Utils/CLLocationCoordinate2D+Extensions.swift
// 作用: 提供坐标距离计算等地理工具方法，避免业务层重复写 CLLocation 转换逻辑

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let left = CLLocation(latitude: latitude, longitude: longitude)
        let right = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return left.distance(from: right)
    }
}
