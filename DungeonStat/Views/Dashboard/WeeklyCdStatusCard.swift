//
//  WeeklyCdStatusCard.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/17.
//

import SwiftUI

struct WeeklyCdStatusCard: View {
    let refreshTrigger: Int
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var teamCdData: TeamCdData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var hasAutoLoaded = false
    
    init(refreshTrigger: Int = 0) {
        self.refreshTrigger = refreshTrigger
    }
    
    var body: some View {
        Group {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在查询副本状态...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let teamCdData = teamCdData {
                dungeonCdContent(teamCdData)
            } else if dungeonManager.selectedCharacter == nil {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    Text("请先选择角色")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    Text("暂无副本数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            }
        }
        .alert("查询失败", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .onAppear {
            if !hasAutoLoaded, let selectedCharacter = dungeonManager.selectedCharacter {
                hasAutoLoaded = true
                Task {
                    await loadTeamCdData(for: selectedCharacter)
                }
            }
        }
        .onChange(of: dungeonManager.selectedCharacter) { _, newCharacter in
            if let character = newCharacter {
                Task {
                    await loadTeamCdData(for: character)
                }
            } else {
                teamCdData = nil
                errorMessage = nil
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            if let selectedCharacter = dungeonManager.selectedCharacter {
                Task {
                    await loadTeamCdData(for: selectedCharacter)
                }
            }
        }
    }
    
    @ViewBuilder
    private func dungeonCdContent(_ data: TeamCdData) -> some View {
        if data.data.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                
                Text("本周暂无副本记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
            ForEach(data.data) { dungeonInfo in
                DungeonCdRow(dungeonInfo: dungeonInfo)
            }
        }
    }
    
    private func loadTeamCdData(for character: GameCharacter) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await JX3APIService.shared.fetchTeamCdList(
                server: character.server,
                name: character.name
            )
            
            await MainActor.run {
                self.teamCdData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.showingError = true
            }
        }
    }
}

struct DungeonCdRow: View {
    let dungeonInfo: DungeonCdInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成状态图标
            Image(systemName: dungeonInfo.isCompleted ? "checkmark.circle.fill" : "clock.circle.fill")
                .foregroundColor(dungeonInfo.isCompleted ? .green : .orange)
                .font(.title3)
                .frame(width: 24)
            
            // 副本信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dungeonInfo.mapName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(dungeonInfo.mapType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 进度条和进度文本
                HStack(spacing: 8) {
                    ProgressView(value: dungeonInfo.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(dungeonInfo.isCompleted ? .green : .blue)
                    
                    Text("\(dungeonInfo.bossFinished)/\(dungeonInfo.bossCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dungeonInfo.isCompleted ? .green : .primary)
                        .frame(minWidth: 30)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BossStatusView: View {
    let boss: BossProgress
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: boss.finished ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(boss.finished ? .green : .gray)
            
            Text(boss.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    WeeklyCdStatusCard(refreshTrigger: 0)
        .environmentObject(DungeonManager())
        .padding()
}
