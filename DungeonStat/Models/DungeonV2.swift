//
//  DungeonV2.swift
//  DungeonStat
//
//  改进版副本模型 - 修复内存管理问题
//  变更：使用 UUID 作为字典键，而不是 GameCharacter 对象
//

import Foundation

// MARK: - 改进版副本数据模型
struct DungeonV2: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var categoryId: UUID?
    var customCategory: String?
    var customCategoryOrder: Int?

    // 改进：使用角色 ID 作为字典键，避免对象作为键导致的内存问题
    var characterCounts: [UUID: Int] = [:]           // characterId -> count
    var characterWeeklyCounts: [UUID: Int] = [:]     // characterId -> weeklyCount
    var characterTotalCounts: [UUID: Int] = [:]      // characterId -> totalCount
    var characterLastCompleted: [UUID: Date] = [:]   // characterId -> lastDate
    var characterInProgress: [UUID: Bool] = [:]      // characterId -> isInProgress
    var characterStartTime: [UUID: Date] = [:]       // characterId -> startTime
    var characterTotalDuration: [UUID: TimeInterval] = [:] // characterId -> totalDuration

    // MARK: - 便捷访问方法（通过 GameCharacter）

    func averageDuration(for character: GameCharacter) -> TimeInterval {
        let totalCount = characterTotalCounts[character.id] ?? 0
        let totalDuration = characterTotalDuration[character.id] ?? 0
        return totalCount > 0 ? totalDuration / Double(totalCount) : 0
    }

    func currentCount(for character: GameCharacter) -> Int {
        return characterCounts[character.id] ?? 0
    }

    func weeklyCount(for character: GameCharacter) -> Int {
        return characterWeeklyCounts[character.id] ?? 0
    }

    func totalCount(for character: GameCharacter) -> Int {
        return characterTotalCounts[character.id] ?? 0
    }

    func isInProgress(for character: GameCharacter) -> Bool {
        return characterInProgress[character.id] ?? false
    }

    func lastCompletedDate(for character: GameCharacter) -> Date? {
        return characterLastCompleted[character.id]
    }

    func startTime(for character: GameCharacter) -> Date? {
        return characterStartTime[character.id]
    }

    // MARK: - 数据更新方法（使用 CharacterID）

    mutating func setCount(_ count: Int, for characterId: UUID) {
        characterCounts[characterId] = count
    }

    mutating func setWeeklyCount(_ count: Int, for characterId: UUID) {
        characterWeeklyCounts[characterId] = count
    }

    mutating func setTotalCount(_ count: Int, for characterId: UUID) {
        characterTotalCounts[characterId] = count
    }

    mutating func setInProgress(_ inProgress: Bool, for characterId: UUID) {
        characterInProgress[characterId] = inProgress
    }

    mutating func setStartTime(_ time: Date?, for characterId: UUID) {
        if let time = time {
            characterStartTime[characterId] = time
        } else {
            characterStartTime.removeValue(forKey: characterId)
        }
    }

    mutating func setLastCompleted(_ date: Date?, for characterId: UUID) {
        if let date = date {
            characterLastCompleted[characterId] = date
        } else {
            characterLastCompleted.removeValue(forKey: characterId)
        }
    }

    mutating func addDuration(_ duration: TimeInterval, for characterId: UUID) {
        characterTotalDuration[characterId] = (characterTotalDuration[characterId] ?? 0) + duration
    }

    // MARK: - 从旧版本迁移

    /// 从旧的 Dungeon 模型创建（用于迁移）
    init(fromLegacy legacy: Dungeon, characterMapping: [GameCharacter: UUID]) {
        self.id = legacy.id
        self.name = legacy.name
        self.categoryId = legacy.categoryId
        self.customCategory = legacy.customCategory
        self.customCategoryOrder = legacy.customCategoryOrder

        // 转换字典：GameCharacter -> UUID
        for (character, count) in legacy.characterCounts {
            if let characterId = characterMapping[character] {
                self.characterCounts[characterId] = count
            }
        }

        for (character, count) in legacy.characterWeeklyCounts {
            if let characterId = characterMapping[character] {
                self.characterWeeklyCounts[characterId] = count
            }
        }

        for (character, count) in legacy.characterTotalCounts {
            if let characterId = characterMapping[character] {
                self.characterTotalCounts[characterId] = count
            }
        }

        for (character, date) in legacy.characterLastCompleted {
            if let characterId = characterMapping[character] {
                self.characterLastCompleted[characterId] = date
            }
        }

        for (character, inProgress) in legacy.characterInProgress {
            if let characterId = characterMapping[character] {
                self.characterInProgress[characterId] = inProgress
            }
        }

        for (character, time) in legacy.characterStartTime {
            if let characterId = characterMapping[character] {
                self.characterStartTime[characterId] = time
            }
        }

        for (character, duration) in legacy.characterTotalDuration {
            if let characterId = characterMapping[character] {
                self.characterTotalDuration[characterId] = duration
            }
        }
    }

    /// 标准初始化方法
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    // MARK: - Hashable & Equatable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DungeonV2, rhs: DungeonV2) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 迁移辅助扩展

extension DungeonV2 {
    /// 验证数据完整性
    func validate() -> [String] {
        var issues: [String] = []

        if name.isEmpty {
            issues.append("副本名称为空")
        }

        // 检查字典一致性
        let allCharacterIds = Set(characterCounts.keys)
            .union(characterWeeklyCounts.keys)
            .union(characterTotalCounts.keys)

        for characterId in allCharacterIds {
            if characterTotalCounts[characterId, default: 0] < characterWeeklyCounts[characterId, default: 0] {
                issues.append("角色 \(characterId) 的周计数超过总计数")
            }
        }

        return issues
    }

    /// 清理指定角色的所有数据
    mutating func removeCharacterData(_ characterId: UUID) {
        characterCounts.removeValue(forKey: characterId)
        characterWeeklyCounts.removeValue(forKey: characterId)
        characterTotalCounts.removeValue(forKey: characterId)
        characterLastCompleted.removeValue(forKey: characterId)
        characterInProgress.removeValue(forKey: characterId)
        characterStartTime.removeValue(forKey: characterId)
        characterTotalDuration.removeValue(forKey: characterId)
    }
}
