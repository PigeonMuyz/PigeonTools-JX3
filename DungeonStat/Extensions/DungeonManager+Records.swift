//
//  DungeonManager+Records.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 记录管理相关扩展
extension DungeonManager {
    
    /// 修改指定记录的角色
    func updateRecordCharacter(_ record: CompletionRecord, to newCharacter: GameCharacter) {
        if let index = completionRecords.firstIndex(where: { $0.id == record.id }) {
            let updatedRecord = CompletionRecord(
                dungeonName: record.dungeonName,
                character: newCharacter,
                completedDate: record.completedDate,
                weekNumber: record.weekNumber,
                year: record.year,
                duration: record.duration,
                drops: record.drops
            )
            
            completionRecords[index] = updatedRecord
            
            // 重新同步统计数据
            syncStatisticsFromRecords()
            saveData()
            
            print("已将记录角色从 \(record.character.displayName) 更新为 \(newCharacter.displayName)")
        }
    }
    
    /// 批量修改角色（可选功能）
    func batchUpdateRecordsCharacter(from oldCharacter: GameCharacter, to newCharacter: GameCharacter) {
        var updatedCount = 0
        
        for i in 0..<completionRecords.count {
            let record = completionRecords[i]
            if record.character.id == oldCharacter.id {
                let updatedRecord = CompletionRecord(
                    dungeonName: record.dungeonName,
                    character: newCharacter,
                    completedDate: record.completedDate,
                    weekNumber: record.weekNumber,
                    year: record.year,
                    duration: record.duration,
                    drops: record.drops
                )
                completionRecords[i] = updatedRecord
                updatedCount += 1
            }
        }
        
        if updatedCount > 0 {
            syncStatisticsFromRecords()
            saveData()
            print("批量更新了 \(updatedCount) 条记录，从 \(oldCharacter.displayName) 到 \(newCharacter.displayName)")
        }
    }
    
    /// 删除完成记录
    func deleteCompletionRecord(_ record: CompletionRecord) {
        // 从完成记录数组中移除指定记录
        completionRecords.removeAll { $0.id == record.id }
        
        // 重新同步统计数据（因为删除了记录，需要重新计算）
        syncStatisticsFromRecords()
        
        print("已删除完成记录：\(record.character.displayName) - \(record.dungeonName)")
    }
    
    /// 手动添加历史记录
    func addManualRecord(dungeonName: String, character: GameCharacter, completedDate: Date, duration: TimeInterval) {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: completedDate)
        let year = calendar.component(.year, from: completedDate)
        
        let record = CompletionRecord(
            dungeonName: dungeonName,
            character: character,
            completedDate: completedDate,
            weekNumber: weekOfYear,
            year: year,
            duration: duration
        )
        completionRecords.append(record)
        
        // 同时更新对应副本的统计数据
        if let dungeonIndex = dungeons.firstIndex(where: { $0.name == dungeonName }) {
            // 更新总计数和总耗时
            dungeons[dungeonIndex].characterTotalCounts[character] = (dungeons[dungeonIndex].characterTotalCounts[character] ?? 0) + 1
            dungeons[dungeonIndex].characterTotalDuration[character] = (dungeons[dungeonIndex].characterTotalDuration[character] ?? 0) + duration
            dungeons[dungeonIndex].characterLastCompleted[character] = completedDate
            
            // 更新当前计数（currentCount应该等于totalCount）
            dungeons[dungeonIndex].characterCounts[character] = dungeons[dungeonIndex].characterTotalCounts[character]
            
            // 如果是当前游戏周，也更新周计数
            let currentGameWeekStart = StatisticsManager.shared.getGameWeekStart(for: Date())
            let recordGameWeekStart = StatisticsManager.shared.getGameWeekStart(for: completedDate)
            if Calendar.current.isDate(currentGameWeekStart, inSameDayAs: recordGameWeekStart) {
                dungeons[dungeonIndex].characterWeeklyCounts[character] = (dungeons[dungeonIndex].characterWeeklyCounts[character] ?? 0) + 1
            }
        }
        
        saveData()
    }
}
