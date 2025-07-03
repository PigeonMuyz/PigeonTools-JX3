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
                "\(record.year)年第\(record.weekNumber)周".contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.dungeonName)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(record.completedDate, formatter: simpleDateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("\(record.character.server) - \(record.character.name)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            // 显示该副本的第几车
                            Text("当前副本 第\(dungeonManager.getCharacterRunNumber(for: record))车")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Text("用时 \(formatDuration(record.duration))")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            // 可选：显示总第几车（所有副本）
                            Text("渡渡鸟帮刷 总共第\(dungeonManager.getTotalRunNumber(for: record))车")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteRecords)
            }
            .navigationTitle("完成历史")
            .searchable(text: $searchText, prompt: "搜索副本、角色或周数...")
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

// MARK: - 格式化器
private let simpleDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-M-d"
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
