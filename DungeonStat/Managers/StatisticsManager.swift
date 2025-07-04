//
//  StatisticsManager.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 统计管理器
class StatisticsManager {
    static let shared = StatisticsManager()
    private init() {}
    
    // MARK: - 游戏周相关方法
    func getGameWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        
        var daysToSubtract = 0
        
        if weekday == 2 { // 周一
            if hour < 7 {
                daysToSubtract = 7
            } else {
                daysToSubtract = 0
            }
        } else if weekday == 1 { // 周日
            daysToSubtract = 6
        } else {
            daysToSubtract = weekday - 2
        }
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfDay),
              let gameWeekStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: weekStart) else {
            return date
        }
        
        return gameWeekStart
    }
    
    // MARK: - 副本统计同步
    func syncStatisticsFromRecords(
        dungeons: inout [Dungeon],
        characters: [GameCharacter],
        completionRecords: [CompletionRecord]
    ) {
        let currentGameWeekStart = getGameWeekStart(for: Date())
        
        // 先清空所有统计数据
        for i in 0..<dungeons.count {
            dungeons[i].characterTotalCounts.removeAll()
            dungeons[i].characterTotalDuration.removeAll()
            dungeons[i].characterWeeklyCounts.removeAll()
            dungeons[i].characterLastCompleted.removeAll()
            dungeons[i].characterCounts.removeAll()
        }
        
        // 根据完成记录重新计算
        for record in completionRecords {
            if let dungeonIndex = dungeons.firstIndex(where: { $0.name == record.dungeonName }) {
                // 查找匹配的角色对象
                guard let matchingCharacter = characters.first(where: {
                    $0.server == record.character.server &&
                    $0.name == record.character.name &&
                    $0.school == record.character.school
                }) else {
                    print("警告: 找不到匹配的角色对象: \(record.character.displayName)")
                    continue
                }
                
                // 更新总计数和总耗时
                let currentTotal = dungeons[dungeonIndex].characterTotalCounts[matchingCharacter] ?? 0
                dungeons[dungeonIndex].characterTotalCounts[matchingCharacter] = currentTotal + 1
                
                let currentDuration = dungeons[dungeonIndex].characterTotalDuration[matchingCharacter] ?? 0
                dungeons[dungeonIndex].characterTotalDuration[matchingCharacter] = currentDuration + record.duration
                
                // 更新最后完成时间
                if let existingDate = dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] {
                    if record.completedDate > existingDate {
                        dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] = record.completedDate
                    }
                } else {
                    dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] = record.completedDate
                }
                
                // 如果是当前游戏周的记录，更新周计数
                let recordGameWeekStart = getGameWeekStart(for: record.completedDate)
                if Calendar.current.isDate(currentGameWeekStart, inSameDayAs: recordGameWeekStart) {
                    let currentWeekly = dungeons[dungeonIndex].characterWeeklyCounts[matchingCharacter] ?? 0
                    dungeons[dungeonIndex].characterWeeklyCounts[matchingCharacter] = currentWeekly + 1
                }
                
                // 同步当前计数
                dungeons[dungeonIndex].characterCounts[matchingCharacter] = dungeons[dungeonIndex].characterTotalCounts[matchingCharacter]
            }
        }
        
        print("数据同步完成：已根据 \(completionRecords.count) 条历史记录重新计算统计数据")
    }
    
    // MARK: - 角色车次统计
    func getCharacterRunNumber(for record: CompletionRecord, in records: [CompletionRecord], dungeonName: String? = nil) -> Int {
        let targetDungeonName = dungeonName ?? record.dungeonName
        
        let characterRecords = records
            .filter {
                $0.character.server == record.character.server &&
                $0.character.name == record.character.name &&
                $0.character.school == record.character.school &&
                $0.dungeonName == targetDungeonName
            }
            .sorted { $0.completedDate < $1.completedDate }
        
        return (characterRecords.firstIndex { $0.id == record.id } ?? 0) + 1
    }
    
    func getTotalRunNumber(for record: CompletionRecord, in records: [CompletionRecord]) -> Int {
        let recordIndex = records
            .sorted { $0.completedDate < $1.completedDate }
            .firstIndex { $0.id == record.id } ?? 0
        return recordIndex + 1
    }
}
