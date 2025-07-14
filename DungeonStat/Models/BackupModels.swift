//
//  BackupModels.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/9.
//

import Foundation

// MARK: - 完整备份数据模型
struct AppBackupData: Codable {
    let backupInfo: BackupMetadata
    let coreData: CoreDataBackup
    let configData: ConfigDataBackup
    let taskData: TaskDataBackup
    let cacheData: CacheDataBackup
    
    struct BackupMetadata: Codable {
        let version: String
        let timestamp: Date
        let deviceInfo: DeviceInfo
        let dataTypes: [String]
        
        struct DeviceInfo: Codable {
            let deviceModel: String
            let systemVersion: String
            let appVersion: String
        }
    }
    
    struct CoreDataBackup: Codable {
        let dungeons: [DungeonBackup]
        let characters: [GameCharacterBackup]
        let selectedCharacter: GameCharacterBackup?
        let completionRecords: [CompletionRecordBackup]
        let categories: [DungeonCategoryBackup]
        
        struct DungeonBackup: Codable {
            let id: UUID
            let name: String
            let characterCounts: [String: Int] // 使用字符串键避免复杂序列化
            let characterWeeklyCounts: [String: Int]
            let characterTotalCounts: [String: Int]
            let characterTotalDuration: [String: TimeInterval]
            let characterLastCompleted: [String: Date]
            let characterInProgress: [String: Bool]
            let characterStartTime: [String: Date]
            let categoryId: UUID?
        }
        
        struct GameCharacterBackup: Codable {
            let id: UUID
            let server: String
            let name: String
            let school: String
            let bodyType: String
        }
        
        struct CompletionRecordBackup: Codable {
            let id: UUID
            let dungeonName: String
            let character: GameCharacterBackup
            let completedDate: Date
            let weekNumber: Int
            let year: Int
            let duration: TimeInterval
        }
        
        struct DungeonCategoryBackup: Codable {
            let id: UUID
            let name: String
            let color: String
            let icon: String
            let isDefault: Bool
            let order: Int
        }
    }
    
    struct ConfigDataBackup: Codable {
        let jx3apiToken: String?
        let jx3apiTokenV2: String?
        let jx3apiTicket: String?
        let autoBackupEnabled: Bool
        let backupInterval: Int
    }
    
    struct TaskDataBackup: Codable {
        let characterDailyTasks: [CharacterDailyTasksBackup]
        let lastDailyTaskRefresh: Date?
        
        struct CharacterDailyTasksBackup: Codable {
            let characterId: UUID
            let date: String
            let tasks: [DailyTaskBackup]
            
            struct DailyTaskBackup: Codable {
                let id: UUID
                let type: String
                let name: String
                let isCompleted: Bool
                let completedDate: Date?
                let refreshDate: Date
                let isCustom: Bool
            }
        }
    }
    
    struct CacheDataBackup: Codable {
        let characterCards: [CharacterCardCacheBackup]
        let achievementCacheKeys: [String] // 只保存缓存键，不保存具体数据
        
        struct CharacterCardCacheBackup: Codable {
            let id: UUID
            let zoneName: String
            let serverName: String
            let roleName: String
            let showHash: String
            let localImagePath: String?
            let imageBase64: String?
            let cacheTime: Int
            let lastUpdated: Date
        }
    }
}

// MARK: - 备份操作结果
struct BackupResult {
    let success: Bool
    let message: String
    let backupData: AppBackupData?
    let fileURL: URL?
    let error: Error?
}

struct RestoreResult {
    let success: Bool
    let message: String
    let restoredDataTypes: [String]
    let error: Error?
}

// MARK: - 备份配置
struct BackupConfiguration: Codable {
    var includeCoreData: Bool
    var includeConfigData: Bool
    var includeTaskData: Bool
    var includeCacheData: Bool
    var compressionEnabled: Bool
    var encryptionEnabled: Bool
    
    static let `default` = BackupConfiguration(
        includeCoreData: true,
        includeConfigData: true,
        includeTaskData: true,
        includeCacheData: false,
        compressionEnabled: false,
        encryptionEnabled: false
    )
}

// MARK: - 备份历史记录
struct BackupHistoryItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let fileSize: Int64
    let dataTypes: [String]
    let filePath: String
    let isAutoBackup: Bool
    
    init(timestamp: Date, fileSize: Int64, dataTypes: [String], filePath: String, isAutoBackup: Bool = false) {
        self.id = UUID()
        self.timestamp = timestamp
        self.fileSize = fileSize
        self.dataTypes = dataTypes
        self.filePath = filePath
        self.isAutoBackup = isAutoBackup
    }
}