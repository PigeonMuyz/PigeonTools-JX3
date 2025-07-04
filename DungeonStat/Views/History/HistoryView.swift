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

// MARK: - 记录行视图组件（修改后的布局）
struct RecordRowView: View {
    let record: CompletionRecord
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCharacterSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 第一行：副本名称 + 完成时间
            HStack {
                Text(record.dungeonName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(record.completedDate, formatter: simpleDateFormatter)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 第二行：服务器 - 角色名
            HStack {
                Text("\(record.character.server) - \(record.character.name)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            // 第三行：标签式显示进度和用时
            HStack(spacing: 8) {
                // 当前副本车次标签
                HStack(spacing: 4) {
                    Text("当前角色的副本\n第\(dungeonManager.getCharacterRunNumber(for: record))车")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(6)
                
                // 渡渡鸟总车次标签
                HStack(spacing: 4) {
                    Text("渡渡鸟帮刷\n第\(dungeonManager.getTotalRunNumber(for: record))车")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.15))
                .cornerRadius(6)
                
                // 用时标签
                HStack(spacing: 4) {
                    Text("用时\n\(formatDuration(record.duration))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
                
                Spacer()
            }
            
            // 第四行：掉落显示
            DropDisplayView(drops: record.drops)
        }
        .padding(.vertical, 6)
    }
}

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

// MARK: - 全局格式化器别名（保持兼容性）
private let simpleDateFormatter = DateFormatters.simpleDateFormatter
private let dateTimeFormatter = DateFormatters.dateTimeFormatter
private let gameWeekFormatter = DateFormatters.gameWeekFormatter
