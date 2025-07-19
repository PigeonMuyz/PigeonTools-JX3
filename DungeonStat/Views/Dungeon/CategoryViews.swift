//
//  CategoryViews.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI

// MARK: - 分类UI组件
struct CategoryHeaderView: View {
    let category: DungeonCategory?
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        Button(action: {
            let categoryId = category?.id ?? DungeonManager.uncategorizedId
            dungeonManager.toggleCategoryCollapse(categoryId)
        }) {
            HStack {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                    .symbolEffect(.bounce, value: isCollapsed)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCollapsed)
                
                if let category = category {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("未分类")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isCollapsed: Bool {
        let categoryId = category?.id ?? DungeonManager.uncategorizedId
        return dungeonManager.isCategoryCollapsed(categoryId)
    }
}

struct CategoryContextMenu: View {
    let dungeon: Dungeon
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCategorySelector = false
    @State private var showingCustomCategoryInput = false
    @State private var customCategoryName = ""
    
    var body: some View {
        Group {
            Button("重新分类") {
                showingCategorySelector = true
            }
            
            Button("自定义分类") {
                showingCustomCategoryInput = true
            }
            
            Button("移除分类") {
                dungeonManager.setDungeonCategory(dungeon, category: nil)
            }
        }
        .sheet(isPresented: $showingCategorySelector) {
            CategorySelectorView(dungeon: dungeon, isPresented: $showingCategorySelector)
        }
        .alert("自定义分类", isPresented: $showingCustomCategoryInput) {
            TextField("分类名称", text: $customCategoryName)
            Button("确定") {
                dungeonManager.setDungeonCustomCategory(dungeon, categoryName: customCategoryName)
                customCategoryName = ""
            }
            Button("取消", role: .cancel) {
                customCategoryName = ""
            }
        }
    }
}

struct CategorySelectorView: View {
    let dungeon: Dungeon
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dungeonManager.categories.sorted(by: { $0.order < $1.order })) { category in
                    Button(action: {
                        dungeonManager.setDungeonCategory(dungeon, category: category)
                        isPresented = false
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(category.color))
                                .frame(width: 20, height: 20)
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if dungeonManager.getCategoryForDungeon(dungeon)?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
