//
//  CategoryEditorView.swift
//  DungeonStat
//
//  Created by Assistant on 2025/8/30.
//

import SwiftUI

struct CategoryEditorView: View {
    let dungeon: Dungeon
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedCategoryId: UUID?
    @State private var showingCustomCategoryInput = false
    @State private var customCategoryName = ""
    @State private var customCategoryOrder = "50"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前副本信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dungeon.name)
                                .font(.headline)
                            
                            if let currentCategory = dungeonManager.getCategoryForDungeon(dungeon) {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("当前分类: \(currentCategory.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if let customCategory = dungeon.customCategory {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("当前分类: \(customCategory)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("未分类")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                Divider()
                
                // 分类选项列表
                List {
                    // 预设分类
                    Section(header: Text("预设分类")) {
                        ForEach(dungeonManager.categories.sorted(by: { $0.order < $1.order })) { category in
                            Button(action: {
                                selectedCategoryId = category.id
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(category.color))
                                        .frame(width: 24, height: 24)
                                    
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if dungeonManager.getCategoryForDungeon(dungeon)?.id == category.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 操作选项
                    Section {
                        // 自定义分类
                        Button(action: {
                            showingCustomCategoryInput = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("创建自定义分类")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // 移除分类
                        if dungeonManager.getCategoryForDungeon(dungeon) != nil || dungeon.customCategory != nil {
                            Button(action: {
                                dungeonManager.setDungeonCategory(dungeon, category: nil)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "folder.badge.minus")
                                        .foregroundColor(.orange)
                                    Text("移除分类")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        if let categoryId = selectedCategoryId,
                           let category = dungeonManager.categories.first(where: { $0.id == categoryId }) {
                            dungeonManager.setDungeonCategory(dungeon, category: category)
                        }
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCategoryId == nil || 
                             selectedCategoryId == dungeonManager.getCategoryForDungeon(dungeon)?.id)
                }
            }
        }
        .sheet(isPresented: $showingCustomCategoryInput) {
            NavigationView {
                Form {
                    Section(header: Text("分类信息")) {
                        TextField("分类名称", text: $customCategoryName)
                        
                        HStack {
                            Text("排序值")
                            TextField("输入数字(越小越靠前)", text: $customCategoryOrder)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Text("提示：排序值决定分类在列表中的位置\n• 预设分类：1-4\n• 建议自定义：10-900\n• 其他分类：999")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("创建自定义分类")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            customCategoryName = ""
                            customCategoryOrder = "50"
                            showingCustomCategoryInput = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("创建") {
                            if !customCategoryName.isEmpty {
                                let order = Int(customCategoryOrder) ?? 50
                                dungeonManager.setDungeonCustomCategory(dungeon, categoryName: customCategoryName, order: order)
                                customCategoryName = ""
                                customCategoryOrder = "50"
                                showingCustomCategoryInput = false
                                isPresented = false
                            }
                        }
                        .disabled(customCategoryName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            // 初始化选中的分类
            if let currentCategory = dungeonManager.getCategoryForDungeon(dungeon) {
                selectedCategoryId = currentCategory.id
            }
        }
    }
}