//
//  Constants.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

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
    }
    
    // MARK: - UI 常量
    struct UI {
        static let maxVisibleDropTags = 3
        static let defaultAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.6
        static let hideComparisonDelay: Double = 5.0
    }
    
    // MARK: - 网络请求
    struct Network {
        static let requestTimeout: TimeInterval = 10.0
        static let maxRetryCount = 3
    }
}
