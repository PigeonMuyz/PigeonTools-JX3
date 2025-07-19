//
//  TeamRecruitView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
//

import SwiftUI

// MARK: - 团队招募主视图
struct TeamRecruitView: View {
    @StateObject private var recruitService = TeamRecruitService.shared
    @StateObject private var settings = TeamRecruitSettings.shared
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var tagsCache: [String: [ProfessionTag]] = [:]
    @State private var searchWorkItem: DispatchWorkItem?
    @EnvironmentObject var dungeonManager: DungeonManager
    
    
    // 过滤后的招募信息（无状态修改版）
    private var filteredRecruits: [TeamRecruitItem] {
        let items = recruitService.recruitItems
        
        return items.filter { item in
            // 排除金团
            if settings.filterGoldTeams {
                let tags = getTagsWithoutCache(for: item)
                let tagLabels = tags.map { $0.label }
                if tagLabels.contains("金团") {
                    return false
                }
            }
            
            // 搜索筛选
            if !debouncedSearchText.isEmpty && debouncedSearchText.count >= 2 {
                let searchLower = debouncedSearchText.lowercased()
                
                // 文本匹配
                let textMatch = item.matchesSearchText(debouncedSearchText)
                
                // 标签匹配
                let tags = getTagsWithoutCache(for: item)
                let tagLabels = tags.map { $0.label }
                let tagMatch = tagLabels.contains { tag in
                    tag.lowercased().contains(searchLower)
                }
                
                return textMatch || tagMatch
            }
            
            return true
        }
    }
    
    var body: some View {
        Group {
            if recruitService.isLoading {
                loadingView
            } else if let errorMessage = recruitService.errorMessage {
                errorView(errorMessage)
            } else if recruitService.recruitItems.isEmpty {
                emptyView
            } else {
                recruitContentView
            }
        }
        .navigationTitle("团队招募")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    refreshRecruits()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(recruitService.isLoading ? 360 : 0))
                        .animation(recruitService.isLoading ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: recruitService.isLoading)
                }
                .disabled(recruitService.isLoading || dungeonManager.selectedCharacter == nil)
            }
        }
        .searchable(text: $searchText, prompt: "搜索活动、团长、内容或职业")
        .onChange(of: searchText) { oldValue, newValue in
            // 取消之前的搜索任务
            searchWorkItem?.cancel()
            
            // 如果搜索文本为空，立即清空
            if newValue.isEmpty {
                debouncedSearchText = ""
                return
            }
            
            // 如果搜索文本长度小于2，不执行搜索
            if newValue.count < 2 {
                return
            }
            
            // 创建新的搜索任务
            let workItem = DispatchWorkItem {
                debouncedSearchText = newValue
            }
            
            searchWorkItem = workItem
            // 延迟1.5秒执行搜索，减少频繁搜索
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
        }
        .onAppear {
            // 如果有选中的角色，默认使用其服务器
            if dungeonManager.selectedCharacter != nil {
                refreshRecruits()
            }
        }
        .onDisappear {
            // 取消待执行的搜索任务
            searchWorkItem?.cancel()
        }
    }
    
    // MARK: - 视图组件
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在加载团队招募信息...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                refreshRecruits()
            }
            .buttonStyle(.borderedProminent)
            .disabled(dungeonManager.selectedCharacter == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))     
                .foregroundColor(.secondary)
            
            Text("暂无团队招募信息")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("请选择角色并点击刷新按钮获取最新团队招募信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var recruitContentView: some View {
        List(filteredRecruits) { item in
            TeamRecruitRow(item: item, tags: getCachedTags(for: item))
                .id(item.id)
        }
        .refreshable {
            refreshRecruits()
        }
    }
    
    // MARK: - 辅助方法
    private func refreshRecruits() {
        guard let selectedCharacter = dungeonManager.selectedCharacter else { return }
        // 清除缓存
        tagsCache.removeAll()
        recruitService.fetchTeamRecruit(server: selectedCharacter.server)
    }
    
    // 获取缓存的标签（安全版）
    private func getCachedTags(for item: TeamRecruitItem) -> [ProfessionTag] {
        let cacheKey = String(item.content.hashValue)
        
        if let cachedTags = tagsCache[cacheKey] {
            return cachedTags
        }
        
        let tags = item.extractedTags
        
        // 使用DispatchQueue延迟更新缓存，避免在视图更新期间修改状态
        DispatchQueue.main.async {
            self.tagsCache[cacheKey] = tags
        }
        
        return tags
    }
    
    // 不使用缓存的标签获取（用于过滤器）
    private func getTagsWithoutCache(for item: TeamRecruitItem) -> [ProfessionTag] {
        return item.extractedTags
    }
}

// MARK: - 团队招募行视图
struct TeamRecruitRow: View {
    let item: TeamRecruitItem
    let tags: [ProfessionTag]
    
    // 优化性能：缓存计算结果
    private var memberStatusColor: Color {
        item.isFull ? .red : .blue
    }
    
    private var memberStatusBackground: Color {
        item.isFull ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部：活动名称和人数状态
            HStack {
                Text(item.activity)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 已满标签（放在人数左侧）
                    if item.isFull {
                        Text("已满")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(6)
                    }
                    
                    // 人数状态
                    Text(item.memberStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(memberStatusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(memberStatusBackground)
                        )
                }
            }
            
            // 中部：团长信息
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(item.leader)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // 招募内容
            if !item.content.isEmpty {
                Text(item.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            
            // 职业标签（统一放在下方）
            if !tags.isEmpty {
                LazyVGrid(columns: tagGridColumns, alignment: .leading, spacing: 4) {
                    ForEach(tags) { tag in
                        TagView(tag: tag)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(item.isFull ? Color.gray.opacity(0.05) : Color.clear)
    }
    
    // 缓存网格列配置
    private let tagGridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
}

// MARK: - 标签视图组件
struct TagView: View {
    let tag: ProfessionTag
    
    var body: some View {
        Text(tag.label)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tag.color)
            .cornerRadius(8)
    }
}
