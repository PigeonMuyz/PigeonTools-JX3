//
//  EnhancedBackupService.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/9.
//

import Foundation
import UIKit
import Combine

class EnhancedBackupService: ObservableObject {
    static let shared = EnhancedBackupService()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // MARK: - 获取文档目录
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - 创建完整备份
    func createFullBackup(configuration: BackupConfiguration = BackupConfiguration.default) async -> BackupResult {
        do {
            let backupData = try await collectAllData(configuration: configuration)
            let fileName = "DungeonStat_Backup_\(formatTimestamp(Date())).json"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // 将数据转换为JSON
            let jsonData = try JSONEncoder().encode(backupData)
            
            // 写入文件
            try jsonData.write(to: fileURL)
            
            // 保存备份历史记录
            saveBackupHistory(fileURL: fileURL, backupData: backupData)
            
            return BackupResult(
                success: true,
                message: "备份创建成功",
                backupData: backupData,
                fileURL: fileURL,
                error: nil
            )
            
        } catch {
            return BackupResult(
                success: false,
                message: "备份创建失败: \(error.localizedDescription)",
                backupData: nil,
                fileURL: nil,
                error: error
            )
        }
    }
    
    // MARK: - 收集所有数据
    private func collectAllData(configuration: BackupConfiguration) async throws -> AppBackupData {
        let metadata = createBackupMetadata(configuration: configuration)
        let coreData = try collectCoreData()
        let configData = collectConfigData()
        let taskData = try collectTaskData()
        let cacheData = try await collectCacheData()
        
        return AppBackupData(
            backupInfo: metadata,
            coreData: coreData,
            configData: configData,
            taskData: taskData,
            cacheData: cacheData
        )
    }
    
