//
//  AchievementCompletionService.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import Foundation

// MARK: - 成就完成状态管理服务
class AchievementCompletionService {
    static let shared = AchievementCompletionService()
    private init() {}
    
    private let completionKey = "achievement_completion_status"
    
    // MARK: - 成就完成状态数据模型
    private struct CompletionData: Codable {
        var completedAchievements: Set<Int> = []
        var lastUpdated: Date = Date()
    }
    
    // MARK: - 获取完成状态数据
    private func getCompletionData() -> CompletionData {
        guard let data = UserDefaults.standard.data(forKey: completionKey),
              let completionData = try? JSONDecoder().decode(CompletionData.self, from: data) else {
            return CompletionData()
        }
        return completionData
    }
    
    // MARK: - 保存完成状态数据
    private func saveCompletionData(_ data: CompletionData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: completionKey)
        }
    }
    
    // MARK: - 标记成就为已完成
    func markAchievementAsCompleted(_ achievementId: Int) {
        var data = getCompletionData()
        data.completedAchievements.insert(achievementId)
        data.lastUpdated = Date()
        saveCompletionData(data)
    }
    
    // MARK: - 标记成就为未完成
    func markAchievementAsIncomplete(_ achievementId: Int) {
        var data = getCompletionData()
        data.completedAchievements.remove(achievementId)
        data.lastUpdated = Date()
        saveCompletionData(data)
    }
    
    // MARK: - 检查成就是否已完成
    func isAchievementCompleted(_ achievementId: Int) -> Bool {
        let data = getCompletionData()
        return data.completedAchievements.contains(achievementId)
    }
    
    // MARK: - 获取所有已完成的成就ID
    func getCompletedAchievements() -> Set<Int> {
        return getCompletionData().completedAchievements
    }
    
    // MARK: - 清除所有完成状态
    func clearAllCompletionStatus() {
        UserDefaults.standard.removeObject(forKey: completionKey)
    }
    
    // MARK: - 获取完成状态统计
    func getCompletionStats(for achievements: [ProcessedAchievement]) -> (completed: Int, total: Int) {
        let completedSet = getCompletedAchievements()
        let completed = achievements.filter { completedSet.contains($0.id) }.count
        return (completed: completed, total: achievements.count)
    }
}