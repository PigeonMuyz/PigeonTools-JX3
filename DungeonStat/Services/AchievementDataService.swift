//
//  AchievementDataService.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import Foundation

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - JX3Box成就数据模型
struct JX3BoxAchievementResponse: Codable {
    let code: Int
    let msg: String
    let data: JX3BoxAchievementContainer
}

struct JX3BoxAchievementContainer: Codable {
    let achievements: [JX3BoxAchievement]
}

struct JX3BoxAchievement: Codable {
    let ID: Int
    let Name: String
    let Note: String?
    let ShortDesc: String?
    let Desc: String?
    let IconID: Int?
    let Point: Int
    let LayerName: String?
    let SceneName: String?
    let SubAchievementList: [JX3BoxSubAchievement]?
    let post: JX3BoxPost?
    
    // 处理可能是数字或字符串的字段
    private let rawPostfix: PostfixValue?
    private let rawCounters: PostfixValue?
    private let rawSubAchievements: PostfixValue?
    private let rawSceneID: PostfixValue?
    private let rawHolidayID: PostfixValue?
    private let rawPostfixName: PostfixValue?
    private let rawPrefix: PostfixValue?         // 新增
    private let rawBDLCOther: PostfixValue?     // 新增
    
    var Postfix: String? {
        switch rawPostfix {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var Counters: String? {
        switch rawCounters {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var SubAchievements: String? {
        switch rawSubAchievements {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var SceneID: String? {
        switch rawSceneID {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var HolidayID: String? {
        switch rawHolidayID {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var PostfixName: String? {
        switch rawPostfixName {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var Prefix: String? {    // 新增
        switch rawPrefix {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    var bDLCOther: String? {    // 新增
        switch rawBDLCOther {
        case .string(let str): return str
        case .integer(let num): return String(num)
        case .none: return nil
        }
    }
    
    // 其他可能为空的字段
    let ShiftID: Int?
    let ShiftType: Int?
    let Exp: String?
    let AnnounceType: Int?
    let General: Int?
    let Sub: Int?
    let Detail: Int?
    let Visible: Int?
    let Message: String?
    let ItemType: Int?
    let ItemID: Int?
    let Series: String?
    let SeriesLevel: Int?
    let ShowGetNew: Int?
    let dwDLCID: Int?
    let dwMapID: Int?
    let PrefixName: String?
    
    enum CodingKeys: String, CodingKey {
        case ID, Name, Note, ShortDesc, Desc, IconID, Point
        case LayerName, SceneName, SubAchievementList, post
        case rawPostfix = "Postfix"
        case rawCounters = "Counters"
        case rawSubAchievements = "SubAchievements"
        case rawSceneID = "SceneID"
        case rawHolidayID = "HolidayID"
        case rawPostfixName = "PostfixName"
        case rawPrefix = "Prefix"           // 新增
        case rawBDLCOther = "bDLCOther"    // 新增
        case ShiftID, ShiftType, Exp
        case AnnounceType, General, Sub, Detail, Visible
        case Message, ItemType, ItemID, Series, SeriesLevel
        case ShowGetNew, dwDLCID, dwMapID, PrefixName
    }
    
    var processedAchievement: ProcessedAchievement {
        return ProcessedAchievement(
            id: ID,
            name: Name,
            note: Note,
            shortDesc: ShortDesc,
            desc: Desc,
            iconID: IconID,
            point: Point,
            layerName: LayerName,
            sceneName: SceneName,
            subAchievementList: SubAchievementList ?? [],
            postContent: post?.content
        )
    }
}

// 处理可能是字符串或数字的值
enum PostfixValue: Codable {
    case string(String)
    case integer(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value must be either string or integer"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .integer(let num):
            try container.encode(num)
        }
    }
}

struct JX3BoxSubAchievement: Codable {
    let ID: Int
    let Name: String
    let Point: Int?  // 改为可选类型
    
    // 如果需要默认值,可以添加自定义解码器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ID = try container.decode(Int.self, forKey: .ID)
        Name = try container.decode(String.self, forKey: .Name)
        Point = try container.decodeIfPresent(Int.self, forKey: .Point) ?? 0  // 如果为null则默认为0
    }
}

struct JX3BoxPost: Codable {
    let content: String?
}

// MARK: - 处理后的成就数据模型
struct ProcessedAchievement: Codable, Identifiable {
    let id: Int
    let name: String
    let note: String?
    let shortDesc: String?
    let desc: String?
    let iconID: Int?
    let point: Int
    let layerName: String?
    let sceneName: String?
    let subAchievementList: [JX3BoxSubAchievement]
    let postContent: String?
}

// MARK: - 按副本和难度分组的成就数据
struct ProcessedAchievementData: Codable {
    let dungeons: [String: [String: [ProcessedAchievement]]]
    let lastUpdated: Date
    let totalAchievements: Int
    
    init() {
        self.dungeons = [:]
        self.lastUpdated = Date()
        self.totalAchievements = 0
    }
    
    init(dungeons: [String: [String: [ProcessedAchievement]]]) {
        self.dungeons = dungeons
        self.lastUpdated = Date()
        self.totalAchievements = dungeons.values.reduce(0) { total, difficulties in
            total + difficulties.values.reduce(0) { $0 + $1.count }
        }
    }
}

// MARK: - 成就数据获取和处理服务
class AchievementDataService {
    static let shared = AchievementDataService()
    private init() {}
    
    private let cacheKey = "processed_achievement_data"
    private let urlList = [
        "https://cms.jx3box.com/api/cms/helper/achievements/11/140?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/141?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/142?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/143?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/144?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/145?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/146?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/147?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/148?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/149?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/150?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/151?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/152?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/153?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/154?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/155?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/322?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/323?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/330?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/331?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/362?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/364?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/365?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/366?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/406?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/407?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/408?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/409?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/421?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/435?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/437?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/440?client=std",
        "https://cms.jx3box.com/api/cms/helper/achievements/11/441?client=std"
    ]
    
    // MARK: - 获取已缓存的成就数据
    func getCachedAchievementData() -> ProcessedAchievementData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let achievementData = try? JSONDecoder().decode(ProcessedAchievementData.self, from: data) else {
            return nil
        }
        return achievementData
    }
    
    // MARK: - 检查是否有缓存数据
    func hasCachedData() -> Bool {
        return getCachedAchievementData() != nil
    }
    
    // MARK: - 获取缓存时间
    func getCacheDate() -> Date? {
        return getCachedAchievementData()?.lastUpdated
    }
    
    // MARK: - 从网络获取并处理成就数据
    func fetchAndProcessAchievementData() async throws -> ProcessedAchievementData {
        var allAchievements: [ProcessedAchievement] = []
        var finalErrors: [APIError] = []
        var successCount = 0
        
        print("🚀 开始获取成就数据，总共\(urlList.count)个URL")
        
        // 分批处理URLs，每批最多5个
        let batchSize = 5
        let batches = urlList.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            print("📦 处理第\(batchIndex + 1)/\(batches.count)批，共\(batch.count)个URL")
            
            // 处理当前批次
            let batchResults = await processBatchWithRetry(batch: batch, batchIndex: batchIndex)
            
            // 收集结果
            for result in batchResults {
                switch result {
                case .success(let achievements):
                    allAchievements.append(contentsOf: achievements)
                    successCount += 1
                case .failure(let error):
                    finalErrors.append(error)
                }
            }
            
            // 批次间延迟500ms
            if batchIndex < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        
        print("📊 获取结果：成功\(successCount)/\(urlList.count)个URL，共\(allAchievements.count)个成就")
        
        // 输出最终失败的URL
        if !finalErrors.isEmpty {
            print("❌ 最终失败的URL:")
            for error in finalErrors {
                print("  \(error.localizedDescription)")
            }
        }
        
        // 如果所有请求都失败，抛出错误
        if allAchievements.isEmpty && !finalErrors.isEmpty {
            throw APIError.apiError("所有URL请求都失败了")
        }
        
        // 检查是否有有效的成就数据
        guard !allAchievements.isEmpty else {
            throw APIError.apiError("未能获取到任何有效的成就数据")
        }
        
        // 按副本和难度分组
        let groupedData = groupAchievementsByDungeonAndDifficulty(allAchievements)
        
        // 检查分组结果
        guard !groupedData.isEmpty else {
            throw APIError.apiError("成就数据分组失败，无有效的副本数据")
        }
        
        print("🏰 分组结果：\(groupedData.keys.count)个副本")
        for (dungeonName, difficulties) in groupedData {
            let totalAchievements = difficulties.values.reduce(0) { $0 + $1.count }
            print("  📍 \(dungeonName): \(difficulties.keys.count)个难度，\(totalAchievements)个成就")
        }
        
        let processedData = ProcessedAchievementData(dungeons: groupedData)
        
        // 保存到缓存
        saveToCache(processedData)
        
        return processedData
    }
    
    // MARK: - 批量处理URL并重试
    private func processBatchWithRetry(batch: [String], batchIndex: Int) async -> [Result<[ProcessedAchievement], APIError>] {
        var results: [Result<[ProcessedAchievement], APIError>] = []
        
        await withTaskGroup(of: (Int, Result<[ProcessedAchievement], APIError>).self) { group in
            for (index, url) in batch.enumerated() {
                group.addTask {
                    let globalIndex = batchIndex * 5 + index + 1
                    let result = await self.fetchWithRetry(url: url, urlIndex: globalIndex)
                    return (index, result)
                }
            }
            
            // 收集结果并按顺序排列
            var tempResults: [(Int, Result<[ProcessedAchievement], APIError>)] = []
            for await result in group {
                tempResults.append(result)
            }
            
            // 按索引排序并提取结果
            tempResults.sort { $0.0 < $1.0 }
            results = tempResults.map { $0.1 }
        }
        
        return results
    }
    
    // MARK: - 单个URL重试逻辑
    private func fetchWithRetry(url: String, urlIndex: Int) async -> Result<[ProcessedAchievement], APIError> {
        let maxRetries = 5
        
        for attempt in 1...maxRetries {
            do {
                let achievements = try await fetchAchievementsFromURL(url)
                print("✅ URL \(urlIndex)/\(urlList.count) 成功，获取\(achievements.count)个成就")
                return .success(achievements)
            } catch {
                if attempt < maxRetries {
                    print("⚠️ URL \(urlIndex)/\(urlList.count) 第\(attempt)次失败，500ms后重试: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: 500_000_000)
                } else {
                    let errorMessage = "URL \(urlIndex)/\(urlList.count) 最终失败: \(error.localizedDescription)"
                    print("❌ \(errorMessage)")
                    return .failure(APIError.apiError(errorMessage))
                }
            }
        }
        
        return .failure(APIError.apiError("URL \(urlIndex)/\(urlList.count) 未知错误"))
    }
    
    // MARK: - 从单个URL获取成就数据
    private func fetchAchievementsFromURL(_ urlString: String) async throws -> [ProcessedAchievement] {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                throw APIError.networkError
            }
            
            do {
                let achievementResponse = try JSONDecoder().decode(JX3BoxAchievementResponse.self, from: data)
                // 解码成功后的日志
                print("✅ Successfully decoded response with \(achievementResponse.data.achievements.count) achievements")
                
                return achievementResponse.data.achievements
                    .filter { $0.SceneName != nil && $0.LayerName != nil }
                    .map { $0.processedAchievement }
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                throw APIError.apiError("Decoding failed: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Network Error: \(error)")
            throw APIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - 按副本和难度分组成就
    private func groupAchievementsByDungeonAndDifficulty(_ achievements: [ProcessedAchievement]) -> [String: [String: [ProcessedAchievement]]] {
        var grouped: [String: [String: [ProcessedAchievement]]] = [:]
        
        guard !achievements.isEmpty else {
            return grouped
        }
        
        for achievement in achievements {
            guard let sceneName = achievement.sceneName,
                  let layerName = achievement.layerName,
                  !sceneName.isEmpty,
                  !layerName.isEmpty else {
                continue
            }
            
            if grouped[sceneName] == nil {
                grouped[sceneName] = [:]
            }
            
            if grouped[sceneName]![layerName] == nil {
                grouped[sceneName]![layerName] = []
            }
            
            grouped[sceneName]![layerName]!.append(achievement)
        }
        
        return grouped
    }
    
    // MARK: - 保存到缓存
    private func saveToCache(_ data: ProcessedAchievementData) {
        guard data.totalAchievements > 0 else {
            print("⚠️ 数据为空，跳过缓存保存")
            return
        }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("💾 成就数据已保存到缓存")
        } catch {
            print("❌ 缓存保存失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 清除缓存
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
    
    // MARK: - 校验资历统计数据
    func validateAchievementData(_ achievementData: AchievementData, 
                                with processedData: ProcessedAchievementData) -> ValidationResult {
        var validatedDungeons: [String: [String: ValidatedDungeonStats]] = [:]
        var totalCalibratedCount = 0
        var totalOriginalCount = 0
        
        // 空值检查
        guard !achievementData.data.dungeons.isEmpty else {
            return ValidationResult(
                validatedDungeons: [:],
                totalCalibratedCount: 0,
                totalOriginalCount: 0,
                calibrationRate: 0
            )
        }
        
        for (dungeonName, difficulties) in achievementData.data.dungeons {
            guard !dungeonName.isEmpty, !difficulties.isEmpty else {
                continue
            }
            
            validatedDungeons[dungeonName] = [:]
            
            for (difficulty, originalStats) in difficulties {
                guard !difficulty.isEmpty else {
                    continue
                }
                
                let calibratedStats = getCalibratedStats(
                    dungeonName: dungeonName,
                    difficulty: difficulty,
                    originalStats: originalStats,
                    processedData: processedData
                )
                
                validatedDungeons[dungeonName]![difficulty] = calibratedStats
                
                if calibratedStats.isCalibrated {
                    totalCalibratedCount += 1
                }
                totalOriginalCount += 1
            }
        }
        
        let calibrationRate = totalOriginalCount > 0 ? 
            Double(totalCalibratedCount) / Double(totalOriginalCount) * 100 : 0
        
        return ValidationResult(
            validatedDungeons: validatedDungeons,
            totalCalibratedCount: totalCalibratedCount,
            totalOriginalCount: totalOriginalCount,
            calibrationRate: calibrationRate
        )
    }
    
    // MARK: - 获取校验后的副本统计
    private func getCalibratedStats(dungeonName: String, 
                                   difficulty: String, 
                                   originalStats: DungeonStats,
                                   processedData: ProcessedAchievementData) -> ValidatedDungeonStats {
        
        // 空值检查
        guard !dungeonName.isEmpty, !difficulty.isEmpty, !processedData.dungeons.isEmpty else {
            return ValidatedDungeonStats(
                original: originalStats,
                calibrated: originalStats,
                isCalibrated: false,
                achievements: []
            )
        }
        
        // 先尝试精确匹配
        if let dungeonAchievements = processedData.dungeons[dungeonName],
           let difficultyAchievements = dungeonAchievements[difficulty] {
            return createValidatedStats(originalStats: originalStats, achievements: difficultyAchievements)
        }
        
        // 尝试模糊匹配副本名称
        for (processedDungeonName, difficulties) in processedData.dungeons {
            guard !processedDungeonName.isEmpty, !difficulties.isEmpty else {
                continue
            }
            
            if dungeonName.contains(processedDungeonName) || processedDungeonName.contains(dungeonName) {
                // 尝试精确匹配难度
                if let difficultyAchievements = difficulties[difficulty] {
                    return createValidatedStats(originalStats: originalStats, achievements: difficultyAchievements)
                }
                
                // 尝试模糊匹配难度
                for (processedDifficulty, achievements) in difficulties {
                    guard !processedDifficulty.isEmpty else {
                        continue
                    }
                    
                    if difficulty.contains(processedDifficulty) || processedDifficulty.contains(difficulty) {
                        return createValidatedStats(originalStats: originalStats, achievements: achievements)
                    }
                }
            }
        }
        
        // 没有找到对应的成就数据，使用原始数据
        return ValidatedDungeonStats(
            original: originalStats,
            calibrated: originalStats,
            isCalibrated: false,
            achievements: []
        )
    }
    
    private func createValidatedStats(originalStats: DungeonStats, achievements: [ProcessedAchievement]) -> ValidatedDungeonStats {
        
        // 空值检查
        guard !achievements.isEmpty else {
            return ValidatedDungeonStats(
                original: originalStats,
                calibrated: originalStats,
                isCalibrated: false,
                achievements: []
            )
        }
        
        // 计算校验后的数据，确保point值有效
        let calibratedTotalSeniority = achievements.reduce(0) { result, achievement in
            let point = max(0, achievement.point) // 确保point值不为负
            return result + point
        }
        let calibratedTotalCount = achievements.count
        
        // 确保原始统计数据有效
        let validOriginalSenioritySpeed = max(0, originalStats.seniority.speed)
        let validOriginalPiecesSpeed = max(0, originalStats.pieces.speed)
        
        let calibratedStats = DungeonStats(
            seniority: SeniorityInfo(
                total: calibratedTotalSeniority,
                speed: validOriginalSenioritySpeed
            ),
            pieces: PiecesInfo(
                total: calibratedTotalCount,
                speed: validOriginalPiecesSpeed
            )
        )
        
        return ValidatedDungeonStats(
            original: originalStats,
            calibrated: calibratedStats,
            isCalibrated: calibratedTotalSeniority > 0 && calibratedTotalCount > 0,
            achievements: achievements
        )
    }
}

// MARK: - 校验结果模型
struct ValidationResult {
    let validatedDungeons: [String: [String: ValidatedDungeonStats]]
    let totalCalibratedCount: Int
    let totalOriginalCount: Int
    let calibrationRate: Double
}

struct ValidatedDungeonStats {
    let original: DungeonStats
    let calibrated: DungeonStats
    let isCalibrated: Bool
    let achievements: [ProcessedAchievement]
    
    // 计算完成率（使用校验后的数据）
    var completionRate: Double {
        return calibrated.pieces.total > 0 
            ? Double(calibrated.pieces.speed) / Double(calibrated.pieces.total) * 100 
            : 0
    }
    
    // 可获得资历（使用校验后的数据）
    var potential: Int {
        return calibrated.seniority.total - calibrated.seniority.speed
    }
}