    // MARK: - 创建备份元数据
    private func createBackupMetadata(configuration: BackupConfiguration) -> AppBackupData.BackupMetadata {
        var dataTypes: [String] = []
        
        if configuration.includeCoreData { dataTypes.append("核心数据") }
        if configuration.includeConfigData { dataTypes.append("配置数据") }
        if configuration.includeTaskData { dataTypes.append("任务数据") }
        if configuration.includeCacheData { dataTypes.append("缓存数据") }
        
        let deviceInfo = AppBackupData.BackupMetadata.DeviceInfo(
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
        
        return AppBackupData.BackupMetadata(
            version: "1.0",
            timestamp: Date(),
            deviceInfo: deviceInfo,
            dataTypes: dataTypes
        )
    }
    
    // MARK: - 收集核心数据
    private func collectCoreData() throws -> AppBackupData.CoreDataBackup {
        let persistence = DataPersistenceManager.shared
        
        // 收集副本数据
        let dungeons = (persistence.loadDungeons() ?? []).map { dungeon in
            AppBackupData.CoreDataBackup.DungeonBackup(
                id: dungeon.id,
                name: dungeon.name,
                characterCounts: convertCharacterDictionary(dungeon.characterCounts),
                characterWeeklyCounts: convertCharacterDictionary(dungeon.characterWeeklyCounts),
                characterTotalCounts: convertCharacterDictionary(dungeon.characterTotalCounts),
                characterTotalDuration: convertCharacterDictionaryTimeInterval(dungeon.characterTotalDuration),
                characterLastCompleted: convertCharacterDictionaryDate(dungeon.characterLastCompleted),
                characterInProgress: convertCharacterDictionaryBool(dungeon.characterInProgress),
                characterStartTime: convertCharacterDictionaryDate(dungeon.characterStartTime),
                categoryId: dungeon.categoryId
            )
        }
        
        // 收集角色数据
        let characters = (persistence.loadCharacters() ?? []).map { character in
            AppBackupData.CoreDataBackup.GameCharacterBackup(
                id: character.id,
                server: character.server,
                name: character.name,
                school: character.school,
                bodyType: character.bodyType
            )
        }
        
        // 收集选中角色
        let selectedCharacter = persistence.loadSelectedCharacter().map { character in
            AppBackupData.CoreDataBackup.GameCharacterBackup(
                id: character.id,
                server: character.server,
                name: character.name,
                school: character.school,
                bodyType: character.bodyType
            )
        }
        
        // 收集完成记录
        let completionRecords = (persistence.loadCompletionRecords() ?? []).map { record in
            AppBackupData.CoreDataBackup.CompletionRecordBackup(
                id: record.id,
                dungeonName: record.dungeonName,
                character: AppBackupData.CoreDataBackup.GameCharacterBackup(
                    id: record.character.id,
                    server: record.character.server,
                    name: record.character.name,
                    school: record.character.school,
                    bodyType: record.character.bodyType
                ),
                completedDate: record.completedDate,
                weekNumber: record.weekNumber,
                year: record.year,
                duration: record.duration
            )
        }
        
        // 收集分类数据
        let categories = loadCategories().map { category in
            AppBackupData.CoreDataBackup.DungeonCategoryBackup(
                id: category.id,
                name: category.name,
                color: category.color,
                icon: category.icon,
                isDefault: category.isDefault,
                order: category.order
            )
        }
        
        return AppBackupData.CoreDataBackup(
            dungeons: dungeons,
            characters: characters,
            selectedCharacter: selectedCharacter,
            completionRecords: completionRecords,
            categories: categories
        )
    }
    
    // MARK: - 收集配置数据
    private func collectConfigData() -> AppBackupData.ConfigDataBackup {
        return AppBackupData.ConfigDataBackup(
            jx3apiToken: userDefaults.string(forKey: "jx3api_token"),
            jx3apiTokenV2: userDefaults.string(forKey: "jx3api_tokenv2"),
            jx3apiTicket: userDefaults.string(forKey: "jx3api_ticket"),
            autoBackupEnabled: userDefaults.bool(forKey: "autoBackupEnabled"),
            backupInterval: userDefaults.integer(forKey: "backupInterval")
        )
    }
    
    // MARK: - 收集任务数据
    private func collectTaskData() throws -> AppBackupData.TaskDataBackup {
        var characterTasks: [AppBackupData.TaskDataBackup.CharacterDailyTasksBackup] = []
        
        // 从UserDefaults中获取任务数据
        if let data = userDefaults.data(forKey: "characterDailyTasks") {
            do {
                let tasks = try JSONDecoder().decode([CharacterDailyTasks].self, from: data)
                
                characterTasks = tasks.map { task in
                    let dailyTasks = task.tasks.map { dailyTask in
                        AppBackupData.TaskDataBackup.CharacterDailyTasksBackup.DailyTaskBackup(
                            id: dailyTask.id,
                            type: dailyTask.type.rawValue,
                            name: dailyTask.name,
                            isCompleted: dailyTask.isCompleted,
                            completedDate: dailyTask.completedDate,
                            refreshDate: dailyTask.refreshDate,
                            isCustom: dailyTask.isCustom
                        )
                    }
                    
                    return AppBackupData.TaskDataBackup.CharacterDailyTasksBackup(
                        characterId: task.characterId,
                        date: task.date,
                        tasks: dailyTasks
                    )
                }
            } catch {
                print("Failed to decode task data: \(error)")
            }
        }
        
        return AppBackupData.TaskDataBackup(
            characterDailyTasks: characterTasks,
            lastDailyTaskRefresh: userDefaults.object(forKey: "lastDailyTaskRefresh") as? Date
        )
    }
    
    // MARK: - 收集缓存数据
    private func collectCacheData() async throws -> AppBackupData.CacheDataBackup {
        // 收集角色卡片缓存
        let characterCards = CharacterCardCacheService.shared.getAllCachedCards().map { cache in
            AppBackupData.CacheDataBackup.CharacterCardCacheBackup(
                id: cache.id,
                zoneName: cache.zoneName,
                serverName: cache.serverName,
                roleName: cache.roleName,
                showHash: cache.showHash,
                localImagePath: cache.localImagePath,
                imageBase64: cache.imageBase64,
                cacheTime: cache.cacheTime,
                lastUpdated: cache.lastUpdated
            )
        }
        
        // 收集成就缓存键
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let achievementCacheKeys = allKeys.filter { $0.hasPrefix("achievement_data_") }
        
        return AppBackupData.CacheDataBackup(
            characterCards: characterCards,
            achievementCacheKeys: achievementCacheKeys
        )
    }
    
    // MARK: - 恢复备份
    func restoreFromBackup(fileURL: URL) async -> RestoreResult {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let backupData = try JSONDecoder().decode(AppBackupData.self, from: jsonData)
            
            var restoredTypes: [String] = []
            
            // 恢复核心数据
            if await restoreCoreData(backupData.coreData) {
                restoredTypes.append("核心数据")
            }
            
            // 恢复配置数据
            if restoreConfigData(backupData.configData) {
                restoredTypes.append("配置数据")
            }
            
            // 恢复任务数据
            if restoreTaskData(backupData.taskData) {
                restoredTypes.append("任务数据")
            }
            
            // 恢复缓存数据
            if await restoreCacheData(backupData.cacheData) {
                restoredTypes.append("缓存数据")
            }
            
            return RestoreResult(
                success: true,
                message: "恢复成功",
                restoredDataTypes: restoredTypes,
                error: nil
            )
            
        } catch {
            return RestoreResult(
                success: false,
                message: "恢复失败: \(error.localizedDescription)",
                restoredDataTypes: [],
                error: error
            )
        }
    }
    
