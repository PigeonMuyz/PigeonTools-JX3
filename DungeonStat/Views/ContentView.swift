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
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(dungeonManager)
                .tabItem {
                    TabBarIcon(systemName: "house", isSelected: selectedTab == 0)
                    Text("仪表盘")
                }
                .tag(0)
            
            DungeonListView()
                .environmentObject(dungeonManager)
                .tabItem {
                    TabBarIcon(systemName: "list.bullet", isSelected: selectedTab == 1)
                    Text("副本")
                }
                .tag(1)
            
            StatisticsView()
                .environmentObject(dungeonManager)
                .tabItem {
                    TabBarIcon(systemName: "chart.bar", isSelected: selectedTab == 2)
                    Text("统计")
                }
                .tag(2)
            
            ToolsView()
                .environmentObject(dungeonManager)
                .tabItem {
                    TabBarIcon(systemName: "wrench.and.screwdriver", isSelected: selectedTab == 3)
                    Text("工具")
                }
                .tag(3)
            
            SettingsView()
                .environmentObject(dungeonManager)
                .tabItem {
                    TabBarIcon(systemName: "gearshape", isSelected: selectedTab == 4)
                    Text("设置")
                }
                .tag(4)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .onChange(of: selectedTab) { oldValue, newValue in
            previousTab = oldValue
            // 添加触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
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