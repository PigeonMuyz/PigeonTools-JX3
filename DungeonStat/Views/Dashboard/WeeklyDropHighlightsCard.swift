//
//  WeeklyDropHighlightsCard.swift
//  DungeonStat
//
//  Created by Codex on 2025/7/22.
//

import SwiftUI

struct WeeklyDropHighlightsCard: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    private let statisticsManager = StatisticsManager.shared
    @State private var showingAllDrops = false
    
    private var weekRange: (start: Date, end: Date)? {
        let start = statisticsManager.getGameWeekStart(for: Date())
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: start),
              let finalEnd = Calendar.current.date(byAdding: .minute, value: -1, to: weekEnd) else {
            return nil
        }
        return (start, finalEnd)
    }
    
    private var recordsInWeek: [CompletionRecord] {
        guard let range = weekRange else { return [] }
        return dungeonManager.completionRecords.filter { record in
            record.completedDate >= range.start && record.completedDate <= range.end
        }
    }
    
    private var recordsWithDrops: [CompletionRecord] {
        recordsInWeek.filter { !$0.drops.isEmpty }
    }
    
    private var dropHighlights: [WeeklyDropHighlight] {
        recordsWithDrops.flatMap { record -> [WeeklyDropHighlight] in
            let runNumber = dungeonManager.getCharacterRunNumber(for: record)
            return record.drops.map { drop in
                WeeklyDropHighlight(
                    itemName: drop.name,
                    itemColor: drop.color,
                    dungeonName: record.dungeonName,
                    character: record.character,
                    runNumber: runNumber,
                    time: record.completedDate
                )
            }
        }
        .sorted { $0.time > $1.time }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    private var dateRangeText: String {
        guard let range = weekRange else { return "" }
        let formatter = Self.dateFormatter
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if dropHighlights.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(dropHighlights.prefix(5)) { event in
                        WeeklyDropHighlightRow(event: event)
                    }
                }
                
                if dropHighlights.count > 5 {
                    Button {
                        showingAllDrops = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("查看全部 \(dropHighlights.count) 个掉落")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .sheet(isPresented: $showingAllDrops) {
            WeeklyDropHighlightsSheet(dropHighlights: dropHighlights)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("本游戏周掉落")
                .font(.headline)
                .fontWeight(.semibold)
            Text(dateRangeText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title3)
                .foregroundColor(.gray)
            Text("本周暂无掉落数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct WeeklyDropHighlight: Identifiable {
    let id = UUID()
    let itemName: String
    let itemColor: Color
    let dungeonName: String
    let character: GameCharacter
    let runNumber: Int
    let time: Date
}

struct WeeklyDropHighlightRow: View {
    let event: WeeklyDropHighlight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(event.itemColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.itemName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(event.dungeonName) · 本周第 \(event.runNumber) 车")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(event.character.server) · \(event.character.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct WeeklyDropHighlightsSheet: View {
    let dropHighlights: [WeeklyDropHighlight]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(dropHighlights) { event in
                WeeklyDropHighlightRow(event: event)
            }
            .navigationTitle("本游戏周掉落")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