    // MARK: - 恢复核心数据
    private func restoreCoreData(_ coreData: AppBackupData.CoreDataBackup) async -> Bool {
        do {
            let persistence = DataPersistenceManager.shared
            
            // 1. 恢复角色数据
            let restoredCharacters = coreData.characters.map { backupChar in
                GameCharacter(
                    server: backupChar.server,
                    name: backupChar.name,
                    school: backupChar.school,
                    bodyType: backupChar.bodyType
                )
            }
            persistence.saveCharacters(restoredCharacters)
            
            // 2. 恢复选中角色
            if let selectedCharBackup = coreData.selectedCharacter {
                let selectedCharacter = GameCharacter(
                    server: selectedCharBackup.server,
                    name: selectedCharBackup.name,
                    school: selectedCharBackup.school,
                    bodyType: selectedCharBackup.bodyType
                )
                persistence.saveSelectedCharacter(selectedCharacter)
            }
            
            // 3. 恢复完成记录
            let restoredRecords = coreData.completionRecords.map { backupRecord in
                CompletionRecord(
                    dungeonName: backupRecord.dungeonName,
                    character: GameCharacter(
                        server: backupRecord.character.server,
                        name: backupRecord.character.name,
                        school: backupRecord.character.school,
                        bodyType: backupRecord.character.bodyType
                    ),
                    completedDate: backupRecord.completedDate,
                    weekNumber: backupRecord.weekNumber,
                    year: backupRecord.year,
                    duration: backupRecord.duration
                )
            }
            persistence.saveCompletionRecords(restoredRecords)
            
            // 4. 恢复分类数据
            let restoredCategories = coreData.categories.map { backupCategory in
                var category = DungeonCategory(
                    name: backupCategory.name,
                    order: backupCategory.order,
                    isDefault: backupCategory.isDefault,
                    color: backupCategory.color,
                    icon: backupCategory.icon
                )
                return category
            }
            if let encoded = try? JSONEncoder().encode(restoredCategories) {
                userDefaults.set(encoded, forKey: "SavedCategories")
            }
            
            // 5. 恢复副本数据 - 这个比较复杂，需要重建字典
            let restoredDungeons = coreData.dungeons.map { backupDungeon in
                // 重建角色字典
                let characterCounts = reconstructCharacterDictionary(backupDungeon.characterCounts, from: restoredCharacters)
                let characterWeeklyCounts = reconstructCharacterDictionary(backupDungeon.characterWeeklyCounts, from: restoredCharacters)
                let characterTotalCounts = reconstructCharacterDictionary(backupDungeon.characterTotalCounts, from: restoredCharacters)
                let characterTotalDuration = reconstructCharacterDictionaryTimeInterval(backupDungeon.characterTotalDuration, from: restoredCharacters)
                let characterLastCompleted = reconstructCharacterDictionaryDate(backupDungeon.characterLastCompleted, from: restoredCharacters)
                let characterInProgress = reconstructCharacterDictionaryBool(backupDungeon.characterInProgress, from: restoredCharacters)
                let characterStartTime = reconstructCharacterDictionaryDate(backupDungeon.characterStartTime, from: restoredCharacters)
                
                var dungeon = Dungeon(name: backupDungeon.name)
                dungeon.categoryId = backupDungeon.categoryId
                dungeon.customCategory = nil
                dungeon.characterCounts = characterCounts
                dungeon.characterWeeklyCounts = characterWeeklyCounts
                dungeon.characterTotalCounts = characterTotalCounts
                dungeon.characterTotalDuration = characterTotalDuration
                dungeon.characterLastCompleted = characterLastCompleted
                dungeon.characterInProgress = characterInProgress
                dungeon.characterStartTime = characterStartTime
                
                return dungeon
            }
            persistence.saveDungeons(restoredDungeons)
            
            return true
        } catch {
            print("Failed to restore core data: \(error)")
            return false
        }
    }
    
