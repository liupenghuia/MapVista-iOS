// 文件路径: MapVista/Services/LocationManager.swift
// 作用: 封装 CoreLocation，统一处理定位授权、定位更新、错误状态和距离计算

import Foundation
import CoreLocation
import Combine

// MARK: - 定位状态
enum LocationState: Equatable {
    case idle
    case requestingAuthorization
    case authorized
    case denied
    case restricted
    case unavailable
    case failed(String)
}

// MARK: - 定位管理协议
protocol LocationManaging: AnyObject, ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var locationState: LocationState { get }
    var lastErrorMessage: String? { get }

    func requestAuthorizationIfNeeded()
    func startUpdatingLocation()
    func requestFreshLocation()
    func stopUpdatingLocation()
    func distance(to coordinate: CLLocationCoordinate2D) -> Double?
}

// MARK: - CoreLocation 管理器
final class LocationManager: NSObject, LocationManaging {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var locationState: LocationState = .idle
    @Published private(set) var lastErrorMessage: String?

    private let locationManager = CLLocationManager()
    private let maximumAcceptedLocationAge: TimeInterval = 5 * 60
    private let maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 100

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2 // 较密的采样率以保证轨迹圆滑
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }

    func requestAuthorizationIfNeeded() {
        if authorizationStatus == .notDetermined {
            locationState = .requestingAuthorization
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func startUpdatingLocation() {
        guard isAuthorized else {
            requestAuthorizationIfNeeded()
            return
        }
        locationState = .authorized
        locationManager.startUpdatingLocation()
    }

    func requestFreshLocation() {
        guard isAuthorized else {
            requestAuthorizationIfNeeded()
            startUpdatingLocation()
            return
        }

        locationState = .authorized
        locationManager.requestLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: target)
    }

    private var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    private func refreshAuthorizationState() {
        authorizationStatus = locationManager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationState = .authorized
        case .denied:
            locationState = .denied
        case .restricted:
            locationState = .restricted
        case .notDetermined:
            locationState = .idle
        @unknown default:
            locationState = .unavailable
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last(where: { location in
            guard location.horizontalAccuracy >= 0 else { return false }
            guard location.horizontalAccuracy <= maximumAcceptedHorizontalAccuracy else { return false }
            let age = -location.timestamp.timeIntervalSinceNow
            return age >= 0 && age <= maximumAcceptedLocationAge
        }) else { return }

        DispatchQueue.main.async {
            self.currentLocation = latest
            self.lastErrorMessage = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationState = .denied
                    self.lastErrorMessage = "定位权限被拒绝，请前往系统设置开启定位权限。"
                case .locationUnknown:
                    self.locationState = .unavailable
                    self.lastErrorMessage = "当前无法获取位置，请稍后重试。"
                default:
                    self.locationState = .failed(error.localizedDescription)
                    self.lastErrorMessage = error.localizedDescription
                }
            } else {
                self.locationState = .failed(error.localizedDescription)
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.refreshAuthorizationState()
            if self.isAuthorized {
                self.startUpdatingLocation()
            }
        }
    }
}
