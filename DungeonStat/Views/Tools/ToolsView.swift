//
//  ToolsView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 工具页面
struct ToolsView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingCharacterManagement = false
    @State private var showingCharacterSelector = false
    @State private var showingManualRecord = false
    @State private var selectedCharacterForCard: GameCharacter?
    @State private var selectedCharacterForAchievement: GameCharacter?
    @State private var selectedCharacterForDetail: GameCharacter?
    @State private var showingCharacterCard = false
    @State private var showingAchievementAnalyzer = false
    @State private var showingCharacterDetail = false
    @State private var characterDetailData: CharacterDetailData?
    @State private var isLoadingDetail = false
    @State private var showingChivalrousEvents = false
    
    var body: some View {
        NavigationView {
            List {
                characterManagementSection
                
                if let selectedCharacter = dungeonManager.selectedCharacter {
                    currentCharacterSection(selectedCharacter)
                }
                
                gameInfoSection
                
                dataManagementSection
            }
            .navigationTitle("工具")
            .sheet(isPresented: $showingCharacterSelector) {
                CharacterSelectorView(isPresented: $showingCharacterSelector)
            }
            .sheet(isPresented: $showingManualRecord) {
                AddManualRecordView(isPresented: $showingManualRecord)
            }
            .sheet(isPresented: $showingCharacterCard) {
                if let character = selectedCharacterForCard {
                    CharacterCardView(server: character.server, name: character.name)
                }
            }
            .sheet(isPresented: $showingAchievementAnalyzer) {
                if let character = selectedCharacterForAchievement {
                    AchievementAnalyzerView(character: character)
                }
            }
            .sheet(isPresented: $showingCharacterDetail) {
                CharacterDetailSheet(
                    character: selectedCharacterForDetail,
                    characterData: characterDetailData,
                    isLoading: isLoadingDetail
                )
            }
            .sheet(isPresented: $showingChivalrousEvents) {
                ChivalrousEventView()
            }
            .onChange(of: selectedCharacterForCard) { _, newValue in
                if newValue != nil {
                    showingCharacterCard = true
                }
            }
            .onChange(of: selectedCharacterForAchievement) { _, newValue in
                if newValue != nil {
                    showingAchievementAnalyzer = true
                }
            }
            .onChange(of: selectedCharacterForDetail) { _, newValue in
                if newValue != nil {
                    showingCharacterDetail = true
                }
            }
        }
    }
    
    private var characterManagementSection: some View {
        Section(header: Text("角色管理")) {
            NavigationLink(destination: CharacterManagementView()) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .symbolEffect(.bounce, value: showingCharacterManagement)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("角色管理")
                            .font(.headline)
                        Text("管理你的游戏角色")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    characterCountBadge
                }
            }
        }
    }
    
    private var characterCountBadge: some View {
        Text("\(dungeonManager.characters.count)")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
    
    private func currentCharacterSection(_ character: GameCharacter) -> some View {
        Section(header: Text("当前角色（\(character.server) - \(character.name)）")) {
            switchCharacterButton(character)
            characterCardButton(character)
            achievementAnalyzerButton(character)
            characterDetailButton(character)
            arenaRecordButton
        }
    }
    
    private func switchCharacterButton(_ character: GameCharacter) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            showingCharacterSelector = true
        }) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("切换角色")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("当前: \(character.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func characterCardButton(_ character: GameCharacter) -> some View {
        Button(action: {
            selectedCharacterForCard = character
        }) {
            HStack {
                Image(systemName: "person.crop.rectangle")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("角色名片")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("查询角色名片")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func achievementAnalyzerButton(_ character: GameCharacter) -> some View {
        Button(action: {
            selectedCharacterForAchievement = character
        }) {
            HStack {
                Image(systemName: "star.circle")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("副本资历统计")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("查看副本成就进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func characterDetailButton(_ character: GameCharacter) -> some View {
        Button(action: {
            selectedCharacterForDetail = character
            loadCharacterDetail(for: character)
        }) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("角色装备")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("查看角色装备详细信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var arenaRecordButton: some View {
        NavigationLink(destination: ArenaRecordView()) {
            HStack {
                Image(systemName: "figure.roll.runningpace")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJC战绩")
                        .font(.headline)
                    Text("查询名剑大会战绩")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var gameInfoSection: some View {
        Section(header: Text("游戏信息")) {
            Button(action: {
                showingChivalrousEvents = true
            }) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("行侠事件")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("查询楚天社、云从社、披风会事件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: TeamRecruitView().environmentObject(dungeonManager)) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("团队招募")
                            .font(.headline)
                        Text("查询服务器团队招募信息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section(header: Text("数据管理")) {
            NavigationLink(destination: HistoryView()) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("历史记录")
                            .font(.headline)
                        Text("查看和管理完成记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func loadCharacterDetail(for character: GameCharacter) {
        isLoadingDetail = true
        
        Task {
            do {
                let data = try await JX3APIService.shared.fetchCharacterData(
                    server: character.server,
                    name: character.name
                )
                
                await MainActor.run {
                    isLoadingDetail = false
                    characterDetailData = CharacterDetailData(
                        code: 200,
                        msg: "success",
                        data: data,
                        time: nil
                    )
                    showingCharacterDetail = true
                }
            } catch {
                await MainActor.run {
                    isLoadingDetail = false
                    characterDetailData = nil
                    showingCharacterDetail = true
                    print("角色数据加载失败: \(error)")
                }
            }
        }
    }
}

