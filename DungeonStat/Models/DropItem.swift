//
//  DropItem.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import SwiftUI

// MARK: - 掉落物品数据模型
struct DropItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    
    // 根据名称判断颜色（支持深色模式）
    var color: Color {
        if name.contains("玄晶") {
            // 金色
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0) // 浅金色
                default:
                    return UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0) // 深金色
                }
            })
        } else {
            // 紫色
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0) // 浅紫色
                default:
                    return UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0) // 深紫色
                }
            })
        }
    }
}
