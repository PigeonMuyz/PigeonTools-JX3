//
//  DailyTasksDetailView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import SwiftUI
import Combine

// MARK: - 日常任务详情视图
struct DailyTasksDetailView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    @State private var selectedCharacter: GameCharacter?
    @State private var showingAddCustomTask = false
    @State private var customTaskName = ""
    @State private var showingEditCustomTask = false
    @State private var editingTask: DailyTask?
    @State private var editingTaskName = ""
    
    var body: some View {
        NavigationView {
            List {
                // 角色选择器 Section
                if !dungeonManager.characters.isEmpty {
                    Section("选择角色") {
                        Picker("角色", selection: $selectedCharacter) {
                            Text("请选择角色").tag(GameCharacter?.none)
                            ForEach(dungeonManager.characters) { character in
                                Text(character.displayName).tag(GameCharacter?.some(character))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // 任务列表 Section
                if let character = selectedCharacter {
                    TaskListView(character: character)
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("请选择角色查看任务")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("今日任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        refreshTasks()
                    }) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("添加自定义任务", isPresented: $showingAddCustomTask) {
                TextField("任务名称", text: $customTaskName)
                Button("添加") {
                    if !customTaskName.isEmpty, let character = selectedCharacter {
                        dungeonManager.dailyTaskManager.addCustomTask(
                            characterId: character.id,
                            taskName: customTaskName
                        )
                        customTaskName = ""
                    }
                }
                Button("取消", role: .cancel) {
                    customTaskName = ""
                }
            } message: {
                Text("请输入自定义任务的名称")
            }
            .alert("编辑任务", isPresented: $showingEditCustomTask) {
                TextField("任务名称", text: $editingTaskName)
                Button("保存") {
                    if !editingTaskName.isEmpty, let task = editingTask, let character = selectedCharacter {
                        dungeonManager.dailyTaskManager.editCustomTask(
                            characterId: character.id,
                            taskId: task.id,
                            newName: editingTaskName
                        )
                        editingTask = nil
                        editingTaskName = ""
                    }
                }
                Button("取消", role: .cancel) {
                    editingTask = nil
                    editingTaskName = ""
                }
            } message: {
                Text("请输入新的任务名称")
            }
        }
        .onAppear {
            // 默认选择第一个角色并自动刷新
            if selectedCharacter == nil {
                selectedCharacter = dungeonManager.characters.first
            }
            
            // 自动刷新任务（强制刷新以确保数据最新）
            refreshTasks()
        }
    }
    
    private func refreshTasks() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        Task {
            await dungeonManager.forceRefreshDailyTasks()
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func showEditTaskAlert(for task: DailyTask) {
        editingTask = task
        editingTaskName = task.name
        showingEditCustomTask = true
    }
}

// MARK: - 任务列表视图（独立组件以确保数据响应）
struct TaskListView: View {
    let character: GameCharacter
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddCustomTask = false
    @State private var customTaskName = ""
    @State private var showingEditCustomTask = false
    @State private var editingTask: DailyTask?
    @State private var editingTaskName = ""
    
    // 直接观察dailyTaskManager的数据变化
    private var tasks: [DailyTask] {
        dungeonManager.dailyTaskManager.getDailyTasks(for: character)
    }
    
    private var systemTasks: [DailyTask] {
        tasks.filter { !$0.isCustom }
    }
    
    private var customTasks: [DailyTask] {
        tasks.filter { $0.isCustom }
    }
    
    var body: some View {
        Group {
            // 系统任务
            if !systemTasks.isEmpty {
                Section("系统任务") {
                    ForEach(systemTasks, id: \.id) { task in
                        TaskRowView(task: task, character: character)
                    }
                }
            }
            
            // 自定义任务
            Section("自定义任务") {
                ForEach(customTasks, id: \.id) { task in
                    TaskRowView(task: task, character: character, showDeleteButton: true)
                        .swipeActions(edge: .trailing) {
                            Button("删除", role: .destructive) {
                                dungeonManager.dailyTaskManager.deleteCustomTask(
                                    characterId: character.id,
                                    taskId: task.id
                                )
                            }
                            
                            Button("编辑") {
                                showEditTaskAlert(for: task)
                            }
                            .tint(.blue)
                        }
                }
                
                // 添加自定义任务按钮
                Button(action: {
                    showingAddCustomTask = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("添加自定义任务")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 任务统计 Section
            if !tasks.isEmpty {
                let completedCount = tasks.filter { $0.isCompleted }.count
                let totalCount = tasks.count
                
                Section("今日进度") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("任务完成情况")
                                .font(.headline)
                            Text("\(completedCount) / \(totalCount) 已完成")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(
                            progress: totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0,
                            lineWidth: 8
                        )
                        .frame(width: 60, height: 60)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .alert("添加自定义任务", isPresented: $showingAddCustomTask) {
            TextField("任务名称", text: $customTaskName)
            Button("添加") {
                if !customTaskName.isEmpty {
                    dungeonManager.dailyTaskManager.addCustomTask(
                        characterId: character.id,
                        taskName: customTaskName
                    )
                    customTaskName = ""
                }
            }
            Button("取消", role: .cancel) {
                customTaskName = ""
            }
        } message: {
            Text("请输入自定义任务的名称")
        }
        .alert("编辑任务", isPresented: $showingEditCustomTask) {
            TextField("任务名称", text: $editingTaskName)
            Button("保存") {
                if !editingTaskName.isEmpty, let task = editingTask {
                    dungeonManager.dailyTaskManager.editCustomTask(
                        characterId: character.id,
                        taskId: task.id,
                        newName: editingTaskName
                    )
                    editingTask = nil
                    editingTaskName = ""
                }
            }
            Button("取消", role: .cancel) {
                editingTask = nil
                editingTaskName = ""
            }
        } message: {
            Text("请输入新的任务名称")
        }
    }
    
    private func showEditTaskAlert(for task: DailyTask) {
        editingTask = task
        editingTaskName = task.name
        showingEditCustomTask = true
    }
}

// MARK: - 任务行视图（简化且响应式）
struct TaskRowView: View {
    let task: DailyTask
    let character: GameCharacter
    let showDeleteButton: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    init(task: DailyTask, character: GameCharacter, showDeleteButton: Bool = false) {
        self.task = task
        self.character = character
        self.showDeleteButton = showDeleteButton
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 复选框
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dungeonManager.dailyTaskManager.toggleTaskCompletionById(
                        characterId: character.id,
                        taskId: task.id
                    )
                }
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
                Text(task.name)
                    .font(.body)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                if task.isCompleted, let completedDate = task.completedDate {
                    Text("完成于 \(formatTime(completedDate))")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if task.isCustom {
                    Text("自定义任务")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // 删除按钮（仅自定义任务）
            if showDeleteButton && task.isCustom {
                Button(action: {
                    dungeonManager.dailyTaskManager.deleteCustomTask(
                        characterId: character.id,
                        taskId: task.id
                    )
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                dungeonManager.dailyTaskManager.toggleTaskCompletionById(
                    characterId: character.id,
                    taskId: task.id
                )
            }
        }
    }
    
    private var taskColor: Color {
        if task.isCompleted {
            return .gray
        }
        
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

// MARK: - 圆形进度视图
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: progress >= 1.0 ? [.green, .mint] : [.blue, .cyan],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
