//
//  GameCharacter.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 角色数据模型
struct GameCharacter: Identifiable, Codable, Hashable {
    let id: UUID
    var server: String // 服务器
    var name: String // 角色名
    var school: String // 门派
    var bodyType: String // 体型

    var displayName: String {
        return "\(server) - \(name) (\(school))"
    }

    // MARK: - 初始化方法

    /// 默认初始化（自动生成 ID）
    init(server: String, name: String, school: String, bodyType: String) {
        self.id = UUID()
        self.server = server
        self.name = name
        self.school = school
        self.bodyType = bodyType
    }

    /// 指定 ID 的初始化（用于从 Core Data 恢复）
    init(id: UUID, server: String, name: String, school: String, bodyType: String) {
        self.id = id
        self.server = server
        self.name = name
        self.school = school
        self.bodyType = bodyType
    }
}
