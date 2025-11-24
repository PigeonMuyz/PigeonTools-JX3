//
//  MigrationManager.swift
//  DungeonStat
//
//  数据迁移管理器 - 负责管理所有数据迁移任务
//

import Foundation
import CoreData

// MARK: - 迁移版本管理
enum DataVersion: Int, Codable {
    case v1_userDefaults = 1           // 原始版本：UserDefaults + GameCharacter 作为字典键
    case v2_characterID = 2            // 第一阶段：修复字典键问题，使用 UUID
    case v3_coreDataHybrid = 3         // 第二阶段：Core Data + UserDefaults 双轨
    case v4_coreDataOnly = 4           // 第三阶段：完全迁移到 Core Data

    var description: String {
        switch self {
        case .v1_userDefaults:
            return "V1 - UserDefaults 存储"
        case .v2_characterID:
            return "V2 - 修复内存问题"
        case .v3_coreDataHybrid:
            return "V3 - 双轨运行"
        case .v4_coreDataOnly:
            return "V4 - Core Data"
        }
    }
}

// MARK: - 迁移结果
struct MigrationResult {
    let success: Bool
    let fromVersion: DataVersion
    let toVersion: DataVersion
    let backupId: String?
    let error: Error?
    let migrationLog: [String]

    var isRollbackAvailable: Bool {
        return backupId != nil
    }
}

// MARK: - 迁移管理器
class MigrationManager {
    static let shared = MigrationManager()
    private init() {}

    private let userDefaults = UserDefaults.standard
    private let versionKey = "DataMigrationVersion"
    private let migrationLogKey = "MigrationLog"

    // MARK: - 当前版本管理

