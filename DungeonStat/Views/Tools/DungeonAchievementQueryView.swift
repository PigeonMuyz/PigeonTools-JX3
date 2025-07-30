//
//  DungeonAchievementQueryView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/28.
//

import SwiftUI

struct DungeonAchievementQueryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cacheService = AchievementQueryCacheService.shared
    @FocusState private var isRoleNameFocused: Bool
    
    @State private var server = ""
    @State private var roleName = ""
    @State private var selectedCharacter: GameCharacter?
    @State private var showingAchievementAnalyzer = false
    @State private var showingCachedQuery = false
    @State private var selectedCachedQuery: AchievementQueryCache?
    @State private var isLoadingCache = false
    @State private var isLoadingQuery = false
    @State private var isShowingSheet = false
    
    private var canQuery: Bool {
        !server.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !roleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var cachedQueries: [AchievementQueryCache] {
        cacheService.getAllCachedQueries()
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("服务器")
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("请输入服务器名", text: $server)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            isRoleNameFocused = true
                        }
                }
                
                HStack {
                    Text("角色名")
                        .foregroundColor(.primary)
                    Spacer()
                    
                    if isLoadingQuery {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在查询...")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                    } else {
                        TextField("请输入角色名", text: $roleName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isRoleNameFocused)
                            .onSubmit {
                                if canQuery {
                                    performQuery()
                                }
                            }
                    }
                }
            } header: {
                Text("角色信息")
            } footer: {
                if isShowingSheet {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在打开统计页面...")
                            .foregroundColor(.green)
                    }
                } else if isLoadingQuery {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在准备查询副本资历统计...")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("输入服务器名和角色名，在键盘上按确定键查询")
                }
            }
            
            if !cachedQueries.isEmpty {
                Section {
                    if isShowingSheet {
                        HStack {
                            ProgressView()
                                .scaleEffect(1.0)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("正在打开统计页面...")
                                    .font(.body)
                                    .foregroundColor(.green)
                                if let selectedCache = selectedCachedQuery {
                                    Text("即将显示 \(selectedCache.displayName) 的统计数据")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if isLoadingCache {
                        HStack {
                            ProgressView()
                                .scaleEffect(1.0)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("正在加载缓存数据...")
                                    .font(.body)
                                    .foregroundColor(.blue)
                                if let selectedCache = selectedCachedQuery {
                                    Text("加载 \(selectedCache.displayName) 的统计数据")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    ForEach(cachedQueries) { cache in
                        Button {
                            loadCachedQuery(cache)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(cache.displayName)
                                            .foregroundColor(.primary)
                                            .font(.body)
                                        Spacer()
                                        Text(formatDate(cache.queryTime))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    
                                    HStack {
                                        Text("\(cache.dungeonData.count) 个副本")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Spacer()
                                        
                                        let totalAchievements = cache.dungeonData.reduce(0) { $0 + $1.totalAchievements }
                                        let completedAchievements = cache.dungeonData.reduce(0) { $0 + $1.completedAchievements }
                                        let completionRate = totalAchievements > 0 ? Double(completedAchievements) / Double(totalAchievements) * 100 : 0
                                        
                                        Text(String(format: "完成率 %.1f%%", completionRate))
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(isLoadingCache || isShowingSheet)
                        .opacity((isLoadingCache || isShowingSheet) ? 0.5 : 1.0)
                    }
                    .onDelete(perform: deleteCachedQueries)
                } header: {
                    Text("缓存数据")
                } footer: {
                    if !isLoadingCache && !isShowingSheet {
                        Text("点击查看已缓存的统计数据，左滑可删除")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("副本资历统计")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAchievementAnalyzer) {
            if let character = selectedCharacter {
                AchievementAnalyzerView(character: character)
            }
        }
        .onChange(of: showingAchievementAnalyzer) { _, isShowing in
            if !isShowing {
                // Sheet关闭时重置状态
                isShowingSheet = false
                selectedCachedQuery = nil
            }
        }
    }
    
    private func loadCachedQuery(_ cache: AchievementQueryCache) {
        selectedCachedQuery = cache
        isLoadingCache = true
        
        // 添加震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 添加适当延迟以显示加载效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoadingCache = false
            isShowingSheet = true
            
            let character = GameCharacter(
                server: cache.serverName,
                name: cache.roleName,
                school: "",
                bodyType: ""
            )
            selectedCharacter = character
            
            // 再稍等一下再显示sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingAchievementAnalyzer = true
            }
        }
    }
    
    private func performQuery() {
        isLoadingQuery = true
        isRoleNameFocused = false
        
        // 添加震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 添加适当延迟以显示加载效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoadingQuery = false
            isShowingSheet = true
            
            let character = GameCharacter(
                server: server.trimmingCharacters(in: .whitespacesAndNewlines),
                name: roleName.trimmingCharacters(in: .whitespacesAndNewlines),
                school: "",
                bodyType: ""
            )
            selectedCharacter = character
            
            // 再稍等一下再显示sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingAchievementAnalyzer = true
            }
        }
    }
    
    private func deleteCachedQueries(offsets: IndexSet) {
        for index in offsets {
            let query = cachedQueries[index]
            cacheService.deleteCachedQuery(query)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}