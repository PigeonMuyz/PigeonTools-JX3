//
//  DailyTaskManager.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 日常任务管理器
class DailyTaskManager: ObservableObject {
    @Published var characterDailyTasks: [CharacterDailyTasks] = []
    @Published var isLoading = false
    @Published var lastRefreshTime: Date?
    
    private let dailyTaskService = DailyTaskService.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadStoredTasks()
    }
    
    // MARK: - 数据持久化
    private func loadStoredTasks() {
        if let data = userDefaults.data(forKey: "characterDailyTasks"),
           let tasks = try? JSONDecoder().decode([CharacterDailyTasks].self, from: data) {
            self.characterDailyTasks = tasks
        }
        
        if let refreshTime = userDefaults.object(forKey: "lastDailyTaskRefresh") as? Date {
            self.lastRefreshTime = refreshTime
        }
    }
    
    private func saveStoredTasks() {
        if let data = try? JSONEncoder().encode(characterDailyTasks) {
            userDefaults.set(data, forKey: "characterDailyTasks")
        }
        
        if let refreshTime = lastRefreshTime {
            userDefaults.set(refreshTime, forKey: "lastDailyTaskRefresh")
        }
    }
    
    // MARK: - 任务刷新
    @MainActor
    func refreshDailyTasks(for characters: [GameCharacter]) async {
        guard !characters.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // 暂时禁用获取日常活动数据的功能
        /*
        do {
            // 获取所有服务器的唯一列表
            let servers = Array(Set(characters.map { $0.server }))
            
            // 为每个服务器获取日常活动数据
            var serverActivities: [String: JX3DailyActivityData] = [:]
            
            for server in servers {
                do {
                    let activityData = try await dailyTaskService.fetchDailyActivities(server: server)
                    serverActivities[server] = activityData
                    print("获取 \(server) 服务器日常活动成功")
                } catch {
                    print("获取 \(server) 服务器日常活动失败: \(error)")
                    // 继续处理其他服务器
                }
            }
            
            // 为每个角色创建或更新日常任务
            let todayString = CharacterDailyTasks.todayDateString()
            
            for character in characters {
                if let activityData = serverActivities[character.server] {
                    updateDailyTasks(for: character, with: activityData, date: todayString)
                }
            }
            
            lastRefreshTime = Date()
            saveStoredTasks()
            
            print("日常任务刷新完成，共处理 \(characters.count) 个角色")
            
        } catch {
            print("刷新日常任务失败: \(error)")
        }
        */
        
        // 只更新刷新时间，不获取服务器数据
        lastRefreshTime = Date()
        saveStoredTasks()
        print("日常任务刷新完成（已跳过服务器数据获取）")
    }
    
    private func updateDailyTasks(for character: GameCharacter, with activityData: JX3DailyActivityData, date: String) {
        // 查找或创建该角色今天的任务数据
        if let index = characterDailyTasks.firstIndex(where: { $0.characterId == character.id && $0.date == date }) {
            // 更新现有任务
            var existingTasks = characterDailyTasks[index]
            let newTasks = dailyTaskService.createDailyTasks(from: activityData)
            
            // 合并任务，保持已完成状态
            for newTask in newTasks {
                if let existingTaskIndex = existingTasks.tasks.firstIndex(where: { $0.type == newTask.type }) {
                    // 更新任务名称，但保持完成状态
                    existingTasks.tasks[existingTaskIndex].name = newTask.name
                } else {
                    // 添加新任务
                    existingTasks.tasks.append(newTask)
                }
            }
            
            characterDailyTasks[index] = existingTasks
        } else {
            // 创建新的任务数据
            let newTasks = dailyTaskService.createDailyTasks(from: activityData)
            let characterTasks = CharacterDailyTasks(
                characterId: character.id,
                date: date,
                tasks: newTasks
            )
            characterDailyTasks.append(characterTasks)
        }
    }
    
    // MARK: - 任务操作
    @MainActor
    func toggleTaskCompletion(characterId: UUID, taskType: DailyTaskType) {
        let todayString = CharacterDailyTasks.todayDateString()
        
        guard let characterIndex = characterDailyTasks.firstIndex(where: { 
            $0.characterId == characterId && $0.date == todayString 
        }) else { return }
        
        guard let taskIndex = characterDailyTasks[characterIndex].tasks.firstIndex(where: { 
            $0.type == taskType 
        }) else { return }
        
        characterDailyTasks[characterIndex].tasks[taskIndex].isCompleted.toggle()
        
        if characterDailyTasks[characterIndex].tasks[taskIndex].isCompleted {
            characterDailyTasks[characterIndex].tasks[taskIndex].completedDate = Date()
        } else {
            characterDailyTasks[characterIndex].tasks[taskIndex].completedDate = nil
        }
        
        saveStoredTasks()
    }
    
    // 通过任务ID切换任务完成状态（支持自定义任务）
    @MainActor
    func toggleTaskCompletionById(characterId: UUID, taskId: UUID) {
        let todayString = CharacterDailyTasks.todayDateString()
        
        guard let characterIndex = characterDailyTasks.firstIndex(where: { 
            $0.characterId == characterId && $0.date == todayString 
        }) else { return }
        
        guard let taskIndex = characterDailyTasks[characterIndex].tasks.firstIndex(where: { 
            $0.id == taskId 
        }) else { return }
        
        characterDailyTasks[characterIndex].tasks[taskIndex].isCompleted.toggle()
        
        if characterDailyTasks[characterIndex].tasks[taskIndex].isCompleted {
            characterDailyTasks[characterIndex].tasks[taskIndex].completedDate = Date()
        } else {
            characterDailyTasks[characterIndex].tasks[taskIndex].completedDate = nil
        }
        
        // 强制触发UI更新
        objectWillChange.send()
        saveStoredTasks()
    }
    
    // MARK: - 自定义任务操作
    @MainActor
    func addCustomTask(characterId: UUID, taskName: String) {
        let todayString = CharacterDailyTasks.todayDateString()
        let refreshTime = CharacterDailyTasks.getRefreshTime()
        
        // 查找或创建该角色今天的任务数据
        if let index = characterDailyTasks.firstIndex(where: { $0.characterId == characterId && $0.date == todayString }) {
            // 添加自定义任务到现有任务列表
            let customTask = DailyTask(
                type: .custom,
                name: taskName,
                refreshDate: refreshTime,
                isCustom: true
            )
            characterDailyTasks[index].tasks.append(customTask)
        } else {
            // 创建新的任务数据，包含自定义任务
            let customTask = DailyTask(
                type: .custom,
                name: taskName,
                refreshDate: refreshTime,
                isCustom: true
            )
            let characterTasks = CharacterDailyTasks(
                characterId: characterId,
                date: todayString,
                tasks: [customTask]
            )
            characterDailyTasks.append(characterTasks)
        }
        
        // 强制触发UI更新
        objectWillChange.send()
        saveStoredTasks()
    }
    
    @MainActor
    func deleteCustomTask(characterId: UUID, taskId: UUID) {
        let todayString = CharacterDailyTasks.todayDateString()
        
        guard let characterIndex = characterDailyTasks.firstIndex(where: { 
            $0.characterId == characterId && $0.date == todayString 
        }) else { return }
        
        // 只允许删除自定义任务
        characterDailyTasks[characterIndex].tasks.removeAll { task in
            task.id == taskId && task.isCustom
        }
        
        // 强制触发UI更新
        objectWillChange.send()
        saveStoredTasks()
    }
    
    @MainActor
    func editCustomTask(characterId: UUID, taskId: UUID, newName: String) {
        let todayString = CharacterDailyTasks.todayDateString()
        
        guard let characterIndex = characterDailyTasks.firstIndex(where: { 
            $0.characterId == characterId && $0.date == todayString 
        }) else { return }
        
        guard let taskIndex = characterDailyTasks[characterIndex].tasks.firstIndex(where: { 
            $0.id == taskId && $0.isCustom 
        }) else { return }
        
        // 只允许编辑自定义任务的名称
        characterDailyTasks[characterIndex].tasks[taskIndex].name = newName
        
        // 强制触发UI更新
        objectWillChange.send()
        saveStoredTasks()
    }
    
    // MARK: - 自动刷新功能
    @MainActor
    func autoRefreshIfNeeded(for characters: [GameCharacter]) async {
        // 检查是否需要刷新
        if shouldRefresh() {
            await refreshDailyTasks(for: characters)
        }
    }
    
    // 手动强制刷新
    @MainActor
    func forceRefresh(for characters: [GameCharacter]) async {
        await refreshDailyTasks(for: characters)
    }
    
    // MARK: - 数据查询
    func getDailyTasks(for character: GameCharacter) -> [DailyTask] {
        let todayString = CharacterDailyTasks.todayDateString()
        
        return characterDailyTasks
            .first { $0.characterId == character.id && $0.date == todayString }?
            .tasks ?? []
    }
    
    func getCompletedTasksCount(for character: GameCharacter) -> Int {
        return getDailyTasks(for: character).filter { $0.isCompleted }.count
    }
    
    func getTotalTasksCount(for character: GameCharacter) -> Int {
        return getDailyTasks(for: character).count
    }
    
    func getAllCharactersTasksProgress() -> (completed: Int, total: Int) {
        let todayString = CharacterDailyTasks.todayDateString()
        
        let allTasks = characterDailyTasks
            .filter { $0.date == todayString }
            .flatMap { $0.tasks }
        
        let completed = allTasks.filter { $0.isCompleted }.count
        let total = allTasks.count
        
        return (completed: completed, total: total)
    }
    
    // MARK: - 刷新检查
    func shouldRefresh() -> Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        
        // 检查是否已经过了今天的刷新时间
        let refreshTime = CharacterDailyTasks.getRefreshTime()
        return lastRefresh < refreshTime
    }
    
    // MARK: - 清理旧数据
    @MainActor
    func cleanupOldTasks() {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let cutoffDateString = dateFormatter.string(from: sevenDaysAgo)
        
        characterDailyTasks = characterDailyTasks.filter { $0.date >= cutoffDateString }
        saveStoredTasks()
    }
}
