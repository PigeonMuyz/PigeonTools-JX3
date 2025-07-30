//
//  AchievementAnalyzerView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import SwiftUI
import SafariServices

// MARK: - 副本资历数据模型
struct DungeonAchievementData: Identifiable {
    let dungeonName: String
    let difficulty: String
    let originalStats: DungeonStats
    let calibratedStats: DungeonStats
    let isCalibrated: Bool
    let achievements: [ProcessedAchievement]
    let completionRate: Double
    let potential: Int
    let priority: Priority
    
    var id: String {
        return "\(dungeonName)-\(difficulty)"
    }
    
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
        
        var sortOrder: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
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
    
    private var userMarkedStats: (userMarked: Int, total: Int) {
        let allAchievements = filteredAchievements.flatMap { $0.achievements }
        let userMarkedCount = allAchievements.filter { AchievementCompletionService.shared.isAchievementCompleted($0.id) }.count
        return (userMarked: userMarkedCount, total: allAchievements.count)
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
                title: "用户标记",
                value: "\(userMarkedStats.userMarked)/\(userMarkedStats.total)",
                subtitle: "个",
                color: .cyan,
                icon: "person.crop.circle.fill.badge.checkmark"
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
                        AchievementSuggestionCard(achievement: achievement, character: character)
                    }
                }
            }
        }
    }
    
    // MARK: - 数据加载
    private func loadData() {
        // 首先尝试从缓存加载用户资历数据
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
            
            // 优先使用JX3Box成就数据缓存进行校验
            if let processedData = AchievementDataService.shared.getCachedAchievementData() {
                self.processedAchievementData = processedData
                performValidation(achievementData: cachedData, processedData: processedData)
            } else {
                processData(cachedData)
            }
        } else {
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
                    
                    // 如果有JX3Box成就数据缓存，自动进行校验
                    if let processedData = AchievementDataService.shared.getCachedAchievementData() {
                        self.processedAchievementData = processedData
                        performValidation(achievementData: data, processedData: processedData)
                    } else {
                        processData(data)
                    }
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
        
        // 保存查询缓存
        saveQueryCache(achievements: achievements)
    }
    
    private func saveQueryCache(achievements: [DungeonAchievementData]) {
        // 转换数据格式用于缓存
        let dungeonSummaries = achievements.map { achievement in
            DungeonAchievementSummary(
                dungeonName: achievement.dungeonName,
                difficulty: achievement.difficulty,
                completionRate: achievement.completionRate,
                totalAchievements: achievement.achievements.count,
                completedAchievements: Int(achievement.completionRate / 100.0 * Double(achievement.achievements.count)),
                potential: achievement.potential,
                priority: achievement.priority.rawValue
            )
        }
        
        // 保存到缓存服务
        AchievementQueryCacheService.shared.saveQueryResult(
            server: character.server,
            roleName: character.name,
            dungeonData: dungeonSummaries
        )
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
    let character: GameCharacter
    @State private var showingDungeonDetailQuery = false
    @State private var isQuerying = false
    @State private var queryResult: DungeonAchievementQueryCache?
    @StateObject private var detailService = DungeonAchievementDetailService.shared
    
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
            
            // 显示查询状态
            if isQuerying {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在查询详细成就...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.top, 8)
            } else if let cached = getCachedQuery() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("上次查询: 未完成 \(cached.unfinishedCount) 个成就")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.priority.color.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            queryDungeonDetail()
        }
        .sheet(isPresented: $showingDungeonDetailQuery) {
            if let result = queryResult {
                DungeonDetailQueryResultView(
                    queryResult: result,
                    jx3boxAchievements: achievement.achievements
                )
            }
        }
    }
    
    private func getCachedQuery() -> DungeonAchievementQueryCache? {
        return detailService.getCachedQuery(
            server: character.server,
            name: character.name,
            dungeonName: achievement.dungeonName
        )
    }
    
    private func queryDungeonDetail() {
        isQuerying = true
        
        Task {
            do {
                // 处理副本名称，如果包含特殊字符，只取后半部分
                let processedDungeonName = self.processDungeonName(achievement.dungeonName)
                let result = try await detailService.queryDungeonAchievements(
                    server: character.server,
                    role: character.name,
                    dungeonName: processedDungeonName
                )
                
                await MainActor.run {
                    // 以JX3Box校验后的数据为准，只显示能匹配到的成就
                    let mergedResult = self.mergeWithJX3BoxData(apiResult: result)
                    self.queryResult = mergedResult
                    
                    // 标记所有匹配到的JX3Box成就为完成
                    self.markAllMatchedAchievementsAsCompleted(mergedResult: mergedResult)
                    
                    self.isQuerying = false
                    self.showingDungeonDetailQuery = true
                }
            } catch {
                await MainActor.run {
                    self.isQuerying = false
                    print("查询副本详情失败: \(error.localizedDescription)")
                    
                    // 如果API查询失败，直接使用JX3Box校验后的数据
                    if !achievement.achievements.isEmpty {
                        self.createJX3BoxOnlyResult()
                        self.showingDungeonDetailQuery = true
                    }
                }
            }
        }
    }
    
    // 处理副本名称，提取实际用于查询的名称
    private func processDungeonName(_ dungeonName: String) -> String {
        // 处理包含特殊字符的副本名，例：尘归海·巨冥湾 -> 巨冥湾
        let processedName: String
        if let dotIndex = dungeonName.firstIndex(of: "·") {
            processedName = String(dungeonName[dungeonName.index(after: dotIndex)...])
        } else {
            processedName = dungeonName
        }
        
        print("🏰 副本名称处理: \(dungeonName) -> \(processedName)")
        return processedName
    }
    
    // 合并API结果和JX3Box数据 - 以JX3Box为主
    private func mergeWithJX3BoxData(apiResult: DungeonAchievementQueryCache) -> DungeonAchievementQueryCache {
        let jx3boxAchievements = achievement.achievements
        
        print("🔍 开始合并数据：")
        print("  JX3Box成就数量: \(jx3boxAchievements.count)")
        print("  API返回成就数量: \(apiResult.achievements.count)")
        
        // 打印前几个成就名称用于调试
        print("  JX3Box成就前5个名称:")
        for (index, achievement) in jx3boxAchievements.prefix(5).enumerated() {
            print("    \(index + 1). \(achievement.name)")
        }
        
        print("  API返回成就前5个名称:")
        for (index, achievement) in apiResult.achievements.prefix(5).enumerated() {
            print("    \(index + 1). \(achievement.name)")
        }
        
        // 只保留能在JX3Box中匹配到的成就
        let mergedAchievements = jx3boxAchievements.compactMap { jx3boxAchievement in
            // 查找JX3API中同名成就 - 使用更智能的匹配逻辑
            if let apiAchievement = findMatchingAchievement(jx3boxAchievement: jx3boxAchievement, apiAchievements: apiResult.achievements) {
                print("    ✅ 成功匹配: JX3Box[\(jx3boxAchievement.name)] <-> API[\(apiAchievement.name)]")
                
                // 使用JX3API的真实完成状态，并同步更新JX3Box的状态
                let apiIsCompleted = apiAchievement.isFinished
                
                // 根据API的真实状态更新JX3Box的标记
                if apiIsCompleted {
                    AchievementCompletionService.shared.markAchievementAsCompleted(jx3boxAchievement.id)
                } else {
                    AchievementCompletionService.shared.markAchievementAsIncomplete(jx3boxAchievement.id)
                }
                
                return AchievementDetail(
                    id: apiAchievement.id,
                    icon: apiAchievement.icon,
                    likes: apiAchievement.likes,
                    name: apiAchievement.name,
                    class: apiAchievement.class,
                    subClass: apiAchievement.subClass,
                    desc: apiAchievement.desc,
                    detail: apiAchievement.detail,
                    maps: apiAchievement.maps,
                    isFinished: apiIsCompleted,
                    isFav: apiAchievement.isFav,
                    type: apiAchievement.type,
                    currentValue: apiAchievement.currentValue,
                    triggerValue: apiAchievement.triggerValue,
                    subset: apiAchievement.subset,
                    rewardItem: apiAchievement.rewardItem,
                    rewardPoint: apiAchievement.rewardPoint,
                    rewardPrefix: apiAchievement.rewardPrefix,
                    rewardSuffix: apiAchievement.rewardSuffix
                )
            } else {
                print("    ❌ 无法匹配: JX3Box[\(jx3boxAchievement.name)] 在API结果中未找到，使用JX3Box保存的状态")
                // JX3Box有但API没有的成就，使用JX3Box保存的状态（不修改）
                let isCompleted = AchievementCompletionService.shared.isAchievementCompleted(jx3boxAchievement.id)
                return AchievementDetail(
                    id: jx3boxAchievement.id,
                    icon: "",
                    likes: 0,
                    name: jx3boxAchievement.name,
                    class: "",
                    subClass: "",
                    desc: jx3boxAchievement.desc ?? "",
                    detail: jx3boxAchievement.note ?? "",
                    maps: [],
                    isFinished: isCompleted,
                    isFav: false,
                    type: "simple",
                    currentValue: isCompleted ? 1 : 0,
                    triggerValue: 1,
                    subset: [],
                    rewardItem: nil,
                    rewardPoint: jx3boxAchievement.point,
                    rewardPrefix: "",
                    rewardSuffix: ""
                )
            }
        }
        
        
        print("📊 合并结果: 成功匹配 \(mergedAchievements.count) 个成就")
        
        let unfinishedCount = mergedAchievements.filter { !$0.isFinished }.count
        
        return DungeonAchievementQueryCache(
            serverName: apiResult.serverName,
            roleName: apiResult.roleName,
            dungeonName: apiResult.dungeonName,
            achievements: mergedAchievements,
            queryTime: apiResult.queryTime,
            unfinishedCount: unfinishedCount,
            totalCount: mergedAchievements.count
        )
    }
    
    // 智能匹配成就
    private func findMatchingAchievement(jx3boxAchievement: ProcessedAchievement, apiAchievements: [AchievementDetail]) -> AchievementDetail? {
        // 1. 精确匹配
        if let exactMatch = apiAchievements.first(where: { $0.name == jx3boxAchievement.name }) {
            return exactMatch
        }
        
        // 2. 包含匹配（API包含JX3Box）
        if let containsMatch = apiAchievements.first(where: { $0.name.contains(jx3boxAchievement.name) }) {
            return containsMatch
        }
        
        // 3. 反向包含匹配（JX3Box包含API）
        if let reverseContainsMatch = apiAchievements.first(where: { jx3boxAchievement.name.contains($0.name) }) {
            return reverseContainsMatch
        }
        
        // 4. 特殊匹配规则：处理"挑战"类成就
        if jx3boxAchievement.name.contains("挑战") {
            // 移除"挑战"后的名称进行匹配
            let baseJX3Name = jx3boxAchievement.name.replacingOccurrences(of: "！挑战", with: "")
            if let challengeMatch = apiAchievements.first(where: { apiAch in
                return apiAch.name.contains(baseJX3Name) || baseJX3Name.contains(apiAch.name.replacingOccurrences(of: "！挑战", with: "").replacingOccurrences(of: "巨冥湾", with: ""))
            }) {
                return challengeMatch
            }
        }
        
        return nil
    }
    
    // 标记所有匹配到的JX3Box成就为完成（保持原有的JX3Box状态）
    private func markAllMatchedAchievementsAsCompleted(mergedResult: DungeonAchievementQueryCache) {
        // 不自动标记，保持JX3Box的原始状态
        // 这个函数现在什么都不做，只是保持接口兼容性
    }
    
    // 只使用JX3Box数据创建结果
    private func createJX3BoxOnlyResult() {
        let jx3boxAchievements = achievement.achievements
        let unfinishedCount = jx3boxAchievements.filter { !AchievementCompletionService.shared.isAchievementCompleted($0.id) }.count
        
        // 将ProcessedAchievement转换为AchievementDetail
        let achievementDetails = jx3boxAchievements.map { processedAchievement in
            AchievementDetail(
                id: processedAchievement.id,
                icon: "",
                likes: 0,
                name: processedAchievement.name,
                class: "",
                subClass: "",
                desc: processedAchievement.desc ?? "",
                detail: processedAchievement.note ?? "",
                maps: [],
                isFinished: AchievementCompletionService.shared.isAchievementCompleted(processedAchievement.id),
                isFav: false,
                type: "simple",
                currentValue: AchievementCompletionService.shared.isAchievementCompleted(processedAchievement.id) ? 1 : 0,
                triggerValue: 1,
                subset: [],
                rewardItem: nil,
                rewardPoint: processedAchievement.point,
                rewardPrefix: "",
                rewardSuffix: ""
            )
        }
        
        self.queryResult = DungeonAchievementQueryCache(
            serverName: character.server,
            roleName: character.name,
            dungeonName: achievement.dungeonName,
            achievements: achievementDetails,
            queryTime: Date(),
            unfinishedCount: unfinishedCount,
            totalCount: achievementDetails.count
        )
    }
}

