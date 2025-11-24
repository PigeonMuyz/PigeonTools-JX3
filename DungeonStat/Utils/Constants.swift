//
//  Constants.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation
import SwiftUI

// MARK: - 常量定义
struct Constants {

    // MARK: - 默认数据
    struct DefaultData {
        static let defaultDungeons = [
            "家族战场",
            "25人普通冷龙峰",
            "25人英雄河阳之战",
            "25人普通河阳之战",
            "25人普通白帝江关",
            "25人英雄范阳夜变"
        ]

        static let defaultCharacter = GameCharacter(
            server: "飞龙在天",
            name: "渡清欢",
            school: "长歌",
            bodyType: "正太"
        )
    }

    // MARK: - OCR 关键字
    struct OCRKeywords {
        static let dropKeywords = [
            "玄晶", "御马踏金", "鞍饰", "头饰", "马具", "足饰",
            "红莲", "扇风耳", "墨言", "聆音", "清泉侍女像", "北拒风狼",
            "玄域辟甲", "百合花", "遗忘的书函", "云鹤报捷", "麒麟", "夜泊蝶影",
            "不渡", "簪花空竹"
        ]

        static let goldItemKeyword = "玄晶"
    }

    // MARK: - UI 常量
    struct UI {
        static let maxVisibleDropTags = 3
        static let defaultAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.6
        static let hideComparisonDelay: Double = 5.0

        // 添加触觉反馈强度
        enum HapticStyle {
            case light
            case medium
            case heavy
        }
    }

    // MARK: - 网络请求
    struct Network {
        static let requestTimeout: TimeInterval = 10.0
        static let maxRetryCount = 3
        static let retryDelay: TimeInterval = 1.0
        static let maxConcurrentRequests = 3
    }

    // MARK: - 数据备份
    struct Backup {
        static let maxBackupCount = 10
        static let autoBackupEnabled = true
        static let autoBackupInterval: TimeInterval = 24 * 3600 // 24小时
    }

    // MARK: - 颜色主题
    struct Colors {
        // 金色物品（玄晶等）
        static let goldItemLight = Color(red: 0.8, green: 0.6, blue: 0.0)
        static let goldItemDark = Color(red: 1.0, green: 0.9, blue: 0.4)

        // 紫色物品（其他掉落）
        static let purpleItemLight = Color(red: 0.6, green: 0.3, blue: 0.8)
        static let purpleItemDark = Color(red: 0.8, green: 0.6, blue: 1.0)

        /// 根据颜色方案返回合适的颜色
        static func goldItem(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? goldItemDark : goldItemLight
        }

        static func purpleItem(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? purpleItemDark : purpleItemLight
        }
    }

    // MARK: - 数据版本
    struct DataVersion {
        static let current = 2 // 当前数据版本
        static let minimumCompatible = 1 // 最低兼容版本
    }

    // MARK: - 缓存配置
    struct Cache {
        static let imageMaxAge: TimeInterval = 7 * 24 * 3600 // 7天
        static let apiResponseMaxAge: TimeInterval = 5 * 60 // 5分钟
        static let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    }

    // MARK: - 日志配置
    struct Logging {
        static let enabled = true
        static let maxLogLines = 100
        static let logLevel: LogLevel = .info

        enum LogLevel: Int {
            case debug = 0
            case info = 1
            case warning = 2
            case error = 3
        }
    }
}
