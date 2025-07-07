//
//  YearlyReportView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import SwiftUI
import Charts

// MARK: - 年度报告视图
struct YearlyReportView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var availableYears: [DynamicYearlyReport] = []
    
    var body: some View {
        NavigationView {
            List {
                if availableYears.isEmpty {
                    EmptyYearlyStateView()
                } else {
                    ForEach(availableYears) { report in
                        NavigationLink(destination: YearlyDetailView(report: report).environmentObject(dungeonManager)) {
                            YearlyRowView(report: report)
                                .environmentObject(dungeonManager)
                        }
                    }
                }
            }
            .navigationTitle("年度报告")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshYearlyData()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("刷新统计")
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            refreshYearlyData()
        }
        .onReceive(dungeonManager.$completionRecords) { _ in
            refreshYearlyData()
        }
    }
    
    private func refreshYearlyData() {
        availableYears = YearlyReportManager.shared.generateAvailableYears(from: dungeonManager.completionRecords)
    }
}

// MARK: - 年度报告行视图
struct YearlyRowView: View {
    let report: DynamicYearlyReport
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var yearlyData: YearlyTaskData = YearlyTaskData()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(report.displayTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(yearFormatter.string(from: report.startDate)) - \(yearFormatter.string(from: report.endDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("总计: \(yearlyData.totalCompletions)次")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    if yearlyData.totalCompletions > 0 {
                        Text("\(yearlyData.activeCharacters)个角色")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if yearlyData.totalCompletions > 0 {
                // 快速概览
                VStack(alignment: .leading, spacing: 4) {
                    if let mostActiveCharacter = yearlyData.mostActiveCharacter {
                        Text("最活跃角色: \(mostActiveCharacter.character.name) (\(mostActiveCharacter.completions)次)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if let mostRunDungeon = yearlyData.mostRunDungeon {
                        Text("最热门副本: \(mostRunDungeon.name) (\(mostRunDungeon.completions)次)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    
                    if yearlyData.userMarkedAchievements > 0 {
                        Text("用户标记成就: \(yearlyData.userMarkedAchievements)个")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
                }
            } else {
                Text("本年度无副本完成记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            updateYearlyData()
        }
        .onReceive(dungeonManager.$completionRecords) { _ in
            updateYearlyData()
        }
    }
    
    private func updateYearlyData() {
        let yearRecords = dungeonManager.completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        yearlyData = YearlyTaskData(records: yearRecords)
    }
}

// MARK: - 年度详细统计视图
struct YearlyDetailView: View {
    let report: DynamicYearlyReport
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedTab = 0
    
    private var yearRecords: [CompletionRecord] {
        dungeonManager.completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
    }
    
    // 有掉落的记录
    private var recordsWithDrops: [CompletionRecord] {
        yearRecords.filter { !$0.drops.isEmpty }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部统计卡片
                YearlyReportOverviewCard(records: yearRecords)
                
                if !yearRecords.isEmpty {
                    // 选项卡
                    Picker("统计类型", selection: $selectedTab) {
                        Text("角色完成情况").tag(0)
                        Text("副本耗时对比").tag(1)
                        Text("掉落统计").tag(2)
                        Text("月度趋势").tag(3)
                        Text("成就完成").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 内容区域
                    switch selectedTab {
                    case 0:
                        YearlyCharacterCompletionView(records: yearRecords)
                    case 1:
                        YearlyDungeonTimeComparisonView(records: yearRecords, report: report)
                    case 2:
                        YearlyDropStatisticsView(
                            records: yearRecords,
                            recordsWithDrops: recordsWithDrops,
                            dungeonManager: dungeonManager
                        )
                    case 3:
                        MonthlyTrendView(records: yearRecords, report: report)
                    case 4:
                        YearlyAchievementView(records: yearRecords, report: report)
                    default:
                        EmptyView()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("本年度暂无副本记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle(report.displayTitle)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - 年度概览卡片
struct YearlyReportOverviewCard: View {
    let records: [CompletionRecord]
    
    private var characterCompletions: [String: Int] {
        Dictionary(grouping: records) { "\($0.character.server)-\($0.character.name)" }
            .mapValues { $0.count }
    }
    
    private var dungeonCompletions: [String: Int] {
        Dictionary(grouping: records) { $0.dungeonName }
            .mapValues { $0.count }
    }
    
    private var userMarkedAchievements: Int {
        AchievementCompletionService.shared.getCompletedAchievements().count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("年度任务概览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                OverviewMetric(
                    title: "副本完成次数",
                    value: "\(records.count)",
                    subtitle: "次",
                    color: .blue
                )
                
                OverviewMetric(
                    title: "参与角色",
                    value: "\(characterCompletions.count)",
                    subtitle: "个",
                    color: .green
                )
                
                OverviewMetric(
                    title: "涉及副本",
                    value: "\(dungeonCompletions.count)",
                    subtitle: "个",
                    color: .orange
                )
                
                OverviewMetric(
                    title: "用户标记成就",
                    value: "\(userMarkedAchievements)",
                    subtitle: "个",
                    color: .cyan
                )
            }
            
            if records.count > 0 {
                let averagePerMonth = Double(records.count) / 12.0
                Text(String(format: "平均每月完成 %.1f 次副本", averagePerMonth))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 年度角色完成视图
struct YearlyCharacterCompletionView: View {
    let records: [CompletionRecord]
    
    private var characterData: [CharacterTaskStat] {
        let grouped = Dictionary(grouping: records) { record in
            "\(record.character.server)-\(record.character.name)"
        }
        
        return grouped.compactMap { (key, records) in
            guard let firstRecord = records.first else { return nil }
            
            let dungeonCounts = Dictionary(grouping: records) { $0.dungeonName }
                .mapValues { $0.count }
            
            return CharacterTaskStat(
                character: firstRecord.character,
                totalCompletions: records.count,
                dungeonBreakdown: dungeonCounts
            )
        }.sorted { $0.totalCompletions > $1.totalCompletions }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("年度角色完成次数排行")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(characterData) { stat in
                BarMark(
                    x: .value("次数", stat.totalCompletions),
                    y: .value("角色", stat.character.name)
                )
                .foregroundStyle(.blue.gradient)
                .annotation(position: .trailing) {
                    Text("\(stat.totalCompletions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: max(200, CGFloat(characterData.count * 40)))
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("各角色副本完成详情")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(characterData) { stat in
                    CharacterTaskDetailCard(stat: stat)
                }
            }
        }
    }
}

// MARK: - 年度副本耗时对比视图
struct YearlyDungeonTimeComparisonView: View {
    let records: [CompletionRecord]
    let report: DynamicYearlyReport
    
    private var dungeonTimeData: [EnhancedDungeonTimeComparison] {
        let grouped = Dictionary(grouping: records) { $0.dungeonName }
        
        let results = grouped.map { (dungeonName, dungeonRecords) -> EnhancedDungeonTimeComparison in
            // 按角色分组
            let characterGroups = Dictionary(grouping: dungeonRecords) { record in
                "\(record.character.server)-\(record.character.name)"
            }
            
            // 生成角色时间数据
            let characterTimes = characterGroups.compactMap { (key, records) -> CharacterTimeData? in
                guard let firstRecord = records.first else { return nil }
                let averageTime = records.reduce(0) { $0 + $1.duration } / Double(records.count)
                return CharacterTimeData(
                    character: firstRecord.character,
                    averageTime: averageTime,
                    completions: records.count
                )
            }.sorted { $0.averageTime < $1.averageTime }
            
            // 计算全副本平均时间
            let totalDuration = dungeonRecords.reduce(0) { $0 + $1.duration }
            let totalCompletions = dungeonRecords.count
            let globalAverageTime = totalCompletions > 0 ? totalDuration / Double(totalCompletions) : 0
            
            return EnhancedDungeonTimeComparison(
                dungeonName: dungeonName,
                characterTimes: characterTimes,
                globalAverageTime: globalAverageTime,
                totalCompletions: totalCompletions,
                weekPeriod: report.displayTitle
            )
        }
        
        return results.sorted { $0.dungeonName < $1.dungeonName }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("年度副本耗时对比分析")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(dungeonTimeData) { dungeonComparison in
                EnhancedDungeonTimeCard(comparison: dungeonComparison)
            }
        }
    }
}

// MARK: - 年度掉落统计视图
struct YearlyDropStatisticsView: View {
    let records: [CompletionRecord]
    let recordsWithDrops: [CompletionRecord]
    let dungeonManager: DungeonManager
    
    private var dropSummary: DropSummaryData {
        DropSummaryData(records: records, recordsWithDrops: recordsWithDrops, dungeonManager: dungeonManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 掉落总览
            DropSummaryCard(summary: dropSummary)
            
            if recordsWithDrops.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("本年度暂无特殊掉落")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("角色掉落详情")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(dropSummary.characterSummaries) { characterSummary in
                    CharacterDropSummaryCard(summary: characterSummary)
                }
            }
        }
    }
}

// MARK: - 月度趋势视图
struct MonthlyTrendView: View {
    let records: [CompletionRecord]
    let report: DynamicYearlyReport
    
    private var monthlyData: [MonthlyTrendData] {
        let calendar = Calendar.current
        let months = (1...12).map { month in
            let monthRecords = records.filter { record in
                calendar.component(.month, from: record.completedDate) == month
            }
            
            return MonthlyTrendData(
                month: month,
                completions: monthRecords.count,
                charactersActive: Set(monthRecords.map { "\($0.character.server)-\($0.character.name)" }).count,
                topDungeon: Dictionary(grouping: monthRecords) { $0.dungeonName }
                    .mapValues { $0.count }
                    .max(by: { $0.value < $1.value })?.key ?? "无"
            )
        }
        
        return months
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("月度趋势分析")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(monthlyData) { data in
                LineMark(
                    x: .value("月份", data.month),
                    y: .value("完成次数", data.completions)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
                
                PointMark(
                    x: .value("月份", data.month),
                    y: .value("完成次数", data.completions)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("各月详情")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(monthlyData.filter { $0.completions > 0 }) { data in
                        MonthlyDetailCard(data: data)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 年度成就视图
struct YearlyAchievementView: View {
    let records: [CompletionRecord]
    let report: DynamicYearlyReport
    
    private var achievementStats: (totalAchievements: Int, userMarkedAchievements: Int) {
        YearlyReportManager.shared.getYearlyAchievementStats(
            for: report,
            from: records,
            characters: []
        )
    }
    
    private var userMarkedAchievements: Set<Int> {
        AchievementCompletionService.shared.getCompletedAchievements()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("年度成就统计")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    OverviewMetric(
                        title: "估算总成就",
                        value: "\(achievementStats.totalAchievements)",
                        subtitle: "个",
                        color: .blue
                    )
                    
                    OverviewMetric(
                        title: "用户标记",
                        value: "\(achievementStats.userMarkedAchievements)",
                        subtitle: "个",
                        color: .cyan
                    )
                }
                
                if achievementStats.userMarkedAchievements > 0 {
                    let completionRate = Double(achievementStats.userMarkedAchievements) / Double(achievementStats.totalAchievements) * 100
                    
                    VStack(spacing: 8) {
                        Text("完成率")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text(String(format: "%.1f%%", completionRate))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        ProgressView(value: completionRate / 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(height: 6)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if !userMarkedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("标记的成就")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("共标记了 \(userMarkedAchievements.count) 个成就")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // 这里可以添加更详细的成就列表
                    VStack(spacing: 8) {
                        ForEach(Array(userMarkedAchievements.prefix(10)), id: \.self) { achievementId in
                            HStack {
                                Text("成就 #\(achievementId)")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        
                        if userMarkedAchievements.count > 10 {
                            Text("还有 \(userMarkedAchievements.count - 10) 个成就...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - 月度详情卡片
struct MonthlyDetailCard: View {
    let data: MonthlyTrendData
    
    private var monthName: String {
        Calendar.current.monthSymbols[data.month - 1]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("完成次数: \(data.completions)")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("活跃角色: \(data.charactersActive)")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("热门副本: \(data.topDungeon)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 空状态视图
struct EmptyYearlyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无年度数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成一些副本后，这里将显示年度统计")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 数据模型
struct YearlyTaskData {
    var totalCompletions: Int = 0
    var activeCharacters: Int = 0
    var mostActiveCharacter: (character: GameCharacter, completions: Int)?
    var mostRunDungeon: (name: String, completions: Int)?
    var userMarkedAchievements: Int = 0
    
    init() {}
    
    init(records: [CompletionRecord]) {
        totalCompletions = records.count
        
        // 统计角色活跃度
        let characterCounts = Dictionary(grouping: records) { record in
            "\(record.character.server)-\(record.character.name)"
        }.mapValues { $0.count }
        
        activeCharacters = characterCounts.count
        
        if let mostActive = characterCounts.max(by: { $0.value < $1.value }),
           let firstRecord = records.first(where: { "\($0.character.server)-\($0.character.name)" == mostActive.key }) {
            mostActiveCharacter = (firstRecord.character, mostActive.value)
        }
        
        // 统计副本热度
        let dungeonCounts = Dictionary(grouping: records) { $0.dungeonName }
            .mapValues { $0.count }
        
        if let mostRun = dungeonCounts.max(by: { $0.value < $1.value }) {
            mostRunDungeon = (mostRun.key, mostRun.value)
        }
        
        // 获取用户标记的成就数量
        userMarkedAchievements = AchievementCompletionService.shared.getCompletedAchievements().count
    }
}

struct MonthlyTrendData: Identifiable {
    let id = UUID()
    let month: Int
    let completions: Int
    let charactersActive: Int
    let topDungeon: String
}

// MARK: - 格式化器
private let yearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年MM月dd日"
    return formatter
}()