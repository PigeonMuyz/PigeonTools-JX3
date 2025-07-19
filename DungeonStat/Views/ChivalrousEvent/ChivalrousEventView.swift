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
        VStack(spacing: 0) {
            // 更新时间显示
            if let lastUpdate = eventService.lastUpdateTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("更新时间: \(formatUpdateTime(lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGroupedBackground))
            }
            
            // 事件列表
            List(getSortedEvents()) { event in
                ChivalrousEventRow(event: event, isInProgress: isEventInProgress(event))
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                eventService.refreshEvents(for: selectedOrganization)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 辅助方法
    private func getSortedEvents() -> [ChivalrousEvent] {
        eventService.events.sorted { event1, event2 in
            let time1 = timeToMinutes(event1.time)
            let time2 = timeToMinutes(event2.time)
            return time1 < time2
        }
    }
    
    private func timeToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return 0
        }
        return hours * 60 + minutes
    }
    
    private func isEventInProgress(_ event: ChivalrousEvent) -> Bool {
        let currentTime = getCurrentTimeInMinutes()
        let eventTime = timeToMinutes(event.time)
        let nextEventTime = getNextEventTime(after: eventTime)
        
        return currentTime >= eventTime && currentTime < (nextEventTime - 1)
    }
    
    private func getCurrentTimeInMinutes() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        return hour * 60 + minute
    }
    
    private func getNextEventTime(after eventTime: Int) -> Int {
        let sortedTimes = eventService.events.map { timeToMinutes($0.time) }.sorted()
        
        for time in sortedTimes {
            if time > eventTime {
                return time
            }
        }
        
        // 如果没有找到下一个事件，返回第二天的第一个事件
        return sortedTimes.first ?? (24 * 60)
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
    let isInProgress: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧时间显示
            VStack(alignment: .center, spacing: 2) {
                Text(event.time)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(isInProgress ? .green : .primary)
                
                if isInProgress {
                    Text("进行中")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.green)
                        .cornerRadius(6)
                }
            }
            .frame(width: 60)
            
            // 中间事件信息
            VStack(alignment: .leading, spacing: 4) {
                // 事件名称
                Text(event.event)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 地图和地点
                HStack(spacing: 4) {
                    Text(event.mapName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(event.site)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                
                // 事件描述
                Text(event.desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // 右侧状态指示
            if isInProgress {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(isInProgress ? Color.green.opacity(0.05) : Color.clear)
    }
}

// MARK: - 预览
#Preview {
    ChivalrousEventView()
}

#Preview("Event Row") {
    ChivalrousEventRow(
        event: ChivalrousEvent(
            mapName: "百溪",
            event: "保护庄稼",
            site: "镇海阁东北",
            desc: "公共任务：帮助村民除去农田里的害虫和杂草。",
            icon: "8",
            time: "05:04"
        ),
        isInProgress: true
    )
    .padding()
}