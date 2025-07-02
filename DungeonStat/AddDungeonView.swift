//
//  AddDungeonView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 添加副本视图
struct AddDungeonView: View {
    @Binding var dungeonName: String
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("副本信息")) {
                    TextField("副本名称", text: $dungeonName)
                }
            }
            .navigationTitle("添加副本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                        dungeonName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if !dungeonName.isEmpty {
                            dungeonManager.addDungeon(name: dungeonName)
                            isPresented = false
                            dungeonName = ""
                        }
                    }
                    .disabled(dungeonName.isEmpty)
                }
            }
        }
    }
}
