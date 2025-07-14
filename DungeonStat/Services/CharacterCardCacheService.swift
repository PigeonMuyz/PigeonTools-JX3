//
//  CharacterCardCacheService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/8.
//

import Foundation
import UIKit
import Combine

class CharacterCardCacheService: ObservableObject {
    static let shared = CharacterCardCacheService()
    private init() {
        loadCacheData()
    }
    
    @Published private var cacheData: [CharacterCardCache] = []
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "character_cards_cache_data"
    
    func getCachedCard(server: String, name: String) -> CharacterCardCache? {
        return cacheData.first { $0.serverName == server && $0.roleName == name }
    }
    
    func getCachedImage(for cardCache: CharacterCardCache) -> UIImage? {
        // 优先使用Base64数据
        if let base64 = cardCache.imageBase64 {
            return ImageCacheService.shared.convertBase64ToImage(base64)
        }
        
        // 向后兼容：如果没有Base64数据，尝试加载本地文件
        if let localPath = cardCache.localImagePath {
            return ImageCacheService.shared.loadImage(from: localPath)
        }
        
        return nil
    }
    
    func getAllCachedCards() -> [CharacterCardCache] {
        return cacheData.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func getHistoricalCards(server: String, name: String) -> [CharacterCardCache] {
        return cacheData.filter { $0.serverName == server && $0.roleName == name }
                        .sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func fetchAndCacheCard(server: String, name: String, forceRefresh: Bool = false) async throws -> CharacterCardCache {
        if !forceRefresh, let existingCache = getCachedCard(server: server, name: name) {
            return existingCache
        }
        
        let cardData = try await JX3APIService.shared.fetchCharacterCard(server: server, name: name)
        
        if let existingCache = getCachedCard(server: server, name: name),
           existingCache.showHash == cardData.showHash,
           !forceRefresh {
            return existingCache
        }
        
        let imageBase64 = try await ImageCacheService.shared.downloadAndConvertToBase64(
            from: cardData.showAvatar
        )
        
        let newCache = CharacterCardCache(
            zoneName: cardData.zoneName,
            serverName: cardData.serverName,
            roleName: cardData.roleName,
            showHash: cardData.showHash,
            imageBase64: imageBase64,
            cacheTime: cardData.cacheTime,
            lastUpdated: Date()
        )
        
        await MainActor.run {
            if let existingIndex = cacheData.firstIndex(where: { 
                $0.serverName == server && $0.roleName == name && $0.showHash == cardData.showHash 
            }) {
                cacheData[existingIndex] = newCache
            } else {
                cacheData.append(newCache)
            }
            saveCacheData()
        }
        
        return newCache
    }
    
    func deleteCachedCard(_ cardCache: CharacterCardCache) {
        // 如果有本地文件路径，删除文件（向后兼容）
        if let localPath = cardCache.localImagePath {
            ImageCacheService.shared.deleteImage(filename: URL(fileURLWithPath: localPath).lastPathComponent)
        }
        
        if let index = cacheData.firstIndex(where: { $0.id == cardCache.id }) {
            cacheData.remove(at: index)
            saveCacheData()
        }
    }
    
    func cleanupOldCaches(keepLatestPerCharacter: Int = 3) {
        let groupedByCharacter = Dictionary(grouping: cacheData) { "\($0.serverName)_\($0.roleName)" }
        
        var toDelete: [CharacterCardCache] = []
        
        for (_, cards) in groupedByCharacter {
            let sortedCards = cards.sorted { $0.lastUpdated > $1.lastUpdated }
            if sortedCards.count > keepLatestPerCharacter {
                toDelete.append(contentsOf: Array(sortedCards.dropFirst(keepLatestPerCharacter)))
            }
        }
        
        for card in toDelete {
            deleteCachedCard(card)
        }
    }
    
    private func generateFilename(server: String, name: String, hash: String) -> String {
        let sanitizedServer = server.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
        let sanitizedName = name.replacingOccurrences(of: "[^a-zA-Z0-9@]", with: "_", options: .regularExpression)
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(sanitizedServer)_\(sanitizedName)_\(hash)_\(timestamp).png"
    }
    
    private func loadCacheData() {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            // 尝试从旧的JSON文件迁移数据
            migrateFromJSONFile()
            return
        }
        
        do {
            cacheData = try JSONDecoder().decode([CharacterCardCache].self, from: data)
            print("Successfully loaded \(cacheData.count) cache items from UserDefaults")
            
            // 检查是否需要将本地文件迁移为Base64
            migrateLocalImagesToBase64()
        } catch {
            print("Failed to load cache data from UserDefaults: \(error)")
            cacheData = []
        }
    }
    
    private func saveCacheData() {
        do {
            let data = try JSONEncoder().encode(cacheData)
            userDefaults.set(data, forKey: cacheKey)
            print("Successfully saved \(cacheData.count) cache items to UserDefaults")
        } catch {
            print("Failed to save cache data to UserDefaults: \(error)")
        }
    }
    
    private func migrateFromJSONFile() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonFile = documentsPath.appendingPathComponent("character_cards_cache.json")
        
        // 也检查旧的Cache目录
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let oldJsonFile = cachesPath.appendingPathComponent("character_cards_cache.json")
        
        let fileToCheck = FileManager.default.fileExists(atPath: jsonFile.path) ? jsonFile : oldJsonFile
        
        guard FileManager.default.fileExists(atPath: fileToCheck.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileToCheck)
            cacheData = try JSONDecoder().decode([CharacterCardCache].self, from: data)
            
            // 保存到UserDefaults
            saveCacheData()
            
            // 删除旧文件
            try? FileManager.default.removeItem(at: fileToCheck)
            
            print("Successfully migrated cache data from JSON file to UserDefaults")
        } catch {
            print("Failed to migrate cache data from JSON file: \(error)")
        }
    }
    
    private func migrateLocalImagesToBase64() {
        var hasChanges = false
        
        for i in 0..<cacheData.count {
            let cache = cacheData[i]
            
            // 如果已经有Base64数据，跳过
            if cache.imageBase64 != nil {
                continue
            }
            
            // 如果有本地文件路径，尝试转换为Base64
            if let localPath = cache.localImagePath,
               let image = ImageCacheService.shared.loadImage(from: localPath) {
                
                let base64String = ImageCacheService.shared.convertImageToBase64(image)
                
                // 创建新的缓存对象，包含Base64数据
                let newCache = CharacterCardCache(
                    id: cache.id,
                    zoneName: cache.zoneName,
                    serverName: cache.serverName,
                    roleName: cache.roleName,
                    showHash: cache.showHash,
                    localImagePath: cache.localImagePath,
                    imageBase64: base64String,
                    cacheTime: cache.cacheTime,
                    lastUpdated: cache.lastUpdated
                )
                
                cacheData[i] = newCache
                hasChanges = true
                
                // 删除本地文件，因为已经转换为Base64
                ImageCacheService.shared.deleteImage(filename: URL(fileURLWithPath: localPath).lastPathComponent)
            }
        }
        
        if hasChanges {
            saveCacheData()
            print("Successfully migrated \(cacheData.count) images from local files to Base64")
        }
    }
}
