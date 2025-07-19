//
//  DungeonAchievementDetailView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/8.
//

import SwiftUI

struct DungeonAchievementDetailView: View {
    let character: GameCharacter
    @Environment(\.dismiss) private var dismiss
    @StateObject private var detailService = DungeonAchievementDetailService.shared
    
    @State private var selectedDungeonName = ""
    @State private var queryResult: DungeonAchievementQueryCache?
    @State private var isQuerying = false
    @State private var errorMessage: String?
    @State private var showingQueryHistory = false
    @State private var searchText = ""
    
    private var recommendedDungeons: [String] {
        detailService.getRecommendedDungeons(for: character)
    }
    
    private var filteredDungeons: [String] {
        if searchText.isEmpty {
            return recommendedDungeons
        } else {
            return recommendedDungeons.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var filteredAchievements: [AchievementDetail] {
        guard let result = queryResult else { return [] }
        
        if searchText.isEmpty {
            return result.achievements
        } else {
            return result.achievements.filter { achievement in
                achievement.name.localizedCaseInsensitiveContains(searchText) ||
                achievement.desc.localizedCaseInsensitiveContains(searchText) ||
                achievement.detail.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if queryResult == nil {
                    dungeonSelectionView
                } else {
                    achievementResultView
                }
            }
            .navigationTitle("副本成就详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("历史查询") {
                            showingQueryHistory = true
                        }
                        
                        if queryResult != nil {
                            Button("重新查询") {
                                queryResult = nil
                                selectedDungeonName = ""
                                errorMessage = nil
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: queryResult == nil ? "搜索副本名称" : "搜索成就名称")
            .sheet(isPresented: $showingQueryHistory) {
                QueryHistoryView(character: character)
            }
        }
    }
    
    private var dungeonSelectionView: some View {
        VStack {
            // 角色信息卡片
            characterInfoCard
            
            // 统计信息
            statisticsCard
            
            // 副本选择
            dungeonSelectionSection
        }
    }
    
    private var characterInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(character.server) · \(character.school)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("副本成就查询")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("详细进度")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var statisticsCard: some View {
        let stats = detailService.getStatistics(for: character.server, name: character.name)
        
        return HStack(spacing: 0) {
            StatisticItem(
                title: "已查询",
                value: "\(stats.totalQueries)",
                subtitle: "个副本",
                color: .blue,
                icon: "magnifyingglass"
            )
            
            Divider()
                .frame(height: 40)
            
            StatisticItem(
                title: "未完成",
                value: "\(stats.totalUnfinished)",
                subtitle: "个成就",
                color: .orange,
                icon: "clock"
            )
            
            Divider()
                .frame(height: 40)
            
            StatisticItem(
                title: "总计",
                value: "\(stats.totalAchievements)",
                subtitle: "个成就",
                color: .green,
                icon: "list.bullet"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var dungeonSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.purple)
                Text("选择要查询的副本")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            
            if isQuerying {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("正在查询 \(selectedDungeonName) 的成就详情...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("查询失败")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("重试") {
                        queryDungeon(selectedDungeonName)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredDungeons, id: \.self) { dungeonName in
                            DungeonSelectionRow(
                                dungeonName: dungeonName,
                                character: character,
                                onTap: { queryDungeon(dungeonName) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var achievementResultView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 查询结果概览
                if let result = queryResult {
                    resultOverviewCard(result: result)
                }
                
                // 成就列表
                achievementListSection
            }
            .padding()
        }
    }
    
    private func resultOverviewCard(result: DungeonAchievementQueryCache) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.dungeonName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("查询时间: \(formatDate(result.queryTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("成就总数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(result.totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("已完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(result.totalCount - result.unfinishedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("未完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(result.unfinishedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("完成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let completionRate = result.totalCount > 0 ? Double(result.totalCount - result.unfinishedCount) / Double(result.totalCount) * 100 : 0
                    Text(String(format: "%.1f%%", completionRate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(completionRate >= 80 ? .green : completionRate >= 50 ? .orange : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var achievementListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.purple)
                Text("成就列表")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(filteredAchievements, id: \.id) { achievement in
                    AchievementDetailCard(achievement: achievement)
                }
            }
        }
    }
    
    private func queryDungeon(_ dungeonName: String) {
        selectedDungeonName = dungeonName
        isQuerying = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await detailService.queryDungeonAchievements(
                    server: character.server,
                    role: character.name,
                    dungeonName: dungeonName
                )
                
                await MainActor.run {
                    self.queryResult = result
                    self.isQuerying = false
                    
                    // 显示查询结果提示
                    if result.unfinishedCount > 0 {
                        print("查询完成：\(dungeonName) 有 \(result.unfinishedCount) 个未完成成就")
                    } else {
                        print("查询完成：\(dungeonName) 所有成就已完成")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isQuerying = false
                    self.errorMessage = error.localizedDescription
                }
            }
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

// MARK: - 副本选择行
struct DungeonSelectionRow: View {
    let dungeonName: String
    let character: GameCharacter
    let onTap: () -> Void
    
    @StateObject private var detailService = DungeonAchievementDetailService.shared
    
    private var cachedQuery: DungeonAchievementQueryCache? {
        detailService.getCachedQuery(server: character.server, name: character.name, dungeonName: dungeonName)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dungeonName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if let cached = cachedQuery {
                    Text("上次查询: \(formatDate(cached.queryTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("未查询")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let cached = cachedQuery {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(cached.totalCount - cached.unfinishedCount)/\(cached.totalCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("已完成")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
        .onTapGesture {
            onTap()
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

// MARK: - 成就详情卡片
struct AchievementDetailCard: View {
    let achievement: AchievementDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: achievement.icon)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "star.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(achievement.desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: achievement.isFinished ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(achievement.isFinished ? .green : .orange)
                        
                        Text(achievement.isFinished ? "已完成" : "未完成")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(achievement.isFinished ? .green : .orange)
                    }
                    
                    if achievement.rewardPoint > 0 {
                        Text("\(achievement.rewardPoint) 分")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if achievement.type != "simple" {
                HStack {
                    Text("进度: \(achievement.currentValue)/\(achievement.triggerValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if achievement.triggerValue > 0 {
                        ProgressView(value: Double(achievement.currentValue) / Double(achievement.triggerValue))
                            .frame(width: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: achievement.isFinished ? .green : .blue))
                    }
                }
            }
            
            if !achievement.detail.isEmpty && achievement.detail != achievement.desc {
                Text(achievement.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(achievement.isFinished ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 查询历史视图
struct QueryHistoryView: View {
    let character: GameCharacter
    @Environment(\.dismiss) private var dismiss
    @StateObject private var detailService = DungeonAchievementDetailService.shared
    
    private var queries: [DungeonAchievementQueryCache] {
        detailService.getQueriesForCharacter(server: character.server, name: character.name)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(queries, id: \.id) { query in
                    QueryHistoryRow(query: query)
                }
                .onDelete(perform: deleteQueries)
            }
            .navigationTitle("查询历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteQueries(offsets: IndexSet) {
        for index in offsets {
            let query = queries[index]
            detailService.deleteCachedQuery(query)
        }
    }
}

// MARK: - 查询历史行
struct QueryHistoryRow: View {
    let query: DungeonAchievementQueryCache
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(query.dungeonName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatDate(query.queryTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("总计: \(query.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("已完成: \(query.totalCount - query.unfinishedCount)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("未完成: \(query.unfinishedCount)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    let completionRate = query.totalCount > 0 ? Double(query.totalCount - query.unfinishedCount) / Double(query.totalCount) * 100 : 0
                    Text(String(format: "%.1f%%", completionRate))
                        .font(.caption)
                        .foregroundColor(completionRate >= 80 ? .green : completionRate >= 50 ? .orange : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}
