//
//  DungeonCategory.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/8.
//

import Foundation

// MARK: - 副本分类数据模型
struct DungeonCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var order: Int // 排序顺序
    var isDefault: Bool = false // 是否为预设分类
    var color: String // 分类颜色
    var icon: String // 分类图标
    
    init(id: UUID = UUID(), name: String, order: Int, isDefault: Bool = false, color: String, icon: String) {
        self.id = id
        self.name = name
        self.order = order
        self.isDefault = isDefault
        self.color = color
        self.icon = icon
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DungeonCategory, rhs: DungeonCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 预设分类定义
extension DungeonCategory {
    static let defaultCategories: [DungeonCategory] = [
        DungeonCategory(name: "丝路风雨", order: 1, isDefault: true, color: "red", icon: "mountain.2.fill"),
        DungeonCategory(name: "横刀断浪", order: 2, isDefault: true, color: "blue", icon: "sword.slash"),
        DungeonCategory(name: "奉天证道", order: 3, isDefault: true, color: "green", icon: "crown.fill"),
        DungeonCategory(name: "世外蓬莱", order: 4, isDefault: true, color: "purple", icon: "cloud.fill"),
        DungeonCategory(name: "其他", order: 999, isDefault: true, color: "gray", icon: "folder.fill")
    ]
}

// MARK: - 副本自动分类规则
struct DungeonCategoryRule {
    let categoryName: String
    let coreNames: [String] // 副本核心名称（不包含难度前缀）
    let priority: Int // 优先级，数字越小优先级越高
    
    static let defaultRules: [DungeonCategoryRule] = [
        // 丝路风雨
        DungeonCategoryRule(
            categoryName: "丝路风雨",
            coreNames: ["一之窟"],
            priority: 1
        ),
        // 横刀断浪
        DungeonCategoryRule(
            categoryName: "横刀断浪",
            coreNames: ["冷龙峰"],
            priority: 2
        ),
        // 奉天证道
        DungeonCategoryRule(
            categoryName: "奉天证道",
            coreNames: ["河阳之战", "白帝江关"],
            priority: 3
        ),
        // 世外蓬莱
        DungeonCategoryRule(
            categoryName: "世外蓬莱",
            coreNames: ["范阳夜变", "熬龙岛"],
            priority: 4
        )
    ]
    
    func matches(_ dungeonName: String) -> Bool {
        let coreName = extractCoreName(from: dungeonName)
        return coreNames.contains { coreNamePattern in
            coreName.contains(coreNamePattern)
        }
    }
    
    // 提取副本核心名称（去除难度前缀）
    private func extractCoreName(from dungeonName: String) -> String {
        // 常见的难度前缀模式
        let difficultyPrefixes = [
            "25人普通", "25人英雄", "25人团队",
            "10人普通", "10人英雄", "10人团队",
            "5人普通", "5人英雄", "5人团队",
            "普通", "英雄", "团队"
        ]
        
        var coreName = dungeonName
        
        // 移除匹配的难度前缀
        for prefix in difficultyPrefixes {
            if coreName.hasPrefix(prefix) {
                coreName = String(coreName.dropFirst(prefix.count))
                break
            }
        }
        
        return coreName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 副本名称解析工具
extension DungeonCategoryRule {
    // 静态方法：提取任意副本名称的核心名称
    static func extractCoreName(from dungeonName: String) -> String {
        let rule = DungeonCategoryRule(categoryName: "", coreNames: [], priority: 0)
        return rule.extractCoreName(from: dungeonName)
    }
}
