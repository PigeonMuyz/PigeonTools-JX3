//
//  DungeonManager+Categories.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/8.
//

import Foundation
import SwiftUI

// MARK: - 分类管理扩展
extension DungeonManager {
    
    // MARK: - 分类相关属性
    // categories 属性已在主类中定义
    // collapsedCategories 属性已在主类中定义
    
    // 未分类的虚拟ID
    static let uncategorizedId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    // MARK: - 分类管理方法
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: "SavedCategories"),
           let savedCategories = try? JSONDecoder().decode([DungeonCategory].self, from: data) {
            categories = savedCategories
        } else {
            // 如果没有保存的分类，使用默认分类
            categories = DungeonCategory.defaultCategories
            saveCategories()
        }
    }
    
    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "SavedCategories")
        }
    }
    
    func addCategory(_ category: DungeonCategory) {
        categories.append(category)
        saveCategories()
    }
    
    func removeCategory(_ category: DungeonCategory) {
        // 不能删除默认分类
        guard !category.isDefault else { return }
        
        // 将使用该分类的副本移动到"其他"分类
        let otherCategory = categories.first { $0.name == "其他" }
        for index in dungeons.indices {
            if dungeons[index].categoryId == category.id {
                dungeons[index].categoryId = otherCategory?.id
                dungeons[index].customCategory = nil
            }
        }
        
        categories.removeAll { $0.id == category.id }
        saveCategories()
        saveData()
    }
    
    func updateCategory(_ category: DungeonCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    // MARK: - 副本分类方法
    func getCategoryForDungeon(_ dungeon: Dungeon) -> DungeonCategory? {
        // 优先使用已设置的分类
        if let categoryId = dungeon.categoryId,
           let category = categories.first(where: { $0.id == categoryId }) {
            return category
        }
        
        // 如果有自定义分类名称，返回一个临时分类对象
        if let customName = dungeon.customCategory, !customName.isEmpty {
            return DungeonCategory(name: customName, order: 999, isDefault: false, color: "gray", icon: "folder.fill")
        }
        
        // 使用自动分类
        return getAutoCategoryForDungeon(dungeon)
    }
    
    func getAutoCategoryForDungeon(_ dungeon: Dungeon) -> DungeonCategory? {
        let sortedRules = DungeonCategoryRule.defaultRules.sorted { $0.priority < $1.priority }
        
        for rule in sortedRules {
            if rule.matches(dungeon.name) {
                return categories.first { $0.name == rule.categoryName }
            }
        }
        
        // 如果没有匹配的规则，返回"其他"分类
        return categories.first { $0.name == "其他" }
    }
    
    func setDungeonCategory(_ dungeon: Dungeon, category: DungeonCategory?) {
        if let index = dungeons.firstIndex(where: { $0.id == dungeon.id }) {
            dungeons[index].categoryId = category?.id
            dungeons[index].customCategory = nil
            saveData()
        }
    }
    
    func setDungeonCustomCategory(_ dungeon: Dungeon, categoryName: String) {
        if let index = dungeons.firstIndex(where: { $0.id == dungeon.id }) {
            dungeons[index].categoryId = nil
            dungeons[index].customCategory = categoryName.isEmpty ? nil : categoryName
            saveData()
        }
    }
    
    // MARK: - 自动分类所有副本
    func autoCategorizeDungeons() {
        for index in dungeons.indices {
            // 重新分类所有副本（除了有自定义分类的）
            if dungeons[index].customCategory == nil {
                if let autoCategory = getAutoCategoryForDungeon(dungeons[index]) {
                    dungeons[index].categoryId = autoCategory.id
                } else {
                    // 如果没有匹配的分类，清除分类ID让它显示为未分类
                    dungeons[index].categoryId = nil
                }
            }
        }
        saveData()
    }
    
    // MARK: - 获取分类后的副本列表
    func getCategorizedDungeons() -> [(category: DungeonCategory?, dungeons: [Dungeon])] {
        var result: [(category: DungeonCategory?, dungeons: [Dungeon])] = []
        var categorizedDungeons: [UUID: [Dungeon]] = [:]
        var uncategorizedDungeons: [Dungeon] = []
        var customCategoryDungeons: [String: [Dungeon]] = [:]
        
        // 分组副本
        for dungeon in dungeons {
            if let categoryId = dungeon.categoryId {
                categorizedDungeons[categoryId, default: []].append(dungeon)
            } else if let customCategory = dungeon.customCategory, !customCategory.isEmpty {
                customCategoryDungeons[customCategory, default: []].append(dungeon)
            } else {
                uncategorizedDungeons.append(dungeon)
            }
        }
        
        // 按分类顺序添加
        let sortedCategories = categories.sorted { $0.order < $1.order }
        for category in sortedCategories {
            if let dungeons = categorizedDungeons[category.id], !dungeons.isEmpty {
                result.append((category: category, dungeons: dungeons))
            }
        }
        
        // 添加自定义分类
        for (categoryName, dungeons) in customCategoryDungeons.sorted(by: { $0.key < $1.key }) {
            let customCategory = DungeonCategory(name: categoryName, order: 998, isDefault: false, color: "gray", icon: "folder.fill")
            result.append((category: customCategory, dungeons: dungeons))
        }
        
        // 添加未分类的副本
        if !uncategorizedDungeons.isEmpty {
            result.append((category: nil, dungeons: uncategorizedDungeons))
        }
        
        return result
    }
    
    // MARK: - 折叠状态管理
    func toggleCategoryCollapse(_ categoryId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if collapsedCategories.contains(categoryId) {
                collapsedCategories.remove(categoryId)
            } else {
                collapsedCategories.insert(categoryId)
            }
            saveCollapsedCategories()
        }
    }
    
    func isCategoryCollapsed(_ categoryId: UUID) -> Bool {
        return collapsedCategories.contains(categoryId)
    }
    
    // 保存折叠状态到UserDefaults
    func saveCollapsedCategories() {
        let categoryIds = Array(collapsedCategories).map { $0.uuidString }
        UserDefaults.standard.set(categoryIds, forKey: "CollapsedCategories")
    }
    
    // 加载折叠状态
    func loadCollapsedCategories() {
        if let categoryIds = UserDefaults.standard.stringArray(forKey: "CollapsedCategories") {
            collapsedCategories = Set(categoryIds.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - 强制重新分类所有副本
    func recategorizeAllDungeons() {
        for index in dungeons.indices {
            // 清除现有分类（保留自定义分类）
            if dungeons[index].customCategory == nil {
                dungeons[index].categoryId = nil
            }
        }
        autoCategorizeDungeons()
    }
    
    // MARK: - 初始化分类系统
    func initializeCategorySystem() {
        loadCategories()
        recategorizeAllDungeons()
        
        // 默认折叠所有分类
        if collapsedCategories.isEmpty {
            // 折叠所有预设分类
            for category in categories {
                collapsedCategories.insert(category.id)
            }
            // 折叠未分类
            collapsedCategories.insert(DungeonManager.uncategorizedId)
        }
    }
}
