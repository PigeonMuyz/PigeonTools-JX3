//
//  TabBarIcon.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - TabBar图标动画组件
struct TabBarIcon: View {
    let systemName: String
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: systemName)
            .symbolEffect(.bounce, value: isSelected)
            .symbolVariant(isSelected ? .fill : .none)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isSelected)
    }
}