//
//  TeamRecruitModels.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/19.
//

import Foundation

// MARK: - 团队招募数据模型
struct TeamRecruitResponse: Codable {
    let code: Int
    let msg: String
    let data: TeamRecruitData
    let time: Int
}

struct TeamRecruitData: Codable {
    let zone: String
    let server: String
    let time: Int
    let data: [TeamRecruitItem]
}

struct TeamRecruitItem: Codable, Identifiable, Equatable {
    let id = UUID()
    let activity: String
    let leader: String
    let number: Int
    let maxNumber: Int
    let content: String
    
    // 其他字段，虽然不重要但需要解析
    let crossServer: Bool?
    let activityId: Int?
    let level: Int?
    let pushId: Int?
    let roomID: String?
    let roleId: Int?
    let createTime: Int?
    let label: [String]?
    
    enum CodingKeys: String, CodingKey {
        case activity
        case leader
        case number
        case maxNumber
        case content
        case crossServer
        case activityId
        case level
        case pushId
        case roomID
        case roleId
        case createTime
        case label
    }
    
    // 人数状态
    var memberStatus: String {
        return "\(number)/\(maxNumber)"
    }
    
    // 是否已满员
    var isFull: Bool {
        return number >= maxNumber
    }
    
    // 缺人数量
    var neededMembers: Int {
        return max(0, maxNumber - number)
    }
}

// MARK: - 团队招募搜索类型
enum TeamRecruitSearchType: Int, CaseIterable {
    case all = 1        // 本服+跨服
    case local = 2      // 仅本服
    case cross = 3      // 仅跨服
    
    var displayName: String {
        switch self {
        case .all:
            return "本服+跨服"
        case .local:
            return "仅本服"
        case .cross:
            return "仅跨服"
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "globe"
        case .local:
            return "house"
        case .cross:
            return "arrow.triangle.2.circlepath"
        }
    }
}