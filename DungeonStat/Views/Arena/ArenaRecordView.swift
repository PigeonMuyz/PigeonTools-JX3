//
//  ArenaRecordView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI

// MARK: - 名剑大会战绩查询视图
struct ArenaRecordView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var arenaData: [ArenaMode: ArenaRecordData] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var hasAutoQueried = false
    
    var body: some View {
        List {
                if let selectedCharacter = dungeonManager.selectedCharacter {
                    if isLoading {
                        Section {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在查询战绩...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                        }
                    } else if arenaData.isEmpty && hasAutoQueried {
                        // 没有找到战绩
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                
                                Text("没有找到竞技战绩")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("该角色可能没有参与过名剑大会\n或者服务器数据暂未更新")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    } else {
                        // 各模式战绩
                        ForEach(ArenaMode.allCases, id: \.self) { mode in
                            if let data = arenaData[mode] {
                                ArenaModeListSection(data: data, mode: mode)
                            }
                        }
                    }
                } else {
                    // 没有选择角色
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            Text("请先选择角色")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("请在工具页面或仪表盘中选择角色")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
        .navigationTitle("名剑大会")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await queryAllArenaRecords()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(dungeonManager.selectedCharacter == nil || isLoading)
            }
        }
        .alert("查询失败", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .onAppear {
            if !hasAutoQueried && dungeonManager.selectedCharacter != nil {
                hasAutoQueried = true
                Task {
                    await queryAllArenaRecords()
                }
            }
        }
    }
    
    private func queryAllArenaRecords() async {
        guard let character = dungeonManager.selectedCharacter else { return }
        
        isLoading = true
        errorMessage = nil
        arenaData.removeAll()
        
        // 并发查询所有模式
        await withTaskGroup(of: (ArenaMode, ArenaRecordData?).self) { group in
            for mode in ArenaMode.allCases {
                group.addTask {
                    do {
                        let data = try await JX3APIService.shared.fetchArenaRecord(
                            server: character.server,
                            name: character.name,
                            mode: mode
                        )
                        return (mode, data)
                    } catch {
                        print("查询\(mode.displayName)战绩失败: \(error)")
                        return (mode, nil)
                    }
                }
            }
            
            for await (mode, data) in group {
                if let data = data {
                    await MainActor.run {
                        arenaData[mode] = data
                    }
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
            if arenaData.isEmpty {
                errorMessage = "没有找到任何竞技战绩"
            }
        }
    }
}
