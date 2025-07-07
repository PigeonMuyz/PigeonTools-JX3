//
//  AchievementDetailView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/7.
//

import SwiftUI

// MARK: - 成就详情视图
struct AchievementDetailView: View {
    let achievementData: DungeonAchievementData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 副本信息卡片
                    dungeonInfoCard
                    
                    // 统计信息卡片
                    statisticsCard
                    
                    // 校验状态卡片
                    if achievementData.isCalibrated {
                        calibrationCard
                    }
                    
                    // 成就列表或提示信息
                    if !achievementData.achievements.isEmpty {
                        achievementsList
                    } else {
                        // 成就数据提示
                        VStack(alignment: .leading, spacing: 12) {
                            Text("成就信息")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if achievementData.isCalibrated {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                        Text("数据已校验")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("该副本共有 \(achievementData.calibratedStats.pieces.total) 个成就")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("总资历点: \(achievementData.calibratedStats.seniority.total) 点")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("已完成: \(achievementData.calibratedStats.pieces.speed)/\(achievementData.calibratedStats.pieces.total)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("可获得资历: +\(achievementData.potential) 点")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                        Text("基础统计信息")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("该副本共有 \(achievementData.originalStats.pieces.total) 个成就")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("总资历点: \(achievementData.originalStats.seniority.total) 点")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("已完成: \(achievementData.originalStats.pieces.speed)/\(achievementData.originalStats.pieces.total)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("可获得资历: +\(achievementData.potential) 点")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("💡 提示")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Text("点击主界面的\"校验数据\"按钮获取详细的成就列表和攻略信息")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("副本详情")
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
    
    private var dungeonInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.columns")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievementData.dungeonName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(achievementData.difficulty)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: achievementData.priority.icon)
                        .font(.caption)
                    Text(achievementData.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(achievementData.priority.color)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("统计信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                StatisticColumn(
                    title: "完成进度",
                    value: "\(achievementData.calibratedStats.pieces.speed)/\(achievementData.calibratedStats.pieces.total)",
                    subtitle: "个成就",
                    color: .blue,
                    icon: "checkmark.circle"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticColumn(
                    title: "当前资历",
                    value: "\(achievementData.calibratedStats.seniority.speed)",
                    subtitle: "点",
                    color: .green,
                    icon: "star.circle"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticColumn(
                    title: "可获得",
                    value: "+\(achievementData.potential)",
                    subtitle: "点",
                    color: .orange,
                    icon: "plus.circle"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticColumn(
                    title: "完成率",
                    value: String(format: "%.1f%%", achievementData.completionRate),
                    subtitle: "",
                    color: achievementData.completionRate < 30 ? .red : 
                            achievementData.completionRate < 60 ? .orange : .green,
                    icon: "percent"
                )
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("完成进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", achievementData.completionRate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(achievementData.completionRate < 30 ? .red : 
                                         achievementData.completionRate < 60 ? .orange : .green)
                }
                
                ProgressView(value: achievementData.completionRate / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: 
                        achievementData.completionRate < 30 ? .red : 
                        achievementData.completionRate < 60 ? .orange : .green))
                    .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据已校验")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("使用魔盒成就数据校验，显示准确的资历和成就信息")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
//            // 校验对比
//            if achievementData.originalStats.pieces.total != achievementData.calibratedStats.pieces.total ||
//               achievementData.originalStats.seniority.total != achievementData.calibratedStats.seniority.total {
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("校验对比")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                    
//                    HStack(spacing: 16) {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("原始数据")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            Text("成就: \(achievementData.originalStats.pieces.total)")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            Text("资历: \(achievementData.originalStats.seniority.total)")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        
//                        Image(systemName: "arrow.right")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("校验后")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                            
//                            Text("成就: \(achievementData.calibratedStats.pieces.total)")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                            
//                            Text("资历: \(achievementData.calibratedStats.seniority.total)")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                        }
//                        
//                        Spacer()
//                    }
//                }
//                .padding()
//                .background(Color.green.opacity(0.1))
//                .cornerRadius(8)
//            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var achievementsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就列表")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(achievementData.achievements) { achievement in
                    AchievementItemView(achievement: achievement)
                }
            }
        }
    }
}

// MARK: - 统计列视图
struct StatisticColumn: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 成就项视图
struct AchievementItemView: View {
    let achievement: ProcessedAchievement
    @State private var isExpanded = false
    @State private var isCompleted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 成就基本信息
            HStack {
                // 完成状态按钮
                Button(action: {
                    isCompleted.toggle()
                    if isCompleted {
                        AchievementCompletionService.shared.markAchievementAsCompleted(achievement.id)
                    } else {
                        AchievementCompletionService.shared.markAchievementAsIncomplete(achievement.id)
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(isCompleted)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    if let shortDesc = achievement.shortDesc {
                        Text(shortDesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(achievement.point)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("资历点")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 展开的详细信息
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // 成就攻略
                    if let postContent = achievement.postContent, !postContent.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                
                                Text("攻略指南")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            AchievementGuideView(htmlContent: postContent)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let desc = achievement.desc {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("详细描述")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let note = achievement.note {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("备注")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 子成就列表
                    if !achievement.subAchievementList.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("子成就")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(achievement.subAchievementList, id: \.ID) { subAchievement in
                                    HStack {
                                        Text("• \(subAchievement.Name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(subAchievement.Point)点")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onAppear {
            isCompleted = AchievementCompletionService.shared.isAchievementCompleted(achievement.id)
        }
    }
}

// MARK: - 成就攻略HTML显示视图
struct AchievementGuideView: View {
    let htmlContent: String
    
    var body: some View {
        Text(htmlContent.htmlToAttributedString())
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// MARK: - HTML转AttributedString扩展
extension String {
    func htmlToAttributedString() -> AttributedString {
        guard self.data(using: .utf8) != nil else {
            return AttributedString(self)
        }
        
        do {
            // 预处理HTML，移除或替换图片标签
            let processedHTML = self.preprocessHTML()
            guard let processedData = processedHTML.data(using: .utf8) else {
                return AttributedString(self)
            }
            
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(data: processedData, options: options, documentAttributes: nil)
            return AttributedString(attributedString)
        } catch {
            // 如果HTML解析失败，移除HTML标签并返回纯文本
            let plainText = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            return AttributedString(plainText)
        }
    }
    
    private func preprocessHTML() -> String {
        var processedHTML = self
        
        // 将图片标签替换为 [图片] 文本
        processedHTML = processedHTML.replacingOccurrences(
            of: "<img[^>]*>",
            with: "[图片]",
            options: .regularExpression
        )
        
        // 移除一些可能导致解析问题的标签
        let problematicTags = ["script", "style", "iframe", "object", "embed"]
        for tag in problematicTags {
            let pattern = "<\(tag)[^>]*>.*?</\(tag)>"
            processedHTML = processedHTML.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // 确保HTML有基本结构
        if !processedHTML.contains("<html>") {
            processedHTML = "<html><body>\(processedHTML)</body></html>"
        }
        
        return processedHTML
    }
}
