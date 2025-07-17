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
    @State private var showingBackupManagement = false
    @State private var showingAPISettings = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // 数据管理区域
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: BackupManagementView()) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                                .symbolEffect(.bounce, value: showingBackupManagement)
                            
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
                                    .symbolEffect(.bounce, value: hasAPITokens)
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
                                .symbolEffect(.bounce, value: showingAbout)
                            
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
    @State private var tokenUsageData: [String: TokenUsageData] = [:]
    @State private var isLoadingUsage = false
    @State private var editingTokenType: EditingTokenType?
    
    enum EditingTokenType {
        case tokenV1, tokenV2, ticket
    }
    
    var body: some View {
        List {
            // 配置状态概览
            Section(header: Text("配置状态")) {
                HStack {
                    Image(systemName: hasAPITokens ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(hasAPITokens ? .green : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasAPITokens ? "API已配置" : "请配置API令牌")
                            .font(.headline)
                            .foregroundColor(hasAPITokens ? .green : .orange)
                        
                        Text("当前已配置：\(configuredTokensCount)个令牌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("帮助") {
                        showingTokenHelp = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
            
            // Token V1 配置
            Section(header: Text("Token V1 - 基础API")) {
                SimpleTokenRow(
                    title: "Token V1",
                    description: "用于基础API调用，如团队招募、装备属性等",
                    value: $jx3ApiToken,  // 直接绑定@AppStorage
                    isEditing: editingTokenType == .tokenV1,
                    usageData: tokenUsageData[jx3ApiToken],
                    isLoadingUsage: isLoadingUsage,
                    onEdit: {
                        editingTokenType = .tokenV1
                    },
                    onSave: {
                        // 值已经通过绑定自动保存
                        if !jx3ApiToken.isEmpty {
                            Task { await fetchTokenUsage(token: jx3ApiToken) }
                        }
                        stopEditing()
                    },
                    onCancel: { stopEditing() },
                    onRefresh: {
                        if !jx3ApiToken.isEmpty {
                            Task { await fetchTokenUsage(token: jx3ApiToken) }
                        }
                    }
                )
                .id("tokenV1-\(jx3ApiToken)")
            }
            
            // Token V2 配置
            Section(header: Text("Token V2 - 高级API")) {
                SimpleTokenRow(
                    title: "Token V2",
                    description: "用于高级API调用，如百战、资历统计等",
                    value: $jx3ApiTokenV2,  // 直接绑定@AppStorage
                    isEditing: editingTokenType == .tokenV2,
                    usageData: tokenUsageData[jx3ApiTokenV2],
                    isLoadingUsage: isLoadingUsage,
                    onEdit: {
                        editingTokenType = .tokenV2
                    },
                    onSave: {
                        // 值已经通过绑定自动保存
                        if !jx3ApiTokenV2.isEmpty {
                            Task { await fetchTokenUsage(token: jx3ApiTokenV2) }
                        }
                        stopEditing()
                    },
                    onCancel: { stopEditing() },
                    onRefresh: {
                        if !jx3ApiTokenV2.isEmpty {
                            Task { await fetchTokenUsage(token: jx3ApiTokenV2) }
                        }
                    }
                )
                .id("tokenV2-\(jx3ApiTokenV2)")
            }
            
            // Ticket 配置
            Section(header: Text("Ticket - 角色信息")) {
                SimpleTokenRow(
                    title: "Ticket",
                    description: "用于角色详细信息查询，格式：ticket:timestamp:platform::hash",
                    value: $jx3ApiTicket,  // 直接绑定@AppStorage
                    isEditing: editingTokenType == .ticket,
                    usageData: nil,
                    isLoadingUsage: false,
                    onEdit: {
                        editingTokenType = .ticket
                    },
                    onSave: {
                        // 值已经通过绑定自动保存
                        stopEditing()
                    },
                    onCancel: { stopEditing() },
                    onRefresh: nil
                )
                .id("ticket-\(jx3ApiTicket)")
            }
            
            // 操作按钮
            Section(header: Text("操作")) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.blue)
                    
                    Button("刷新所有Token用量") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        Task {
                            await refreshAllTokenUsage()
                        }
                    }
                    .disabled(jx3ApiToken.isEmpty && jx3ApiTokenV2.isEmpty)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                    
                    Button("清除所有配置") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        jx3ApiToken = ""
                        jx3ApiTokenV2 = ""
                        jx3ApiTicket = ""
                        tokenUsageData.removeAll()
                    }
                    
                    Spacer()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("API设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTokenHelp) {
            TokenHelpView()
        }
        .task {
            await refreshAllTokenUsage()
        }
    }
    
    private var hasAPITokens: Bool {
        !jx3ApiToken.isEmpty || !jx3ApiTokenV2.isEmpty || !jx3ApiTicket.isEmpty
    }
    
    private var configuredTokensCount: Int {
        var count = 0
        if !jx3ApiToken.isEmpty { count += 1 }
        if !jx3ApiTokenV2.isEmpty { count += 1 }
        if !jx3ApiTicket.isEmpty { count += 1 }
        return count
    }
    
    private func stopEditing() {
        editingTokenType = nil
    }
    
    private func fetchTokenUsage(token: String) async {
        guard !token.isEmpty else { return }
        
        isLoadingUsage = true
        defer { isLoadingUsage = false }
        
        do {
            let usage = try await JX3APIService.shared.fetchTokenUsage(token: token)
            await MainActor.run {
                tokenUsageData[token] = usage
            }
        } catch {
            print("获取Token用量失败: \(error)")
        }
    }
    
    private func refreshAllTokenUsage() async {
        await withTaskGroup(of: Void.self) { group in
            if !jx3ApiToken.isEmpty {
                group.addTask {
                    await fetchTokenUsage(token: jx3ApiToken)
                }
            }
            
            if !jx3ApiTokenV2.isEmpty {
                group.addTask {
                    await fetchTokenUsage(token: jx3ApiTokenV2)
                }
            }
        }
    }
}

// MARK: - Token类型枚举
enum TokenType {
    case v1
    case v2
}

// MARK: - 简化的Token行视图
struct SimpleTokenRow: View {
    let title: String
    let description: String
    @Binding var value: String  // 直接绑定到@AppStorage
    let isEditing: Bool
    let usageData: TokenUsageData?
    let isLoadingUsage: Bool
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onRefresh: (() -> Void)?
    
    @State private var originalValue: String = ""  // 保存原始值用于取消
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和状态
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 状态指示器
                    Image(systemName: value.isEmpty ? "xmark.circle" : "checkmark.circle.fill")
                        .foregroundColor(value.isEmpty ? .red : .green)
                        .font(.title2)
                    
                    // 刷新按钮
                    if !value.isEmpty && onRefresh != nil {
                        Button(action: { onRefresh?() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoadingUsage)
                    }
                }
            }
            
            // 编辑区域或显示区域
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("请输入\(title)", text: $value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onAppear {
                            originalValue = value  // 保存原始值
                        }
                    
                    HStack {
                        Button("取消") {
                            value = originalValue  // 恢复原始值
                            onCancel()
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button("保存") {
                            // value已经通过绑定自动保存到@AppStorage了
                            print("DEBUG: 保存后的value = '\(value)'")
                            onSave()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    }
                }
            } else {
                // 显示当前值
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if value.isEmpty {
                            Text("未配置")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        } else {
                            Text("已配置 (\(String(value.prefix(8)))...)")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        // 用量信息
                        if let usage = usageData {
                            HStack(spacing: 4) {
                                Text("用量：\(usage.count)")
                                    .foregroundColor(.orange)
                                Text("/")
                                    .foregroundColor(.secondary)
                                Text(usage.level == 1 && usage.limit == 1 ? "无限制" : "\(usage.limit)")
                                    .foregroundColor(usage.level == 1 && usage.limit == 1 ? .green : .blue)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                        } else if isLoadingUsage {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("检查用量中...")
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Spacer()
                    
                    Button("编辑") {
                        onEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // 用量进度条
            if let usage = usageData, usage.level == 2 || (usage.level == 1 && usage.limit > 1) {
                let percentage = Double(usage.count) / Double(usage.limit)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("使用进度")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(percentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(percentage > 0.8 ? .red : percentage > 0.6 ? .orange : .green)
                    }
                    
                    ProgressView(value: percentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: percentage > 0.8 ? .red : percentage > 0.6 ? .orange : .green))
                        .frame(height: 6)
                }
            }
        }
        .padding(.vertical, 8)
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
                        
                        Text("• 用于基础API调用，如团队招募、装备属性等")
                        Text("• 获取地址：https://store.jx3api.com")
                        Text("• 需付费")
                        
                        Text("Token V2")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 用于高级API调用，如百战、资历统计等")
                        Text("• 需要付费用户权限")
                        Text("• 私聊神奇姐姐获取")
                        
                        Text("Ticket")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 用于角色详细信息查询")
                        Text("• 格式：ticket:timestamp:platform::hash")
                        Text("• 从推栏获取")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: YearlyReportView().environmentObject(dungeonManager)) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                            Text("年统计")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
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

// MARK: - 仪表盘页面（Dashboard）
struct DashboardView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingQuickStart = false
    @State private var showingCharacterSelector = false
    
    var body: some View {
        NavigationView {
            List {
                // 欢迎回来区域
                Section {
                    WelcomeBackRow()
                }
                
                // 周副本完成进度（圆形进度条）
                Section {
                    WeeklyProgressRow()
                }
                
                // 全局数据统计
                Section {
                    GlobalStatsRows()
                }
                
                // 全局进行中任务
                Section {
                    AllInProgressTasksRows()
                }
                
                // 角色分组显示
                if !dungeonManager.characters.isEmpty {
                    Section {
                        CharacterBreakdownRows()
                    }
                }
            }
            .navigationTitle("仪表盘")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingQuickStart = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingQuickStart) {
                QuickStartView(isPresented: $showingQuickStart)
            }
            .sheet(isPresented: $showingCharacterSelector) {
                CharacterSelectorView(isPresented: $showingCharacterSelector)
            }
            .onAppear {
                // 初始化仪表盘
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



struct InProgressTask {
    let taskId: String
    let dungeon: Dungeon
    let character: GameCharacter
    let dungeonIndex: Int
}

// MARK: - 周副本完成进度行
struct WeeklyProgressRow: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 圆形进度条
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progressPercentage)
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("本周完成")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(currentWeekCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("目标（上周）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(lastWeekCount)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text(differenceText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(differenceColor)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var currentWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return dungeonManager.completionRecords.filter { record in
            record.completedDate >= startOfWeek
        }.count
    }
    
    private var lastWeekCount: Int {
        // 获取上周的周报告数据，与周统计页面保持一致
        let calendar = Calendar.current
        let now = Date()
        
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
            return 0
        }
        
        // 查找对应的周报告
        if let lastWeekReport = dungeonManager.availableGameWeeks.first(where: { report in
            calendar.isDate(report.startDate, inSameDayAs: lastWeekStart)
        }) {
            // 使用与周统计相同的计算方式
            let weekRecords = dungeonManager.completionRecords.filter { record in
                record.completedDate >= lastWeekReport.startDate && record.completedDate <= lastWeekReport.endDate
            }
            return weekRecords.count
        }
        
        // 如果没有找到对应的周报告，回退到原始计算方式
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart) ?? lastWeekStart
        return dungeonManager.completionRecords.filter { record in
            record.completedDate >= lastWeekStart && record.completedDate <= lastWeekEnd
        }.count
    }
    
    private var progressPercentage: CGFloat {
        guard lastWeekCount > 0 else { return 0 }
        return min(CGFloat(currentWeekCount) / CGFloat(lastWeekCount), 1.0)
    }
    
    private var progressColor: Color {
        if progressPercentage >= 1.0 {
            return .green
        } else if progressPercentage >= 0.7 {
            return .blue
        } else if progressPercentage >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var differenceText: String {
        let difference = currentWeekCount - lastWeekCount
        if difference > 0 {
            return "超出 \(difference) 个"
        } else if difference < 0 {
            return "还差 \(abs(difference)) 个"
        } else {
            return "刚好达标"
        }
    }
    
    private var differenceColor: Color {
        let difference = currentWeekCount - lastWeekCount
        if difference > 0 {
            return .green
        } else if difference < 0 {
            return .red
        } else {
            return .blue
        }
    }
}

// MARK: - 全局数据统计行
struct GlobalStatsRows: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        Group {
            // 单个角色最高完成数
            HStack {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("单角色最高")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if let topCharacter = singleCharacterMaxInfo.character {
                        Text(topCharacter.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(singleCharacterMaxInfo.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // 副本最高记录
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("副本最高记录")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if let topDungeon = dungeonMaxCompletions.dungeon {
                        Text(topDungeon.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(dungeonMaxCompletions.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            // 本周完成总数
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("本周完成")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(globalWeeklyCompletedCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // 总角色数
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("总角色数")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(dungeonManager.characters.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
        }
    }
    
    // 单个角色最大完成数的详细信息
    private var singleCharacterMaxInfo: (character: GameCharacter?, count: Int) {
        var maxCount = 0
        var topCharacter: GameCharacter?
        
        for character in dungeonManager.characters {
            let characterCount = dungeonManager.completionRecords.filter { record in
                record.character.id == character.id ||
                (record.character.name == character.name && record.character.server == character.server)
            }.count
            
            if characterCount > maxCount {
                maxCount = characterCount
                topCharacter = character
            }
        }
        
        return (topCharacter, maxCount)
    }
    
    // 某副本的最大完成数
    private var dungeonMaxCompletions: (dungeon: Dungeon?, count: Int) {
        var maxCount = 0
        var topDungeon: Dungeon?
        
        for dungeon in dungeonManager.dungeons {
            let dungeonCount = dungeonManager.completionRecords.filter { record in
                record.dungeonName == dungeon.name
            }.count
            
            if dungeonCount > maxCount {
                maxCount = dungeonCount
                topDungeon = dungeon
            }
        }
        
        return (topDungeon, maxCount)
    }
    
    // 本周完成数
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

// MARK: - 进行中任务行
struct AllInProgressTasksRows: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Group {
            if allInProgressTasks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("当前没有进行中的任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(allInProgressTasks, id: \.taskId) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.dungeon.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Text(task.character.name)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("·")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(task.character.server)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            if let startTime = task.dungeon.startTime(for: task.character) {
                                Text(formatDuration(currentTime.timeIntervalSince(startTime)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    let originalCharacter = dungeonManager.selectedCharacter
                                    dungeonManager.selectedCharacter = task.character
                                    dungeonManager.cancelDungeon(at: task.dungeonIndex)
                                    dungeonManager.selectedCharacter = originalCharacter
                                }) {
                                    Image(systemName: "xmark.circle.fill")
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
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
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

// MARK: - 角色分组行
struct CharacterBreakdownRows: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            // 展开/收起按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("角色详情")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 角色列表
            if isExpanded {
                ForEach(dungeonManager.characters) { character in
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(character.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("\(character.server) · \(character.school)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .center, spacing: 2) {
                                Text("\(inProgressCount(for: character))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("进行中")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .center, spacing: 2) {
                                Text("\(weeklyCount(for: character))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("本周")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func inProgressCount(for character: GameCharacter) -> Int {
        dungeonManager.dungeons.reduce(0) { total, dungeon in
            total + (dungeon.isInProgress(for: character) ? 1 : 0)
        }
    }
    
    private func weeklyCount(for character: GameCharacter) -> Int {
        dungeonManager.dungeons.reduce(0) { total, dungeon in
            total + dungeon.weeklyCount(for: character)
        }
    }
}

// MARK: - 年统计视图
struct YearlyStatisticsView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    private var availableYears: [Int] {
        var allDates: [Date] = dungeonManager.completionRecords.map { $0.completedDate }
        allDates.append(contentsOf: getAllTaskCompletionRecords().map { $0.completedDate })
        
        let years = Set(allDates.compactMap { date in
            Calendar.current.component(.year, from: date)
        })
        return Array(years).sorted(by: >)
    }
    
    private var yearlyData: YearlyStatisticsData {
        YearlyStatisticsData(year: selectedYear, dungeonManager: dungeonManager)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 年份选择器
                if !availableYears.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("选择年份")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Picker("年份", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text("\(year)年").tag(year)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // 年度总览
                YearlyOverviewCard(data: yearlyData)
                
                // 副本详细统计
                if !yearlyData.dungeonSummaries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("各副本年度统计")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(yearlyData.dungeonSummaries) { summary in
                            YearlyDungeonSummaryCard(summary: summary)
                        }
                    }
                }
                
                // 角色年度统计
                if !yearlyData.characterSummaries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("各角色年度统计")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(yearlyData.characterSummaries) { summary in
                            YearlyCharacterSummaryCard(summary: summary)
                        }
                    }
                }
                
                if yearlyData.totalDungeonCompletions == 0 && yearlyData.totalTasksCompleted == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("\(selectedYear)年暂无统计数据")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("完成一些副本或任务后，这里将显示年度统计")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding()
        }
        .onAppear {
            if availableYears.isEmpty {
                selectedYear = Calendar.current.component(.year, from: Date())
            } else if !availableYears.contains(selectedYear) {
                selectedYear = availableYears.first ?? Calendar.current.component(.year, from: Date())
            }
        }
    }
    
    // 获取所有任务完成记录（模拟数据，实际需要从DailyTaskManager获取）
    private func getAllTaskCompletionRecords() -> [TaskCompletionRecord] {
        var records: [TaskCompletionRecord] = []
        
        for characterTasks in dungeonManager.dailyTaskManager.characterDailyTasks {
            if let character = dungeonManager.characters.first(where: { $0.id == characterTasks.characterId }) {
                for task in characterTasks.tasks {
                    if task.isCompleted, let completedDate = task.completedDate {
                        records.append(TaskCompletionRecord(
                            character: character,
                            taskName: task.type.displayName,
                            completedDate: completedDate
                        ))
                    }
                }
            }
        }
        
        return records
    }
}

// MARK: - 年统计数据模型
struct YearlyStatisticsData {
    let year: Int
    let totalDungeonCompletions: Int
    let totalTasksCompleted: Int
    let dungeonSummaries: [YearlyDungeonSummary]
    let characterSummaries: [YearlyCharacterSummary]
    
    init(year: Int, dungeonManager: DungeonManager) {
        self.year = year
        
        // 获取指定年份的所有副本完成记录
        let yearRecords = dungeonManager.completionRecords.filter { record in
            Calendar.current.component(.year, from: record.completedDate) == year
        }
        
        self.totalDungeonCompletions = yearRecords.count
        
        // 获取指定年份的所有任务完成记录
        var yearTaskRecords: [TaskCompletionRecord] = []
        for characterTasks in dungeonManager.dailyTaskManager.characterDailyTasks {
            if let character = dungeonManager.characters.first(where: { $0.id == characterTasks.characterId }) {
                for task in characterTasks.tasks {
                    if task.isCompleted, let completedDate = task.completedDate,
                       Calendar.current.component(.year, from: completedDate) == year {
                        yearTaskRecords.append(TaskCompletionRecord(
                            character: character,
                            taskName: task.type.displayName,
                            completedDate: completedDate
                        ))
                    }
                }
            }
        }
        
        self.totalTasksCompleted = yearTaskRecords.count
        
        // 生成副本统计摘要
        let dungeonGroups = Dictionary(grouping: yearRecords) { $0.dungeonName }
        self.dungeonSummaries = dungeonGroups.map { (dungeonName, records) in
            let totalDuration = records.reduce(0) { $0 + $1.duration }
            let averageTime = records.count > 0 ? totalDuration / Double(records.count) : 0
            let characterCount = Set(records.map { "\($0.character.server)-\($0.character.name)" }).count
            
            return YearlyDungeonSummary(
                dungeonName: dungeonName,
                totalCompletions: records.count,
                averageTime: averageTime,
                participatingCharacters: characterCount,
                year: year
            )
        }.sorted { $0.totalCompletions > $1.totalCompletions }
        
        // 生成角色统计摘要
        let characterGroups = Dictionary(grouping: yearRecords) { record in
            "\(record.character.server)-\(record.character.name)"
        }
        
        self.characterSummaries = characterGroups.compactMap { (key, records) -> YearlyCharacterSummary? in
            guard let firstRecord = records.first else { return nil }
            
            let taskCount = yearTaskRecords.filter { taskRecord in
                "\(taskRecord.character.server)-\(taskRecord.character.name)" == key
            }.count
            
            return YearlyCharacterSummary(
                character: firstRecord.character,
                dungeonCompletions: records.count,
                taskCompletions: taskCount,
                year: year
            )
        }.sorted { $0.dungeonCompletions + $0.taskCompletions > $1.dungeonCompletions + $1.taskCompletions }
    }
}

struct TaskCompletionRecord {
    let character: GameCharacter
    let taskName: String
    let completedDate: Date
}

struct YearlyDungeonSummary: Identifiable {
    let id = UUID()
    let dungeonName: String
    let totalCompletions: Int
    let averageTime: TimeInterval
    let participatingCharacters: Int
    let year: Int
}

struct YearlyCharacterSummary: Identifiable {
    let id = UUID()
    let character: GameCharacter
    let dungeonCompletions: Int
    let taskCompletions: Int
    let year: Int
}

// MARK: - 年统计UI组件
struct YearlyOverviewCard: View {
    let data: YearlyStatisticsData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(data.year)年度总览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                OverviewMetric(
                    title: "副本完成总数",
                    value: "\(data.totalDungeonCompletions)",
                    subtitle: "次",
                    color: .blue
                )
                
                OverviewMetric(
                    title: "任务完成总数", 
                    value: "\(data.totalTasksCompleted)",
                    subtitle: "个",
                    color: .green
                )
                
                OverviewMetric(
                    title: "涉及副本数",
                    value: "\(data.dungeonSummaries.count)",
                    subtitle: "个",
                    color: .orange
                )
                
                OverviewMetric(
                    title: "活跃角色数",
                    value: "\(data.characterSummaries.count)",
                    subtitle: "个",
                    color: .purple
                )
            }
            
            if data.totalDungeonCompletions > 0 || data.totalTasksCompleted > 0 {
                let totalActivities = data.totalDungeonCompletions + data.totalTasksCompleted
                Text(totalActivities >= 1000 ? "年度游戏活跃度：资深玩家" :
                     totalActivities >= 500 ? "年度游戏活跃度：活跃玩家" :
                     totalActivities >= 100 ? "年度游戏活跃度：普通玩家" : "年度游戏活跃度：偶尔上线")
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

struct YearlyDungeonSummaryCard: View {
    let summary: YearlyDungeonSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.dungeonName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(summary.totalCompletions) 次")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均用时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDurationShort(summary.averageTime))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("参与角色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(summary.participatingCharacters) 个")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("统计年份")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(summary.year)年")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct YearlyCharacterSummaryCard: View {
    let summary: YearlyCharacterSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.character.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("总计 \(summary.dungeonCompletions + summary.taskCompletions)")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("副本完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(summary.dungeonCompletions) 次")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(summary.taskCompletions) 个")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("服务器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(summary.character.server)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - 欢迎回来行
struct WelcomeBackRow: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCharacterSelector = false
    
    private var currentTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        case 18..<22:
            return "晚上好"
        default:
            return "深夜好"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if let selectedCharacter = dungeonManager.selectedCharacter {
                    HStack(spacing: 8) {
                        Text(currentTime + "，")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(selectedCharacter.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(selectedCharacter.server)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "theatermasks.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text(selectedCharacter.school)
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("点击切换角色")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("欢迎回来！")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("点击选择角色")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            showingCharacterSelector = true
        }
        .sheet(isPresented: $showingCharacterSelector) {
            CharacterSelectorView(isPresented: $showingCharacterSelector)
        }
    }
}

