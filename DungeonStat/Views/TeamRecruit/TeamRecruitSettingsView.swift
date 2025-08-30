//
//  TeamRecruitSettingsView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
//

import SwiftUI

// MARK: - 团队招募设置界面
struct TeamRecruitSettingsView: View {
    @StateObject private var settings = TeamRecruitSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
                // 过滤设置
                Section {
                    Toggle("过滤金团", isOn: $settings.filterGoldTeams)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("过滤浪客行", isOn: $settings.filterPioneerTeams)
                        .toggleStyle(SwitchToggleStyle())
                    
                } header: {
                    Text("过滤设置")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("金团识别：内容包含 0抵消、来打手、包团 等关键字")
                        Text("浪客行识别：标签包含 浪客行 关键字")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                
                // 帮助信息
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("搜索技巧")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 单字母搜索：T、N、D 快速找坦克、奶妈、输出")
                            Text("• 职业搜索：奶歌、毒奶、策T等精确职业")
                            Text("• 补贴搜索：输入\"补\"或\"TN补\"查找有补贴团队")
                            Text("• 通用搜索：支持活动名称、团长、内容关键字")
                            Text("• 明确搜索金团或浪客行时不会被过滤")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("使用说明")
                }
            }
            .navigationTitle("团队招募设置")
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

// MARK: - 预览
#Preview {
    TeamRecruitSettingsView()
}
