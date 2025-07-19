//
//  CharacterSelectorView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI

// MARK: - 角色选择器视图
struct CharacterSelectorView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dungeonManager.characters) { gameCharacter in
                    VStack(alignment: .leading, spacing: 8) {
                        // 角色名和选中状态 - 最突出
                        HStack {
                            Text(gameCharacter.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if dungeonManager.selectedCharacter?.id == gameCharacter.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .symbolEffect(.bounce.up, value: dungeonManager.selectedCharacter?.id == gameCharacter.id)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // 服务器 - 次重要信息
                        Text("服务器：\(gameCharacter.server)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        // 门派和体型 - 紧凑水平布局
                        HStack(spacing: 12) {
                            Text("门派：\(gameCharacter.school)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Text("体型：\(gameCharacter.bodyType)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        dungeonManager.selectCharacter(gameCharacter)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("选择角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
