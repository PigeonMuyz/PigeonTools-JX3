//
//  DungeonManager+Statistics.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 统计相关扩展
extension DungeonManager {
    
    /// 获取指定角色在指定副本的第几车
    func getCharacterRunNumber(for record: CompletionRecord, dungeonName: String? = nil) -> Int {
        return StatisticsManager.shared.getCharacterRunNumber(
            for: record,
            in: completionRecords,
            dungeonName: dungeonName
        )
    }
    
    /// 获取指定角色在所有副本的总车数
    func getTotalRunNumber(for record: CompletionRecord) -> Int {
        return StatisticsManager.shared.getTotalRunNumber(
            for: record,
            in: completionRecords
        )
    }
    
    /// 获取指定角色在指定副本的当前总车数
    func getCurrentRunCount(for character: GameCharacter, dungeonName: String) -> Int {
        return completionRecords.filter {
            $0.character.server == character.server &&
            $0.character.name == character.name &&
            $0.character.school == character.school &&
            $0.dungeonName == dungeonName
        }.count
    }
    
    /// 获取指定角色的所有副本车数统计
    func getAllDungeonRunCounts(for character: GameCharacter) -> [String: Int] {
        var dungeonCounts: [String: Int] = [:]
        
        let characterRecords = completionRecords.filter {
            $0.character.server == character.server &&
            $0.character.name == character.name &&
            $0.character.school == character.school
        }
        
        for record in characterRecords {
            dungeonCounts[record.dungeonName, default: 0] += 1
        }
        
        return dungeonCounts
    }
    
    /// 获取各角色的记录数量统计（调试用）
    func getCharacterRecordCounts() -> [(character: GameCharacter, count: Int)] {
        let groups = Dictionary(grouping: completionRecords) { $0.character.id }
        
        return groups.compactMap { (characterId, records) in
            if let character = characters.first(where: { $0.id == characterId }) {
                return (character: character, count: records.count)
            }
            return nil
        }.sorted { $0.count > $1.count }
    }
    
    /// 手动周结算（仅用于更新当前周统计）
    func manualGameWeeklyReset() {
        // 重新同步统计数据以更新当前周计数
        syncStatisticsFromRecords()
        print("手动执行游戏周结算完成")
    }
}
