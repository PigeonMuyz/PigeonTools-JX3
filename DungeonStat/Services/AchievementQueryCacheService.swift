//
//  AchievementQueryCacheService.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/28.
//

import Foundation
import Combine
// MARK: - 查询缓存数据模型
struct AchievementQueryCache: Identifiable, Codable {
    let id = UUID()
    let serverName: String
    let roleName: String
    let queryTime: Date
    let dungeonData: [DungeonAchievementSummary]
    
    var displayName: String {
        return "\(serverName) - \(roleName)"
    }
}

struct DungeonAchievementSummary: Codable, Identifiable {
    let id = UUID()
    let dungeonName: String
    let difficulty: String
    let completionRate: Double
    let totalAchievements: Int
    let completedAchievements: Int
    let potential: Int
    let priority: String
}

// MARK: - 缓存服务
class AchievementQueryCacheService: ObservableObject {
    static let shared = AchievementQueryCacheService()
    private init() {
        loadCacheData()
    }
    
    @Published private var cacheData: [AchievementQueryCache] = []
    
    private let cacheFileName = "achievement_query_cache.json"
    private let fileManager = FileManager.default
    
    private var cacheFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(cacheFileName)
    }
    
    func getAllCachedQueries() -> [AchievementQueryCache] {
        return cacheData.sorted { $0.queryTime > $1.queryTime }
    }
    
    func getCachedQuery(server: String, name: String) -> AchievementQueryCache? {
        return cacheData.first { 
            $0.serverName == server && $0.roleName == name 
        }
    }
    
    func saveQueryResult(server: String, roleName: String, dungeonData: [DungeonAchievementSummary]) {
        // 删除已存在的缓存
        cacheData.removeAll { $0.serverName == server && $0.roleName == roleName }
        
        // 添加新的缓存
        let newCache = AchievementQueryCache(
            serverName: server,
            roleName: roleName,
            queryTime: Date(),
            dungeonData: dungeonData
        )
        
        cacheData.append(newCache)
        saveCacheData()
    }
    
    func deleteCachedQuery(_ queryCache: AchievementQueryCache) {
        if let index = cacheData.firstIndex(where: { $0.id == queryCache.id }) {
            cacheData.remove(at: index)
            saveCacheData()
        }
    }
    
    func clearAllCachedQueries() {
        cacheData.removeAll()
        saveCacheData()
    }
    
    private func loadCacheData() {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            cacheData = try JSONDecoder().decode([AchievementQueryCache].self, from: data)
        } catch {
            print("Failed to load achievement query cache: \(error)")
            cacheData = []
        }
    }
    
    private func saveCacheData() {
        do {
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: cacheFileURL)
        } catch {
            print("Failed to save achievement query cache: \(error)")
        }
    }
}
