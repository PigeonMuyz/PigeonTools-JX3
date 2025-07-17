//
//  WeeklyReportView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI
import Charts

// MARK: - 主要的游戏周报视图
struct WeeklyReportView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        NavigationView {
            List {
                if dungeonManager.availableGameWeeks.isEmpty {
                    EmptyWeeklyStateView()
                } else {
                    ForEach(dungeonManager.availableGameWeeks) { report in
                        NavigationLink(destination: WeeklyDetailView(report: report).environmentObject(dungeonManager)) {
                            TaskOrientedWeeklyRowView(report: report)
                                .environmentObject(dungeonManager)
                        }
                    }
                }
            }
            .navigationTitle("游戏周报告")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dungeonManager.manualGameWeeklyReset()
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
    }
}

// MARK: - 任务导向的周报告行视图
struct TaskOrientedWeeklyRowView: View {
    let report: DynamicWeeklyReport
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var weeklyData: WeeklyTaskData = WeeklyTaskData()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(report.displayTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(gameWeekFormatter.string(from: report.startDate)) - \(gameWeekFormatter.string(from: report.endDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("总计: \(weeklyData.totalCompletions)次")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    if weeklyData.totalCompletions > 0 {
                        Text("\(weeklyData.activeCharacters)个角色")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if weeklyData.totalCompletions > 0 {
                // 快速概览：显示最活跃的角色和副本
                VStack(alignment: .leading, spacing: 4) {
                    if let mostActiveCharacter = weeklyData.mostActiveCharacter {
                        Text("刷本最多的角色: \(mostActiveCharacter.character.name) (\(mostActiveCharacter.completions)次)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if let mostRunDungeon = weeklyData.mostRunDungeon {
                        Text("出击最多的副本: \(mostRunDungeon.name) (\(mostRunDungeon.completions)次)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
//                .padding(.top, 4)
//                .padding()
            } else {
                Text("本周无副本完成记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            updateWeeklyData()
        }
        .onReceive(dungeonManager.$completionRecords) { _ in
            updateWeeklyData()
        }
    }
    
    private func updateWeeklyData() {
        let weekRecords = dungeonManager.completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
        
        weeklyData = WeeklyTaskData(records: weekRecords)
    }
}

// MARK: - 详细统计视图
struct WeeklyDetailView: View {
    let report: DynamicWeeklyReport
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedTab = 0
    
    private var weekRecords: [CompletionRecord] {
        dungeonManager.completionRecords.filter { record in
            record.completedDate >= report.startDate && record.completedDate <= report.endDate
        }
    }
    
    // 新增：有掉落的记录
    private var recordsWithDrops: [CompletionRecord] {
        weekRecords.filter { !$0.drops.isEmpty }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部统计卡片
                TaskOverviewCard(records: weekRecords)
                
                if !weekRecords.isEmpty {
                    // 选项卡 - 去掉任务完成统计
                    Picker("统计类型", selection: $selectedTab) {
                        Text("角色完成情况").tag(0)
                        Text("副本耗时对比").tag(1)
                        Text("掉落统计").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 内容区域
                    switch selectedTab {
                    case 0:
                        CharacterCompletionView(records: weekRecords)
                    case 1:
                        EnhancedDungeonTimeComparisonView(records: weekRecords, report: report)
                    case 2:
                        DropStatisticsView(
                            records: weekRecords,
                            recordsWithDrops: recordsWithDrops,
                            dungeonManager: dungeonManager
                        )
                    default:
                        EmptyView()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("本周暂无副本记录")
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

// MARK: - 新增：掉落统计视图
struct DropStatisticsView: View {
    let records: [CompletionRecord]
    let recordsWithDrops: [CompletionRecord]
    let dungeonManager: DungeonManager
    
    private var dropSummary: DropSummaryData {
        DropSummaryData(records: records, recordsWithDrops: recordsWithDrops, dungeonManager: dungeonManager)
    }
    
    private var dungeonDropSummaries: [DungeonDropSummary] {
        let grouped = Dictionary(grouping: recordsWithDrops) { $0.dungeonName }
        
        return grouped.map { (dungeonName, records) in
            let dropEvents = records.flatMap { record -> [DropEvent] in
                record.drops.map { drop in
                    DropEvent(
                        itemName: drop.name,
                        itemColor: drop.color,
                        dungeonName: record.dungeonName,
                        runNumber: dungeonManager.getCharacterRunNumber(for: record),
                        time: record.completedDate
                    )
                }
            }.sorted { $0.time > $1.time }
            
            return DungeonDropSummary(
                dungeonName: dungeonName,
                totalDrops: dropEvents.count,
                dropEvents: dropEvents
            )
        }.sorted { $0.totalDrops > $1.totalDrops }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 掉落总览
            DropSummaryCard(summary: dropSummary)
            
            if recordsWithDrops.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("本周暂无特殊掉落")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 副本掉落详情
                Text("副本掉落详情")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(dungeonDropSummaries) { dungeonSummary in
                    DungeonDropSummaryCard(summary: dungeonSummary)
                }
                
                // 角色掉落详情
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

// MARK: - 新增：掉落总览卡片
struct DropSummaryCard: View {
    let summary: DropSummaryData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("掉落统计")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                OverviewMetric(
                    title: "总特殊掉落数量",
                    value: "\(summary.totalDrops)",
                    subtitle: "个",
                    color: .purple
                )
                
                OverviewMetric(
                    title: "获得特殊的倒霉蛋",
                    value: "\(summary.luckyCharacters)",
                    subtitle: "个",
                    color: .green
                )
                
                OverviewMetric(
                    title: "出货次数",
                    value: "\(summary.dropInstances)",
                    subtitle: "次",
                    color: .orange
                )
                
                OverviewMetric(
                    title: "玄晶数量",
                    value: "\(summary.xuanjingCount)",
                    subtitle: "个",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 新增：副本掉落详情卡片
struct DungeonDropSummaryCard: View {
    let summary: DungeonDropSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 副本信息
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text(summary.dungeonName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("掉落 \(summary.totalDrops) 个物品")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 掉落列表 - 可展开
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(summary.dropEvents) { event in
                        DropEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 新增：角色掉落详情卡片
struct CharacterDropSummaryCard: View {
    let summary: CharacterDropSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 角色信息
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(summary.character.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("获得 \(summary.totalItems) 个物品")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 掉落列表 - 可展开
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(summary.dropEvents) { event in
                        DropEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 新增：掉落事件行
struct DropEventRow: View {
    let event: DropEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // 物品颜色指示器
            Circle()
                .fill(event.itemColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                // 物品名称
                Text(event.itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(event.itemColor)
                
                // 详细信息
                HStack(spacing: 8) {
                    Text(event.dungeonName)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("第\(event.runNumber)车")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(3)
                    
                    Text(timeFormatter.string(from: event.time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// MARK: - 其他现有视图组件
struct TaskOverviewCard: View {
    let records: [CompletionRecord]
    
    private var characterCompletions: [String: Int] {
        Dictionary(grouping: records) { "\($0.character.server)-\($0.character.name)" }
            .mapValues { $0.count }
    }
    
    private var dungeonCompletions: [String: Int] {
        Dictionary(grouping: records) { $0.dungeonName }
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("本周任务概览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                OverviewMetric(
                    title: "副本完成次数",
                    value: "\(records.count)",
                    subtitle: "次",
                    color: .blue
                )
                
                OverviewMetric(
                    title: "参与的倒霉蛋",
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
                
//                OverviewMetric(
//                    title: "平均每角色",
//                    value: characterCompletions.isEmpty ? "0" : String(format: "%.1f", Double(records.count) / Double(characterCompletions.count)),
//                    subtitle: "次",
//                    color: .purple
//                )
            }
            if records.count > 0 {
                Text(records.count <= 25 ? "嘶，叼毛还在偷懒" :
                     records.count <= 50 ? "🤔有点意思" : "🤔有点东西")
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

struct CharacterCompletionView: View {
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
            Text("角色完成次数排行")
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

struct DungeonTimeComparisonView: View {
    let records: [CompletionRecord]
    
    private var dungeonTimeData: [DungeonTimeComparison] {
        let grouped = Dictionary(grouping: records) { $0.dungeonName }
        
        return grouped.map { (dungeonName, records) in
            let characterTimes = Dictionary(grouping: records) { record in
                "\(record.character.server)-\(record.character.name)"
            }.compactMap { (key, records) -> CharacterTimeData? in
                guard let firstRecord = records.first else { return nil }
                let averageTime = records.reduce(0) { $0 + $1.duration } / Double(records.count)
                return CharacterTimeData(
                    character: firstRecord.character,
                    averageTime: averageTime,
                    completions: records.count
                )
            }.sorted { $0.averageTime < $1.averageTime }
            
            return DungeonTimeComparison(
                dungeonName: dungeonName,
                characterTimes: characterTimes
            )
        }.sorted { $0.dungeonName < $1.dungeonName }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("副本耗时对比分析")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(dungeonTimeData) { dungeonComparison in
                DungeonTimeCard(comparison: dungeonComparison)
            }
        }
    }
}

struct CharacterTaskDetailCard: View {
    let stat: CharacterTaskStat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.character.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("总计 \(stat.totalCompletions) 次")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 4) {
                ForEach(Array(stat.dungeonBreakdown.keys.sorted()), id: \.self) { dungeonName in
                    HStack {
                        Text(dungeonName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(stat.dungeonBreakdown[dungeonName] ?? 0)次")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct DungeonTimeCard: View {
    let comparison: DungeonTimeComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(comparison.dungeonName)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if comparison.characterTimes.count > 1 {
                Chart(comparison.characterTimes) { timeData in
                    BarMark(
                        x: .value("角色", timeData.character.name),
                        y: .value("平均耗时", timeData.averageTime / 60)
                    )
                    .foregroundStyle(.orange.gradient)
                    .annotation(position: .top) {
                        Text(formatDurationShort(timeData.averageTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
            }
            
            VStack(spacing: 6) {
                ForEach(comparison.characterTimes) { timeData in
                    HStack {
                        Text(timeData.character.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(timeData.completions)次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("平均 \(formatDurationShort(timeData.averageTime))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct OverviewMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyWeeklyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无游戏周数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成一些副本后，这里将显示游戏周统计")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 数据模型
struct WeeklyTaskData {
    var totalCompletions: Int = 0
    var activeCharacters: Int = 0
    var mostActiveCharacter: (character: GameCharacter, completions: Int)?
    var mostRunDungeon: (name: String, completions: Int)?
    
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
    }
}

struct CharacterTaskStat: Identifiable {
    let id = UUID()
    let character: GameCharacter
    let totalCompletions: Int
    let dungeonBreakdown: [String: Int] // 副本名称 -> 完成次数
}

struct DungeonTimeComparison: Identifiable {
    let id = UUID()
    let dungeonName: String
    let characterTimes: [CharacterTimeData]
}

struct CharacterTimeData: Identifiable {
    let id = UUID()
    let character: GameCharacter
    let averageTime: TimeInterval
    let completions: Int
}

// MARK: - 新增：掉落统计数据模型
struct DropSummaryData {
    let totalDrops: Int
    let luckyCharacters: Int
    let dropInstances: Int
    let xuanjingCount: Int
    let characterSummaries: [CharacterDropSummary]
    
    init(records: [CompletionRecord], recordsWithDrops: [CompletionRecord], dungeonManager: DungeonManager) {
        self.totalDrops = recordsWithDrops.reduce(0) { $0 + $1.drops.count }
        self.dropInstances = recordsWithDrops.count
        
        // 按角色分组
        let characterGroups = Dictionary(grouping: recordsWithDrops) { record in
            "\(record.character.server)-\(record.character.name)"
        }
        
        self.luckyCharacters = characterGroups.count
        
        // 统计玄晶数量
        self.xuanjingCount = recordsWithDrops.reduce(0) { total, record in
            total + record.drops.filter { $0.name.contains("玄晶") }.count
        }
        
        // 生成角色简报
        self.characterSummaries = characterGroups.compactMap { (key, records) in
            guard let firstRecord = records.first else { return nil }
            
            let dropEvents = records.flatMap { record -> [DropEvent] in
                record.drops.map { drop in
                    DropEvent(
                        itemName: drop.name,
                        itemColor: drop.color,
                        dungeonName: record.dungeonName,
                        runNumber: dungeonManager.getCharacterRunNumber(for: record),
                        time: record.completedDate
                    )
                }
            }.sorted { $0.time > $1.time }
            
            return CharacterDropSummary(
                character: firstRecord.character,
                totalItems: dropEvents.count,
                dropEvents: dropEvents
            )
        }.sorted { $0.totalItems > $1.totalItems }
    }
}

struct CharacterDropSummary: Identifiable {
    let id = UUID()
    let character: GameCharacter
    let totalItems: Int
    let dropEvents: [DropEvent]
}

struct DropEvent: Identifiable {
    let id = UUID()
    let itemName: String
    let itemColor: Color
    let dungeonName: String
    let runNumber: Int
    let time: Date
}

struct DungeonDropSummary: Identifiable {
    let id = UUID()
    let dungeonName: String
    let totalDrops: Int
    let dropEvents: [DropEvent]
}

// MARK: - 任务完成统计视图
struct WeeklyTaskCompletionView: View {
    let report: DynamicWeeklyReport
    let dungeonManager: DungeonManager
    
    private var weeklyTaskData: WeeklyTaskCompletionData {
        WeeklyTaskCompletionData(report: report, dungeonManager: dungeonManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 总览
            WeeklyTaskOverviewCard(data: weeklyTaskData)
            
            if weeklyTaskData.hasTaskData {
                // 角色任务完成详情
                Text("各角色任务完成情况")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(weeklyTaskData.characterTaskSummaries) { summary in
                    CharacterTaskCompletionCard(summary: summary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("本周暂无任务完成数据")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("在任务台中管理日常任务完成状态")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - 增强的副本耗时对比视图
struct EnhancedDungeonTimeComparisonView: View {
    let records: [CompletionRecord]
    let report: DynamicWeeklyReport
    
    private var dungeonTimeData: [EnhancedDungeonTimeComparison] {
        let grouped = Dictionary(grouping: records) { $0.dungeonName }
        
        let results = grouped.map { (dungeonName, dungeonRecords) -> EnhancedDungeonTimeComparison in
            // 计算全副本平均时间
            let totalDuration = dungeonRecords.reduce(0) { $0 + $1.duration }
            let totalCompletions = dungeonRecords.count
            let globalAverageTime = totalCompletions > 0 ? totalDuration / Double(totalCompletions) : 0
            
            // 格式化时间段
            let startDateStr = gameWeekFormatter.string(from: report.startDate)
            let endDateStr = gameWeekFormatter.string(from: report.endDate)
            let weekPeriod = "\(startDateStr) - \(endDateStr)"
            
            return EnhancedDungeonTimeComparison(
                dungeonName: dungeonName,
                characterTimes: [],  // 不再需要角色时间数据
                globalAverageTime: globalAverageTime,
                totalCompletions: totalCompletions,
                weekPeriod: weekPeriod
            )
        }
        
        return results.sorted { $0.totalCompletions > $1.totalCompletions }  // 按次数降序排序
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("副本耗时对比分析")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(dungeonTimeData) { dungeonComparison in
                EnhancedDungeonTimeCard(comparison: dungeonComparison)
            }
        }
    }
}

// MARK: - 数据模型
struct WeeklyTaskCompletionData {
    let totalTasksCompleted: Int
    let totalCharactersWithTasks: Int
    let mostActiveCharacter: (character: GameCharacter, tasksCompleted: Int)?
    let characterTaskSummaries: [CharacterTaskSummary]
    let hasTaskData: Bool
    
    init(report: DynamicWeeklyReport, dungeonManager: DungeonManager) {
        // 获取本周的任务完成数据
        let weekStart = report.startDate
        let weekEnd = report.endDate
        
        var characterTaskCounts: [String: (character: GameCharacter, count: Int)] = [:]
        var totalCompleted = 0
        
        // 遍历所有角色的任务数据
        for characterTasks in dungeonManager.dailyTaskManager.characterDailyTasks {
            // 找到对应的角色
            if let character = dungeonManager.characters.first(where: { $0.id == characterTasks.characterId }) {
                let characterKey = "\(character.server)-\(character.name)"
                
                // 统计本周完成的任务数量
                let completedTasks = characterTasks.tasks.filter { task in
                    if let completedDate = task.completedDate {
                        return completedDate >= weekStart && completedDate <= weekEnd && task.isCompleted
                    }
                    return false
                }
                
                if !completedTasks.isEmpty {
                    totalCompleted += completedTasks.count
                    characterTaskCounts[characterKey] = (character, completedTasks.count)
                }
            }
        }
        
        self.totalTasksCompleted = totalCompleted
        self.totalCharactersWithTasks = characterTaskCounts.count
        self.hasTaskData = totalCompleted > 0
        
        // 找到最活跃的角色
        if let mostActive = characterTaskCounts.values.max(by: { $0.count < $1.count }) {
            self.mostActiveCharacter = (character: mostActive.character, tasksCompleted: mostActive.count)
        } else {
            self.mostActiveCharacter = nil
        }
        
        // 生成角色任务摘要
        self.characterTaskSummaries = characterTaskCounts.values.map { (character, count) in
            let startDateStr = gameWeekFormatter.string(from: weekStart)
            let endDateStr = gameWeekFormatter.string(from: weekEnd)
            let weekPeriod = "\(startDateStr) - \(endDateStr)"
            
            return CharacterTaskSummary(
                character: character,
                completedTasksCount: count,
                weekPeriod: weekPeriod
            )
        }.sorted { $0.completedTasksCount > $1.completedTasksCount }
    }
}

struct CharacterTaskSummary: Identifiable {
    let id = UUID()
    let character: GameCharacter
    let completedTasksCount: Int
    let weekPeriod: String
}

struct EnhancedDungeonTimeComparison: Identifiable {
    let id = UUID()
    let dungeonName: String
    let characterTimes: [CharacterTimeData]
    let globalAverageTime: TimeInterval
    let totalCompletions: Int
    let weekPeriod: String
}

// MARK: - UI组件
struct WeeklyTaskOverviewCard: View {
    let data: WeeklyTaskCompletionData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("任务完成总览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                OverviewMetric(
                    title: "总完成任务数",
                    value: "\(data.totalTasksCompleted)",
                    subtitle: "个",
                    color: .blue
                )
                
                OverviewMetric(
                    title: "活跃角色数",
                    value: "\(data.totalCharactersWithTasks)",
                    subtitle: "个",
                    color: .green
                )
                
                if let mostActive = data.mostActiveCharacter {
                    OverviewMetric(
                        title: "最勤劳角色",
                        value: mostActive.character.name,
                        subtitle: "\(mostActive.tasksCompleted)个任务",
                        color: .purple
                    )
                } else {
                    OverviewMetric(
                        title: "平均每角色",
                        value: data.totalCharactersWithTasks > 0 ? String(format: "%.1f", Double(data.totalTasksCompleted) / Double(data.totalCharactersWithTasks)) : "0",
                        subtitle: "个任务",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CharacterTaskCompletionCard: View {
    let summary: CharacterTaskSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.character.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("完成 \(summary.completedTasksCount) 个任务")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("服务器: \(summary.character.server)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("统计周期: \(summary.weekPeriod)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct EnhancedDungeonTimeCard: View {
    let comparison: EnhancedDungeonTimeComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 副本名称和总览
            VStack(alignment: .leading, spacing: 8) {
                Text(comparison.dungeonName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    HStack {
                        Text("总完成次数:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(comparison.totalCompletions)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("平均用时:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDurationShort(comparison.globalAverageTime))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                
                Text("统计周期: \(comparison.weekPeriod)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 全局格式化器别名（保持兼容性）
private let gameWeekFormatter = DateFormatters.gameWeekShortFormatter
private let dateTimeFormatter = DateFormatters.gameWeekFormatter
private let timeFormatter = DateFormatters.timeFormatter