    var currentVersion: DataVersion {
        get {
            let rawValue = userDefaults.integer(forKey: versionKey)
            return DataVersion(rawValue: rawValue) ?? .v1_userDefaults
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: versionKey)
            logMigration("数据版本更新为: \(newValue.description)")
        }
    }

    // MARK: - 迁移执行

    /// 检查是否需要迁移
    func needsMigration(to targetVersion: DataVersion) -> Bool {
        return currentVersion.rawValue < targetVersion.rawValue
    }

    /// 执行迁移到目标版本
    @MainActor
    func migrate(to targetVersion: DataVersion) async -> MigrationResult {
        let startVersion = currentVersion
        var logs: [String] = []

        logs.append("=== 开始迁移: \(startVersion.description) -> \(targetVersion.description) ===")

        // 1. 创建自动备份
        guard let backupId = DataPersistenceManager.shared.createDataBackup() else {
            let error = NSError(domain: "MigrationManager", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "创建备份失败"])
            logs.append("❌ 备份创建失败，迁移中止")
            return MigrationResult(success: false, fromVersion: startVersion,
                                 toVersion: targetVersion, backupId: nil,
                                 error: error, migrationLog: logs)
        }

        logs.append("✅ 备份创建成功: \(backupId)")

        // 2. 执行迁移步骤
        do {
            var currentStep = startVersion

            // 逐步迁移到目标版本
            while currentStep.rawValue < targetVersion.rawValue {
                let nextStep = DataVersion(rawValue: currentStep.rawValue + 1)!
                logs.append("开始迁移步骤: \(currentStep.description) -> \(nextStep.description)")

                try await performMigrationStep(from: currentStep, to: nextStep, logs: &logs)

                currentStep = nextStep
                currentVersion = nextStep

                logs.append("✅ 迁移步骤完成: \(nextStep.description)")
            }

            logs.append("=== 迁移成功完成 ===")
            logMigration(logs.joined(separator: "\n"))

            return MigrationResult(success: true, fromVersion: startVersion,
                                 toVersion: targetVersion, backupId: backupId,
                                 error: nil, migrationLog: logs)

        } catch {
            logs.append("❌ 迁移失败: \(error.localizedDescription)")
            logs.append("正在回滚到备份...")

            // 自动回滚
            if DataPersistenceManager.shared.restoreFromBackup(backupId) {
                logs.append("✅ 已回滚到迁移前状态")
            } else {
                logs.append("⚠️ 回滚失败，请手动恢复备份: \(backupId)")
            }

            logMigration(logs.joined(separator: "\n"))

            return MigrationResult(success: false, fromVersion: startVersion,
                                 toVersion: targetVersion, backupId: backupId,
                                 error: error, migrationLog: logs)
        }
    }

    // MARK: - 具体迁移步骤

    private func performMigrationStep(from: DataVersion, to: DataVersion, logs: inout [String]) async throws {
        switch (from, to) {
        case (.v1_userDefaults, .v2_characterID):
            try migrateV1ToV2(logs: &logs)

        case (.v2_characterID, .v3_coreDataHybrid):
            try await migrateV2ToV3(logs: &logs)

        case (.v3_coreDataHybrid, .v4_coreDataOnly):
            try await migrateV3ToV4(logs: &logs)

        default:
            throw NSError(domain: "MigrationManager", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "不支持的迁移路径"])
        }
    }

    // MARK: - V1 -> V2: 修复字典键问题

    private func migrateV1ToV2(logs: inout [String]) throws {
        logs.append("开始 V1->V2 迁移: 修复 Dungeon 字典键问题")

        // 1. 加载旧的 Dungeon 数据
        guard let oldDungeonsData = userDefaults.data(forKey: "SavedDungeons"),
              let oldDungeons = try? JSONDecoder().decode([Dungeon].self, from: oldDungeonsData) else {
            logs.append("⚠️ 未找到旧副本数据，跳过迁移")
            return
        }

        // 2. 加载角色数据
        guard let charactersData = userDefaults.data(forKey: "SavedCharacters"),
              let characters = try? JSONDecoder().decode([GameCharacter].self, from: charactersData) else {
            logs.append("⚠️ 未找到角色数据，无法进行迁移")
            throw NSError(domain: "MigrationManager", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "缺少角色数据"])
        }

        logs.append("找到 \(oldDungeons.count) 个副本，\(characters.count) 个角色")

        // 3. 使用辅助工具迁移数据
        let migratedDungeons = DataMigrationHelper.migrateDungeons(oldDungeons, characters: characters)
        logs.append("✅ 副本数据转换完成")

        // 4. 验证迁移结果
        let validation = DataMigrationHelper.validateMigration(
            legacy: oldDungeons,
            migrated: migratedDungeons,
            characters: characters
        )

        if !validation.isValid {
            logs.append("❌ 数据验证失败：")
            logs.append(contentsOf: validation.issues.map { "  • \($0)" })
            throw NSError(domain: "MigrationManager", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "数据验证失败"])
        }

        if !validation.warnings.isEmpty {
            logs.append("⚠️ 验证警告：")
            logs.append(contentsOf: validation.warnings.map { "  ⚠️ \($0)" })
        }

        // 5. 保存迁移后的数据
        if let encoded = try? JSONEncoder().encode(migratedDungeons) {
            userDefaults.set(encoded, forKey: "SavedDungeonsV2")
            logs.append("✅ 新版副本数据已保存")

            // 6. 生成迁移报告
            let report = DataMigrationHelper.generateMigrationReport(
                legacy: oldDungeons,
                migrated: migratedDungeons,
                characters: characters
            )
            logs.append("\n" + report)
        } else {
            throw NSError(domain: "MigrationManager", code: -5,
                         userInfo: [NSLocalizedDescriptionKey: "副本数据编码失败"])
        }
    }

    // MARK: - V2 -> V3: 建立 Core Data 双轨运行

    private func migrateV2ToV3(logs: inout [String]) async throws {
        logs.append("开始 V2->V3 迁移: 建立 Core Data 存储")

        // 1. 加载 V2 数据
        guard let dungeonsData = userDefaults.data(forKey: "SavedDungeonsV2"),
              let dungeons = try? JSONDecoder().decode([DungeonV2].self, from: dungeonsData) else {
            logs.append("⚠️ 未找到 V2 副本数据，尝试从旧格式迁移")

            // 尝试加载旧格式
            guard let oldData = userDefaults.data(forKey: "SavedDungeons"),
                  let oldDungeons = try? JSONDecoder().decode([Dungeon].self, from: oldData),
                  let charactersData = userDefaults.data(forKey: "SavedCharacters"),
                  let characters = try? JSONDecoder().decode([GameCharacter].self, from: charactersData) else {
                throw NSError(domain: "MigrationManager", code: -10,
                             userInfo: [NSLocalizedDescriptionKey: "无法加载副本数据"])
            }

            // 转换旧格式到 V2
            let migratedDungeons = DataMigrationHelper.migrateDungeons(oldDungeons, characters: characters)

            // 保存为 V2 格式
            if let encoded = try? JSONEncoder().encode(migratedDungeons) {
                userDefaults.set(encoded, forKey: "SavedDungeonsV2")
                return try await migrateV2ToV3(logs: &logs) // 递归重试
            } else {
                throw NSError(domain: "MigrationManager", code: -11,
                             userInfo: [NSLocalizedDescriptionKey: "数据转换失败"])
            }
        }

        guard let charactersData = userDefaults.data(forKey: "SavedCharacters"),
              let characters = try? JSONDecoder().decode([GameCharacter].self, from: charactersData) else {
            throw NSError(domain: "MigrationManager", code: -12,
                         userInfo: [NSLocalizedDescriptionKey: "无法加载角色数据"])
        }

        if userDefaults.data(forKey: "CompletionRecords") == nil {
            logs.append("⚠️ 未找到完成记录数据，将创建空的 Core Data 存储")
        }

        logs.append("已加载 V2 数据: \(dungeons.count) 个副本, \(characters.count) 个角色")

        // 2. 初始化 Core Data
        let coreDataStack = CoreDataStack.shared
        let context = coreDataStack.viewContext

        logs.append("✅ Core Data Stack 初始化成功")

        // 3. 清空现有 Core Data 数据（确保干净的迁移）
        do {
            try coreDataStack.clearAllData()
            logs.append("✅ Core Data 已清空")
        } catch {
            logs.append("⚠️ 清空 Core Data 失败: \(error.localizedDescription)")
        }

        // 4. 写入角色数据
        for character in characters {
            _ = CDGameCharacter.create(from: character, in: context)
        }

        try context.save()
        logs.append("✅ 已写入 \(characters.count) 个角色到 Core Data")

        // 5. 写入副本数据
        for dungeon in dungeons {
            _ = CDDungeon.create(from: dungeon, in: context)
        }

        try context.save()
        logs.append("✅ 已写入 \(dungeons.count) 个副本到 Core Data")

        // 6. 写入完成记录
        if let records = try? JSONDecoder().decode([CompletionRecord].self, from: userDefaults.data(forKey: "CompletionRecords") ?? Data()) {
            for record in records {
                let cdRecord = CDCompletionRecord.create(from: record, in: context)

                // 添加掉落物品
                for drop in record.drops {
                    let cdDrop = CDDropItem.create(from: drop, recordId: record.id, in: context)
                    cdRecord.addDrop(cdDrop)
                }
            }

            try context.save()
            logs.append("✅ 已写入 \(records.count) 条完成记录到 Core Data")
        }

        // 7. 验证数据一致性
        let cdCharacters = try CDGameCharacter.fetchAll(in: context)
        let cdDungeons = try CDDungeon.fetchAll(in: context)
        let cdRecords = try CDCompletionRecord.fetchAll(in: context)

        if cdCharacters.count != characters.count {
            throw NSError(domain: "MigrationManager", code: -13,
                         userInfo: [NSLocalizedDescriptionKey: "角色数量不一致"])
        }

        if cdDungeons.count != dungeons.count {
            throw NSError(domain: "MigrationManager", code: -14,
                         userInfo: [NSLocalizedDescriptionKey: "副本数量不一致"])
        }

        logs.append("✅ 数据验证成功")
        logs.append("   - 角色: \(cdCharacters.count)")
        logs.append("   - 副本: \(cdDungeons.count)")
        logs.append("   - 记录: \(cdRecords.count)")

        // 8. 设置双轨运行标志
        userDefaults.set(true, forKey: "CoreDataEnabled")
        logs.append("✅ 已启用 Core Data 双轨运行模式")
    }

    // MARK: - V3 -> V4: 完全切换到 Core Data

    private func migrateV3ToV4(logs: inout [String]) async throws {
        logs.append("开始 V3->V4 迁移: 切换到 Core Data")

        // TODO: 在后续步骤实现
        // 1. 验证 Core Data 数据完整性
        // 2. 停止写入 UserDefaults
        // 3. 清理旧的 UserDefaults 数据（保留备份）

        logs.append("⚠️ V3->V4 迁移暂未实现")
    }

    // MARK: - 回滚支持

    /// 回滚到指定版本
    func rollback(to version: DataVersion, using backupId: String) -> Bool {
        logMigration("开始回滚到版本: \(version.description)，备份ID: \(backupId)")

        if DataPersistenceManager.shared.restoreFromBackup(backupId) {
            currentVersion = version
            logMigration("✅ 回滚成功")
            return true
        } else {
            logMigration("❌ 回滚失败")
            return false
        }
    }

    // MARK: - 日志管理

    private func logMigration(_ message: String) {
        print("[Migration] \(message)")

        var logs = userDefaults.stringArray(forKey: migrationLogKey) ?? []
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")

        // 只保留最近100条日志
        if logs.count > 100 {
            logs = Array(logs.suffix(100))
        }

        userDefaults.set(logs, forKey: migrationLogKey)
    }

    /// 获取迁移日志
    func getMigrationLogs() -> [String] {
        return userDefaults.stringArray(forKey: migrationLogKey) ?? []
    }

    /// 清除迁移日志
    func clearMigrationLogs() {
        userDefaults.removeObject(forKey: migrationLogKey)
    }
}
