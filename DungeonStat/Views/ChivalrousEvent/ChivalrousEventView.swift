//
//  ChivalrousEventView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/18.
//

import SwiftUI

// MARK: - 行侠事件主视图
struct ChivalrousEventView: View {
    @StateObject private var eventService = ChivalrousEventService.shared
    @State private var selectedOrganization: ChivalrousOrganization = .pifenghui
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 组织选择器
                organizationSelector
                
                // 事件列表
                eventsList
            }
            .navigationTitle("行侠事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        eventService.refreshEvents(for: selectedOrganization)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(eventService.isLoading ? 360 : 0))
                            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: eventService.isLoading)
                    }
                    .disabled(eventService.isLoading)
                }
            }
            .onAppear {
                if eventService.events.isEmpty {
                    eventService.fetchChivalrousEvents(for: selectedOrganization)
                }
            }
        }
    }
    
    // MARK: - 组织选择器
    private var organizationSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChivalrousOrganization.allCases, id: \.self) { organization in
                    Button(action: {
                        selectedOrganization = organization
                        eventService.fetchChivalrousEvents(for: organization)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: organization.iconName)
                                .font(.system(size: 16))
                            
                            Text(organization.displayName)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(selectedOrganization == organization ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedOrganization == organization ? 
                                     Color.accentColor : Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 事件列表
    private var eventsList: some View {
        Group {
            if eventService.isLoading {
                loadingView
            } else if let errorMessage = eventService.errorMessage {
                errorView(errorMessage)
            } else if eventService.events.isEmpty {
                emptyView
            } else {
                eventsContentView
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在加载行侠事件...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 错误视图
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                eventService.fetchChivalrousEvents(for: selectedOrganization)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 空数据视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无事件")
                .font(.headline)
            
            Text("当前没有可用的行侠事件")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - 事件内容视图
    private var eventsContentView: some View {
        List {
            // 更新时间显示
            if let lastUpdate = eventService.lastUpdateTime {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text("更新时间: \(formatUpdateTime(lastUpdate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 按地图分组显示事件
            let groupedEvents = eventService.groupEventsByMap()
            ForEach(eventService.getAllMapNames(), id: \.self) { mapName in
                Section(header: Text(mapName).font(.headline)) {
                    if let events = groupedEvents[mapName] {
                        ForEach(events) { event in
                            ChivalrousEventRow(event: event)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .background(Color(UIColor.systemGroupedBackground))
        .refreshable {
            eventService.refreshEvents(for: selectedOrganization)
        }
    }
    
    // MARK: - 辅助方法
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 行侠事件行视图
struct ChivalrousEventRow: View {
    let event: ChivalrousEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 事件标题和时间
            HStack {
                Text(event.event)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(event.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 地点信息
            HStack {
                Image(systemName: "location")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(event.site)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // 事件描述
            Text(event.desc)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 预览
#Preview {
    ChivalrousEventView()
}

#Preview("Event Row") {
    ChivalrousEventRow(event: ChivalrousEvent(
        mapName: "百溪",
        event: "保护庄稼",
        site: "镇海阁东北",
        desc: "公共任务：帮助村民除去农田里的害虫和杂草。",
        icon: "8",
        time: "05:04"
    ))
    .padding()
}