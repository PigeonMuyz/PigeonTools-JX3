//
//  AddManualRecordView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 手动添加记录视图
struct AddManualRecordView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var selectedDungeon = ""
    @State private var selectedCharacter: GameCharacter?
    @State private var completedDate = Date()
    @State private var hours = 0
    @State private var minutes = 30
    @State private var seconds = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("记录信息")) {
                    Picker("副本", selection: $selectedDungeon) {
                        Text("请选择副本").tag("")
                        ForEach(dungeonManager.dungeons) { dungeon in
                            Text(dungeon.name).tag(dungeon.name)
                        }
                    }
                    
                    Picker("角色", selection: $selectedCharacter) {
                        Text("请选择角色").tag(GameCharacter?.none)
                        ForEach(dungeonManager.characters) { gameCharacter in
                            Text(gameCharacter.displayName).tag(GameCharacter?.some(gameCharacter))
                        }
                    }
                    
                    DatePicker("完成时间", selection: $completedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("用时")) {
                    HStack {
                        Picker("小时", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        Picker("分钟", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        
                        Picker("秒", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)秒").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                }
            }
            .navigationTitle("添加历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if let character = selectedCharacter, !selectedDungeon.isEmpty {
                            let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                            dungeonManager.addManualRecord(
                                dungeonName: selectedDungeon,
                                character: character,
                                completedDate: completedDate,
                                duration: duration
                            )
                            isPresented = false
                        }
                    }
                    .disabled(selectedDungeon.isEmpty || selectedCharacter == nil)
                }
            }
        }
        .onAppear {
            selectedCharacter = dungeonManager.selectedCharacter
        }
    }
}