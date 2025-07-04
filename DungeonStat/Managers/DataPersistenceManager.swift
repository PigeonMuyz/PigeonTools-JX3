//
//  DataPersistenceManager.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 备份信息数据模型
struct BackupInfo: Codable, Identifiable {
    let id = UUID()
    let timestamp: Int
    let date: Date
    let keys: [String]
    let suffix: String
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "备份 - \(formatter.string(from: date))"
    }
}

// MARK: - 数据持久化管理器
class DataPersistenceManager {
    static let shared = DataPersistenceManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - 存储键
    private struct Keys {
        static let dungeons = "SavedDungeons"
        static let characters = "SavedCharacters"
        static let selectedCharacter = "SelectedCharacter"
        static let completionRecords = "CompletionRecords"
    }
    
    // MARK: - 保存数据
    func saveDungeons(_ dungeons: [Dungeon]) {
        if let encoded = try? JSONEncoder().encode(dungeons) {
            userDefaults.set(encoded, forKey: Keys.dungeons)
        }
    }
    
    func saveCharacters(_ characters: [GameCharacter]) {
        if let encoded = try? JSONEncoder().encode(characters) {
            userDefaults.set(encoded, forKey: Keys.characters)
        }
    }
    
    func saveSelectedCharacter(_ character: GameCharacter?) {
        if let character = character,
           let encoded = try? JSONEncoder().encode(character) {
            userDefaults.set(encoded, forKey: Keys.selectedCharacter)
        }
    }
    
    func saveCompletionRecords(_ records: [CompletionRecord]) {
        if let encoded = try? JSONEncoder().encode(records) {
            userDefaults.set(encoded, forKey: Keys.completionRecords)
        }
    }
    
    // MARK: - 加载数据
    func loadDungeons() -> [Dungeon]? {
        guard let data = userDefaults.data(forKey: Keys.dungeons) else {
            print("DataPersistenceManager: 未找到副本数据")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode([Dungeon].self, from: data)
            print("DataPersistenceManager: 成功加载 \(decoded.count) 个副本")
            return decoded
        } catch {
            print("DataPersistenceManager: 副本数据解析失败 - \(error)")
            return nil
        }
    }
    
    func loadCharacters() -> [GameCharacter]? {
        guard let data = userDefaults.data(forKey: Keys.characters) else {
            print("DataPersistenceManager: 未找到角色数据")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode([GameCharacter].self, from: data)
            print("DataPersistenceManager: 成功加载 \(decoded.count) 个角色")
            return decoded
        } catch {
            print("DataPersistenceManager: 角色数据解析失败 - \(error)")
            return nil
        }
    }
    
