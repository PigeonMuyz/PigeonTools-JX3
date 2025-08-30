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
    @State private var filteredRecruitIds: Set<UUID> = []
    @State private var isFiltering = false
    @EnvironmentObject var dungeonManager: DungeonManager
    
    
    // 优化后的过滤逻辑
    private var displayedRecruits: [TeamRecruitItem] {
        let items = recruitService.recruitItems
        
        // 如果正在过滤，显示当前状态
        if isFiltering {
            // 在过滤时继续显示已有的结果
            if !filteredRecruitIds.isEmpty {
                return items.filter { filteredRecruitIds.contains($0.id) }
            }
            return items
        }
        
        // 使用缓存的过滤结果（如果有搜索文本）
        if !debouncedSearchText.isEmpty {
            return items.filter { filteredRecruitIds.contains($0.id) }
        }
        
        // 没有搜索文本时，只应用基本过滤（金团和浪客行）
        return items.filter { item in
            let tags = getCachedTags(for: item)
            let tagLabels = tags.map { $0.label }
            
            if settings.filterGoldTeams && tagLabels.contains("金团") {
                return false
            }
            
            if settings.filterPioneerTeams && tagLabels.contains("浪客行") {
                return false
            }
            
            return true
        }
    }
    
    // 异步过滤方法
    private func performFiltering() {
        isFiltering = true
        
        Task {
            let searchText = debouncedSearchText
            let items = recruitService.recruitItems
            let shouldFilterGold = settings.filterGoldTeams
            let shouldFilterPioneer = settings.filterPioneerTeams
            let enableSubsidySearch = settings.enableSubsidySearch
            let enableProfessionSearch = settings.enableProfessionSearch
            
            // 在后台线程执行过滤
            let filtered = await Task.detached(priority: .userInitiated) {
                items.compactMap { item -> UUID? in
                    let tags = self.getTagsWithoutCache(for: item)
                    let tagLabels = tags.map { $0.label }
                    
                    // 搜索过滤
                    if !searchText.isEmpty && searchText.count >= 2 {
                        let searchLower = searchText.lowercased()
                        
                        // 检查是否明确搜索金团或浪客行
                        let searchingForGold = searchLower.contains("金团") || searchLower.contains("金")
                        let searchingForPioneer = searchLower.contains("浪客行") || searchLower.contains("浪客")
                        
                        // 如果不是明确搜索金团/浪客行，应用过滤
                        if !searchingForGold && shouldFilterGold && tagLabels.contains("金团") {
                            return nil
                        }
                        
                        if !searchingForPioneer && shouldFilterPioneer && tagLabels.contains("浪客行") {
                            return nil
                        }
                        
                        // 检查文本匹配
                        let textMatch = item.matchesSearchText(searchText, 
                                                              enableSubsidySearch: enableSubsidySearch,
                                                              enableProfessionSearch: enableProfessionSearch)
                        let tagMatch = tagLabels.contains { tag in
                            tag.lowercased().contains(searchLower)
                        }
                        
                        if textMatch || tagMatch {
                            return item.id
                        } else {
                            return nil
                        }
                    }
                    
                    // 没有搜索文本时，只应用基本过滤
                    if shouldFilterGold && tagLabels.contains("金团") {
                        return nil
                    }
                    
                    if shouldFilterPioneer && tagLabels.contains("浪客行") {
                        return nil
                    }
                    
                    return item.id
                }
            }.value
            
            await MainActor.run {
                self.filteredRecruitIds = Set(filtered)
                self.isFiltering = false
            }
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
        .searchable(text: $searchText, prompt: "搜索活动、团长、职业（如奶歌）、TN补")
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
                self.performFiltering()
            }
            
            searchWorkItem = workItem
            // 延迟0.5秒执行搜索，优化响应速度
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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
        .onChange(of: settings.filterGoldTeams) { _, _ in
            // 过滤设置改变时重新过滤
            performFiltering()
        }
        .onChange(of: settings.filterPioneerTeams) { _, _ in
            // 过滤设置改变时重新过滤
            performFiltering()
        }
        .onChange(of: recruitService.recruitItems) { _, _ in
            // 数据更新时重新过滤
            performFiltering()
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
        List(displayedRecruits) { item in
            TeamRecruitRow(item: item, tags: getCachedTags(for: item))
                .id(item.id)
        }
        .refreshable {
            refreshRecruits()
        }
        .overlay(alignment: .top) {
            if isFiltering {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在筛选...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Material.regular)
                .cornerRadius(8)
                .padding(.top, 8)
            }
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
