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
    
    private let userDefaults = UserDefaults.standard
    private let dungeonsKey = "SavedDungeons"
    private let charactersKey = "SavedCharacters"
    private let selectedCharacterKey = "SelectedCharacter"
    private let recordsKey = "CompletionRecords"
    
    init() {
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
        if let encoded = try? JSONEncoder().encode(dungeons) {
            userDefaults.set(encoded, forKey: dungeonsKey)
        }
        if let encoded = try? JSONEncoder().encode(characters) {
            userDefaults.set(encoded, forKey: charactersKey)
        }
        if let selectedCharacter = selectedCharacter,
           let encoded = try? JSONEncoder().encode(selectedCharacter) {
            userDefaults.set(encoded, forKey: selectedCharacterKey)
        }
        if let encoded = try? JSONEncoder().encode(completionRecords) {
            userDefaults.set(encoded, forKey: recordsKey)
        }
    }
    
    // MARK: - 数据同步
    private func syncStatisticsFromRecords() {
        // 根据历史记录重新计算所有统计数据
        let currentGameWeekStart = getGameWeekStart(for: Date())
        
        // 先清空所有统计数据
        for i in 0..<dungeons.count {
            dungeons[i].characterTotalCounts.removeAll()
            dungeons[i].characterTotalDuration.removeAll()
            dungeons[i].characterWeeklyCounts.removeAll()
            dungeons[i].characterLastCompleted.removeAll()
            dungeons[i].characterCounts.removeAll()
        }
        
        // 根据完成记录重新计算
        for record in completionRecords {
            
            if let dungeonIndex = dungeons.firstIndex(where: { $0.name == record.dungeonName }) {
                // 查找匹配的角色对象（通过显示名称匹配，而不是对象引用）
                guard let matchingCharacter = characters.first(where: {
                    $0.server == record.character.server &&
                    $0.name == record.character.name &&
                    $0.school == record.character.school
                }) else {
                    print("警告: 找不到匹配的角色对象: \(record.character.displayName)")
                    continue
                }
                
                // 更新总计数和总耗时
                let currentTotal = dungeons[dungeonIndex].characterTotalCounts[matchingCharacter] ?? 0
                dungeons[dungeonIndex].characterTotalCounts[matchingCharacter] = currentTotal + 1
                
                let currentDuration = dungeons[dungeonIndex].characterTotalDuration[matchingCharacter] ?? 0
                dungeons[dungeonIndex].characterTotalDuration[matchingCharacter] = currentDuration + record.duration
                
                // 更新最后完成时间（保留最新的）
                if let existingDate = dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] {
                    if record.completedDate > existingDate {
                        dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] = record.completedDate
                    }
                } else {
                    dungeons[dungeonIndex].characterLastCompleted[matchingCharacter] = record.completedDate
                }
                
                // 如果是当前游戏周的记录，更新周计数
                let recordGameWeekStart = getGameWeekStart(for: record.completedDate)
                if Calendar.current.isDate(currentGameWeekStart, inSameDayAs: recordGameWeekStart) {
                    let currentWeekly = dungeons[dungeonIndex].characterWeeklyCounts[matchingCharacter] ?? 0
                    dungeons[dungeonIndex].characterWeeklyCounts[matchingCharacter] = currentWeekly + 1
                }
                
                // 同步当前计数（设置为总计数）
                dungeons[dungeonIndex].characterCounts[matchingCharacter] = dungeons[dungeonIndex].characterTotalCounts[matchingCharacter]
                
            } else {
                print("警告: 找不到副本 \(record.dungeonName)，跳过记录")
            }
        }
        
        print("数据同步完成：已根据 \(completionRecords.count) 条历史记录重新计算统计数据")
        
        // 打印最终统计结果
        for dungeon in dungeons {
            for character in characters {
                let total = dungeon.characterTotalCounts[character] ?? 0
                let weekly = dungeon.characterWeeklyCounts[character] ?? 0
                if total > 0 || weekly > 0 {
                    print("  \(character.name): 总计 \(total), 本周 \(weekly)")
                }
            }
        }
        
        // 同步完成后保存数据
        saveData()
    }
    
    func loadData() {
        print("=== 开始加载数据 ===")
        
        // 加载角色数据
        if let data = userDefaults.data(forKey: charactersKey),
           let decoded = try? JSONDecoder().decode([GameCharacter].self, from: data) {
            characters = decoded
            print("已加载 \(characters.count) 个角色")
            for char in characters {
                print("  角色: \(char.displayName), ID: \(char.id)")
            }
        } else {
            // 默认角色
            let defaultCharacter = GameCharacter(server: "飞龙在天", name: "渡清欢", school: "长歌", bodyType: "正太")
            characters = [defaultCharacter]
            print("使用默认角色")
        }
        
        // 加载选中的角色
        if let data = userDefaults.data(forKey: selectedCharacterKey),
           let decoded = try? JSONDecoder().decode(GameCharacter.self, from: data) {
            selectedCharacter = decoded
            print("已加载选中角色: \(decoded.displayName), ID: \(decoded.id)")
        } else {
            selectedCharacter = characters.first
            print("使用第一个角色作为选中角色")
        }
        
        // 加载副本数据 - 需要处理数据迁移
        if let data = userDefaults.data(forKey: dungeonsKey),
           let decoded = try? JSONDecoder().decode([Dungeon].self, from: data) {
            dungeons = decoded
            print("已加载 \(dungeons.count) 个副本")
        } else {
            // 尝试从旧版本数据迁移
            print("未找到副本数据，尝试迁移旧数据")
            migrateFromOldData()
        }
        
        // 加载完成记录 - 需要处理数据迁移
        if let data = userDefaults.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([CompletionRecord].self, from: data) {
            completionRecords = decoded
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
        
        if let oldData = userDefaults.data(forKey: "SavedDungeons"),
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
            dungeons = [
                Dungeon(name: "25人普通冷龙峰"),
                Dungeon(name: "25人英雄河阳之战"),
                Dungeon(name: "25人普通河阳之战"),
                Dungeon(name: "25人普通白帝江关"),
                Dungeon(name: "25人英雄范阳夜变")
            ]
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
        
        if let oldData = userDefaults.data(forKey: "CompletionRecords"),
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
        if userDefaults.object(forKey: "WeeklyReports") != nil {
            userDefaults.removeObject(forKey: "WeeklyReports")
            print("已清理旧的周报告存储数据")
        }
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
    
    // MARK: - 手动添加历史记录
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
            let currentGameWeekStart = getGameWeekStart(for: Date())
            let recordGameWeekStart = getGameWeekStart(for: completedDate)
            if Calendar.current.isDate(currentGameWeekStart, inSameDayAs: recordGameWeekStart) {
                dungeons[dungeonIndex].characterWeeklyCounts[character] = (dungeons[dungeonIndex].characterWeeklyCounts[character] ?? 0) + 1
            }
        }
        
        saveData()
    }
    
    // MARK: - 游戏周相关方法（重构）
    private func getGameWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        
        var daysToSubtract = 0
        
        if weekday == 2 { // 周一
            if hour < 7 {
                daysToSubtract = 7
            } else {
                daysToSubtract = 0
            }
        } else if weekday == 1 { // 周日
            daysToSubtract = 6
        } else {
            daysToSubtract = weekday - 2
        }
        
        let startOfDay = calendar.startOfDay(for: date)
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfDay),
              let gameWeekStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: weekStart) else {
            return date
        }
        
        return gameWeekStart
    }
    
    // MARK: - 动态生成游戏周报告
    var availableGameWeeks: [DynamicWeeklyReport] {
        guard !completionRecords.isEmpty else { return [] }
        
        // 找到最早的完成记录
        let sortedRecords = completionRecords.sorted { $0.completedDate < $1.completedDate }
        guard let earliestRecord = sortedRecords.first else { return [] }
        
        var weeks: [DynamicWeeklyReport] = []
        let calendar = Calendar.current
        
        // 从最早记录的游戏周开始，到当前游戏周
        let earliestWeekStart = getGameWeekStart(for: earliestRecord.completedDate)
        let currentWeekStart = getGameWeekStart(for: Date())
        
        var currentDate = earliestWeekStart
        
        while currentDate <= currentWeekStart {
            let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentDate),
                  let weekEndFinal = calendar.date(byAdding: .minute, value: -1, to: weekEnd) else {
                break
            }
            
            let report = DynamicWeeklyReport(
                weekNumber: weekOfYear,
                year: year,
                startDate: currentDate,
                endDate: weekEndFinal
            )
            
            weeks.append(report)
            
            // 移动到下一个游戏周
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) else {
                break
            }
            currentDate = nextWeek
        }
        
        return weeks.sorted { $0.startDate > $1.startDate } // 最新的在前
    }
    
    // MARK: - 获取指定游戏周的统计数据
    func getWeeklyStatistics(for report: DynamicWeeklyReport) -> (characterDungeonCounts: [GameCharacter: [String: Int]], totalCompletions: Int) {
        let weekRecords = completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        var characterDungeonCounts: [GameCharacter: [String: Int]] = [:]
        var totalCompletions = 0
        
        for record in weekRecords {
            // 找到匹配的角色对象
            guard let matchingCharacter = characters.first(where: {
                $0.server == record.character.server &&
                $0.name == record.character.name &&
                $0.school == record.character.school
            }) else { continue }
            
            if characterDungeonCounts[matchingCharacter] == nil {
                characterDungeonCounts[matchingCharacter] = [:]
            }
            
            let currentCount = characterDungeonCounts[matchingCharacter]?[record.dungeonName] ?? 0
            characterDungeonCounts[matchingCharacter]?[record.dungeonName] = currentCount + 1
            totalCompletions += 1
        }
        
        return (characterDungeonCounts, totalCompletions)
    }
    
    // MARK: - 手动周结算（仅用于更新当前周统计）
    func manualGameWeeklyReset() {
        // 重新同步统计数据以更新当前周计数
        syncStatisticsFromRecords()
        print("手动执行游戏周结算完成")
    }
    
    // MARK: - 删除完成记录
    func deleteCompletionRecord(_ record: CompletionRecord) {
        // 从完成记录数组中移除指定记录
        completionRecords.removeAll { $0.id == record.id }
        
        // 重新同步统计数据（因为删除了记录，需要重新计算）
        syncStatisticsFromRecords()
        
        print("已删除完成记录：\(record.character.displayName) - \(record.dungeonName)")
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
}

