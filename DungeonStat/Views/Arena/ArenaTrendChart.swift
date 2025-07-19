//
//  ArenaTrendChart.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI

// MARK: - MMR趋势图
struct ArenaTrendChart: View {
    let trendData: [ArenaTrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近MMR变化")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !trendData.isEmpty {
                let maxMMR = trendData.map { $0.mmr }.max() ?? 1000
                let minMMR = trendData.map { $0.mmr }.min() ?? 1000
                let range = max(maxMMR - minMMR, 100)
                
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(trendData.enumerated()), id: \.offset) { index, trend in
                        let height = CGFloat((trend.mmr - minMMR)) / CGFloat(range) * 60 + 20
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.7), .blue.opacity(0.3)]),
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                            .frame(height: height)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 80)
                
                HStack {
                    Text("最低: \(minMMR)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("最高: \(maxMMR)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("暂无趋势数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
