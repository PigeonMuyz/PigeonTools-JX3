//
//  HybridDataService.swift
//  DungeonStat
//
//  混合数据服务 - V3 双轨运行模式
//  同时写入 Core Data 和 UserDefaults，确保数据安全
//

import Foundation
import CoreData

// MARK: - 混合数据服务
class HybridDataService {
    static let shared = HybridDataService()

    private let userDefaults = UserDefaults.standard
    private let coreDataStack = CoreDataStack.shared
    private let persistence = DataPersistenceManager.shared

    private init() {}

    // 检查是否启用 Core Data
    var isCoreDataEnabled: Bool {
        return userDefaults.bool(forKey: "CoreDataEnabled")
    }

    // MARK: - 角色管理

    func saveCharacters(_ characters: [GameCharacter]) {
        // 1. 保存到 UserDefaults（主存储）
        persistence.saveCharacters(characters)

        // 2. 如果启用了 Core Data，同步到 Core Data
        if isCoreDataEnabled {
            let context = coreDataStack.viewContext

            // 清空现有数据
            if let existing = try? CDGameCharacter.fetchAll(in: context) {
                existing.forEach { context.delete($0) }
            }

            // 写入新数据
            for character in characters {
                _ = CDGameCharacter.create(from: character, in: context)
            }

            try? context.save()
            print("✅ 角色数据已同步到 Core Data")
        }
    }

    func loadCharacters() -> [GameCharacter]? {
        // 优先从 UserDefaults 加载
        if let characters = persistence.loadCharacters() {
            return characters
        }

        // 如果 UserDefaults 没有数据，尝试从 Core Data 恢复
        if isCoreDataEnabled {
            do {
                let cdCharacters = try CDGameCharacter.fetchAll(in: coreDataStack.viewContext)
                let characters = cdCharacters.map { $0.toModel() }

                // 恢复到 UserDefaults
                persistence.saveCharacters(characters)
                print("✅ 从 Core Data 恢复了 \(characters.count) 个角色")

                return characters
            } catch {
                print("❌ 从 Core Data 加载角色失败: \(error)")
            }
        }

        return nil
    }

    // MARK: - 副本管理

    func saveDungeonsV2(_ dungeons: [DungeonV2]) {
        // 1. 保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(dungeons) {
            userDefaults.set(encoded, forKey: "SavedDungeonsV2")
        }

        // 2. 同步到 Core Data
        if isCoreDataEnabled {
            let context = coreDataStack.viewContext

            // 清空现有数据
            if let existing = try? CDDungeon.fetchAll(in: context) {
                existing.forEach { context.delete($0) }
            }

            // 写入新数据
            for dungeon in dungeons {
                _ = CDDungeon.create(from: dungeon, in: context)
            }

            try? context.save()
            print("✅ 副本数据已同步到 Core Data")
        }
    }

    func loadDungeonsV2() -> [DungeonV2]? {
        // 从 UserDefaults 加载
        if let data = userDefaults.data(forKey: "SavedDungeonsV2"),
           let dungeons = try? JSONDecoder().decode([DungeonV2].self, from: data) {
            return dungeons
        }

        // 从 Core Data 恢复
        if isCoreDataEnabled {
            do {
                let cdDungeons = try CDDungeon.fetchAll(in: coreDataStack.viewContext)
                let dungeons = cdDungeons.map { $0.toModel() }

                // 恢复到 UserDefaults
                if let encoded = try? JSONEncoder().encode(dungeons) {
                    userDefaults.set(encoded, forKey: "SavedDungeonsV2")
                }

                print("✅ 从 Core Data 恢复了 \(dungeons.count) 个副本")
                return dungeons
            } catch {
                print("❌ 从 Core Data 加载副本失败: \(error)")
            }
        }

        return nil
    }

    // MARK: - 完成记录管理

    func saveCompletionRecords(_ records: [CompletionRecord]) {
        // 1. 保存到 UserDefaults
        persistence.saveCompletionRecords(records)

        // 2. 同步到 Core Data
        if isCoreDataEnabled {
            let context = coreDataStack.viewContext

            // 清空现有数据
            if let existing = try? CDCompletionRecord.fetchAll(in: context) {
                existing.forEach { context.delete($0) }
            }

            // 写入新数据
            for record in records {
                let cdRecord = CDCompletionRecord.create(from: record, in: context)

                // 添加掉落物品
                for drop in record.drops {
                    let cdDrop = CDDropItem.create(from: drop, recordId: record.id, in: context)
                    cdRecord.addDrop(cdDrop)
                }
            }

            try? context.save()
            print("✅ 完成记录已同步到 Core Data")
        }
    }

    func loadCompletionRecords() -> [CompletionRecord]? {
        // 从 UserDefaults 加载
        if let records = persistence.loadCompletionRecords() {
            return records
        }

        // 从 Core Data 恢复（需要角色信息）
        if isCoreDataEnabled,
           let characters = loadCharacters() {
            do {
                let cdRecords = try CDCompletionRecord.fetchAll(in: coreDataStack.viewContext)

                // 转换为 CompletionRecord（需要匹配角色）
                let records = cdRecords.compactMap { cdRecord -> CompletionRecord? in
                    guard let character = characters.first(where: { $0.id == cdRecord.characterId }) else {
                        return nil
                    }
                    return cdRecord.toModel(character: character)
                }

                // 恢复到 UserDefaults
                persistence.saveCompletionRecords(records)
                print("✅ 从 Core Data 恢复了 \(records.count) 条完成记录")

                return records
            } catch {
                print("❌ 从 Core Data 加载完成记录失败: \(error)")
            }
        }

        return nil
    }

    // MARK: - 数据验证

    func validateDataConsistency() -> (isConsistent: Bool, issues: [String]) {
        var issues: [String] = []

        guard isCoreDataEnabled else {
            return (true, [])
        }

        // 验证角色数据
        if let udCharacters = loadCharacters() {
            do {
                let cdCharacters = try CDGameCharacter.fetchAll(in: coreDataStack.viewContext)
                if udCharacters.count != cdCharacters.count {
                    issues.append("角色数量不一致: UserDefaults(\(udCharacters.count)) vs CoreData(\(cdCharacters.count))")
                }
            } catch {
                issues.append("无法读取 Core Data 角色数据: \(error)")
            }
        }

        // 验证副本数据
        if let udDungeons = loadDungeonsV2() {
            do {
                let cdDungeons = try CDDungeon.fetchAll(in: coreDataStack.viewContext)
                if udDungeons.count != cdDungeons.count {
                    issues.append("副本数量不一致: UserDefaults(\(udDungeons.count)) vs CoreData(\(cdDungeons.count))")
                }
            } catch {
                issues.append("无法读取 Core Data 副本数据: \(error)")
            }
        }

        return (issues.isEmpty, issues)
    }
}
