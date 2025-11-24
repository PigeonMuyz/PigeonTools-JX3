//
//  MigrationTestView.swift
//  DungeonStat
//
//  数据迁移测试和管理视图
//

import SwiftUI

struct MigrationTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMigrating = false
    @State private var migrationResult: MigrationResult?
    @State private var showingResult = false
    @State private var showingLogs = false

    private let migrationManager = MigrationManager.shared

    var body: some View {
        NavigationView {
            List {
                // 当前版本信息
                Section(header: Text("当前版本")) {
                    HStack {
                        Text("数据版本")
                        Spacer()
                        Text(migrationManager.currentVersion.description)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("是否需要迁移")
                        Spacer()
                        if migrationManager.needsMigration(to: .v2_characterID) {
                            Label("需要", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        } else {
                            Label("最新", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }

                // 迁移操作
                Section(header: Text("迁移操作")) {
                    // V1 -> V2 迁移
                    Button {
                        performMigration(to: .v2_characterID)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("迁移到 V2")
                                    .font(.headline)
                                Text("修复内存管理问题")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isMigrating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.circle")
                            }
                        }
                    }
                    .disabled(isMigrating || !migrationManager.needsMigration(to: .v2_characterID))

                    // V2 -> V3 迁移
                    Button {
                        performMigration(to: .v3_coreDataHybrid)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("迁移到 V3")
                                    .font(.headline)
                                Text("建立 Core Data 双轨存储")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isMigrating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.circle")
                            }
                        }
                    }
                    .disabled(isMigrating || !migrationManager.needsMigration(to: .v3_coreDataHybrid))
                }

                // 迁移日志
                Section(header: Text("迁移日志")) {
                    Button {
                        showingLogs = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("查看迁移日志")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        migrationManager.clearMigrationLogs()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除日志")
                        }
                    }
                }

                // 危险操作
                Section(header: Text("高级操作"),
                       footer: Text("⚠️ 这些操作可能会影响数据，请谨慎使用")) {
                    if let result = migrationResult, result.isRollbackAvailable {
                        Button(role: .destructive) {
                            rollbackMigration(result)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("回滚最近的迁移")
                                Spacer()
                                Text(result.toVersion.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("数据迁移")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                if let result = migrationResult {
                    MigrationResultView(result: result)
                }
            }
            .sheet(isPresented: $showingLogs) {
                MigrationLogsView()
            }
        }
    }

    // MARK: - 操作方法

    private func performMigration(to version: DataVersion) {
        isMigrating = true

        Task {
            let result = await migrationManager.migrate(to: version)

            await MainActor.run {
                self.migrationResult = result
                self.isMigrating = false
                self.showingResult = true
            }
        }
    }

    private func rollbackMigration(_ result: MigrationResult) {
        guard let backupId = result.backupId else { return }

        let success = migrationManager.rollback(to: result.fromVersion, using: backupId)

        if success {
            // 显示成功提示
            print("回滚成功")
        } else {
            // 显示失败提示
            print("回滚失败")
        }
    }
}

// MARK: - 迁移结果视图

struct MigrationResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: MigrationResult

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 结果状态
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(result.success ? .green : .red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.success ? "迁移成功" : "迁移失败")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(result.fromVersion.description) → \(result.toVersion.description)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // 错误信息
                    if let error = result.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("错误信息")
                                .font(.headline)

                            Text(error.localizedDescription)
                                .font(.callout)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // 迁移日志
                    VStack(alignment: .leading, spacing: 8) {
                        Text("迁移日志")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.migrationLog, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(logColor(for: log))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // 备份信息
                    if let backupId = result.backupId {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备份信息")
                                .font(.headline)

                            HStack {
                                Image(systemName: "archivebox.fill")
                                    .foregroundColor(.blue)
                                Text(backupId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("迁移结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func logColor(for log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else {
            return .primary
        }
    }
}

// MARK: - 迁移日志视图

struct MigrationLogsView: View {
    @Environment(\.dismiss) private var dismiss
    private let logs = MigrationManager.shared.getMigrationLogs()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if logs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("暂无迁移日志")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("迁移日志")
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

#Preview {
    MigrationTestView()
}