// MARK: - 副本详情查询结果视图
struct DungeonDetailQueryResultView: View {
    let queryResult: DungeonAchievementQueryCache
    let jx3boxAchievements: [ProcessedAchievement] // JX3Box成就数据
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: AchievementFilter = .all
    
    enum AchievementFilter: String, CaseIterable {
        case all = "全部"
        case completed = "已完成"
        case uncompleted = "未完成"
    }
    
    private var filteredAchievements: [AchievementDetail] {
        switch selectedFilter {
        case .all:
            return queryResult.achievements
        case .completed:
            return queryResult.achievements.filter { $0.isFinished }
        case .uncompleted:
            return queryResult.achievements.filter { !$0.isFinished }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分段选择器
                Picker("过滤条件", selection: $selectedFilter) {
                    ForEach(AchievementFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 结果概览
                        resultOverviewCard
                        
                        // 成就列表
                        achievementsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(queryResult.dungeonName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var resultOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("查询结果")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("查询时间: \(formatDate(queryResult.queryTime))")
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
                    
                    Text("\(queryResult.totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("已完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(queryResult.totalCount - queryResult.unfinishedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("未完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(queryResult.unfinishedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(selectedFilter == .completed ? .green : selectedFilter == .uncompleted ? .orange : .blue)
                Text("\(selectedFilter.rawValue)成就")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(filteredAchievements.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if filteredAchievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: selectedFilter == .completed ? "checkmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text(selectedFilter == .completed ? "暂无已完成成就" : selectedFilter == .uncompleted ? "暂无未完成成就" : "暂无成就数据")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredAchievements, id: \.id) { achievement in
                        DetailedAchievementCard(
                            achievement: achievement,
                            jx3boxAchievement: findJX3BoxAchievement(for: achievement)
                        )
                    }
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
    
    private func findJX3BoxAchievement(for achievement: AchievementDetail) -> ProcessedAchievement? {
        return jx3boxAchievements.first { $0.name == achievement.name }
    }
}

// MARK: - 详细成就卡片（支持展开攻略）
struct DetailedAchievementCard: View {
    let achievement: AchievementDetail
    let jx3boxAchievement: ProcessedAchievement? // 对应的JX3Box成就数据
    @State private var isExpanded = false
    
    init(achievement: AchievementDetail, jx3boxAchievement: ProcessedAchievement? = nil) {
        self.achievement = achievement
        self.jx3boxAchievement = jx3boxAchievement
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 基础信息
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
                        .lineLimit(isExpanded ? nil : 2)
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
            
            // 进度条（如果有）
            if achievement.type != "simple" && achievement.triggerValue > 0 {
                HStack {
                    Text("进度: \(achievement.currentValue)/\(achievement.triggerValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ProgressView(value: Double(achievement.currentValue) / Double(achievement.triggerValue))
                        .frame(width: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.isFinished ? .green : .blue))
                }
            }
            
            // 详细描述（如果有）
            if isExpanded && !achievement.detail.isEmpty && achievement.detail != achievement.desc {
                Text(achievement.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // 子成就列表（如果有）
            if isExpanded && !achievement.subset.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("子成就")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    ForEach(achievement.subset, id: \.id) { subAchievement in
                        HStack {
                            Image(systemName: subAchievement.isFinished ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(subAchievement.isFinished ? .green : .gray)
                                .font(.caption2)
                            
                            Text(subAchievement.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.leading, 16)
                    }
                }
            }
            
            // JX3Box攻略指南（如果有）
            if isExpanded, let jx3boxAchievement = jx3boxAchievement, 
               let postContent = jx3boxAchievement.postContent, !postContent.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("攻略指南")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    AchievementGuideView(htmlContent: postContent)
                        .padding(.leading, 16)
                }
            }
            
            // 展开/收起按钮
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        Text(isExpanded ? "收起" : "展开详情")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
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


// MARK: - Safari视图包装
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - 简化成就卡片（向后兼容）
struct SimpleAchievementCard: View {
    let achievement: AchievementDetail
    
    var body: some View {
        DetailedAchievementCard(achievement: achievement)
    }
}