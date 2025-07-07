//
//  AchievementAnalyzerView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import SwiftUI

// MARK: - 副本资历数据模型
struct DungeonAchievementData: Identifiable {
    let id = UUID()
    let dungeonName: String
    let difficulty: String
    let originalStats: DungeonStats
    let calibratedStats: DungeonStats
    let isCalibrated: Bool
    let achievements: [ProcessedAchievement]
    let completionRate: Double
    let potential: Int
    let priority: Priority
    
    enum Priority: String, CaseIterable {
        case high = "高优先级"
        case medium = "中优先级"
        case low = "低优先级"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .high: return "flame.fill"
            case .medium: return "clock.fill"
            case .low: return "checkmark.circle.fill"
            }
        }
    }
}

// MARK: - 副本资历统计视图
struct AchievementAnalyzerView: View {
    let character: GameCharacter
    @Environment(\.dismiss) private var dismiss
    
    @State private var achievementData: AchievementData?
    @State private var processedAchievementData: ProcessedAchievementData?
    @State private var validationResult: ValidationResult?
    @State private var isLoading = false
    @State private var isLoadingCalibrationData = false
    @State private var errorMessage: String?
    @State private var dungeonAchievements: [DungeonAchievementData] = []
    @State private var completionThreshold: Double = 80
    @State private var cacheTimestamp: Date?
    @State private var showingAchievementDetail = false
    @State private var selectedAchievementData: DungeonAchievementData?
    @State private var hasLoaded = false
    @State private var searchText = ""
    @State private var showingCacheOptions = false
    
    private var filteredAchievements: [DungeonAchievementData] {
        let thresholdFiltered = dungeonAchievements.filter { achievement in
            achievement.completionRate < completionThreshold || achievement.calibratedStats.pieces.speed == 0
        }
        
        let searchFiltered = searchText.isEmpty ? thresholdFiltered : thresholdFiltered.filter { achievement in
            achievement.dungeonName.localizedCaseInsensitiveContains(searchText) ||
            achievement.difficulty.localizedCaseInsensitiveContains(searchText) ||
            achievement.achievements.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return searchFiltered.sorted { first, second in
            if first.priority != second.priority {
                return first.priority.rawValue < second.priority.rawValue
            }
            return first.potential > second.potential
        }
    }
    
    private var totalPotentialSeniority: Int {
        filteredAchievements.reduce(0) { $0 + $1.potential }
    }
    
    private var completionStats: (completed: Int, total: Int) {
        let allAchievements = filteredAchievements.flatMap { $0.achievements }
        return AchievementCompletionService.shared.getCompletionStats(for: allAchievements)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if let data = achievementData {
                    contentView(data: data)
                } else {
                    emptyView
                }
            }
            .navigationTitle("副本资历统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("校验数据") {
                            if AchievementDataService.shared.hasCachedData() {
                                showingCacheOptions = true
                            } else {
                                fetchCalibrationData(useCache: false)
                            }
                        }
                        .disabled(isLoadingCalibrationData)
                        
                        Button("刷新") {
                            refreshData()
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .onAppear {
                // 只在第一次加载或者有错误时才加载数据
                if !hasLoaded || achievementData == nil {
                    errorMessage = nil
                    loadData()
                }
            }
            .searchable(text: $searchText, prompt: "搜索副本、难度或成就名称")
            .sheet(isPresented: $showingAchievementDetail) {
                if let selectedData = selectedAchievementData {
                    AchievementDetailView(achievementData: selectedData)
                }
            }
            .confirmationDialog("选择数据源", isPresented: $showingCacheOptions, titleVisibility: .visible) {
                Button("使用本地缓存") {
                    fetchCalibrationData(useCache: true)
                }
                Button("重新获取网络数据") {
                    fetchCalibrationData(useCache: false)
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("检测到本地已有成就数据，请选择使用方式")
            }
        }
    }
    
    // MARK: - 子视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载资历数据中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                // 清除错误状态并重新加载数据
                errorMessage = nil
                loadData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("点击刷新获取数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("获取数据") {
                loadData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 如果还没有加载过，自动加载数据（先尝试缓存）
            if !hasLoaded {
                loadData()
            }
        }
    }
    
