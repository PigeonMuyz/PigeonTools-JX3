//
//  DungeonAchievementDetailService.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/8.
//

import Foundation
import Combine

class DungeonAchievementDetailService: ObservableObject {
    static let shared = DungeonAchievementDetailService()
    private init() {
        loadCacheData()
    }
    
    @Published private var cacheData: [DungeonAchievementQueryCache] = []
    @Published var isQuerying = false
    
    private let cacheFileName = "dungeon_achievement_queries.json"
    private let fileManager = FileManager.default
    
    private var cacheFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(cacheFileName)
    }
    
    func getCachedQuery(server: String, name: String, dungeonName: String) -> DungeonAchievementQueryCache? {
        return cacheData.first { 
            $0.serverName == server && 
            $0.roleName == name && 
            $0.dungeonName == dungeonName 
        }
    }
    
    func getAllCachedQueries() -> [DungeonAchievementQueryCache] {
        return cacheData.sorted { $0.queryTime > $1.queryTime }
    }
    
    func getQueriesForCharacter(server: String, name: String) -> [DungeonAchievementQueryCache] {
        return cacheData.filter { $0.serverName == server && $0.roleName == name }
                        .sorted { $0.queryTime > $1.queryTime }
    }
    
    func queryDungeonAchievements(server: String, role: String, dungeonName: String) async throws -> DungeonAchievementQueryCache {
        await MainActor.run {
            isQuerying = true
        }
        
        defer {
            Task {
                await MainActor.run {
                    isQuerying = false
                }
            }
        }
        
        do {
            let detailData = try await JX3APIService.shared.fetchCharacterAchievementDetail(
                server: server,
                role: role,
                name: dungeonName
            )
            print("查询成功: \(dungeonName), 成就数量: \(detailData.data.count)")
        } catch {
            print("查询失败: \(error)")
            throw error
        }
        
        let detailData = try await JX3APIService.shared.fetchCharacterAchievementDetail(
            server: server,
            role: role,
            name: dungeonName
        )
        
        // 统计未完成的成就
        let unfinishedAchievements = detailData.data.filter { !$0.isFinished }
        let unfinishedCount = unfinishedAchievements.count
        let totalCount = detailData.data.count
        
        // 创建查询缓存
        let queryCache = DungeonAchievementQueryCache(
            serverName: detailData.serverName,
            roleName: detailData.roleName,
            dungeonName: dungeonName,
            achievements: detailData.data,
            queryTime: Date(),
            unfinishedCount: unfinishedCount,
            totalCount: totalCount
        )
        
        // 自动标记已完成的成就
        for achievement in detailData.data {
            if achievement.isFinished {
                AchievementCompletionService.shared.markAchievementAsCompleted(achievement.id)
            }
        }
        
        await MainActor.run {
            // 更新或添加缓存
            if let existingIndex = cacheData.firstIndex(where: { 
                $0.serverName == server && 
                $0.roleName == role && 
                $0.dungeonName == dungeonName 
            }) {
                cacheData[existingIndex] = queryCache
            } else {
                cacheData.append(queryCache)
            }
            
            saveCacheData()
        }
        
        return queryCache
    }
    
    func deleteCachedQuery(_ queryCache: DungeonAchievementQueryCache) {
        if let index = cacheData.firstIndex(where: { $0.id == queryCache.id }) {
            cacheData.remove(at: index)
            saveCacheData()
        }
    }
    
    func clearAllCachedQueries() {
        cacheData.removeAll()
        saveCacheData()
    }
    
    func clearCachedQueriesForCharacter(server: String, name: String) {
        cacheData.removeAll { $0.serverName == server && $0.roleName == name }
        saveCacheData()
    }
    
    private func loadCacheData() {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            cacheData = try JSONDecoder().decode([DungeonAchievementQueryCache].self, from: data)
        } catch {
            print("Failed to load dungeon achievement query cache: \(error)")
            cacheData = []
        }
    }
    
    private func saveCacheData() {
        do {
            let data = try JSONEncoder().encode(cacheData)
            try data.write(to: cacheFileURL)
        } catch {
            print("Failed to save dungeon achievement query cache: \(error)")
        }
    }
    
    // 获取统计信息
    func getStatistics(for server: String, name: String) -> (totalQueries: Int, totalUnfinished: Int, totalAchievements: Int) {
        let queries = getQueriesForCharacter(server: server, name: name)
        let totalQueries = queries.count
        let totalUnfinished = queries.reduce(0) { $0 + $1.unfinishedCount }
        let totalAchievements = queries.reduce(0) { $0 + $1.totalCount }
        
        return (totalQueries: totalQueries, totalUnfinished: totalUnfinished, totalAchievements: totalAchievements)
    }
    
    // 获取推荐查询的副本（基于现有的成就分析数据）
    func getRecommendedDungeons(for character: GameCharacter) -> [String] {
        // 这里可以基于现有的成就分析数据来推荐需要详细查询的副本
        // 暂时返回一些常见的副本名称
        return [
            "阴阳两界",
            "范阳夜变",
            "战宝之争",
            "血战天策",
            "智者寺",
            "哀莫大于心死",
            "血龙殿",
            "毒牙门",
            "狼牙堡",
            "刀帝陵",
            "疑踪疑云",
            "千载云间",
            "妖域余孽",
            "神女殿",
            "恶人谷",
            "浩气盟",
            "血色龙城",
            "荡寇复仇",
            "圣光镇",
            "无影殿",
            "诸葛孔明",
            "杀戮道",
            "万剑冢",
            "决战巅峰",
            "桃花岛",
            "雪域神殿",
            "天龙殿",
            "焚影塔",
            "苍云要塞",
            "雪山派",
            "太乙殿",
            "阴阳大法",
            "妖魔道",
            "三界伏魔",
            "万花争艳",
            "怒海争锋"
        ]
    }
}
