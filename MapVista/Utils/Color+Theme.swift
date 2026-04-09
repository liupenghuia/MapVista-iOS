// 文件路径: MapVista/Utils/Color+Theme.swift
// 作用: 统一常用系统主题色，避免在视图中重复写 UIKit 桥接

import SwiftUI
import UIKit

extension Color {
    static var systemTeal: Color { Color(UIColor.systemTeal) }
    static var systemBlue: Color { Color(UIColor.systemBlue) }
    static var systemGreen: Color { Color(UIColor.systemGreen) }
    static var systemOrange: Color { Color(UIColor.systemOrange) }
    static var systemYellow: Color { Color(UIColor.systemYellow) }
    static var systemRed: Color { Color(UIColor.systemRed) }
    static var systemGray: Color { Color(UIColor.systemGray) }

    /// 山水地图页的兜底背景色，避免任何空白区域露出系统黑底
    static var mapCanvasBackground: Color {
        Color(red: 0.07, green: 0.15, blue: 0.12)
    }
}
