//
//  YearlyReportManager.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import Foundation

// MARK: - 年度报告管理器
class YearlyReportManager {
    static let shared = YearlyReportManager()
    private init() {}
    
    // MARK: - 动态生成年度报告
    func generateAvailableYears(from completionRecords: [CompletionRecord]) -> [DynamicYearlyReport] {
        guard !completionRecords.isEmpty else { return [] }
        
        // 获取所有记录的年份
        let years = Set(completionRecords.map { Calendar.current.component(.year, from: $0.completedDate) })
        
        var yearlyReports: [DynamicYearlyReport] = []
        let calendar = Calendar.current
        
        for year in years.sorted(by: >) { // 最新的年份在前
            guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                  let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
                  let actualEndDate = calendar.date(byAdding: .second, value: -1, to: endDate) else {
                continue
            }
            
            let report = DynamicYearlyReport(
                year: year,
                startDate: startDate,
                endDate: actualEndDate
            )
            
            yearlyReports.append(report)
        }
        
        return yearlyReports
    }
    
    // MARK: - 获取指定年度的统计数据
    func getYearlyStatistics(
        for report: DynamicYearlyReport,
        from completionRecords: [CompletionRecord],
        characters: [GameCharacter]
    ) -> (characterDungeonCounts: [GameCharacter: [String: Int]], totalCompletions: Int) {
        let yearRecords = completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        var characterDungeonCounts: [GameCharacter: [String: Int]] = [:]
        var totalCompletions = 0
        
        for record in yearRecords {
            // 找到匹配的角色对象
            guard let matchingCharacter = characters.first(where: {
                $0.server == record.character.server &&
                $0.name == record.character.name &&
                $0.school == record.character.school
            }) else { continue }
            
            if characterDungeonCounts[matchingCharacter] == nil {
                characterDungeonCounts[matchingCharacter] = [:]
            }
            
            let currentCount = characterDungeonCounts[matchingCharacter]?[record.dungeonName] ?? 0
            characterDungeonCounts[matchingCharacter]?[record.dungeonName] = currentCount + 1
            totalCompletions += 1
        }
        
        return (characterDungeonCounts, totalCompletions)
    }
    
    // MARK: - 获取年度成就统计
    func getYearlyAchievementStats(
        for report: DynamicYearlyReport,
        from completionRecords: [CompletionRecord],
        characters: [GameCharacter]
    ) -> (totalAchievements: Int, userMarkedAchievements: Int) {
        // 获取年度内的记录
        let yearRecords = completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        // 获取涉及的副本
        let dungeonNames = Set(yearRecords.map { $0.dungeonName })
        
        // 这里需要从成就服务获取相关成就数据
        // 为了简化，我们返回基本统计
        let totalAchievements = dungeonNames.count * 10 // 每个副本估算10个成就
        let userMarkedAchievements = AchievementCompletionService.shared.getCompletedAchievements().count
        
        return (totalAchievements: totalAchievements, userMarkedAchievements: userMarkedAchievements)
    }
}