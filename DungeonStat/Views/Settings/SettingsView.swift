//
//  SettingsView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import SwiftUI
import Combine

// MARK: - 设置页面主视图
struct SettingsView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled = true
    @AppStorage("backupInterval") private var backupInterval = 24 // 小时
    @AppStorage("jx3api_token") private var jx3ApiToken = ""
    @AppStorage("jx3api_tokenv2") private var jx3ApiTokenV2 = ""
    @AppStorage("jx3api_ticket") private var jx3ApiTicket = ""
    @State private var showingCharacterManagement = false
    @State private var showingBackupManagement = false
    @State private var showingAPISettings = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // 角色管理区域
                Section(header: Text("角色管理")) {
                    NavigationLink(destination: CharacterManagementView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("角色管理")
                                    .font(.headline)
                                Text("管理你的游戏角色")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(dungeonManager.characters.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let selectedCharacter = dungeonManager.selectedCharacter {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("当前角色")
                                    .font(.headline)
                                Text(selectedCharacter.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("切换") {
                                showingCharacterManagement = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // 数据管理区域
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: BackupManagementView()) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("备份管理")
                                    .font(.headline)
                                Text("管理应用数据备份")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $autoBackupEnabled) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("自动备份")
                                    .font(.headline)
                                Text(autoBackupEnabled ? "每\(backupInterval)小时自动备份" : "已禁用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if autoBackupEnabled {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("备份间隔")
                                    .font(.headline)
                                
                                Picker("", selection: $backupInterval) {
                                    Text("6小时").tag(6)
                                    Text("12小时").tag(12)
                                    Text("24小时").tag(24)
                                    Text("48小时").tag(48)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                    }
                }
                
                // API设置区域
                Section(header: Text("API设置")) {
                    NavigationLink(destination: APISettingsView()) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.cyan)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("JX3API配置")
                                    .font(.headline)
                                Text(hasAPITokens ? "已配置" : "未配置")
                                    .font(.caption)
                                    .foregroundColor(hasAPITokens ? .green : .orange)
                            }
                            
                            Spacer()
                            
                            if hasAPITokens {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // 关于区域
                Section(header: Text("关于")) {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("关于应用")
                                    .font(.headline)
                                Text("版本信息和帮助")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingCharacterManagement) {
                CharacterSelectorView(isPresented: $showingCharacterManagement)
            }
        }
    }
    
    private var hasAPITokens: Bool {
        !jx3ApiToken.isEmpty || !jx3ApiTokenV2.isEmpty || !jx3ApiTicket.isEmpty
    }
}

// MARK: - API设置视图
struct APISettingsView: View {
    @AppStorage("jx3api_token") private var jx3ApiToken = ""
    @AppStorage("jx3api_tokenv2") private var jx3ApiTokenV2 = ""
    @AppStorage("jx3api_ticket") private var jx3ApiTicket = ""
    @State private var showingTokenHelp = false
    
    var body: some View {
        Form {
            Section(header: HStack {
                Text("JX3API令牌配置")
                Spacer()
                Button("帮助") {
                    showingTokenHelp = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Token V1
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Token V1")
                            .font(.headline)
                        TextField("请输入Token V1", text: $jx3ApiToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("用于基础API调用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Token V2
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Token V2")
                            .font(.headline)
                        TextField("请输入Token V2", text: $jx3ApiTokenV2)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("用于高级API调用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Ticket
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket")
                            .font(.headline)
                        TextField("请输入Ticket", text: $jx3ApiTicket)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("用于角色详细信息查询")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("配置状态")) {
                HStack {
                    Text("Token V1")
                    Spacer()
                    Image(systemName: jx3ApiToken.isEmpty ? "xmark.circle" : "checkmark.circle")
                        .foregroundColor(jx3ApiToken.isEmpty ? .red : .green)
                }
                
                HStack {
                    Text("Token V2")
                    Spacer()
                    Image(systemName: jx3ApiTokenV2.isEmpty ? "xmark.circle" : "checkmark.circle")
                        .foregroundColor(jx3ApiTokenV2.isEmpty ? .red : .green)
                }
                
                HStack {
                    Text("Ticket")
                    Spacer()
                    Image(systemName: jx3ApiTicket.isEmpty ? "xmark.circle" : "checkmark.circle")
                        .foregroundColor(jx3ApiTicket.isEmpty ? .red : .green)
                }
            }
            
            Section(header: Text("操作")) {
                Button("清除所有配置") {
                    jx3ApiToken = ""
                    jx3ApiTokenV2 = ""
                    jx3ApiTicket = ""
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("API设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTokenHelp) {
            TokenHelpView()
        }
    }
}

// MARK: - 令牌帮助视图
struct TokenHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("JX3API令牌说明")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Group {
                        Text("Token V1")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 用于基础API调用，如服务器状态、日常活动等")
                        Text("• 获取地址：https://jx3api.com")
                        Text("• 免费用户可获取")
                        
                        Text("Token V2")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 用于高级API调用，如角色装备、奇遇记录等")
                        Text("• 需要付费用户权限")
                        Text("• 提供更详细的游戏数据")
                        
                        Text("Ticket")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 用于角色详细信息查询")
                        Text("• 格式：ticket:timestamp:platform::hash")
                        Text("• 从游戏客户端或官方API获取")
                    }
                    .font(.body)
                    
                    Divider()
                    
                    Text("配置说明")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("• 至少需要配置一个Token才能使用API功能")
                    Text("• 建议配置完整的Token和Ticket获得最佳体验")
                    Text("• 令牌信息会安全存储在本地")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("API帮助")
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
}

// MARK: - 关于视图
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 应用信息
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("副本统计")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("专为剑网3玩家设计的副本记录工具")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Divider()
                
                // 功能特点
                VStack(alignment: .leading, spacing: 16) {
                    Text("主要功能")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    FeatureRow(icon: "timer", title: "副本计时", description: "精确记录副本完成时间")
                    FeatureRow(icon: "person.3", title: "多角色支持", description: "管理多个游戏角色的数据")
                    FeatureRow(icon: "chart.bar", title: "数据统计", description: "详细的完成数据分析")
                    FeatureRow(icon: "icloud", title: "数据备份", description: "安全的本地数据备份")
                    FeatureRow(icon: "network", title: "API集成", description: "支持JX3API数据获取")
                }
                .padding()
                
                Divider()
                
                // 技术信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("技术信息")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("• 基于SwiftUI构建")
                    Text("• 使用Core Data进行数据持久化")
                    Text("• 集成JX3API获取游戏数据")
                    Text("• 支持iOS 15.0及以上版本")
                }
                .font(.body)
                .padding()
                
                Divider()
                
                // 联系信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("联系我们")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("如有问题或建议，请联系开发者")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 功能特点行视图
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 统计页面（合并周报告功能）
struct StatisticsView: View {
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
            .navigationTitle("统计")
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

// MARK: - 任务台页面（Dashboard）
struct DashboardView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingQuickStart = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 全局进行中任务
                    AllInProgressTasksCard()
                    
                    // 日常任务卡片
                    DailyTasksCard()
                    
                    // 全局今日统计
                    GlobalTodayStatsCard()
                    
                    // 角色分组显示（可选展开）
                    if !dungeonManager.characters.isEmpty {
                        CharacterBreakdownCard()
                    }
                }
                .padding()
            }
            .navigationTitle("任务台")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingQuickStart = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingQuickStart) {
                QuickStartView(isPresented: $showingQuickStart)
            }
        }
    }
}

// MARK: - 快速开始任务视图
struct QuickStartView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedCharacter: GameCharacter?
    @State private var selectedDungeon: Dungeon?
    
    var body: some View {
        NavigationView {
            Form {
                if dungeonManager.characters.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("没有角色")
                                .font(.headline)
                            
                            Text("请先在设置中添加角色")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else if dungeonManager.dungeons.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "building.2.crop.circle.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("没有副本")
                                .font(.headline)
                            
                            Text("请先在副本页面添加副本")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section(header: Text("选择角色")) {
                        Picker("角色", selection: $selectedCharacter) {
                            Text("请选择角色").tag(GameCharacter?.none)
                            ForEach(dungeonManager.characters) { character in
                                Text(character.displayName).tag(GameCharacter?.some(character))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section(header: Text("选择副本")) {
                        Picker("副本", selection: $selectedDungeon) {
                            Text("请选择副本").tag(Dungeon?.none)
                            ForEach(availableDungeons) { dungeon in
                                Text(dungeon.name).tag(Dungeon?.some(dungeon))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(selectedCharacter == nil)
                    }
                    
                    if selectedCharacter != nil && selectedDungeon != nil {
                        Section(header: Text("确认信息")) {
                            HStack {
                                Text("角色")
                                Spacer()
                                Text(selectedCharacter!.displayName)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("副本")
                                Spacer()
                                Text(selectedDungeon!.name)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let character = selectedCharacter, let dungeon = selectedDungeon {
                                HStack {
                                    Text("本周完成")
                                    Spacer()
                                    Text("\(dungeon.weeklyCount(for: character))")
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Text("总完成")
                                    Spacer()
                                    Text("\(dungeon.totalCount(for: character))")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        Section {
                            Button(action: {
                                startSelectedTask()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                    Text("开始任务")
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .navigationTitle("快速开始")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // 默认选择当前角色
            selectedCharacter = dungeonManager.selectedCharacter
        }
        .onChange(of: selectedCharacter) { _, _ in
            // 角色变化时清空副本选择
            selectedDungeon = nil
        }
    }
    
    private var availableDungeons: [Dungeon] {
        guard let character = selectedCharacter else { return [] }
        
        // 只显示该角色还没在进行中的副本
        return dungeonManager.dungeons.filter { dungeon in
            !dungeon.isInProgress(for: character)
        }
    }
    
    private func startSelectedTask() {
        guard let character = selectedCharacter,
              let dungeon = selectedDungeon,
              let dungeonIndex = dungeonManager.dungeons.firstIndex(where: { $0.id == dungeon.id }) else {
            return
        }
        
        // 临时切换到选中的角色
        let originalCharacter = dungeonManager.selectedCharacter
        dungeonManager.selectedCharacter = character
        
        // 开始副本
        dungeonManager.startDungeon(at: dungeonIndex)
        
        // 恢复原来的角色
        dungeonManager.selectedCharacter = originalCharacter
        
        // 关闭窗口
        isPresented = false
    }
}

// MARK: - 日常任务卡片
struct DailyTasksCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingDailyTasksDetail = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日任务")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(taskProgressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingDailyTasksDetail = true
                }) {
                    HStack(spacing: 4) {
                        Text("详情")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 显示前3个角色的任务进度
            if !dungeonManager.characters.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(dungeonManager.characters.prefix(3)), id: \.id) { character in
                        DailyTaskProgressRow(character: character)
                    }
                    
                    if dungeonManager.characters.count > 3 {
                        Text("还有 \(dungeonManager.characters.count - 3) 个角色...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("请先添加角色")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingDailyTasksDetail) {
            DailyTasksDetailView()
        }
    }
    
    private var taskProgressText: String {
        let progress = dungeonManager.dailyTaskManager.getAllCharactersTasksProgress()
        if progress.total == 0 {
            return "等待刷新任务数据"
        } else {
            return "全部进度: \(progress.completed)/\(progress.total)"
        }
    }
}

struct DailyTaskProgressRow: View {
    let character: GameCharacter
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(character.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
            
            Text("\(completedCount)/\(totalCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var completedCount: Int {
        dungeonManager.dailyTaskManager.getCompletedTasksCount(for: character)
    }
    
    private var totalCount: Int {
        dungeonManager.dailyTaskManager.getTotalTasksCount(for: character)
    }
    
    private var progressValue: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    private var progressColor: Color {
        if totalCount == 0 { return .gray }
        if completedCount == totalCount { return .green }
        if completedCount > totalCount / 2 { return .orange }
        return .blue
    }
}

// MARK: - Dashboard 卡片组件
struct AllInProgressTasksCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("进行中任务")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("所有角色正在进行的副本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(allInProgressTasks.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            if allInProgressTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("当前没有进行中的任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("所有角色都已完成当前副本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(allInProgressTasks, id: \.taskId) { task in
                    GlobalInProgressTaskRow(task: task, currentTime: currentTime)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var allInProgressTasks: [InProgressTask] {
        var tasks: [InProgressTask] = []
        
        for (dungeonIndex, dungeon) in dungeonManager.dungeons.enumerated() {
            for (character, isInProgress) in dungeon.characterInProgress {
                if isInProgress {
                    tasks.append(InProgressTask(
                        taskId: "\(dungeon.id)-\(character.id)",
                        dungeon: dungeon,
                        character: character,
                        dungeonIndex: dungeonIndex
                    ))
                }
            }
        }
        
        return tasks.sorted { task1, task2 in
            let startTime1 = task1.dungeon.startTime(for: task1.character) ?? Date.distantPast
            let startTime2 = task2.dungeon.startTime(for: task2.character) ?? Date.distantPast
            return startTime1 > startTime2
        }
    }
}

struct InProgressTask {
    let taskId: String
    let dungeon: Dungeon
    let character: GameCharacter
    let dungeonIndex: Int
}

struct GlobalInProgressTaskRow: View {
    let task: InProgressTask
    let currentTime: Date
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCancelAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.dungeon.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(task.character.name)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(task.character.server)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let startTime = task.dungeon.startTime(for: task.character) {
                    Text("已进行 \(formatDuration(currentTime.timeIntervalSince(startTime)))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    showingCancelAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    let originalCharacter = dungeonManager.selectedCharacter
                    dungeonManager.selectedCharacter = task.character
                    dungeonManager.completeDungeon(at: task.dungeonIndex)
                    dungeonManager.selectedCharacter = originalCharacter
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .alert("取消副本", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认取消", role: .destructive) {
                let originalCharacter = dungeonManager.selectedCharacter
                dungeonManager.selectedCharacter = task.character
                dungeonManager.cancelDungeon(at: task.dungeonIndex)
                dungeonManager.selectedCharacter = originalCharacter
            }
        } message: {
            Text("确定要取消 \(task.character.name) 正在进行的「\(task.dungeon.name)」吗？")
        }
    }
}

struct GlobalTodayStatsCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("全局数据统计")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("所有角色的完成情况")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                GlobalStatItem(
                    title: "今日完成",
                    value: "\(globalTodayCompletedCount)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                GlobalStatItem(
                    title: "本周完成", 
                    value: "\(globalWeeklyCompletedCount)",
                    color: .blue,
                    icon: "calendar.circle.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                GlobalStatItem(
                    title: "总角色数",
                    value: "\(dungeonManager.characters.count)",
                    color: .purple,
                    icon: "person.3.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var globalTodayCompletedCount: Int {
        let today = Date()
        let filtered = dungeonManager.completionRecords.filter { record in
            Calendar.current.isDate(record.completedDate, inSameDayAs: today)
        }
        
        // 调试信息
        print("全局今日完成数量: \(filtered.count)")
        print("所有完成记录数量: \(dungeonManager.completionRecords.count)")
        
        return filtered.count
    }
    
    private var globalWeeklyCompletedCount: Int {
        var total = 0
        for character in dungeonManager.characters {
            for dungeon in dungeonManager.dungeons {
                total += dungeon.weeklyCount(for: character)
            }
        }
        return total
    }
}

struct GlobalStatItem: View {
    let title: String
    let value: String
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CharacterBreakdownCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("角色分组详情")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("点击查看各角色的详细数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ForEach(dungeonManager.characters) { character in
                    CharacterSummaryRow(character: character)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CharacterSummaryRow: View {
    let character: GameCharacter
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(character.server) · \(character.school)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 2) {
                    Text("\(inProgressCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("进行中")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .center, spacing: 2) {
                    Text("\(todayCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("今日")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .center, spacing: 2) {
                    Text("\(weeklyCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("本周")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var inProgressCount: Int {
        dungeonManager.dungeons.reduce(0) { total, dungeon in
            total + (dungeon.isInProgress(for: character) ? 1 : 0)
        }
    }
    
    private var todayCount: Int {
        let today = Date()
        let filtered = dungeonManager.completionRecords.filter { record in
            // 使用名字和服务器匹配，而不是只使用ID
            (record.character.id == character.id ||
             (record.character.name == character.name && record.character.server == character.server)) &&
            Calendar.current.isDate(record.completedDate, inSameDayAs: today)
        }
        
        // 调试信息
        print("角色 \(character.name) 今日完成数量: \(filtered.count)")
        let allRecords = dungeonManager.completionRecords.filter { 
            $0.character.id == character.id ||
            ($0.character.name == character.name && $0.character.server == character.server)
        }
        print("该角色所有记录: \(allRecords.count)")
        
        return filtered.count
    }
    
    private var weeklyCount: Int {
        dungeonManager.dungeons.reduce(0) { total, dungeon in
            total + dungeon.weeklyCount(for: character)
        }
    }
}

