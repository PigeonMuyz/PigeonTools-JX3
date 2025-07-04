//
//  WeeklyReport.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 周报告数据模型
struct WeeklyReport: Identifiable, Codable {
    let id = UUID()
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    let characterDungeonCounts: [GameCharacter: [String: Int]] // 角色: [副本名称: 完成次数]
    let totalCompletions: Int
}

// MARK: - 动态周报告数据模型
struct DynamicWeeklyReport: Identifiable, Codable {
    let id = UUID()
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    
    var displayTitle: String {
        return "\(year)-\(String(format: "%02d", weekNumber))周"
    }
}
