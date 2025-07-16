//
//  DungeonManager+Drops.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 掉落物品相关扩展
extension DungeonManager {
    
    /// 批量为记录添加掉落物品
    func addMultipleDropsToRecord(_ record: CompletionRecord, dropNames: [String]) {
        guard !dropNames.isEmpty else { return }
        
        if let index = completionRecords.firstIndex(where: { $0.id == record.id }) {
            let currentRecord = completionRecords[index]
            var newDrops = currentRecord.drops
            
            // 批量创建 DropItem 并添加
            for dropName in dropNames {
                let dropItem = DropItem(name: dropName)
                newDrops.append(dropItem)
            }
            
            // 创建新记录
            let newRecord = CompletionRecord(
                dungeonName: currentRecord.dungeonName,
                character: currentRecord.character,
                completedDate: currentRecord.completedDate,
                weekNumber: currentRecord.weekNumber,
                year: currentRecord.year,
                duration: currentRecord.duration,
                drops: newDrops
            )
            
            completionRecords[index] = newRecord
            saveData()
        }
    }
    
    /// 为记录添加掉落物品
    func addDropToRecord(_ record: CompletionRecord, dropItem: DropItem) {
        addMultipleDropsToRecord(record, dropNames: [dropItem.name])
    }
    
    /// 从记录中移除掉落物品
    func removeDropFromRecord(_ record: CompletionRecord, dropId: UUID) {
        if let index = completionRecords.firstIndex(where: { $0.id == record.id }) {
            var currentRecord = completionRecords[index]
            let newDrops = currentRecord.drops.filter { $0.id != dropId }
            
            let newRecord = CompletionRecord(
                dungeonName: currentRecord.dungeonName,
                character: currentRecord.character,
                completedDate: currentRecord.completedDate,
                weekNumber: currentRecord.weekNumber,
                year: currentRecord.year,
                duration: currentRecord.duration,
                drops: newDrops
            )
            
            completionRecords[index] = newRecord
            saveData()
        }
    }
}
