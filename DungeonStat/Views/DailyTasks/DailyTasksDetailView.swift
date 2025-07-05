//
//  DailyTasksDetailView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import SwiftUI

// MARK: - 日常任务详情视图
struct DailyTasksDetailView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    @State private var selectedCharacter: GameCharacter?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 角色选择器
                if !dungeonManager.characters.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("选择角色")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 刷新按钮
                            Button(action: {
                                refreshTasks()
                            }) {
                                if isRefreshing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isRefreshing)
                        }
                        
                        Picker("角色", selection: $selectedCharacter) {
                            Text("请选择角色").tag(GameCharacter?.none)
                            ForEach(dungeonManager.characters) { character in
                                Text(character.displayName).tag(GameCharacter?.some(character))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    Divider()
                }
                
                // 任务列表
                if let character = selectedCharacter {
                    DailyTasksList(character: character)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("请选择角色查看任务")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("今日任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // 默认选择第一个角色
            if selectedCharacter == nil {
                selectedCharacter = dungeonManager.characters.first
            }
        }
    }
    
    private func refreshTasks() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        Task {
            await dungeonManager.manualRefreshDailyTasks()
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 任务列表组件
struct DailyTasksList: View {
    let character: GameCharacter
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let tasks = dungeonManager.dailyTaskManager.getDailyTasks(for: character)
                
                if tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("暂无今日任务")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("等待任务数据刷新")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(tasks, id: \.id) { task in
                        DailyTaskChecklistRow(task: task, character: character)
                        
                        if task.id != tasks.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 清单式任务行
struct DailyTaskChecklistRow: View {
    let task: DailyTask
    let character: GameCharacter
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 复选框
            Button(action: {
                dungeonManager.dailyTaskManager.toggleTaskCompletion(
                    characterId: character.id,
                    taskType: task.type
                )
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 任务图标
            Image(systemName: task.type.icon)
                .font(.title3)
                .foregroundColor(taskColor)
                .frame(width: 24)
            
            // 任务内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.type.displayName)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                if task.name != task.type.displayName {
                    Text(task.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 完成时间
                if task.isCompleted, let completedDate = task.completedDate {
                    Text("完成于 \(formatTime(completedDate))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(task.isCompleted ? Color(.systemGray6).opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            dungeonManager.dailyTaskManager.toggleTaskCompletion(
                characterId: character.id,
                taskType: task.type
            )
        }
    }
    
    private var taskColor: Color {
        let color = task.isCompleted ? .gray : taskColorForType
        return color
    }
    
    private var taskColorForType: Color {
        switch task.type.color {
        case "red": return .red
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        default: return .gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
