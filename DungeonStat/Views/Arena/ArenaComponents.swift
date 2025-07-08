//
//  ArenaComponents.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 单个模式战绩List区域
struct ArenaModeListSection: View {
    let data: ArenaRecordData
    let mode: ArenaMode
    
    var body: some View {
        Group {
            // 模式标题和表现
            Section(header: HStack {
                Text(mode.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if let performance = data.performance[mode.apiKey] {
                    Text("第\(performance.grade)段")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .cornerRadius(6)
                }
            }) {
                if let performance = data.performance[mode.apiKey] {
                    ArenaPerformanceListCard(performance: performance)
                }
            }
            
            // 近期战绩
            if !data.history.isEmpty {
                Section(header: Text("近期战绩")) {
                    ForEach(Array(data.history.prefix(10).enumerated()), id: \.offset) { index, record in
                        ArenaHistoryListRow(record: record)
                    }
                    
                    if data.history.count > 10 {
                        HStack {
                            Spacer()
                            Text("还有\(data.history.count - 10)场战绩")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // MMR趋势（如果有数据）
            if !data.trend.isEmpty {
                Section(header: Text("MMR趋势")) {
                    ArenaTrendChart(trendData: data.trend)
                }
            }
        }
    }
}

// MARK: - 单个模式战绩区域（保留用于其他地方）
struct ArenaModeSection: View {
    let data: ArenaRecordData
    let mode: ArenaMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 模式标题
            HStack {
                Text(mode.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let performance = data.performance[mode.apiKey] {
                    Text("第\(performance.grade)段")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
            
            // 竞技表现
            if let performance = data.performance[mode.apiKey] {
                ArenaPerformanceCard(performance: performance)
            }
            
            // 近期战绩
            if !data.history.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("近期战绩")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(data.history.prefix(5).enumerated()), id: \.offset) { index, record in
                        ArenaHistoryRow(record: record)
                    }
                    
                    if data.history.count > 5 {
                        Text("... 还有\(data.history.count - 5)场战绩")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
            
            // MMR趋势（如果有数据）
            if !data.trend.isEmpty {
                ArenaTrendChart(trendData: data.trend)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 竞技表现卡片
struct ArenaPerformanceCard: View {
    let performance: ArenaPerformance
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前MMR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(performance.mmr)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("段位")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("第\(performance.grade)段")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            
            HStack(spacing: 16) {
                StatItem(title: "胜场", value: "\(performance.winCount)", color: .green)
                StatItem(title: "总场", value: "\(performance.totalCount)", color: .blue)
                StatItem(title: "MVP", value: "\(performance.mvpCount)", color: .orange)
                StatItem(title: "胜率", value: "\(performance.winRate)%", color: performance.winRate >= 60 ? .green : performance.winRate >= 50 ? .orange : .red)
            }
            
            if performance.ranking != "-" {
                HStack {
                    Text("排名:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(performance.ranking)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 竞技表现List卡片
struct ArenaPerformanceListCard: View {
    let performance: ArenaPerformance
    
    var body: some View {
        HStack(spacing: 16) {
            // MMR和段位
            VStack(alignment: .leading, spacing: 4) {
                Text("MMR: \(performance.mmr)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("胜率: \(performance.winRate)%")
                    .font(.caption)
                    .foregroundColor(performance.winRate >= 60 ? .green : performance.winRate >= 50 ? .orange : .red)
            }
            
            Spacer()
            
            // 战绩统计
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(performance.winCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("胜场")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(performance.totalCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("总场")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(performance.mvpCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("MVP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 战绩历史List行
struct ArenaHistoryListRow: View {
    let record: ArenaHistoryRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 胜负标识
            Image(systemName: record.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(record.won ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.kungfu)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if record.mvp {
                        Text("MVP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .cornerRadius(3)
                    }
                }
                
                HStack {
                    Text("MMR: \(record.mmr > 0 ? "+" : "")\(record.mmr)")
                        .font(.caption)
                        .foregroundColor(record.mmr > 0 ? .green : record.mmr < 0 ? .red : .secondary)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("用时: \(formatMatchDuration(start: record.startTime, end: record.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTimestamp(record.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("段位: \(record.avgGrade)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatMatchDuration(start: Int, end: Int) -> String {
        let duration = end - start
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 统计项目
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 战绩历史行
struct ArenaHistoryRow: View {
    let record: ArenaHistoryRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 胜负标识
            Image(systemName: record.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(record.won ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.kungfu)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if record.mvp {
                        Text("MVP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text("MMR: \(record.mmr > 0 ? "+" : "")\(record.mmr)")
                        .font(.caption)
                        .foregroundColor(record.mmr > 0 ? .green : record.mmr < 0 ? .red : .secondary)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("段位: \(record.avgGrade)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatMatchDuration(start: record.startTime, end: record.endTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatTimestamp(record.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatMatchDuration(start: Int, end: Int) -> String {
        let duration = end - start
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}