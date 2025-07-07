//
//  AchievementCacheService.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import Foundation

class AchievementCacheService {
    static let shared = AchievementCacheService()
    private init() {}
    
    private let cacheKeyPrefix = "achievement_data_"
    
    // 生成缓存键
    private func cacheKey(for server: String, name: String) -> String {
        return "\(cacheKeyPrefix)\(server)_\(name)"
    }
    
    // 保存缓存
    func saveCache(data: AchievementData, for server: String, name: String) {
        let key = cacheKey(for: server, name: name)
        let cacheItem = CacheItem(data: data, timestamp: Date())
        
        if let encoded = try? JSONEncoder().encode(cacheItem) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // 读取缓存
    func loadCache(for server: String, name: String) -> AchievementData? {
        let key = cacheKey(for: server, name: name)
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let cacheItem = try? JSONDecoder().decode(CacheItem.self, from: data) else {
            return nil
        }
        
        return cacheItem.data
    }
    
    // 检查缓存是否存在
    func hasCachedData(for server: String, name: String) -> Bool {
        let key = cacheKey(for: server, name: name)
        return UserDefaults.standard.data(forKey: key) != nil
    }
    
    // 清除特定角色的缓存
    func clearCache(for server: String, name: String) {
        let key = cacheKey(for: server, name: name)
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // 清除所有缓存
    func clearAllCache() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix(cacheKeyPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    // 获取缓存时间戳
    func getCacheTimestamp(for server: String, name: String) -> Date? {
        let key = cacheKey(for: server, name: name)
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let cacheItem = try? JSONDecoder().decode(CacheItem.self, from: data) else {
            return nil
        }
        
        return cacheItem.timestamp
    }
}

// MARK: - Cache Models
private struct CacheItem: Codable {
    let data: AchievementData
    let timestamp: Date
}