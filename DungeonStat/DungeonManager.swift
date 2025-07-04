//
//  DungeonManager.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI
import Foundation
import Combine

// MARK: - 数据管理器
class DungeonManager: ObservableObject {
    @Published var dungeons: [Dungeon] = []
    @Published var characters: [GameCharacter] = []
    @Published var selectedCharacter: GameCharacter?
    @Published var completionRecords: [CompletionRecord] = []
    
    // 管理器实例
    private let persistenceManager = DataPersistenceManager.shared
    private let statisticsManager = StatisticsManager.shared
    private let weeklyReportManager = WeeklyReportManager.shared
    
    init() {
//        // 在加载数据前创建备份（仅在有数据时）
//        if UserDefaults.standard.data(forKey: "SavedDungeons") != nil ||
//           UserDefaults.standard.data(forKey: "SavedCharacters") != nil ||
//           UserDefaults.standard.data(forKey: "CompletionRecords") != nil {
//            if let backupId = persistenceManager.createDataBackup() {
//                print("DungeonManager: 初始化备份创建成功: \(backupId)")
//            }
//        }
        
        loadData()
        
        // 添加调试输出
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let character = self.selectedCharacter {
                for dungeon in self.dungeons {
                    let total = dungeon.totalCount(for: character)
                    let weekly = dungeon.weeklyCount(for: character)
                    if total > 0 || weekly > 0 {
                        print("  \(dungeon.name): 总计 \(total), 本周 \(weekly)")
                    }
                }
            }
        }
    }
    
    // MARK: - 数据持久化
    func saveData() {
        persistenceManager.saveDungeons(dungeons)
        persistenceManager.saveCharacters(characters)
        persistenceManager.saveSelectedCharacter(selectedCharacter)
        persistenceManager.saveCompletionRecords(completionRecords)
    }
    
    // MARK: - 数据同步
    func syncStatisticsFromRecords() {
        statisticsManager.syncStatisticsFromRecords(
            dungeons: &dungeons,
            characters: characters,
            completionRecords: completionRecords
        )
        
        print("数据同步完成：已根据 \(completionRecords.count) 条历史记录重新计算统计数据")
        
        // 同步完成后保存数据
        saveData()
    }
    
    func loadData() {
        print("=== 开始加载数据 ===")
        
        // 加载角色数据
        if let loadedCharacters = persistenceManager.loadCharacters() {
            characters = loadedCharacters
            print("已加载 \(characters.count) 个角色")
            for char in characters {
                print("  角色: \(char.displayName), ID: \(char.id)")
            }
        } else {
            // 默认角色
            characters = [Constants.DefaultData.defaultCharacter]
            print("使用默认角色")
        }
        
        // 加载选中的角色
        if let loadedSelectedCharacter = persistenceManager.loadSelectedCharacter() {
            selectedCharacter = loadedSelectedCharacter
            print("已加载选中角色: \(loadedSelectedCharacter.displayName), ID: \(loadedSelectedCharacter.id)")
        } else {
            selectedCharacter = characters.first
            print("使用第一个角色作为选中角色")
        }
        
        // 加载副本数据
        if let loadedDungeons = persistenceManager.loadDungeons() {
            dungeons = loadedDungeons
            print("已加载 \(dungeons.count) 个副本")
        } else {
            // 尝试从旧版本数据迁移
            print("未找到副本数据，尝试迁移旧数据")
            migrateFromOldData()
        }
        
        // 加载完成记录
        if let loadedRecords = persistenceManager.loadCompletionRecords() {
            completionRecords = loadedRecords
            print("已加载 \(completionRecords.count) 条完成记录")
            
            // 打印最近几条记录用于调试
            let recentRecords = completionRecords.suffix(5)
            for record in recentRecords {
                print("  记录: \(record.character.displayName) - \(record.dungeonName) - \(record.completedDate)")
                print("    记录中角色ID: \(record.character.id)")
            }
        } else {
            // 尝试从旧版本数据迁移
            print("未找到完成记录，尝试迁移旧数据")
            migrateOldCompletionRecords()
        }
        
        // 迁移旧的周报告数据（清理）
        migrateOldWeeklyReports()
        
        // 数据加载完成后，同步统计数据
        print("=== 开始同步统计数据 ===")
        syncStatisticsFromRecords()
        
        // 强制重新设置选中角色（确保引用正确的对象）
        if let selectedChar = selectedCharacter {
            if let matchingChar = characters.first(where: {
                $0.server == selectedChar.server &&
                $0.name == selectedChar.name &&
                $0.school == selectedChar.school
            }) {
                selectedCharacter = matchingChar
                print("重新设置选中角色为匹配的对象: \(matchingChar.displayName)")
            }
        } else {
            selectedCharacter = characters.first
            print("selectedCharacter 为 nil，设置为第一个角色")
        }
        
        // 验证同步结果
        print("=== 数据加载和同步完成 ===")
        print("最终状态检查:")
        for dungeon in dungeons {
            for character in characters {
                let total = dungeon.characterTotalCounts[character] ?? 0
                let weekly = dungeon.characterWeeklyCounts[character] ?? 0
                if total > 0 || weekly > 0 {
                    print("  \(dungeon.name) - \(character.name): 总计 \(total), 本周 \(weekly)")
                }
            }
        }
        
        // 额外调试：检查字典中的实际内容
        print("=== 字典内容调试 ===")
        for (index, dungeon) in dungeons.enumerated() {
            if !dungeon.characterTotalCounts.isEmpty {
                print("副本 \(index): \(dungeon.name)")
                for (char, count) in dungeon.characterTotalCounts {
                    print("  角色: \(char.displayName) (ID: \(char.id)) -> 总计: \(count)")
                }
            }
        }
    }
    
    // MARK: - 数据迁移
    private func migrateFromOldData() {
        // 检查是否有旧版本的副本数据
        struct OldDungeon: Codable {
            let name: String
            let currentCount: Int
            let weeklyCount: Int
            let totalCount: Int
            let lastCompletedDate: Date?
            let totalDuration: TimeInterval
        }
        
        if let oldData = UserDefaults.standard.data(forKey: "SavedDungeons"),
           let oldDungeons = try? JSONDecoder().decode([OldDungeon].self, from: oldData),
           let defaultCharacter = characters.first {
            
            // 将旧数据迁移到新格式
            dungeons = oldDungeons.map { oldDungeon in
                var newDungeon = Dungeon(name: oldDungeon.name)
                newDungeon.characterCounts[defaultCharacter] = oldDungeon.currentCount
                newDungeon.characterWeeklyCounts[defaultCharacter] = oldDungeon.weeklyCount
                newDungeon.characterTotalCounts[defaultCharacter] = oldDungeon.totalCount
                newDungeon.characterTotalDuration[defaultCharacter] = oldDungeon.totalDuration
                if let lastCompleted = oldDungeon.lastCompletedDate {
                    newDungeon.characterLastCompleted[defaultCharacter] = lastCompleted
                }
                return newDungeon
            }
            
            print("已迁移 \(dungeons.count) 个副本的数据到默认角色")
        } else {
            // 没有旧数据，创建默认副本列表
            dungeons = Constants.DefaultData.defaultDungeons.map { Dungeon(name: $0) }
        }
    }
    
    private func migrateOldCompletionRecords() {
        // 检查是否有旧版本的完成记录
        struct OldCompletionRecord: Codable {
            let dungeonName: String
            let completedDate: Date
            let weekNumber: Int
            let year: Int
            let duration: TimeInterval
        }
        
        if let oldData = UserDefaults.standard.data(forKey: "CompletionRecords"),
           let oldRecords = try? JSONDecoder().decode([OldCompletionRecord].self, from: oldData),
           let defaultCharacter = characters.first {
            
            // 将旧记录迁移到新格式
            completionRecords = oldRecords.map { oldRecord in
                CompletionRecord(
                    dungeonName: oldRecord.dungeonName,
                    character: defaultCharacter,
                    completedDate: oldRecord.completedDate,
                    weekNumber: oldRecord.weekNumber,
                    year: oldRecord.year,
                    duration: oldRecord.duration
                )
            }
            
            print("已迁移 \(completionRecords.count) 条历史记录到默认角色")
            
            // 迁移完成后同步统计数据
            syncStatisticsFromRecords()
        }
    }
    
    // 迁移旧的周报告数据（清理旧存储）
    private func migrateOldWeeklyReports() {
        persistenceManager.removeOldKey("WeeklyReports")
        print("已清理旧的周报告存储数据")
    }
    
    // MARK: - 角色操作
    func addCharacter(server: String, name: String, school: String, bodyType: String) {
        let newCharacter = GameCharacter(server: server, name: name, school: school, bodyType: bodyType)
        characters.append(newCharacter)
        if selectedCharacter == nil {
            selectedCharacter = newCharacter
        }
        saveData()
    }
    
    func deleteCharacter(_ character: GameCharacter) {
        characters.removeAll { $0.id == character.id }
        if selectedCharacter?.id == character.id {
            selectedCharacter = characters.first
        }
        saveData()
    }
    
    func selectCharacter(_ character: GameCharacter) {
        selectedCharacter = character
        print("selectCharacter called: \(character.displayName)")
        saveData()
        
        // 强制刷新 UI
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - 副本操作
    func addDungeon(name: String) {
        let newDungeon = Dungeon(name: name)
        dungeons.append(newDungeon)
        saveData()
    }
    
    func startDungeon(at index: Int) {
        guard index < dungeons.count, let character = selectedCharacter else { return }
        
        dungeons[index].characterInProgress[character] = true
        dungeons[index].characterStartTime[character] = Date()
        saveData()
    }
    
    func completeDungeon(at index: Int) {
        guard index < dungeons.count,
              let character = selectedCharacter,
              let startTime = dungeons[index].characterStartTime[character],
              dungeons[index].characterInProgress[character] == true else { return }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // 更新各种计数
        dungeons[index].characterCounts[character] = (dungeons[index].characterCounts[character] ?? 0) + 1
        dungeons[index].characterWeeklyCounts[character] = (dungeons[index].characterWeeklyCounts[character] ?? 0) + 1
        dungeons[index].characterTotalCounts[character] = (dungeons[index].characterTotalCounts[character] ?? 0) + 1
        dungeons[index].characterTotalDuration[character] = (dungeons[index].characterTotalDuration[character] ?? 0) + duration
        dungeons[index].characterLastCompleted[character] = endTime
        dungeons[index].characterInProgress[character] = false
        dungeons[index].characterStartTime.removeValue(forKey: character)
        
        // 记录完成记录
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: endTime)
        let year = calendar.component(.year, from: endTime)
        
        let record = CompletionRecord(
            dungeonName: dungeons[index].name,
            character: character,
            completedDate: endTime,
            weekNumber: weekOfYear,
            year: year,
            duration: duration
        )
        completionRecords.append(record)
        
        saveData()
    }
    
    func cancelDungeon(at index: Int) {
        guard index < dungeons.count, let character = selectedCharacter else { return }
        
        dungeons[index].characterInProgress[character] = false
        dungeons[index].characterStartTime.removeValue(forKey: character)
        saveData()
    }
    
    func deleteDungeon(at index: Int) {
        guard index < dungeons.count else { return }
        dungeons.remove(at: index)
        saveData()
    }
    
    // MARK: - 指定角色的副本操作（不影响全局选中角色）
    
    /// 完成指定角色的副本，不改变全局选中角色
    func completeDungeonForCharacter(at index: Int, character: GameCharacter) {
        guard index < dungeons.count,
              let startTime = dungeons[index].characterStartTime[character],
              dungeons[index].characterInProgress[character] == true else { return }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // 更新各种计数
        dungeons[index].characterCounts[character] = (dungeons[index].characterCounts[character] ?? 0) + 1
        dungeons[index].characterWeeklyCounts[character] = (dungeons[index].characterWeeklyCounts[character] ?? 0) + 1
        dungeons[index].characterTotalCounts[character] = (dungeons[index].characterTotalCounts[character] ?? 0) + 1
        dungeons[index].characterTotalDuration[character] = (dungeons[index].characterTotalDuration[character] ?? 0) + duration
        dungeons[index].characterLastCompleted[character] = endTime
        dungeons[index].characterInProgress[character] = false
        dungeons[index].characterStartTime.removeValue(forKey: character)
        
        // 记录完成记录
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: endTime)
        let year = calendar.component(.year, from: endTime)
        
        let record = CompletionRecord(
            dungeonName: dungeons[index].name,
            character: character,
            completedDate: endTime,
            weekNumber: weekOfYear,
            year: year,
            duration: duration
        )
        completionRecords.append(record)
        
        saveData()
        
        print("已完成副本：\(character.displayName) - \(dungeons[index].name)")
    }

    /// 取消指定角色的副本，不改变全局选中角色
    func cancelDungeonForCharacter(at index: Int, character: GameCharacter) {
        guard index < dungeons.count else { return }
        
        dungeons[index].characterInProgress[character] = false
        dungeons[index].characterStartTime.removeValue(forKey: character)
        saveData()
        
        print("已取消副本：\(character.displayName) - \(dungeons[index].name)")
    }
    
    // MARK: - 动态生成游戏周报告
    var availableGameWeeks: [DynamicWeeklyReport] {
        return weeklyReportManager.generateAvailableGameWeeks(from: completionRecords)
    }
    
    // MARK: - 获取指定游戏周的统计数据
    func getWeeklyStatistics(for report: DynamicWeeklyReport) -> (characterDungeonCounts: [GameCharacter: [String: Int]], totalCompletions: Int) {
        return weeklyReportManager.getWeeklyStatistics(
            for: report,
            from: completionRecords,
            characters: characters
        )
    }
    
    // MARK: - 备份和恢复功能
    
    /// 创建数据备份
    func createBackup() -> String? {
        return persistenceManager.createDataBackup()
    }
    
    /// 从备份恢复数据
    func restoreFromBackup(_ backupSuffix: String) -> Bool {
        let success = persistenceManager.restoreFromBackup(backupSuffix)
        if success {
            // 恢复成功后重新加载数据
            loadData()
        }
        return success
    }
    
    /// 获取可用的备份列表
    func getAvailableBackups() -> [BackupInfo] {
        return persistenceManager.getAvailableBackups()
    }
    
    /// 删除指定备份
    func deleteBackup(_ backupSuffix: String) -> Bool {
        return persistenceManager.deleteBackup(backupSuffix)
    }
    
    /// 获取数据状态信息（用于调试）
    func getDataStatusInfo() -> String {
        var info = "=== 数据状态信息 ==="
        info += "\n角色数量: \(characters.count)"
        info += "\n副本数量: \(dungeons.count)"
        info += "\n完成记录: \(completionRecords.count)"
        info += "\n当前选中角色: \(selectedCharacter?.displayName ?? "无")"
        
        let backups = getAvailableBackups()
        info += "\n可用备份: \(backups.count) 个"
        
        if let lastBackupDate = UserDefaults.standard.object(forKey: "LastBackupDate") as? Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            info += "\n最后备份时间: \(formatter.string(from: lastBackupDate))"
        }
        
        return info
    }
}
