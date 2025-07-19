//
//  WeeklyReportManager.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 周报告管理器
class WeeklyReportManager {
    static let shared = WeeklyReportManager()
    private init() {}
    
    private let statisticsManager = StatisticsManager.shared
    
    // MARK: - 动态生成游戏周报告
    func generateAvailableGameWeeks(from completionRecords: [CompletionRecord]) -> [DynamicWeeklyReport] {
        guard !completionRecords.isEmpty else { return [] }
        
        // 找到最早的完成记录
        let sortedRecords = completionRecords.sorted { $0.completedDate < $1.completedDate }
        guard let earliestRecord = sortedRecords.first else { return [] }
        
        var weeks: [DynamicWeeklyReport] = []
        let calendar = Calendar.current
        
        // 从最早记录的游戏周开始，到当前游戏周
        let earliestWeekStart = statisticsManager.getGameWeekStart(for: earliestRecord.completedDate)
        let currentWeekStart = statisticsManager.getGameWeekStart(for: Date())
        
        var currentDate = earliestWeekStart
        
        while currentDate <= currentWeekStart {
            let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentDate),
                  let weekEndFinal = calendar.date(byAdding: .minute, value: -1, to: weekEnd) else {
                break
            }
            
            let report = DynamicWeeklyReport(
                weekNumber: weekOfYear,
                year: year,
                startDate: currentDate,
                endDate: weekEndFinal
            )
            
            weeks.append(report)
            
            // 移动到下一个游戏周
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) else {
                break
            }
            currentDate = nextWeek
        }
        
        return weeks.sorted { $0.startDate > $1.startDate } // 最新的在前
    }
    
    // MARK: - 获取指定游戏周的统计数据
    func getWeeklyStatistics(
        for report: DynamicWeeklyReport,
        from completionRecords: [CompletionRecord],
        characters: [GameCharacter]
    ) -> (characterDungeonCounts: [GameCharacter: [String: Int]], totalCompletions: Int) {
        let weekRecords = completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        var characterDungeonCounts: [GameCharacter: [String: Int]] = [:]
        var totalCompletions = 0
        
        for record in weekRecords {
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
}
