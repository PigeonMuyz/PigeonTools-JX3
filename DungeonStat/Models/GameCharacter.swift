//
//  GameCharacter.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 角色数据模型
struct GameCharacter: Identifiable, Codable, Hashable {
    let id = UUID()
    var server: String // 服务器
    var name: String // 角色名
    var school: String // 门派
    var bodyType: String // 体型
    
    var displayName: String {
        return "\(server) - \(name) (\(school))"
    }
}
