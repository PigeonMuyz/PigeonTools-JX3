//
//  BackupManagementView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 备份管理视图
struct BackupManagementView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @StateObject private var enhancedBackupService = EnhancedBackupService.shared
    @State private var jsonBackupHistory: [BackupHistoryItem] = []
    @State private var isCreatingJsonBackup = false
    @State private var showingDataStatus = false
    @State private var showingBackupConfig = false
    @State private var showingFilePicker = false
    @State private var showingShareSheet = false
    @State private var showingBackupPreview = false
    @State private var isLoadingBackupFile = false
    @State private var backupFileURL: URL?
    @State private var backupResult: BackupResult?
    @State private var restoreResult: RestoreResult?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var backupConfig = BackupConfiguration.default
    @State private var previewBackupData: AppBackupData?
    
    var body: some View {
        NavigationView {
            List {
                // 数据状态区域
                Section(header: Text("数据状态")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("角色数量: \(dungeonManager.characters.count)")
                        }
                        
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.green)
                            Text("副本数量: \(dungeonManager.dungeons.count)")
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("完成记录: \(dungeonManager.completionRecords.count)")
                        }
                        
                        Button("查看详细信息") {
                            showingDataStatus = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // 操作区域
                Section(header: Text("操作")) {
                    Button(action: {
                        showingBackupConfig = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.green)
                            Text("导出JSON备份")
                            Spacer()
                            if isCreatingJsonBackup {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isCreatingJsonBackup)
                    
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(.orange)
                            Text("导入JSON备份")
                            Spacer()
                            if isLoadingBackupFile {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isLoadingBackupFile)
                }
                
                // 备份列表
                Section(header: HStack {
                    Text("备份列表")
                    Spacer()
                    Text("\(jsonBackupHistory.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }) {
                    if jsonBackupHistory.isEmpty {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("暂无备份")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(jsonBackupHistory) { backup in
                            JsonBackupRowView(backup: backup) {
                                shareJsonBackup(backup)
                            }
                        }
                        .onDelete(perform: deleteJsonBackup)
                    }
                }
            }
            .navigationTitle("备份管理")
            .onAppear {
                refreshJsonBackupHistory()
            }
            .sheet(isPresented: $showingDataStatus) {
                DataStatusView(statusInfo: dungeonManager.getDataStatusInfo())
            }
            .sheet(isPresented: $showingBackupConfig) {
                BackupConfigurationView(
                    configuration: $backupConfig,
                    onCreateBackup: {
                        showingBackupConfig = false
                        createJsonBackup()
                    }
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = backupFileURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingBackupPreview) {
                if let previewData = previewBackupData {
                    BackupPreviewView(backupData: previewData) {
                        // 确认导入
                        Task {
                            await performBackupImport()
                        }
                    } onCancel: {
                        // 取消导入
                        previewBackupData = nil
                        showingBackupPreview = false
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        previewJsonBackup(from: url)
                    }
                case .failure(let error):
                    alertMessage = "文件选择失败: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func refreshJsonBackupHistory() {
        jsonBackupHistory = enhancedBackupService.getBackupHistory()
    }
    
    private func createJsonBackup() {
        isCreatingJsonBackup = true
        
        Task {
            let result = await enhancedBackupService.createFullBackup(configuration: backupConfig)
            
            await MainActor.run {
                isCreatingJsonBackup = false
                
                if result.success {
                    backupFileURL = result.fileURL
                    alertMessage = "JSON备份创建成功！"
                    showingAlert = true
                    refreshJsonBackupHistory()
                } else {
                    alertMessage = result.message
                    showingAlert = true
                }
            }
        }
    }
    
    private func shareJsonBackup(_ backup: BackupHistoryItem) {
        let fileURL = URL(fileURLWithPath: backup.filePath)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            backupFileURL = fileURL
            showingShareSheet = true
        } else {
            alertMessage = "备份文件不存在"
            showingAlert = true
        }
    }
    
    private func previewJsonBackup(from url: URL) {
        Task {
            // 显示加载状态
            await MainActor.run {
                isLoadingBackupFile = true
            }
            
            // 获取文件访问权限
            guard url.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    isLoadingBackupFile = false
                    alertMessage = "无法获取文件访问权限"
                    showingAlert = true
                }
                return
            }
            
            defer {
                // 释放文件访问权限
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let jsonData = try Data(contentsOf: url)
                let backupData = try JSONDecoder().decode(AppBackupData.self, from: jsonData)
                
                await MainActor.run {
                    isLoadingBackupFile = false
                    previewBackupData = backupData
                    backupFileURL = url
                    showingBackupPreview = true
                }
            } catch {
                await MainActor.run {
                    isLoadingBackupFile = false
                    alertMessage = "备份文件解析失败: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func performBackupImport() async {
        guard let url = backupFileURL else { return }
        
        // 获取文件访问权限
        guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                alertMessage = "无法获取文件访问权限"
                showingAlert = true
            }
            return
        }
        
        defer {
            // 释放文件访问权限
            url.stopAccessingSecurityScopedResource()
        }
        
        let result = await enhancedBackupService.restoreFromBackup(fileURL: url)
        
        await MainActor.run {
            showingBackupPreview = false
            previewBackupData = nil
            backupFileURL = nil
            
            if result.success {
                alertMessage = "备份导入成功！已恢复: \(result.restoredDataTypes.joined(separator: ", "))"
                refreshJsonBackupHistory()
                
                // 通知DungeonManager重新加载数据
                dungeonManager.reloadAllData()
            } else {
                alertMessage = result.message
            }
            showingAlert = true
        }
    }
    
    private func deleteJsonBackup(at offsets: IndexSet) {
        for index in offsets {
            let backup = jsonBackupHistory[index]
            let fileURL = URL(fileURLWithPath: backup.filePath)
            
            // 删除文件
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("备份文件删除成功: \(backup.filePath)")
            } catch {
                print("删除备份文件失败: \(error)")
            }
        }
        
        // 从历史记录中移除
        jsonBackupHistory.remove(atOffsets: offsets)
        
        // 更新UserDefaults中的历史记录
        updateBackupHistory()
    }
    
    private func updateBackupHistory() {
        if let encoded = try? JSONEncoder().encode(jsonBackupHistory) {
            UserDefaults.standard.set(encoded, forKey: "backup_history")
        }
    }
}


// MARK: - JSON备份行视图
struct JsonBackupRowView: View {
    let backup: BackupHistoryItem
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(backup.timestamp))
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("包含: \(backup.dataTypes.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("文件大小: \(formatFileSize(backup.fileSize))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("分享") {
                    onShare()
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - 备份配置视图
struct BackupConfigurationView: View {
    @Binding var configuration: BackupConfiguration
    @Environment(\.dismiss) private var dismiss
    let onCreateBackup: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("备份内容")) {
                    Toggle("核心数据", isOn: $configuration.includeCoreData)
                    Toggle("配置数据", isOn: $configuration.includeConfigData)
                    Toggle("任务数据", isOn: $configuration.includeTaskData)
                    Toggle("缓存数据", isOn: $configuration.includeCacheData)
                }
                
                Section(header: Text("选项")) {
                    Toggle("启用压缩", isOn: $configuration.compressionEnabled)
                    Toggle("启用加密", isOn: $configuration.encryptionEnabled)
                }
                
                Section(header: Text("说明")) {
                    Text("核心数据: 副本、角色、完成记录等")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("配置数据: API令牌、应用设置等")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("任务数据: 日常任务进度等")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("缓存数据: 名片缓存、成就缓存等")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("备份配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        onCreateBackup()
                    }
                    .disabled(!configuration.includeCoreData && !configuration.includeConfigData && !configuration.includeTaskData && !configuration.includeCacheData)
                }
            }
        }
    }
}

