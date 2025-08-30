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
                
                // 搜索设置
                Section {
                    Toggle("支持快速搜索TN补", isOn: $settings.enableSubsidySearch)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("支持职业快速搜索", isOn: $settings.enableProfessionSearch)
                        .toggleStyle(SwitchToggleStyle())
                    
                } header: {
                    Text("搜索设置")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TN补搜索：匹配内容中的 补1 、 补500 等补贴信息")
                        Text("职业搜索：支持歌奶、药奶、秀奶、毒奶、花奶等职业关键字")
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
                            Text("• 搜索 TN补 或 xxx补 可查找有补贴的团队")
                            Text("• 搜索职业关键字可快速找到对应职业缺位")
                            Text("• 支持同时搜索活动名称、团长和内容")
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