    // MARK: - 恢复配置数据
    private func restoreConfigData(_ configData: AppBackupData.ConfigDataBackup) -> Bool {
        if let token = configData.jx3apiToken {
            userDefaults.set(token, forKey: "jx3api_token")
        }
        if let tokenV2 = configData.jx3apiTokenV2 {
            userDefaults.set(tokenV2, forKey: "jx3api_tokenv2")
        }
        if let ticket = configData.jx3apiTicket {
            userDefaults.set(ticket, forKey: "jx3api_ticket")
        }
        
        userDefaults.set(configData.autoBackupEnabled, forKey: "autoBackupEnabled")
        userDefaults.set(configData.backupInterval, forKey: "backupInterval")
        
        return true
    }
    
    // MARK: - 恢复任务数据
    private func restoreTaskData(_ taskData: AppBackupData.TaskDataBackup) -> Bool {
        do {
            // 将备份的任务数据转换为原始格式
            let restoredTasks = taskData.characterDailyTasks.map { backupTask in
                let dailyTasks = backupTask.tasks.map { backupDailyTask in
                    var task = DailyTask(
                        type: DailyTaskType(rawValue: backupDailyTask.type) ?? .custom,
                        name: backupDailyTask.name,
                        refreshDate: backupDailyTask.refreshDate,
                        isCustom: backupDailyTask.isCustom
                    )
                    task.isCompleted = backupDailyTask.isCompleted
                    task.completedDate = backupDailyTask.completedDate
                    return task
                }
                
                return CharacterDailyTasks(
                    characterId: backupTask.characterId,
                    date: backupTask.date,
                    tasks: dailyTasks
                )
            }
            
            // 保存恢复的任务数据
            let taskDataToRestore = try JSONEncoder().encode(restoredTasks)
            userDefaults.set(taskDataToRestore, forKey: "characterDailyTasks")
            
            // 恢复刷新时间
            if let refreshTime = taskData.lastDailyTaskRefresh {
                userDefaults.set(refreshTime, forKey: "lastDailyTaskRefresh")
            }
            
            return true
        } catch {
            print("Failed to restore task data: \(error)")
            return false
        }
    }
    
    // MARK: - 恢复缓存数据
    private func restoreCacheData(_ cacheData: AppBackupData.CacheDataBackup) async -> Bool {
        do {
            // 恢复角色卡片缓存
            let restoredCards = cacheData.characterCards.map { backupCard in
                CharacterCardCache(
                    id: backupCard.id,
                    zoneName: backupCard.zoneName,
                    serverName: backupCard.serverName,
                    roleName: backupCard.roleName,
                    showHash: backupCard.showHash,
                    localImagePath: backupCard.localImagePath,
                    imageBase64: backupCard.imageBase64,
                    cacheTime: backupCard.cacheTime,
                    lastUpdated: backupCard.lastUpdated
                )
            }
            
            let cardCacheData = try JSONEncoder().encode(restoredCards)
            userDefaults.set(cardCacheData, forKey: "character_cards_cache_data")
            
            // 恢复成就缓存键信息（仅作为记录，实际数据需要重新获取）
            let achievementKeysData = try JSONEncoder().encode(cacheData.achievementCacheKeys)
            userDefaults.set(achievementKeysData, forKey: "backup_achievement_keys")
            
            return true
        } catch {
            print("Failed to restore cache data: \(error)")
            return false
        }
    }
    
