//
//  ServerStatusIndicator.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/18.
//

import SwiftUI
import Foundation

// MARK: - 服务器状态指示灯
struct ServerStatusIndicator: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @StateObject private var serverStatusManager = ServerStatusManager.shared
    @State private var showingStatusDetail = false
    
    private var overallStatus: ServerOverallStatus {
        serverStatusManager.getOverallStatus(for: dungeonManager.characters)
    }
    
    var body: some View {
        Button(action: {
            showingStatusDetail = true
        }) {
            HStack(spacing: 6) {
                // 指示灯圆点
                Circle()
                    .fill(overallStatus.indicatorColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(overallStatus.indicatorColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(serverStatusManager.isLoading ? 1.5 : 1.0)
                            .opacity(serverStatusManager.isLoading ? 0 : 1)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: serverStatusManager.isLoading)
                    )
                
                // 状态文本（可选，根据空间决定是否显示）
                if !dungeonManager.characters.isEmpty {
                    Text(shortStatusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingStatusDetail) {
            ServerStatusDetailView()
                .environmentObject(dungeonManager)
        }
    }
    
    private var shortStatusText: String {
        switch overallStatus {
        case .allOnline:
            return "正常"
        case .allOffline:
            return "维护"
        case .partialOffline:
            return "部分维护"
        case .unknown:
            return "检查中"
        }
    }
}

// MARK: - 服务器状态详情视图
struct ServerStatusDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dungeonManager: DungeonManager
    @StateObject private var serverStatusManager = ServerStatusManager.shared
    
    private var userServerStatuses: [ServerStatus] {
        serverStatusManager.getUserServerStatuses(for: dungeonManager.characters)
    }
    
    var body: some View {
        NavigationView {
            List {
                // 整体状态概览
                Section(header: Text("整体状态")) {
                    HStack {
                        Circle()
                            .fill(overallStatus.indicatorColor)
                            .frame(width: 12, height: 12)
                        
                        Text(overallStatus.statusText)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let lastUpdate = serverStatusManager.lastUpdateTime {
                            Text("更新于 \(formatTime(lastUpdate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 用户角色服务器状态
                if !userServerStatuses.isEmpty {
                    Section(header: Text("角色服务器状态")) {
                        ForEach(userServerStatuses) { server in
                            ServerStatusRow(server: server)
                        }
                    }
                } else if dungeonManager.characters.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("暂无角色")
                                .font(.headline)
                            
                            Text("添加角色后可查看对应服务器状态")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                
                // 所有服务器状态（可选展开）
                Section(header: Text("所有服务器状态")) {
                    if serverStatusManager.serverStatuses.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在加载服务器状态...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                    } else {
                        ForEach(serverStatusManager.serverStatuses) { server in
                            ServerStatusRow(server: server)
                        }
                    }
                }
            }
            .navigationTitle("服务器状态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        serverStatusManager.refreshServerStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(serverStatusManager.isLoading ? 360 : 0))
                            .animation(serverStatusManager.isLoading ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: serverStatusManager.isLoading)
                    }
                    .disabled(serverStatusManager.isLoading)
                }
            }
            .refreshable {
                serverStatusManager.refreshServerStatus()
            }
        }
    }
    
    private var overallStatus: ServerOverallStatus {
        serverStatusManager.getOverallStatus(for: dungeonManager.characters)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 服务器状态行
struct ServerStatusRow: View {
    let server: ServerStatus
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            Circle()
                .fill(server.isOnline ? .green : .red)
                .frame(width: 10, height: 10)
            
            // 服务器信息
            VStack(alignment: .leading, spacing: 2) {
                Text(server.server)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(server.zone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态文本和时间
            VStack(alignment: .trailing, spacing: 2) {
                Text(server.statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(server.isOnline ? .green : .red)
                
                Text(formatLastUpdate(server.lastUpdateDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 预览
#Preview {
    ServerStatusIndicator()
        .environmentObject(DungeonManager())
}

#Preview("Detail View") {
    ServerStatusDetailView()
        .environmentObject(DungeonManager())
}