//
//  Dungeon.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 副本数据模型
struct Dungeon: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var categoryId: UUID? // 分类ID，可为空
    var customCategory: String? // 用户自定义分类名称
    var characterCounts: [GameCharacter: Int] = [:] // 每个角色的当前计数
    var characterWeeklyCounts: [GameCharacter: Int] = [:] // 每个角色的周计数
    var characterTotalCounts: [GameCharacter: Int] = [:] // 每个角色的总计数
    var characterLastCompleted: [GameCharacter: Date] = [:] // 每个角色的最后完成时间
    var characterInProgress: [GameCharacter: Bool] = [:] // 每个角色是否在进行中
    var characterStartTime: [GameCharacter: Date] = [:] // 每个角色的开始时间
    var characterTotalDuration: [GameCharacter: TimeInterval] = [:] // 每个角色的总耗时
    
    func averageDuration(for character: GameCharacter) -> TimeInterval {
        let totalCount = characterTotalCounts[character] ?? 0
        let totalDuration = characterTotalDuration[character] ?? 0
        return totalCount > 0 ? totalDuration / Double(totalCount) : 0
    }
    
    func currentCount(for character: GameCharacter) -> Int {
        return characterCounts[character] ?? 0
    }
    
    func weeklyCount(for character: GameCharacter) -> Int {
        return characterWeeklyCounts[character] ?? 0
    }
    
    func totalCount(for character: GameCharacter) -> Int {
        return characterTotalCounts[character] ?? 0
    }
    
    func isInProgress(for character: GameCharacter) -> Bool {
        return characterInProgress[character] ?? false
    }
    
    func lastCompletedDate(for character: GameCharacter) -> Date? {
        return characterLastCompleted[character]
    }
    
    func startTime(for character: GameCharacter) -> Date? {
        return characterStartTime[character]
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Dungeon, rhs: Dungeon) -> Bool {
        return lhs.id == rhs.id
    }
}