    func loadSelectedCharacter() -> GameCharacter? {
        guard let data = userDefaults.data(forKey: Keys.selectedCharacter),
              let decoded = try? JSONDecoder().decode(GameCharacter.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func loadCompletionRecords() -> [CompletionRecord]? {
        guard let data = userDefaults.data(forKey: Keys.completionRecords) else {
            print("DataPersistenceManager: 未找到完成记录数据")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode([CompletionRecord].self, from: data)
            print("DataPersistenceManager: 成功加载 \(decoded.count) 条完成记录")
            return decoded
        } catch {
            print("DataPersistenceManager: 完成记录解析失败 - \(error)")
            // 尝试加载旧格式数据
            print("DataPersistenceManager: 尝试加载旧格式数据...")
            return nil
        }
    }
    
    // MARK: - 数据备份和恢复
    private let maxBackupCount = 10 // 最多保留10个备份
    
    func createDataBackup() -> String? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupSuffix = "_backup_\(timestamp)"
        
        // 备份所有数据
        let keysToBackup = [Keys.dungeons, Keys.characters, Keys.selectedCharacter, Keys.completionRecords]
        var backedUpKeys: [String] = []
        
        for key in keysToBackup {
            if let data = userDefaults.data(forKey: key) {
                let backupKey = key + backupSuffix
                userDefaults.set(data, forKey: backupKey)
                backedUpKeys.append(backupKey)
                print("DataPersistenceManager: 已备份 \(key) -> \(backupKey)")
            }
        }
        
        if !backedUpKeys.isEmpty {
            // 保存备份信息
            let backupInfo = BackupInfo(
                timestamp: timestamp,
                date: Date(),
                keys: backedUpKeys,
                suffix: backupSuffix
            )
            
            if let encoded = try? JSONEncoder().encode(backupInfo) {
                userDefaults.set(encoded, forKey: "BackupInfo_\(timestamp)")
            }
            
            // 更新最后备份时间
            userDefaults.set(Date(), forKey: "LastBackupDate")
            
            // 清理旧备份
            cleanupOldBackups()
            
            print("DataPersistenceManager: 数据备份完成，备份ID: \(backupSuffix)")
            return backupSuffix
        }
        
        print("DataPersistenceManager: 没有数据需要备份")
        return nil
    }
    
    func restoreFromBackup(_ backupSuffix: String) -> Bool {
        print("DataPersistenceManager: 开始从备份恢复数据: \(backupSuffix)")
        
        let keysToRestore = [Keys.dungeons, Keys.characters, Keys.selectedCharacter, Keys.completionRecords]
        var restoredCount = 0
        
        // 首先备份当前数据（以防恢复失败）
        let emergencyBackup = "_emergency_\(Int(Date().timeIntervalSince1970))"
        for key in keysToRestore {
            if let data = userDefaults.data(forKey: key) {
                userDefaults.set(data, forKey: key + emergencyBackup)
            }
        }
        
        // 从备份恢复数据
        for key in keysToRestore {
            let backupKey = key + backupSuffix
            if let backupData = userDefaults.data(forKey: backupKey) {
                userDefaults.set(backupData, forKey: key)
                restoredCount += 1
                print("DataPersistenceManager: 已恢复 \(key) <- \(backupKey)")
            } else {
                print("DataPersistenceManager: 未找到备份数据 \(backupKey)")
            }
        }
        
        if restoredCount > 0 {
            userDefaults.set(Date(), forKey: "LastRestoreDate")
            print("DataPersistenceManager: 数据恢复完成，恢复了 \(restoredCount) 项")
            return true
        } else {
            print("DataPersistenceManager: 数据恢复失败，没有找到有效的备份数据")
            return false
        }
    }
    
    func getAvailableBackups() -> [BackupInfo] {
        var backups: [BackupInfo] = []
        
        // 查找所有备份信息
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let backupInfoKeys = allKeys.filter { $0.hasPrefix("BackupInfo_") }
        
        for key in backupInfoKeys {
            if let data = userDefaults.data(forKey: key),
               let backupInfo = try? JSONDecoder().decode(BackupInfo.self, from: data) {
                backups.append(backupInfo)
            }
        }
        
        // 按时间排序，最新的在前
        return backups.sorted { $0.timestamp > $1.timestamp }
    }
    
    func deleteBackup(_ backupSuffix: String) -> Bool {
        let keysToDelete = [Keys.dungeons, Keys.characters, Keys.selectedCharacter, Keys.completionRecords]
        var deletedCount = 0
        
        for key in keysToDelete {
            let backupKey = key + backupSuffix
            if userDefaults.data(forKey: backupKey) != nil {
                userDefaults.removeObject(forKey: backupKey)
                deletedCount += 1
            }
        }
        
        // 删除备份信息
        let timestamp = backupSuffix.replacingOccurrences(of: "_backup_", with: "")
        userDefaults.removeObject(forKey: "BackupInfo_\(timestamp)")
        
        print("DataPersistenceManager: 已删除备份 \(backupSuffix)，删除了 \(deletedCount) 项")
        return deletedCount > 0
    }
    
    // MARK: - 清理旧数据
    func removeOldKey(_ key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    private func cleanupOldBackups() {
        let backups = getAvailableBackups()
        
        // 如果备份数量超过限制，删除最旧的备份
        if backups.count > maxBackupCount {
            let backupsToDelete = backups.suffix(backups.count - maxBackupCount)
            
            for backup in backupsToDelete {
                // 删除备份数据
                for key in [Keys.dungeons, Keys.characters, Keys.selectedCharacter, Keys.completionRecords] {
                    let backupKey = key + backup.suffix
                    userDefaults.removeObject(forKey: backupKey)
                }
                
                // 删除备份信息
                let timestamp = backup.suffix.replacingOccurrences(of: "_backup_", with: "")
                userDefaults.removeObject(forKey: "BackupInfo_\(timestamp)")
                
                print("DataPersistenceManager: 已清理旧备份 \(backup.suffix)")
            }
            
            print("DataPersistenceManager: 清理完成，保留最新的 \(maxBackupCount) 个备份")
        }
    }
}
