//
//  WeeklyCdStatusCard.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/17.
//

import SwiftUI

struct WeeklyCdStatusCard: View {
    let refreshTrigger: Int
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var teamCdData: TeamCdData?
    @State private var isLoading = false
    @State private var isRefreshing = false  // 用于区分首次加载和刷新
    @State private var errorMessage: String?
    @State private var consecutiveFailures = 0
    @State private var lastLoadedCharacter: GameCharacter?
    @State private var lastRefreshTime: Date?
    
    init(refreshTrigger: Int = 0) {
        self.refreshTrigger = refreshTrigger
    }
    
    var body: some View {
        Group {
            // 如果正在加载且没有数据，显示loading
            if isLoading && teamCdData == nil {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在查询副本状态...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            }
            // 如果有数据，显示数据（可能带有刷新动画）
            else if let teamCdData = teamCdData {
                VStack(spacing: 8) {
                    ZStack {
                        dungeonCdContent(teamCdData)
                            .opacity(isRefreshing ? 0.5 : 1.0)
                        
                        // 刷新时在数据上显示loading
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
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
        .onAppear {
            // 每次出现在屏幕上都尝试刷新
            if let selectedCharacter = dungeonManager.selectedCharacter {
                Task {
                    await autoRefreshIfNeeded(for: selectedCharacter)
                }
            }
        }
        .onChange(of: dungeonManager.selectedCharacter) { _, newCharacter in
            if let character = newCharacter {
                // 切换角色时，如果是新角色则加载，否则刷新
                Task {
                    if lastLoadedCharacter?.id != character.id {
                        // 新角色，清空数据并重新加载
                        await MainActor.run {
                            teamCdData = nil
                            consecutiveFailures = 0
                        }
                        await loadTeamCdData(for: character, isRefresh: false)
                    } else {
                        // 同一角色，刷新数据
                        await loadTeamCdData(for: character, isRefresh: true)
                    }
                }
            } else {
                teamCdData = nil
                errorMessage = nil
                lastLoadedCharacter = nil
                consecutiveFailures = 0
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            if let selectedCharacter = dungeonManager.selectedCharacter {
                Task {
                    // 手动刷新时，如果有数据则显示刷新状态
                    await loadTeamCdData(for: selectedCharacter, isRefresh: teamCdData != nil)
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
            VStack(spacing: 12) {
                ForEach(data.data) { dungeonInfo in
                    DungeonCdRow(dungeonInfo: dungeonInfo)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func loadTeamCdData(for character: GameCharacter, isRefresh: Bool) async {
        await MainActor.run {
            if isRefresh {
                isRefreshing = true
            } else {
                isLoading = true
            }
            errorMessage = nil
        }
        
        var lastError: Error?
        
        for _ in 0..<2 {
            do {
                let data = try await JX3APIService.shared.fetchTeamCdList(
                    server: character.server,
                    name: character.name
                )
                
                await MainActor.run {
                    // 检查数据是否有变化
                    let hasChanges = !isDataEqual(old: self.teamCdData, new: data)
                    
                    if hasChanges || !isRefresh {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.teamCdData = data
                        }
                    }
                    
                    self.lastLoadedCharacter = character
                    self.lastRefreshTime = Date()
                    self.isLoading = false
                    self.isRefreshing = false
                    self.consecutiveFailures = 0
                }
                return
            } catch {
                lastError = error
            }
        }
        
        await MainActor.run {
            self.errorMessage = lastError?.localizedDescription ?? "未知错误"
            self.isLoading = false
            self.isRefreshing = false
            self.consecutiveFailures = min(self.consecutiveFailures + 1, 3)
        }
    }
    
    // 自动刷新逻辑
    private func autoRefreshIfNeeded(for character: GameCharacter) async {
        if teamCdData == nil && consecutiveFailures > 0 {
            return
        }
        // 如果角色变了，或者没有数据，或者距离上次刷新超过30秒，则刷新
        let shouldRefresh = lastLoadedCharacter?.id != character.id ||
                           teamCdData == nil ||
                           (lastRefreshTime.map { Date().timeIntervalSince($0) > 30 } ?? true)
        
        if shouldRefresh {
            let isRefresh = teamCdData != nil && lastLoadedCharacter?.id == character.id
            await loadTeamCdData(for: character, isRefresh: isRefresh)
        }
    }
    
    // 比较两个TeamCdData是否相同
    private func isDataEqual(old: TeamCdData?, new: TeamCdData) -> Bool {
        guard let old = old else { return false }
        
        // 比较副本数量
        if old.data.count != new.data.count { return false }
        
        // 比较每个副本的进度
        for (oldDungeon, newDungeon) in zip(old.data, new.data) {
            if oldDungeon.mapName != newDungeon.mapName ||
               oldDungeon.bossFinished != newDungeon.bossFinished ||
               oldDungeon.bossCount != newDungeon.bossCount {
                return false
            }
        }
        
        return true
    }
}

struct DungeonCdRow: View {
    let dungeonInfo: DungeonCdInfo
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要的副本信息行
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
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
                                .foregroundColor(.primary)
                            
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
                    
                    // 展开指示器
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 展开的boss详情
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 12)
                    
                    if !dungeonInfo.bossProgress.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(dungeonInfo.bossProgress.count, 4)), spacing: 8) {
                            ForEach(dungeonInfo.bossProgress) { boss in
                                BossStatusView(boss: boss)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    } else {
                        Text("暂无boss信息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct BossStatusView: View {
    let boss: BossProgress
    
    var body: some View {
        VStack(spacing: 4) {
            // Boss图标或状态
            ZStack {
                Circle()
                    .fill(boss.finished ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: boss.finished ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 16))
                    .foregroundColor(boss.finished ? .green : .gray)
            }
            
            // Boss名称
            Text(boss.name)
                .font(.caption2)
                .foregroundColor(boss.finished ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fontWeight(boss.finished ? .medium : .regular)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WeeklyCdStatusCard(refreshTrigger: 0)
        .environmentObject(DungeonManager())
        .padding()
}
