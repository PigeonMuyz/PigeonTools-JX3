//
//  CharacterManagementView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - 角色详细数据模型
struct CharacterDetailData: Codable {
    let code: Int
    let msg: String
    let data: CharacterData?
    let time: Int?
}

struct CharacterData: Codable {
    let zoneName: String
    let serverName: String
    let roleName: String
    let roleId: String
    let globalRoleId: String
    let forceName: String
    let forceId: String
    let bodyName: String
    let bodyId: String
    let tongName: String?
    let tongId: String?
    let campName: String
    let campId: String
    let personName: String
    let personId: String?        // 修改为可选类型
    let personAvatar: String?    // 修改为可选类型
    let gameClient: String?      // 新增字段，可选类型
    let gameMode: String?        // 新增字段，可选类型
    let kungfuType: String?      // 新增字段，可选类型
    let kungfuName: String
    let kungfuId: String
    let equipList: [Equipment]
    let qixueList: [Qixue]
    let panelList: PanelList
}

struct Equipment: Codable, Identifiable {
    let id = UUID()
    let name: String
    let `class`: String
    let icon: String
    let kind: String
    let subKind: String
    let quality: String
    let strengthLevel: String
    let maxStrengthLevel: String
    let color: String
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case name, `class`, icon, kind, subKind, quality, strengthLevel, maxStrengthLevel, color, desc
    }
}

struct Qixue: Codable, Identifiable {
    let id = UUID()
    let name: String
    let level: Int
    let icon: String
    let kind: String
    let subKind: String
    let desc: String
    
    private enum CodingKeys: String, CodingKey {
        case name, level, icon, kind, subKind, desc
    }
}

struct PanelList: Codable {
    let score: Int
    let panel: [PanelAttribute]
}

struct PanelAttribute: Codable, Identifiable {
    let id = UUID()
    let name: String
    let percent: Bool
    let value: Double
    
    private enum CodingKeys: String, CodingKey {
        case name, percent, value
    }
}

// MARK: - 角色管理视图
struct CharacterManagementView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddCharacter = false
    @State private var showingCharacterDetail = false
    @State private var selectedCharacterForDetail: GameCharacter?
    @State private var characterDetailData: CharacterDetailData?
    @State private var isLoadingDetail = false
    
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
                                Text("当前选中")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
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
                        dungeonManager.selectCharacter(gameCharacter)
                    }
                    .onLongPressGesture {
                        selectedCharacterForDetail = gameCharacter
                        loadCharacterDetail(for: gameCharacter)
                    }
                }
                .onDelete(perform: deleteCharacters)
            }
            .navigationTitle("角色管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加角色") {
                        showingAddCharacter = true
                    }
                }
            }
            .sheet(isPresented: $showingAddCharacter) {
                AddCharacterView(isPresented: $showingAddCharacter)
            }
            .sheet(isPresented: $showingCharacterDetail) {
                CharacterDetailSheet(
                    character: selectedCharacterForDetail,
                    characterData: characterDetailData,
                    isLoading: isLoadingDetail
                )
            }
        }
    }
    
    func deleteCharacters(offsets: IndexSet) {
        for index in offsets {
            let gameCharacter = dungeonManager.characters[index]
            dungeonManager.deleteCharacter(gameCharacter)
        }
    }
    
    func loadCharacterDetail(for character: GameCharacter) {
        isLoadingDetail = true
        showingCharacterDetail = true
        
        let ticket = "[REDACTED_TICKET]"
        let token = "[REDACTED_TOKEN]"
        // 构建API URL
        guard let url = URL(string: "https://www.jx3api.com/data/role/attribute?server=\(character.server)&name=\(character.name)&ticket=\(ticket)&token=\(token)") else {
            isLoadingDetail = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingDetail = false
                
                if let data = data {
                    do {
                        let detailData = try JSONDecoder().decode(CharacterDetailData.self, from: data)
                        characterDetailData = detailData
                    } catch {
                        print("解析失败: \(error)")
                        characterDetailData = nil
                    }
                } else {
                    characterDetailData = nil
                }
            }
        }.resume()
    }
}

// MARK: - 角色详情Sheet
struct CharacterDetailSheet: View {
    let character: GameCharacter?
    let characterData: CharacterDetailData?
    let isLoading: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("加载角色数据中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else if let data = characterData?.data {
                    LazyVStack(spacing: 20) {
                        // 角色基本信息卡片
                        CharacterInfoCard(data: data)
                        
                        // 属性面板
                        AttributePanel(panelList: data.panelList)
                        
                        // 装备网格
                        EquipmentGrid(equipments: data.equipList)
                        
                        // 奇穴展示（仅在有数据时显示）
                        if !data.qixueList.isEmpty {
                            QixueSection(qixueList: data.qixueList)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("无法加载角色数据")
                            .font(.headline)
                        Text("请检查网络连接或稍后重试")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }
            }
            .navigationTitle(character?.name ?? "角色详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 角色信息卡片
struct CharacterInfoCard: View {
    let data: CharacterData
    
    var body: some View {
        VStack(spacing: 12) {
            // 头像和基本信息
            HStack(spacing: 15) {
                // 处理可能为nil的头像URL
                if let avatarURL = data.personAvatar {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // 当头像为nil时显示默认头像
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                        .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.roleName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(data.forceName) - \(data.kungfuName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("\(data.zoneName) - \(data.serverName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 显示游戏模式（如果有的话）
                    if let gameMode = data.gameMode {
                        Text("模式：\(gameMode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 装分显示
                VStack {
                    Text(String(format: "%.0f", Double(data.panelList.score)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("装分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - 装备网格
struct EquipmentGrid: View {
    let equipments: [Equipment]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("装备")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(equipments) { equipment in
                    EquipmentCard(equipment: equipment)
                }
            }
        }
    }
}

// MARK: - 装备卡片
struct EquipmentCard: View {
    let equipment: Equipment
    
    private var qualityColor: Color {
        switch equipment.color {
        case "1": return .gray
        case "2": return .green
        case "3": return .blue
        case "4": return .purple
        case "5": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: equipment.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "square.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            
            Text(equipment.name)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(qualityColor)
                .fontWeight(.medium)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(qualityColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 属性面板
struct AttributePanel: View {
    let panelList: PanelList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("属性")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 1) {
                ForEach(panelList.panel) { attribute in
                    AttributeRow(attribute: attribute)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - 属性行
struct AttributeRow: View {
    let attribute: PanelAttribute
    
    var body: some View {
        HStack {
            Text(attribute.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if attribute.percent {
                Text(String(format: "%.2f%%", attribute.value))
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text(String(format: "%.0f", attribute.value))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - 奇穴部分
struct QixueSection: View {
    let qixueList: [Qixue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("奇穴")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(qixueList) { qixue in
                        QixueCard(qixue: qixue)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 奇穴卡片
struct QixueCard: View {
    let qixue: Qixue
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: qixue.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "star.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            
            Text(qixue.name)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(width: 80)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
