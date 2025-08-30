//
//  DungeonListView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI

// MARK: - 副本列表视图
struct DungeonListView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddDungeon = false
    @State private var newDungeonName = ""
    @State private var showingCharacterSelector = false
    @State private var showingCategoryEditor = false
    @State private var selectedDungeonForCategory: Dungeon?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dungeonManager.getCategorizedDungeons(), id: \.category?.id) { categoryGroup in
                    Section(header: CategoryHeaderView(category: categoryGroup.category)) {
                        if !isCategoryCollapsed(categoryGroup.category) {
                            ForEach(Array(categoryGroup.dungeons.enumerated()), id: \.element.id) { index, dungeon in
                                DungeonRowView(dungeon: dungeon, index: dungeonManager.dungeons.firstIndex(where: { $0.id == dungeon.id }) ?? index)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            selectedDungeonForCategory = dungeon
                                            showingCategoryEditor = true
                                        } label: {
                                            Label("分类", systemImage: "folder")
                                        }
                                        .tint(.blue)
                                        
                                        Button(role: .destructive) {
                                            if let globalIndex = dungeonManager.dungeons.firstIndex(where: { $0.id == dungeon.id }) {
                                                dungeonManager.deleteDungeon(at: globalIndex)
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteDungeons)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingCharacterSelector = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                if let character = dungeonManager.selectedCharacter {
                                    Text(character.name)
                                        .lineLimit(1)
                                } else {
                                    Text("选择角色")
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingAddDungeon = true
                    }
                }
            }
            .sheet(isPresented: $showingAddDungeon) {
                AddDungeonView(dungeonName: $newDungeonName, isPresented: $showingAddDungeon)
            }
            .sheet(isPresented: $showingCharacterSelector) {
                CharacterSelectorView(isPresented: $showingCharacterSelector)
            }
            .sheet(isPresented: $showingCategoryEditor) {
                if let dungeon = selectedDungeonForCategory {
                    CategoryEditorView(dungeon: dungeon, isPresented: $showingCategoryEditor)
                        .environmentObject(dungeonManager)
                }
            }
        }
    }
    
    func deleteDungeons(offsets: IndexSet) {
        for index in offsets {
            dungeonManager.deleteDungeon(at: index)
        }
    }
    
    private func isCategoryCollapsed(_ category: DungeonCategory?) -> Bool {
        let categoryId = category?.id ?? DungeonManager.uncategorizedId
        return dungeonManager.isCategoryCollapsed(categoryId)
    }
}
