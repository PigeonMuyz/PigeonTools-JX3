//
//  ToolsView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 工具页面
struct ToolsView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCharacterManagement = false
    @State private var showingCharacterSelector = false
    @State private var showingManualRecord = false
    
    var body: some View {
        NavigationView {
            List {
                // 角色管理区域
                Section(header: Text("角色管理")) {
                    NavigationLink(destination: CharacterManagementView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                                .symbolEffect(.bounce, value: showingCharacterManagement)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("角色管理")
                                    .font(.headline)
                                Text("管理你的游戏角色")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
//                            
//                            Spacer()
//                            
//                            Text("\(dungeonManager.characters.count)")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(8)
                        }
                    }
                    
                    if let selectedCharacter = dungeonManager.selectedCharacter {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("当前角色")
                                    .font(.headline)
                                Text(selectedCharacter.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("切换") {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                showingCharacterSelector = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // 数据管理区域
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: HistoryView()) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("历史记录")
                                    .font(.headline)
                                Text("查看和管理完成记录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: ArenaRecordView()) {
                        HStack {
                            Image(systemName: "figure.roll.runningpace")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("JJC战绩")
                                    .font(.headline)
                                Text("查询名剑大会战绩")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // 预留扩展区域
                Section(header: Text("更多工具")) {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("更多功能")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("敬请期待")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("工具")
            .sheet(isPresented: $showingCharacterSelector) {
                CharacterSelectorView(isPresented: $showingCharacterSelector)
            }
            .sheet(isPresented: $showingManualRecord) {
                AddManualRecordView(isPresented: $showingManualRecord)
            }
        }
    }
}
