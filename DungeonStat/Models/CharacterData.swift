//
//  CharacterData.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 角色详细数据模型
struct CharacterDetailData: Codable {
    let code: Int
    let msg: String
    let data: CharacterData?
    let time: Int?
}

struct CharacterData: Codable {
    let zoneName: String?        // 修改为可选类型
    let serverName: String
    let roleName: String
    let roleId: String
    let globalRoleId: String
    let forceName: String
    let forceId: String
    let bodyName: String
    let bodyId: String
    let tongName: String?
    let tongId: String?
    let campName: String
    let campId: String
    let personName: String
    let personId: String?        // 修改为可选类型
    let personAvatar: String?    // 修改为可选类型
    let gameClient: String?      // 新增字段，可选类型
    let gameMode: String?        // 新增字段，可选类型
    let kungfuType: String?      // 新增字段，可选类型
    let kungfuName: String
    let kungfuId: String
    let equipList: [Equipment]
    let qixueList: [Qixue]
    let panelList: PanelList
}

struct Equipment: Codable, Identifiable {
    let id = UUID()
    let name: String
    let `class`: String
    let icon: String
    let kind: String
    let subKind: String
    let quality: String
    let strengthLevel: String
    let maxStrengthLevel: String
    let color: String
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case name, `class`, icon, kind, subKind, quality, strengthLevel, maxStrengthLevel, color, desc
    }
}

struct Qixue: Codable, Identifiable {
    let id = UUID()
    let name: String
    let level: Int
    let icon: String
    let kind: String
    let subKind: String
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case name, level, icon, kind, subKind, desc
    }
}

struct PanelList: Codable {
    let score: Int
    let panel: [PanelAttribute]
}

struct PanelAttribute: Codable, Identifiable {
    let id = UUID()
    let name: String
    let percent: Bool
    let value: Double
    
    private enum CodingKeys: String, CodingKey {
        case name, percent, value
    }
}
