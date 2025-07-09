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
    
    private let cacheFileName = "character_cards_cache.json"
    private let fileManager = FileManager.default
    
    private var cacheFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(cacheFileName)
    }
    
    func getCachedCard(server: String, name: String) -> CharacterCardCache? {
        return cacheData.first { $0.serverName == server && $0.roleName == name }
    }
    
    func getCachedImage(for cardCache: CharacterCardCache) -> UIImage? {
        return ImageCacheService.shared.loadImage(from: cardCache.localImagePath)
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
        
        let filename = generateFilename(server: server, name: name, hash: cardData.showHash)
        let imagePath = try await ImageCacheService.shared.downloadAndSaveImage(
            from: cardData.showAvatar,
            filename: filename
        )
        
        let newCache = CharacterCardCache(
            zoneName: cardData.zoneName,
            serverName: cardData.serverName,
            roleName: cardData.roleName,
            showHash: cardData.showHash,
            localImagePath: imagePath,
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
        ImageCacheService.shared.deleteImage(filename: URL(fileURLWithPath: cardCache.localImagePath).lastPathComponent)
        
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
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            cacheData = try JSONDecoder().decode([CharacterCardCache].self, from: data)
        } catch {
            print("Failed to load cache data: \(error)")
            cacheData = []
        }
    }
    
    private func saveCacheData() {
        do {
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: cacheFileURL)
        } catch {
            print("Failed to save cache data: \(error)")
        }
    }
}