    // MARK: - 获取备份历史
    func getBackupHistory() -> [BackupHistoryItem] {
        guard let data = userDefaults.data(forKey: "backup_history"),
              let history = try? JSONDecoder().decode([BackupHistoryItem].self, from: data) else {
            return []
        }
        return history.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - 保存备份历史
    private func saveBackupHistory(fileURL: URL, backupData: AppBackupData) {
        var history = getBackupHistory()
        
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        
        let historyItem = BackupHistoryItem(
            timestamp: Date(),
            fileSize: Int64(fileSize),
            dataTypes: backupData.backupInfo.dataTypes,
            filePath: fileURL.path,
            isAutoBackup: false
        )
        
        history.append(historyItem)
        
        // 保留最近50个备份记录
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: "backup_history")
        }
    }
    
    // MARK: - 工具方法
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
    
    private func convertCharacterDictionary(_ dict: [GameCharacter: Int]) -> [String: Int] {
        return dict.reduce(into: [:]) { result, element in
            result["\(element.key.server)_\(element.key.name)"] = element.value
        }
    }
    
    private func convertCharacterDictionaryTimeInterval(_ dict: [GameCharacter: TimeInterval]) -> [String: TimeInterval] {
        return dict.reduce(into: [:]) { result, element in
            result["\(element.key.server)_\(element.key.name)"] = element.value
        }
    }
    
    private func convertCharacterDictionaryDate(_ dict: [GameCharacter: Date]) -> [String: Date] {
        return dict.reduce(into: [:]) { result, element in
            result["\(element.key.server)_\(element.key.name)"] = element.value
        }
    }
    
    private func convertCharacterDictionaryBool(_ dict: [GameCharacter: Bool]) -> [String: Bool] {
        return dict.reduce(into: [:]) { result, element in
            result["\(element.key.server)_\(element.key.name)"] = element.value
        }
    }
    
    private func loadCategories() -> [DungeonCategory] {
        guard let data = userDefaults.data(forKey: "SavedCategories"),
              let categories = try? JSONDecoder().decode([DungeonCategory].self, from: data) else {
            return []
        }
        return categories
    }
    
    // MARK: - 字典重建辅助方法
    private func reconstructCharacterDictionary(_ stringDict: [String: Int], from characters: [GameCharacter]) -> [GameCharacter: Int] {
        var result: [GameCharacter: Int] = [:]
        for (key, value) in stringDict {
            let components = key.components(separatedBy: "_")
            if components.count >= 2 {
                let server = components[0]
                let name = components[1]
                if let character = characters.first(where: { $0.server == server && $0.name == name }) {
                    result[character] = value
                }
            }
        }
        return result
    }
    
    private func reconstructCharacterDictionaryTimeInterval(_ stringDict: [String: TimeInterval], from characters: [GameCharacter]) -> [GameCharacter: TimeInterval] {
        var result: [GameCharacter: TimeInterval] = [:]
        for (key, value) in stringDict {
            let components = key.components(separatedBy: "_")
            if components.count >= 2 {
                let server = components[0]
                let name = components[1]
                if let character = characters.first(where: { $0.server == server && $0.name == name }) {
                    result[character] = value
                }
            }
        }
        return result
    }
    
    private func reconstructCharacterDictionaryDate(_ stringDict: [String: Date], from characters: [GameCharacter]) -> [GameCharacter: Date] {
        var result: [GameCharacter: Date] = [:]
        for (key, value) in stringDict {
            let components = key.components(separatedBy: "_")
            if components.count >= 2 {
                let server = components[0]
                let name = components[1]
                if let character = characters.first(where: { $0.server == server && $0.name == name }) {
                    result[character] = value
                }
            }
        }
        return result
    }
    
    private func reconstructCharacterDictionaryBool(_ stringDict: [String: Bool], from characters: [GameCharacter]) -> [GameCharacter: Bool] {
        var result: [GameCharacter: Bool] = [:]
        for (key, value) in stringDict {
            let components = key.components(separatedBy: "_")
            if components.count >= 2 {
                let server = components[0]
                let name = components[1]
                if let character = characters.first(where: { $0.server == server && $0.name == name }) {
                    result[character] = value
                }
            }
        }
        return result
    }
}
