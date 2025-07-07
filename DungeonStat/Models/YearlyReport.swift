//
//  YearlyReport.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import Foundation

// MARK: - 年度报告数据模型
struct YearlyReport: Identifiable, Codable {
    let id = UUID()
    let year: Int
    let startDate: Date
    let endDate: Date
    let characterDungeonCounts: [GameCharacter: [String: Int]] // 角色: [副本名称: 完成次数]
    let totalCompletions: Int
    let totalAchievements: Int
    let userMarkedAchievements: Int
}

// MARK: - 动态年度报告数据模型
struct DynamicYearlyReport: Identifiable, Codable {
    let id = UUID()
    let year: Int
    let startDate: Date
    let endDate: Date
    
    var displayTitle: String {
        return "\(year)年"
    }
}