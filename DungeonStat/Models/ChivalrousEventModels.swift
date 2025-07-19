//
//  ChivalrousEventModels.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/18.
//

import Foundation

// MARK: - 行侠事件数据模型
struct ChivalrousEventResponse: Codable {
    let code: Int
    let msg: String
    let data: [ChivalrousEvent]
    let time: Int
}

struct ChivalrousEvent: Codable, Identifiable, Equatable {
    let id = UUID()
    let mapName: String
    let event: String
    let site: String
    let desc: String
    let icon: String
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case mapName = "map"
        case event = "stage"
        case site
        case desc
        case icon
        case time
    }
}

// MARK: - 行侠事件组织类型
enum ChivalrousOrganization: String, CaseIterable {
    case chutianshe = "楚天社"
    case yuncongshe = "云从社"
    case pifenghui = "披风会"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .chutianshe:
            return "leaf.fill"
        case .yuncongshe:
            return "cloud.fill"
        case .pifenghui:
            return "cape.fill"
        }
    }
    
    var color: String {
        switch self {
        case .chutianshe:
            return "green"
        case .yuncongshe:
            return "blue"
        case .pifenghui:
            return "purple"
        }
    }
}