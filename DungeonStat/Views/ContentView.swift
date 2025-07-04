//
//  ContentView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//
import SwiftUI
import Foundation
import Combine


// MARK: - 主应用视图
struct ContentView: View {
    @StateObject private var dungeonManager = DungeonManager()
    @State private var selectedTab = 0
    @State private var hasEverHadTasks = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(dungeonManager)
                .tabItem {
                    Image(systemName: "house")
                    Text("任务台")
                }
                .tag(0)
            
            DungeonListView()
                .environmentObject(dungeonManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("副本")
                }
                .tag(1)
            
            HistoryView()
                .environmentObject(dungeonManager)
                .tabItem {
                    Image(systemName: "clock")
                    Text("历史")
                }
                .tag(2)
            
            StatisticsView()
                .environmentObject(dungeonManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }
                .tag(3)
            
            SettingsView()
                .environmentObject(dungeonManager)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
                .tag(4)
        }
        .onAppear {
            // 初始化时检查是否有任务
            if inProgressCount > 0 {
                hasEverHadTasks = true
            }
        }
    }
    
    // 计算进行中任务数量
    private var inProgressCount: Int {
        var count = 0
        for dungeon in dungeonManager.dungeons {
            // 直接统计副本中进行状态为true的数量
            count += dungeon.characterInProgress.values.filter { $0 }.count
        }
        return count
    }
}

// MARK: - 副本列表视图
struct DungeonListView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddDungeon = false
    @State private var newDungeonName = ""
    @State private var showingCharacterSelector = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(dungeonManager.dungeons.enumerated()), id: \.element.id) { index, dungeon in
                    DungeonRowView(dungeon: dungeon, index: index)
                }
                .onDelete(perform: deleteDungeons)
            }
//            .navigationTitle("副本计数器")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingCharacterSelector = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                if let character = dungeonManager.selectedCharacter {
                                    Text(character.name)
                                        .lineLimit(1)
                                } else {
                                    Text("选择角色")
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingAddDungeon = true
                    }
                }
            }
            .sheet(isPresented: $showingAddDungeon) {
                AddDungeonView(dungeonName: $newDungeonName, isPresented: $showingAddDungeon)
            }
            .sheet(isPresented: $showingCharacterSelector) {
                CharacterSelectorView(isPresented: $showingCharacterSelector)
            }
        }
    }
    
    func deleteDungeons(offsets: IndexSet) {
        for index in offsets {
            dungeonManager.deleteDungeon(at: index)
        }
    }
}

// MARK: - 优化的副本行视图
struct DungeonRowView: View {
    let dungeon: Dungeon
    let index: Int
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCancelAlert = false
    @State private var currentTime = Date()
    @State private var showDetailedComparison = true
    @State private var hideComparisonTimer: Timer?
    @State private var lastRecordTimestamp: Date?
    
