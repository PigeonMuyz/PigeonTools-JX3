//
//  BackupManagementView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import SwiftUI

// MARK: - 备份管理视图
struct BackupManagementView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var backups: [BackupInfo] = []
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: BackupInfo?
    @State private var showingDeleteAlert = false
    @State private var backupToDelete: BackupInfo?
    @State private var isCreatingBackup = false
    @State private var showingDataStatus = false
    
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
                        createNewBackup()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("创建新备份")
                            Spacer()
                            if isCreatingBackup {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isCreatingBackup)
                }
                
                // 备份列表
                Section(header: HStack {
                    Text("备份列表")
                    Spacer()
                    Text("\(backups.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }) {
                    if backups.isEmpty {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundColor(.gray)
                            Text("暂无备份")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(backups) { backup in
                            BackupRowView(
                                backup: backup,
                                onRestore: {
                                    selectedBackup = backup
                                    showingRestoreAlert = true
                                },
                                onDelete: {
                                    backupToDelete = backup
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("备份管理")
            .onAppear {
                refreshBackups()
            }
            .alert("恢复备份", isPresented: $showingRestoreAlert) {
                Button("取消", role: .cancel) { }
                Button("恢复", role: .destructive) {
                    if let backup = selectedBackup {
                        restoreBackup(backup)
                    }
                }
            } message: {
                Text("确定要从备份「\(selectedBackup?.displayName ?? "")」恢复数据吗？\n\n警告：这将覆盖当前所有数据！")
            }
            .alert("删除备份", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let backup = backupToDelete {
                        deleteBackup(backup)
                    }
                }
            } message: {
                Text("确定要删除备份「\(backupToDelete?.displayName ?? "")」吗？\n\n此操作不可恢复！")
            }
            .sheet(isPresented: $showingDataStatus) {
                DataStatusView(statusInfo: dungeonManager.getDataStatusInfo())
            }
        }
    }
    
    private func refreshBackups() {
        backups = dungeonManager.getAvailableBackups()
    }
    
    private func createNewBackup() {
        isCreatingBackup = true
        
        if let backupId = dungeonManager.createBackup() {
            print("备份创建成功: \(backupId)")
            refreshBackups()
        } else {
            print("备份创建失败")
        }
        
        isCreatingBackup = false
    }
    
    private func restoreBackup(_ backup: BackupInfo) {
        if dungeonManager.restoreFromBackup(backup.suffix) {
            print("数据恢复成功")
            refreshBackups()
        } else {
            print("数据恢复失败")
        }
    }
    
    private func deleteBackup(_ backup: BackupInfo) {
        if dungeonManager.deleteBackup(backup.suffix) {
            print("备份删除成功")
            refreshBackups()
        } else {
            print("备份删除失败")
        }
    }
}

// MARK: - 备份行视图
struct BackupRowView: View {
    let backup: BackupInfo
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("包含 \(backup.keys.count) 项数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("备份ID: \(backup.suffix)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("恢复") {
                        onRestore()
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(6)
                    
                    Button("删除") {
                        onDelete()
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 4)
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
