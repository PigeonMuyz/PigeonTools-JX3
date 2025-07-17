//
//  WeeklyCdStatusCard.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/17.
//

import SwiftUI

struct WeeklyCdStatusCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var teamCdData: TeamCdData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var hasAutoLoaded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("本周副本状态")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let selectedCharacter = dungeonManager.selectedCharacter {
                    Button(action: {
                        Task {
                            await loadTeamCdData(for: selectedCharacter)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
            }
            
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(data.data) { dungeonInfo in
                    DungeonCdCard(dungeonInfo: dungeonInfo)
                }
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

struct DungeonCdCard: View {
    let dungeonInfo: DungeonCdInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 副本名称和类型
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dungeonInfo.mapName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(dungeonInfo.mapType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 完成状态图标
                Image(systemName: dungeonInfo.isCompleted ? "checkmark.circle.fill" : "clock.circle.fill")
                    .foregroundColor(dungeonInfo.isCompleted ? .green : .orange)
                    .font(.title3)
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(dungeonInfo.bossFinished)/\(dungeonInfo.bossCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dungeonInfo.isCompleted ? .green : .primary)
                }
                
                ProgressView(value: dungeonInfo.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(dungeonInfo.isCompleted ? .green : .blue)
            }
            
            // Boss详情（可选显示）
            if dungeonInfo.bossCount <= 4 {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(dungeonInfo.bossCount, 4)), spacing: 4) {
                    ForEach(dungeonInfo.bossProgress) { boss in
                        BossStatusView(boss: boss)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
    WeeklyCdStatusCard()
        .environmentObject(DungeonManager())
        .padding()
}