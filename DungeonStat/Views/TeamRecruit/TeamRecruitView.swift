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
    @EnvironmentObject var dungeonManager: DungeonManager
    
    // 过滤后的招募信息
    private var filteredRecruits: [TeamRecruitItem] {
        var items = recruitService.recruitItems
        
        // 首先应用金团过滤
        if settings.filterGoldTeams && !settings.showGoldTeamsInSearch {
            items = items.filter { !$0.isGoldTeam }
        }
        
        // 如果没有搜索文本，返回过滤后的全部结果
        guard !searchText.isEmpty else {
            return items
        }
        
        // 应用搜索过滤
        return items.filter { item in
            // 基础搜索：活动名称、团长、内容
            let basicMatch = item.activity.localizedCaseInsensitiveContains(searchText) ||
                           item.leader.localizedCaseInsensitiveContains(searchText) ||
                           item.content.localizedCaseInsensitiveContains(searchText)
            
            // 如果基础搜索匹配，直接返回
            if basicMatch {
                return true
            }
            
            // 补贴搜索
            if settings.enableSubsidySearch && (searchText.lowercased().contains("补") || searchText.lowercased().contains("tn补")) {
                if item.hasSubsidy {
                    return true
                }
            }
            
            // 职业搜索
            if settings.enableProfessionSearch {
                if item.matchesProfession(searchText) {
                    return true
                }
            }
            
            return false
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
        .searchable(text: $searchText, prompt: "搜索活动、团长或内容")
        .onAppear {
            // 如果有选中的角色，默认使用其服务器
            if dungeonManager.selectedCharacter != nil {
                refreshRecruits()
            }
        }
    }
    
    
    // MARK: - 加载视图
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
    
    // MARK: - 错误视图
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
    
    // MARK: - 空数据视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无团队招募")
                .font(.headline)
            
            Text("当前没有找到团队招募信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 团队招募内容视图
    private var recruitContentView: some View {
        VStack(spacing: 0) {
            // 团队列表
            List(filteredRecruits) { item in
                TeamRecruitRow(item: item)
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                refreshRecruits()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 辅助方法
    private func refreshRecruits() {
        guard let selectedCharacter = dungeonManager.selectedCharacter else { return }
        recruitService.fetchTeamRecruit(server: selectedCharacter.server)
    }
    
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 团队招募行视图
struct TeamRecruitRow: View {
    let item: TeamRecruitItem
    
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
                    // 人数状态
                    Text(item.memberStatus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(item.isFull ? .red : .blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.isFull ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                    
                    // 仅显示满员状态
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
                    
                    // 显示金团标识
                    if item.isGoldTeam {
                        Text("金团")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                    
                    // 显示补贴标识
                    if let subsidyInfo = item.subsidyInfo {
                        Text(subsidyInfo)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(6)
                    }
                }
            }
            
            // 中部：团长信息
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("\(item.leader)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // 底部：招募内容
            if !item.content.isEmpty {
                Text(item.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(item.isFull ? Color.gray.opacity(0.05) : Color.clear)
    }
}
    