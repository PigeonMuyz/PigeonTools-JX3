//
//  DataMigrationHelper.swift
//  DungeonStat
//
//  数据迁移辅助工具 - 提供具体的数据转换方法
//

import Foundation

// MARK: - 迁移辅助工具
class DataMigrationHelper {

    // MARK: - V1 -> V2 迁移：Dungeon -> DungeonV2

    /// 迁移单个副本数据
    static func migrateDungeon(_ legacy: Dungeon, characters: [GameCharacter]) -> DungeonV2 {
        // 构建角色映射表
        var characterMapping: [GameCharacter: UUID] = [:]

        // 从字典中提取所有出现过的角色
        var allCharacters = Set<GameCharacter>()
        legacy.characterCounts.keys.forEach { allCharacters.insert($0) }
        legacy.characterWeeklyCounts.keys.forEach { allCharacters.insert($0) }
        legacy.characterTotalCounts.keys.forEach { allCharacters.insert($0) }

        // 为每个角色找到对应的 ID
        for character in allCharacters {
            // 尝试在现有角色列表中匹配
            if let matchedCharacter = characters.first(where: {
                $0.server == character.server &&
                $0.name == character.name &&
                $0.school == character.school
            }) {
                characterMapping[character] = matchedCharacter.id
            } else {
                // 如果找不到匹配的角色，使用原角色的 ID
                characterMapping[character] = character.id
            }
        }

        return DungeonV2(fromLegacy: legacy, characterMapping: characterMapping)
    }

    /// 批量迁移副本数据
    static func migrateDungeons(_ legacyDungeons: [Dungeon], characters: [GameCharacter]) -> [DungeonV2] {
        return legacyDungeons.map { migrateDungeon($0, characters: characters) }
    }

    // MARK: - 数据验证

    /// 验证迁移后的数据完整性
    static func validateMigration(
        legacy: [Dungeon],
        migrated: [DungeonV2],
        characters: [GameCharacter]
    ) -> MigrationValidationResult {
        var issues: [String] = []
        var warnings: [String] = []

        // 1. 检查数量一致性
        if legacy.count != migrated.count {
            issues.append("副本数量不一致：原始 \(legacy.count)，迁移后 \(migrated.count)")
        }

        // 2. 检查每个副本的数据
        for (index, legacyDungeon) in legacy.enumerated() {
            guard index < migrated.count else { continue }
            let migratedDungeon = migrated[index]

            // 检查基本信息
            if legacyDungeon.name != migratedDungeon.name {
                issues.append("副本 \(index) 名称不一致")
            }

            // 检查统计数据总数
            let legacyTotalRecords = legacyDungeon.characterTotalCounts.values.reduce(0, +)
            let migratedTotalRecords = migratedDungeon.characterTotalCounts.values.reduce(0, +)

            if legacyTotalRecords != migratedTotalRecords {
                issues.append("副本 '\(legacyDungeon.name)' 总记录数不一致：\(legacyTotalRecords) -> \(migratedTotalRecords)")
            }

            // 验证数据完整性
            let validationIssues = migratedDungeon.validate()
            if !validationIssues.isEmpty {
                warnings.append("副本 '\(migratedDungeon.name)' 存在问题：\(validationIssues.joined(separator: ", "))")
            }
        }

        return MigrationValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }

    // MARK: - 数据对比（用于调试）

    /// 生成迁移前后的对比报告
    static func generateMigrationReport(
        legacy: [Dungeon],
        migrated: [DungeonV2],
        characters: [GameCharacter]
    ) -> String {
        var report = "=== 数据迁移报告 ===\n\n"

        report += "副本数量：\(legacy.count) -> \(migrated.count)\n"

        var totalRecordsBefore = 0
        var totalRecordsAfter = 0

        for legacyDungeon in legacy {
            totalRecordsBefore += legacyDungeon.characterTotalCounts.values.reduce(0, +)
        }

        for migratedDungeon in migrated {
            totalRecordsAfter += migratedDungeon.characterTotalCounts.values.reduce(0, +)
        }

        report += "总记录数：\(totalRecordsBefore) -> \(totalRecordsAfter)\n\n"

        report += "详细信息：\n"
        for (index, migratedDungeon) in migrated.enumerated() {
            let totalCount = migratedDungeon.characterTotalCounts.values.reduce(0, +)
            let weeklyCount = migratedDungeon.characterWeeklyCounts.values.reduce(0, +)
            report += "  \(index + 1). \(migratedDungeon.name)\n"
            report += "     总计: \(totalCount), 本周: \(weeklyCount)\n"
            report += "     涉及角色: \(migratedDungeon.characterCounts.keys.count) 个\n"
        }

        return report
    }
}

// MARK: - 验证结果

struct MigrationValidationResult {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]

    var summary: String {
        var text = isValid ? "✅ 验证通过" : "❌ 验证失败"

        if !issues.isEmpty {
            text += "\n\n问题 (\(issues.count)):\n"
            text += issues.map { "  • \($0)" }.joined(separator: "\n")
        }

        if !warnings.isEmpty {
            text += "\n\n警告 (\(warnings.count)):\n"
            text += warnings.map { "  ⚠️ \($0)" }.joined(separator: "\n")
        }

        return text
    }
}