    // 定时器用于更新进行中的时间
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧信息区域
            VStack(alignment: .leading, spacing: 6) {
                // 副本名称
                Text(dungeon.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let character = dungeonManager.selectedCharacter {
                    // 状态信息区域
                    statusInfoView(for: character)
                } else {
                    // 未选择角色时的占位内容
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("需要选择角色才能查看数据")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
            
            if let character = dungeonManager.selectedCharacter {
                // 右侧统计和按钮区域
                VStack(alignment: .trailing, spacing: 8) {
                    // 统计数据
                    statisticsView(for: character)
                    
                    // 操作按钮
                    actionButtonsView(for: character)
                }
            } else {
                // 未选择角色提示
                VStack {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("请选择角色")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            currentTime = Date()
            checkForNewCompletion()
        }
        .onAppear {
            initializeComparisonState()
        }
        .alert("取消副本", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认取消", role: .destructive) {
                dungeonManager.cancelDungeon(at: index)
            }
        } message: {
            Text("确定要取消当前进行中的副本吗？")
        }
    }
    
    // MARK: - 状态信息视图
    @ViewBuilder
    private func statusInfoView(for character: GameCharacter) -> some View {
        if dungeon.isInProgress(for: character), let startTime = dungeon.startTime(for: character) {
            // 进行中状态
            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("进行中")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                Text("(\(timeElapsed(from: startTime, to: currentTime)))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        } else {
            // 完成状态信息
            let totalCount = dungeon.totalCount(for: character)
            let lastRecord = getLastCompletedRecord(for: character)
            
            if totalCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    // 优先显示上次完成信息（如果有记录）
                    if let lastRecord = lastRecord {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("上次: \(gameWeekFormatter.string(from: lastRecord.completedDate))")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("用时: \(formatDuration(lastRecord.duration))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        // 如果没有详细记录，显示最后完成日期（从副本数据获取）
                        if let lastCompletedDate = dungeon.lastCompletedDate(for: character) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("最后完成: \(gameWeekFormatter.string(from: lastCompletedDate))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // 平均用时（总是显示）
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text("平均用时: \(formatDuration(dungeon.averageDuration(for: character)))")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    
                    // 与平均时间对比（可隐藏，且需要有详细记录）
                    if showDetailedComparison && totalCount > 1, let lastRecord = lastRecord {
                        let avgDuration = dungeon.averageDuration(for: character)
                        let difference = lastRecord.duration - avgDuration
                        let isImprovement = difference < 0
                        
                        HStack(spacing: 4) {
                            Image(systemName: isImprovement ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.caption2)
                                .foregroundColor(isImprovement ? .green : .red)
                            
                            Text("比平均")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(isImprovement ? "快\(formatDuration(abs(difference)))（你他喵的真是个天才啊！）" : "慢\(formatDuration(difference))（摸鱼是吧你他喵的！）")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isImprovement ? .green : .red)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            } else {
                // 没有任何完成记录时的占位内容
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("还未开始此副本")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("点击开始按钮来记录第一次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 统计数据视图
    @ViewBuilder
    private func statisticsView(for character: GameCharacter) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 本周完成次数
            HStack(spacing: 4) {
                Text("本周")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(dungeon.weeklyCount(for: character))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // 总完成次数
            HStack(spacing: 4) {
                Text("总计")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(dungeon.totalCount(for: character))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // 最佳用时（只有在有记录时显示）
            if let bestTime = getBestTime(for: character) {
                HStack(spacing: 4) {
                    Text("最佳")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(bestTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    // MARK: - 操作按钮视图
    @ViewBuilder
    private func actionButtonsView(for character: GameCharacter) -> some View {
        if dungeon.isInProgress(for: character) {
            HStack(spacing: 8) {
                // 取消按钮
                Button(action: {
                    showingCancelAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 完成按钮
                Button(action: {
                    dungeonManager.completeDungeon(at: index)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else {
            // 开始按钮
            Button(action: {
                dungeonManager.startDungeon(at: index)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("开始")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 辅助方法
    private func timeElapsed(from startTime: Date, to currentTime: Date) -> String {
        let elapsed = currentTime.timeIntervalSince(startTime)
        return formatDuration(elapsed)
    }
    
    // 获取指定角色上次完成该副本的记录
    private func getLastCompletedRecord(for character: GameCharacter) -> CompletionRecord? {
        return dungeonManager.completionRecords
            .filter { $0.dungeonName == dungeon.name && $0.character.id == character.id }
            .sorted { $0.completedDate > $1.completedDate }
            .first
    }
    
    // 获取指定角色该副本的最佳用时
    private func getBestTime(for character: GameCharacter) -> TimeInterval? {
        let records = dungeonManager.completionRecords
            .filter { $0.dungeonName == dungeon.name && $0.character.id == character.id }
        
        return records.isEmpty ? nil : records.map { $0.duration }.min()
    }
    
    // 检查是否有新的完成记录
    private func checkForNewCompletion() {
        guard let character = dungeonManager.selectedCharacter else { return }
        
        // 检查 CompletionRecord 中的记录
        if let lastRecord = getLastCompletedRecord(for: character) {
            // 如果发现新的完成记录
            if lastRecordTimestamp != lastRecord.completedDate {
                lastRecordTimestamp = lastRecord.completedDate
                // 如果是最近3秒内完成的，显示详细对比并启动隐藏计时器
                if Date().timeIntervalSince(lastRecord.completedDate) < 3 {
                    resetComparisonDisplay()
                }
            }
        }
    }
    
    // 初始化对比显示状态
    private func initializeComparisonState() {
        guard let character = dungeonManager.selectedCharacter else { return }
        
        // 检查是否有完成记录
        if let lastRecord = getLastCompletedRecord(for: character) {
            lastRecordTimestamp = lastRecord.completedDate
            
            // 如果是最近10秒内完成的记录，启动隐藏计时器
            if Date().timeIntervalSince(lastRecord.completedDate) < 10 {
                startHideComparisonTimer()
            } else {
                // 如果不是最近完成的，默认隐藏详细对比
                showDetailedComparison = false
            }
        } else {
            // 没有记录时隐藏详细对比
            showDetailedComparison = false
        }
    }
    
    // 启动隐藏对比分析的计时器
    private func startHideComparisonTimer() {
        hideComparisonTimer?.invalidate()
        hideComparisonTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                showDetailedComparison = false
            }
        }
    }
    
    // 重置显示状态（当有新的完成记录时调用）
    private func resetComparisonDisplay() {
        withAnimation(.easeIn(duration: 0.3)) {
            showDetailedComparison = true
        }
        startHideComparisonTimer()
    }
}

// MARK: - 角色选择器视图
struct CharacterSelectorView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dungeonManager.characters) { gameCharacter in
                    VStack(alignment: .leading, spacing: 8) {
                        // 角色名和选中状态 - 最突出
                        HStack {
                            Text(gameCharacter.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if dungeonManager.selectedCharacter?.id == gameCharacter.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // 服务器 - 次重要信息
                        Text("服务器：\(gameCharacter.server)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        // 门派和体型 - 紧凑水平布局
                        HStack(spacing: 12) {
                            Text("门派：\(gameCharacter.school)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Text("体型：\(gameCharacter.bodyType)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dungeonManager.selectCharacter(gameCharacter)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("选择角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
            }
        }
    }
}

// MARK: - 手动添加记录视图
struct AddManualRecordView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedDungeon = ""
    @State private var selectedCharacter: GameCharacter?
    @State private var completedDate = Date()
    @State private var hours = 0
    @State private var minutes = 30
    @State private var seconds = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("记录信息")) {
                    Picker("副本", selection: $selectedDungeon) {
                        Text("请选择副本").tag("")
                        ForEach(dungeonManager.dungeons) { dungeon in
                            Text(dungeon.name).tag(dungeon.name)
                        }
                    }
                    
                    Picker("角色", selection: $selectedCharacter) {
                        Text("请选择角色").tag(GameCharacter?.none)
                        ForEach(dungeonManager.characters) { gameCharacter in
                            Text(gameCharacter.displayName).tag(GameCharacter?.some(gameCharacter))
                        }
                    }
                    
                    DatePicker("完成时间", selection: $completedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("用时")) {
                    HStack {
                        Picker("小时", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        Picker("分钟", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        Picker("秒", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)秒").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                }
            }
            .navigationTitle("添加历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if let character = selectedCharacter, !selectedDungeon.isEmpty {
                            let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                            dungeonManager.addManualRecord(
                                dungeonName: selectedDungeon,
                                character: character,
                                completedDate: completedDate,
                                duration: duration
                            )
                            isPresented = false
                        }
                    }
                    .disabled(selectedDungeon.isEmpty || selectedCharacter == nil)
                }
            }
        }
        .onAppear {
            selectedCharacter = dungeonManager.selectedCharacter
        }
    }
}

// MARK: - 全局格式化器别名（保持兼容性）
private let dateFormatter = DateFormatters.dateFormatter
private let dateTimeFormatter = DateFormatters.dateTimeFormatter
private let gameWeekFormatter = DateFormatters.gameWeekFormatter