    private func contentView(data: AchievementData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 角色信息卡片
                characterInfoCard
                
                // 缓存状态信息
                if let cacheTimestamp = cacheTimestamp {
                    cacheInfoCard(timestamp: cacheTimestamp)
                }
                
                // 校验状态信息
                calibrationStatusCard
                
                // 完成度阈值设置
                thresholdCard
                
                // 统计总览
                statisticsOverview
                
                // 建议列表
                suggestionsSection
            }
            .padding()
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
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func cacheInfoCard(timestamp: Date) -> some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.green)
            
            Text("数据缓存时间：\(formatDate(timestamp))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("永久缓存")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.green)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var calibrationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isLoadingCalibrationData ? "arrow.clockwise" : "checkmark.seal.fill")
                    .foregroundColor(getCalibrationStatusColor())
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据校验状态")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(getCalibrationStatusText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let result = validationResult {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(result.totalCalibratedCount)/\(result.totalOriginalCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(getCalibrationStatusColor())
                        
                        Text("校验副本数/总副本数")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f%%校验率", result.calibrationRate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isLoadingCalibrationData {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let processedData = processedAchievementData {
                HStack {
                    Text("成就数据: \(processedData.totalAchievements)个成就")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let cacheDate = AchievementDataService.shared.getCacheDate() {
                        Text("更新: \(formatDate(cacheDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(getCalibrationBackgroundColor())
        .cornerRadius(12)
    }
    
    private func getCalibrationStatusColor() -> Color {
        if isLoadingCalibrationData {
            return .blue
        } else if validationResult != nil {
            return .green
        } else if AchievementDataService.shared.hasCachedData() {
            return .orange
        } else {
            return .gray
        }
    }
    
    private func getCalibrationBackgroundColor() -> Color {
        if validationResult != nil {
            return .green.opacity(0.1)
        } else if AchievementDataService.shared.hasCachedData() {
            return .orange.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private func getCalibrationStatusText() -> String {
        if isLoadingCalibrationData {
            return "正在获取成就数据进行校验..."
        } else if validationResult != nil {
            return "数据已校验，显示准确的资历和成就信息"
        } else if AchievementDataService.shared.hasCachedData() {
            return "有本地成就数据，点击\"校验数据\"进行校验"
        } else {
            return "点击\"校验数据\"获取最新成就数据"
        }
    }
    
    private var thresholdCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.orange)
                
                Text("完成度阈值设置")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(completionThreshold))%")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
            }
            
            Slider(value: $completionThreshold, in: 0...100, step: 10)
                .accentColor(.orange)
            
            Text("显示完成度低于 \(Int(completionThreshold))% 的副本或未开始的副本")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsOverview: some View {
        HStack(spacing: 0) {
            StatisticItem(
                title: "符合条件",
                value: "\(filteredAchievements.count)",
                subtitle: "个副本",
                color: .blue,
                icon: "list.bullet"
            )
            
            Divider()
                .frame(height: 40)
            
            StatisticItem(
                title: "可获得资历",
                value: "\(totalPotentialSeniority)",
                subtitle: "点",
                color: .green,
                icon: "star.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            StatisticItem(
                title: "已完成成就",
                value: "\(completionStats.completed)/\(completionStats.total)",
                subtitle: "个",
                color: .purple,
                icon: "checkmark.circle.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            StatisticItem(
                title: "高优先级",
                value: "\(filteredAchievements.filter { $0.priority == .high }.count)",
                subtitle: "个",
                color: .red,
                icon: "flame.fill"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("提升建议")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if filteredAchievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("恭喜！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("在当前阈值下，没有需要提升的副本")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementSuggestionCard(achievement: achievement)
                            .onTapGesture {
                                selectedAchievementData = achievement
                                showingAchievementDetail = true
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - 数据加载
    private func loadData() {
        // 首先尝试从缓存加载
        if let cachedData = AchievementCacheService.shared.loadCache(
            for: character.server,
            name: character.name
        ) {
            self.achievementData = cachedData
            self.cacheTimestamp = AchievementCacheService.shared.getCacheTimestamp(
                for: character.server,
                name: character.name
            )
            self.hasLoaded = true
            
            // 检查是否有成就数据进行校验
            if let processedData = AchievementDataService.shared.getCachedAchievementData() {
                self.processedAchievementData = processedData
                performValidation(achievementData: cachedData, processedData: processedData)
            } else {
                processData(cachedData)
            }
        } else {
            // 如果没有缓存，则从网络加载
            refreshData()
        }
    }
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await JX3APIService.shared.fetchAchievementData(
                    server: character.server,
                    name: character.name
                )
                
                await MainActor.run {
                    // 保存到缓存
                    AchievementCacheService.shared.saveCache(
                        data: data,
                        for: character.server,
                        name: character.name
                    )
                    
                    self.achievementData = data
                    self.cacheTimestamp = Date()
                    self.isLoading = false
                    self.hasLoaded = true
                    processData(data)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func processData(_ data: AchievementData) {
        var achievements: [DungeonAchievementData] = []
        
        for (dungeonName, difficulties) in data.data.dungeons {
            for (difficulty, originalStats) in difficulties {
                // 检查是否有校验结果
                var actualStats = originalStats
                var calibratedStats = originalStats
                var isCalibrated = false
                var achievementsList: [ProcessedAchievement] = []
                
                if let validationResult = validationResult,
                   let validatedDungeonStats = validationResult.validatedDungeons[dungeonName]?[difficulty] {
                    actualStats = validatedDungeonStats.calibrated
                    calibratedStats = validatedDungeonStats.calibrated
                    isCalibrated = validatedDungeonStats.isCalibrated
                    achievementsList = validatedDungeonStats.achievements
                } else {
                    actualStats = originalStats
                    calibratedStats = originalStats
                }
                
                let completionRate = actualStats.pieces.total > 0 
                    ? Double(actualStats.pieces.speed) / Double(actualStats.pieces.total) * 100 
                    : 0
                
                let potential = actualStats.seniority.total - actualStats.seniority.speed
                
                // 确定优先级
                let priority: DungeonAchievementData.Priority
                if actualStats.pieces.speed == 0 {
                    priority = .high
                } else if completionRate < 30 {
                    priority = .high
                } else if completionRate < 60 {
                    priority = .medium
                } else {
                    priority = .low
                }
                
                achievements.append(DungeonAchievementData(
                    dungeonName: dungeonName,
                    difficulty: difficulty,
                    originalStats: originalStats,
                    calibratedStats: calibratedStats,
                    isCalibrated: isCalibrated,
                    achievements: achievementsList,
                    completionRate: completionRate,
                    potential: potential,
                    priority: priority
                ))
            }
        }
        
        self.dungeonAchievements = achievements
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - 成就数据校验
    private func fetchCalibrationData(useCache: Bool) {
        isLoadingCalibrationData = true
        
        Task {
            do {
                let processedData: ProcessedAchievementData
                
                if useCache, let cachedData = AchievementDataService.shared.getCachedAchievementData() {
                    processedData = cachedData
                } else {
                    processedData = try await AchievementDataService.shared.fetchAndProcessAchievementData()
                }
                
                await MainActor.run {
                    guard processedData.totalAchievements > 0 else {
                        self.isLoadingCalibrationData = false
                        self.errorMessage = "校验数据为空，请重试"
                        return
                    }
                    
                    self.processedAchievementData = processedData
                    self.isLoadingCalibrationData = false
                    
                    // 如果有成就数据，立即进行校验
                    if let achievementData = self.achievementData {
                        performValidation(achievementData: achievementData, processedData: processedData)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingCalibrationData = false
                    print("校验数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performValidation(achievementData: AchievementData, processedData: ProcessedAchievementData) {
        let result = AchievementDataService.shared.validateAchievementData(achievementData, with: processedData)
        self.validationResult = result
        
        // 重新处理数据以使用校验结果
        processData(achievementData)
    }
}

// MARK: - 统计项视图
struct StatisticItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 成就建议卡片
struct AchievementSuggestionCard: View {
    let achievement: DungeonAchievementData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.dungeonName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(achievement.difficulty)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: achievement.priority.icon)
                        .font(.caption)
                    Text(achievement.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(achievement.priority.color)
                .cornerRadius(8)
            }
            
            // 校验状态指示器
            if achievement.isCalibrated {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("已校验")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if achievement.achievements.count > 0 {
                        Text("\(achievement.achievements.count)个成就")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 4)
            }
            
            // 进度信息
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("完成进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(achievement.calibratedStats.pieces.speed)/\(achievement.calibratedStats.pieces.total)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前资历")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(achievement.calibratedStats.seniority.speed)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("可获得")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("+\(achievement.potential)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("完成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", achievement.completionRate))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(achievement.completionRate < 30 ? .red : 
                                         achievement.completionRate < 60 ? .orange : .green)
                }
            }
            
            // 进度条
            ProgressView(value: achievement.completionRate / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: 
                    achievement.completionRate < 30 ? .red : 
                    achievement.completionRate < 60 ? .orange : .green))
                .frame(height: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.priority.color.opacity(0.3), lineWidth: 1)
        )
    }
}