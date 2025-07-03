//
//  HistoryView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 历史记录视图
struct HistoryView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddManualRecord = false
    @State private var searchText = ""
    
    // 过滤后的记录
    private var filteredRecords: [CompletionRecord] {
        if searchText.isEmpty {
            return dungeonManager.completionRecords.reversed()
        } else {
            return dungeonManager.completionRecords.reversed().filter { record in
                record.dungeonName.localizedCaseInsensitiveContains(searchText) ||
                record.character.displayName.localizedCaseInsensitiveContains(searchText) ||
                "\(record.year)年第\(record.weekNumber)周".contains(searchText) ||
                record.drops.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRecords) { record in
                    NavigationLink(destination: DropManagementView(record: record)) {
                        RecordRowView(record: record)
                    }
                }
                .onDelete(perform: deleteRecords)
            }
            .navigationTitle("完成历史")
            .searchable(text: $searchText, prompt: "搜索副本、角色、周数或掉落...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("手动添加") {
                        showingAddManualRecord = true
                    }
                }
            }
            .sheet(isPresented: $showingAddManualRecord) {
                AddManualRecordView(isPresented: $showingAddManualRecord)
            }
        }
    }
    
    func deleteRecords(offsets: IndexSet) {
        // 注意：这里需要从原始记录中找到对应的索引
        let originalRecords = dungeonManager.completionRecords
        
        for index in offsets {
            let recordToDelete = filteredRecords[index]
            if let originalIndex = originalRecords.firstIndex(where: { $0.id == recordToDelete.id }) {
                dungeonManager.deleteCompletionRecord(originalRecords[originalIndex])
            }
        }
    }
}

// MARK: - 记录行视图组件（添加角色编辑功能）
struct RecordRowView: View {
    let record: CompletionRecord
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCharacterSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 第一行：副本名称和日期
            HStack {
                Text(record.dungeonName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(record.completedDate, formatter: simpleDateFormatter)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 第二行：角色信息和车次（添加可点击修改角色功能）
            HStack {
                Button(action: {
                    showingCharacterSelector = true
                }) {
                    HStack(spacing: 4) {
                        Text("\(record.character.server) - \(record.character.name)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
//                        
//                        Image(systemName: "pencil.circle")
//                            .font(.caption)
//                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("\(record.dungeonName) 第\(dungeonManager.getCharacterRunNumber(for: record))车")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // 第三行：用时和总车次
            HStack {
                Text("用时 \(formatDuration(record.duration))")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("渡渡鸟帮刷 总共第\(dungeonManager.getTotalRunNumber(for: record))车")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(3)
            }
            
            // 第四行：掉落显示
            DropDisplayView(drops: record.drops)
        }
        .padding(.vertical, 6)
//        .sheet(isPresented: $showingCharacterSelector) {
//            CharacterSelectorViews(
//                currentCharacter: record.character,
//                availableCharacters: dungeonManager.characters,
//                isPresented: $showingCharacterSelector,
//                onCharacterSelected: { newCharacter in
//                    dungeonManager.updateRecordCharacter(record, to: newCharacter)
//                }
//            )
//        }
    }
}

//// MARK: - 角色选择器视图
//struct CharacterSelectorViews: View {
//    let currentCharacter: GameCharacter
//    let availableCharacters: [GameCharacter]
//    @Binding var isPresented: Bool
//    let onCharacterSelected: (GameCharacter) -> Void
//    
//    var body: some View {
//        NavigationView {
//            List {
//                Section(header: Text("选择正确的角色")) {
//                    ForEach(availableCharacters) { character in
//                        Button(action: {
//                            onCharacterSelected(character)
//                            isPresented = false
//                        }) {
//                            HStack {
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text(character.name)
//                                        .font(.headline)
//                                        .foregroundColor(.primary)
//                                    
//                                    HStack {
//                                        Text(character.server)
//                                            .font(.caption)
//                                            .foregroundColor(.blue)
//                                        
//                                        Text("•")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                        
//                                        Text(character.school)
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                        
//                                        Text("•")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                        
//                                        Text(character.bodyType)
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                    }
//                                }
//                                
//                                Spacer()
//                                
//                                if character.id == currentCharacter.id {
//                                    HStack {
//                                        Text("当前")
//                                            .font(.caption)
//                                            .foregroundColor(.blue)
//                                        Image(systemName: "checkmark.circle.fill")
//                                            .foregroundColor(.blue)
//                                    }
//                                } else {
//                                    Image(systemName: "circle")
//                                        .foregroundColor(.secondary)
//                                }
//                            }
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                }
//                
//                Section {
//                    Text("当前记录的角色是：\(currentCharacter.displayName)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .italic()
//                }
//            }
//            .navigationTitle("修改角色")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("取消") {
//                        isPresented = false
//                    }
//                }
//            }
//        }
//    }
//}

// MARK: - 掉落显示组件
struct DropDisplayView: View {
    let drops: [DropItem]
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 掉落标签
            Text("掉落:")
                .font(.caption)
                .foregroundColor(.secondary)
                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
            
            if drops.isEmpty {
                Text("无")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                // 掉落物品标签
                DropTagsView(drops: drops)
            }
        }
    }
}

// MARK: - 掉落标签视图
struct DropTagsView: View {
    let drops: [DropItem]
    
    // 最多显示的标签数量
    private let maxDisplayTags = 3
    
    var body: some View {
        if drops.count <= maxDisplayTags {
            // 如果掉落数量少，直接显示所有
            HStack(spacing: 4) {
                ForEach(drops) { drop in
                    DropTag(drop: drop)
                }
            }
        } else {
            // 如果掉落数量多，显示前几个 + "更多"
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    ForEach(drops.prefix(maxDisplayTags)) { drop in
                        DropTag(drop: drop)
                    }
                }
                
                if drops.count > maxDisplayTags {
                    HStack(spacing: 4) {
                        Text("还有\(drops.count - maxDisplayTags)个...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        // 显示剩余物品的简要信息
                        ForEach(drops.dropFirst(maxDisplayTags).prefix(2)) { drop in
                            Text(drop.name.prefix(4) + "...")
                                .font(.caption2)
                                .foregroundColor(drop.color.opacity(0.7))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 单个掉落标签
struct DropTag: View {
    let drop: DropItem
    
    var body: some View {
        HStack(spacing: 3) {
            // 颜色指示器
            Circle()
                .fill(drop.color)
                .frame(width: 4, height: 4)
            
            Text(drop.name)
                .font(.caption)
                .foregroundColor(drop.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(drop.color.opacity(0.12))
        .cornerRadius(4)
    }
}

// MARK: - 格式化器
private let simpleDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter
}()

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

private let gameWeekFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()
