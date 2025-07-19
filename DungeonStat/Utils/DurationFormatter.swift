//
//  DurationFormatter.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

// MARK: - 时长格式化器
struct DurationFormatter {
    
    /// 格式化时长为字符串
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化短时长（用于统计图表）
    static func formatDurationShort(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 全局函数（保持兼容性）
func formatDuration(_ duration: TimeInterval) -> String {
    return DurationFormatter.formatDuration(duration)
}

func formatDurationShort(_ duration: TimeInterval) -> String {
    return DurationFormatter.formatDurationShort(duration)
}