// MARK: - 动态周报告数据模型
struct DynamicWeeklyReport: Identifiable, Codable {
    let id = UUID()
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    
    var displayTitle: String {
        return "\(year)-\(String(format: "%02d", weekNumber))周"
    }
}

// MARK: - 角色车数统计
extension DungeonManager {
    
    /// 获取指定角色在指定副本的第几车
    func getCharacterRunNumber(for record: CompletionRecord, dungeonName: String? = nil) -> Int {
        let targetDungeonName = dungeonName ?? record.dungeonName
        
        let characterRecords = completionRecords
            .filter {
                $0.character.server == record.character.server &&
                $0.character.name == record.character.name &&
                $0.character.school == record.character.school &&
                $0.dungeonName == targetDungeonName
            }
            .sorted { $0.completedDate < $1.completedDate }
        
        return (characterRecords.firstIndex { $0.id == record.id } ?? 0) + 1
    }
    
    /// 获取指定角色在所有副本的总车数
    func getTotalRunNumber(for record: CompletionRecord) -> Int {
        let recordIndex = completionRecords
            .sorted { $0.completedDate < $1.completedDate }
            .firstIndex { $0.id == record.id } ?? 0
        return recordIndex + 1
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
    
}

// MARK: - 掉落物拓展
extension DungeonManager {
    
    // 批量为记录添加掉落物品 - 新增方法
    func addMultipleDropsToRecord(_ record: CompletionRecord, dropNames: [String]) {
        guard !dropNames.isEmpty else { return }
        
        if let index = completionRecords.firstIndex(where: { $0.id == record.id }) {
            var currentRecord = completionRecords[index]
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
    
    // 为记录添加掉落物品 - 保持原有方法
    func addDropToRecord(_ record: CompletionRecord, dropItem: DropItem) {
        if let index = completionRecords.firstIndex(where: { $0.id == record.id }) {
            var currentRecord = completionRecords[index]
            var newDrops = currentRecord.drops
            newDrops.append(dropItem)
            
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
    
    // 从记录中移除掉落物品
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

// 紧急修复历史纪录问题
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
}
