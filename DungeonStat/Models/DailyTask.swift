//
//  DailyTask.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 日常任务数据模型
struct DailyTask: Identifiable, Codable, Hashable {
    let id = UUID()
    let type: DailyTaskType
    var name: String
    var isCompleted: Bool = false
    var completedDate: Date?
    let refreshDate: Date // 刷新日期（每天7点）
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DailyTask, rhs: DailyTask) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 日常任务类型
enum DailyTaskType: String, CaseIterable, Codable {
    case war = "war"           // 大战
    case battle = "battle"     // 积分日常
    case orecar = "orecar"     // 牛车
    case luck = "luck"         // 家园祈福
    case trade = "trade"       // 跑商
    
    var displayName: String {
        switch self {
        case .war: return "大战"
        case .battle: return "积分日常"
        case .orecar: return "牛车"
        case .luck: return "家园祈福"
        case .trade: return "跑商"
        }
    }
    
    var icon: String {
        switch self {
        case .war: return "sword.fill"
        case .battle: return "target"
        case .orecar: return "car.fill"
        case .luck: return "house.fill"
        case .trade: return "cart.fill"
        }
    }
    
    var color: String {
        switch self {
        case .war: return "red"
        case .battle: return "blue"
        case .orecar: return "purple"
        case .luck: return "green"
        case .trade: return "orange"
        }
    }
}

// MARK: - JX3API日常活动响应模型
struct JX3DailyActivityResponse: Codable {
    let code: Int
    let msg: String
    let data: JX3DailyActivityData?
    let time: Int
}

struct JX3DailyActivityData: Codable {
    let date: String
    let week: String
    let war: String?
    let battle: String?
    let orecar: String?
    let school: String?
    let rescue: String?
    let luck: [String]?
    let card: [String]?
    let team: [String]?
}

// MARK: - 角色日常任务数据
struct CharacterDailyTasks: Identifiable, Codable {
    let id = UUID()
    let characterId: UUID
    let date: String // 格式: "2025-07-04"
    var tasks: [DailyTask] = []
    
    // 检查是否需要刷新（当前时间是否已过今天的7点）
    static func shouldRefresh(for date: Date) -> Bool {
        let calendar = Calendar.current
        let refreshTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date
        return Date() >= refreshTime
    }
    
    // 获取今天的日期字符串
    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 获取任务刷新时间（今天7点）
    static func getRefreshTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 如果当前时间已经过了今天7点，返回今天7点
        if let todayRefresh = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now),
           now >= todayRefresh {
            return todayRefresh
        } else {
            // 如果还没到今天7点，返回昨天7点
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: yesterday) ?? now
        }
    }
}