// MARK: - 备份预览视图
struct BackupPreviewView: View {
    let backupData: AppBackupData
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 备份信息
                Section(header: Text("备份信息")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(backupData.backupInfo.version)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(formatDate(backupData.backupInfo.timestamp))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("设备型号")
                        Spacer()
                        Text(backupData.backupInfo.deviceInfo.deviceModel)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("系统版本")
                        Spacer()
                        Text(backupData.backupInfo.deviceInfo.systemVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("应用版本")
                        Spacer()
                        Text(backupData.backupInfo.deviceInfo.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 数据内容
                Section(header: Text("数据内容")) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                        Text("角色")
                        Spacer()
                        Text("\(backupData.coreData.characters.count) 个")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.green)
                        Text("副本")
                        Spacer()
                        Text("\(backupData.coreData.dungeons.count) 个")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("完成记录")
                        Spacer()
                        Text("\(backupData.coreData.completionRecords.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.purple)
                        Text("分类")
                        Spacer()
                        Text("\(backupData.coreData.categories.count) 个")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.red)
                        Text("任务数据")
                        Spacer()
                        Text("\(backupData.taskData.characterDailyTasks.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.cyan)
                        Text("名片缓存")
                        Spacer()
                        Text("\(backupData.cacheData.characterCards.count) 个")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 包含的数据类型
                Section(header: Text("包含的数据类型")) {
                    ForEach(backupData.backupInfo.dataTypes, id: \.self) { dataType in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(dataType)
                        }
                    }
                }
            }
            .navigationTitle("备份预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("导入") {
                        onConfirm()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 数据状态视图
struct DataStatusView: View {
    let statusInfo: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(statusInfo)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("数据状态")
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
