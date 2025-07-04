//
//  CompletionRecord.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 完成记录数据模型
struct CompletionRecord: Identifiable, Codable, Equatable {
    let id = UUID()
    let dungeonName: String
    let character: GameCharacter
    let completedDate: Date
    let weekNumber: Int
    let year: Int
    let duration: TimeInterval
    let drops: [DropItem]
    
    // Equatable 协议的实现
    static func == (lhs: CompletionRecord, rhs: CompletionRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(dungeonName: String, character: GameCharacter, completedDate: Date,
         weekNumber: Int, year: Int, duration: TimeInterval, drops: [DropItem] = []) {
        self.dungeonName = dungeonName
        self.character = character
        self.completedDate = completedDate
        self.weekNumber = weekNumber
        self.year = year
        self.duration = duration
        self.drops = drops
    }
}
