//
//  InProgressView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/2.
//
import SwiftUI
import Combine

// MARK: - 进行中任务视图
struct InProgressView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var currentTime = Date()
    
    // 定时器用于更新进行中的时间
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            Group {
                if inProgressTasks.isEmpty {
                    // 空状态视图
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("当前没有进行中的任务")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("开始一个副本来追踪进度")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 进行中任务列表
                    List {
                        ForEach(inProgressTasks, id: \.0.id) { task in
                            InProgressTaskRow(
                                dungeon: task.dungeon,
                                character: task.character,
                                dungeonIndex: task.dungeonIndex,
                                currentTime: currentTime
                            )
                        }
                    }
                }
            }
            .navigationTitle("进行中")
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
    
    // 计算属性：获取所有进行中的任务
    private var inProgressTasks: [(dungeon: Dungeon, character: GameCharacter, dungeonIndex: Int)] {
        var result: [(Dungeon, GameCharacter, Int)] = []
        
        for (index, dungeon) in dungeonManager.dungeons.enumerated() {
            // 直接遍历副本中存储的进行状态
            for (storedCharacter, isInProgress) in dungeon.characterInProgress {
                if isInProgress {
                    // 通过ID找到当前角色列表中对应的角色对象，确保引用一致
                    if let matchingCharacter = dungeonManager.characters.first(where: { $0.id == storedCharacter.id }) {
                        result.append((dungeon, matchingCharacter, index))
                    } else if let matchingCharacter = dungeonManager.characters.first(where: {
                        $0.server == storedCharacter.server &&
                        $0.name == storedCharacter.name &&
                        $0.school == storedCharacter.school
                    }) {
                        result.append((dungeon, matchingCharacter, index))
                    } else {
                        // 如果找不到匹配的角色，使用存储的角色对象
                        result.append((dungeon, storedCharacter, index))
                    }
                }
            }
        }
        
        return result.sorted { (task1: (dungeon: Dungeon, character: GameCharacter, dungeonIndex: Int), task2: (dungeon: Dungeon, character: GameCharacter, dungeonIndex: Int)) in
            // 按开始时间排序，最新开始的在前
            let startTime1 = task1.0.startTime(for: task1.1) ?? Date.distantPast
            let startTime2 = task2.0.startTime(for: task2.1) ?? Date.distantPast
            return startTime1 > startTime2
        }
    }
}

// MARK: - 进行中任务行视图
struct InProgressTaskRow: View {
    let dungeon: Dungeon
    let character: GameCharacter
    let dungeonIndex: Int
    let currentTime: Date
    
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCancelAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧信息区域
            VStack(alignment: .leading, spacing: 8) {
                // 副本名称
                Text(dungeon.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // 角色信息
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(character.displayName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                // 进行状态和用时
                if let startTime = dungeon.startTime(for: character) {
                    HStack(spacing: 8) {
                        // 进行中状态
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("进行中")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        // 已用时间
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text("已用时: \(timeElapsed(from: startTime, to: currentTime))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // 开始时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("开始于: \(startTimeFormatter.string(from: startTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("找不到开始时间")
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            // 右侧操作按钮
            VStack(alignment: .trailing, spacing: 12) {
                // 角色统计简要信息
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("本周")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(dungeon.weeklyCount(for: character))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 4) {
                        Text("总计")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(dungeon.totalCount(for: character))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // 操作按钮
                HStack(spacing: 8) {
                    // 取消按钮
                    Button(action: {
                        showingCancelAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 完成按钮
                    Button(action: {
                        // 临时切换到对应角色以完成副本（暂时方案）
                        let originalCharacter = dungeonManager.selectedCharacter
                        dungeonManager.selectedCharacter = character
                        dungeonManager.completeDungeon(at: dungeonIndex)
                        dungeonManager.selectedCharacter = originalCharacter
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .alert("取消副本", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认取消", role: .destructive) {
                // 临时切换到对应角色以取消副本（暂时方案）
                let originalCharacter = dungeonManager.selectedCharacter
                dungeonManager.selectedCharacter = character
                dungeonManager.cancelDungeon(at: dungeonIndex)
                dungeonManager.selectedCharacter = originalCharacter
            }
        } message: {
            Text("确定要取消 \(character.name) 正在进行的「\(dungeon.name)」吗？")
        }
    }
    
    // 计算已用时间
    private func timeElapsed(from startTime: Date, to currentTime: Date) -> String {
        let elapsed = currentTime.timeIntervalSince(startTime)
        return formatDuration(elapsed)
    }
}

// MARK: - 全局格式化器别名（保持兼容性）
private let startTimeFormatter = DateFormatters.startTimeFormatter
