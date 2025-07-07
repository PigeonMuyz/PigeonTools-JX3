//
//  CharacterManagementView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI


// MARK: - 角色卡片头部
struct CharacterCardsHeader: View {
    let characters: [CharacterData]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(characters.indices, id: \.self) { index in
                    let character = characters[index]
                    let isTopScore = character.panelList.score == characters.map { $0.panelList.score }.max()
                    
                    VStack(spacing: 8) {
                        // 头像占位
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: isTopScore ? [.orange, .yellow] : [.blue.opacity(0.7), .purple.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            if let avatarURL = character.personAvatar {
                                AsyncImage(url: URL(string: avatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Text(String(character.roleName.prefix(1)))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text(String(character.roleName.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            if isTopScore {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "crown.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .background(
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 20, height: 20)
                                            )
                                            .offset(x: 8, y: 8)
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 2) {
                            Text(character.roleName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Text(character.forceName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 80)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 装分对比卡片
struct ScoreComparisonCard: View {
    let characters: [CharacterData]
    
    private var maxScore: Int {
        characters.map { $0.panelList.score }.max() ?? 0
    }
    
    private var minScore: Int {
        characters.map { $0.panelList.score }.min() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("装分对比")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 12) {
                ForEach(characters.indices, id: \.self) { index in
                    let character = characters[index]
                    let score = character.panelList.score
                    let isHighest = score == maxScore
                    let isLowest = score == minScore && maxScore != minScore
                    let percentage = maxScore > 0 ? Double(score) / Double(maxScore) : 0
                    
                    HStack(spacing: 12) {
                        // 角色名
                        Text(character.roleName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        // 进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 24)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: isHighest ? [.orange, .yellow] : [.blue.opacity(0.8), .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(40, CGFloat(percentage) * 180), height: 24)
                                .animation(.easeInOut(duration: 0.8), value: percentage)
                            
                            HStack {
                                Text("\(score)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                if isHighest && maxScore != minScore {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        .frame(width: 180)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 属性对比卡片
struct AttributeComparisonCard: View {
    let attributeName: String
    let values: [Double]
    let isPercent: Bool
    let characters: [CharacterData]
    
    private var maxValue: Double {
        values.max() ?? 0
    }
    
    private var minValue: Double {
        values.min() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: getAttributeIcon())
                    .foregroundColor(.blue)
                Text(attributeName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                ForEach(values.indices, id: \.self) { index in
                    let value = values[index]
                    let character = characters[index]
                    let isHighest = value == maxValue && maxValue != minValue
                    let isLowest = value == minValue && maxValue != minValue
                    let percentage = maxValue > 0 ? value / maxValue : 0
                    
                    HStack(spacing: 12) {
                        // 角色名
                        Text(character.roleName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        // 可视化条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(getBarColor(isHighest: isHighest, isLowest: isLowest))
                                .frame(width: max(30, CGFloat(percentage) * 150), height: 20)
                                .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: percentage)
                            
                            HStack {
                                Text(formatValue(value))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(percentage > 0.5 ? .white : .primary)
                                    .padding(.leading, 6)
                                
                                Spacer()
                                
                                if isHighest && maxValue != minValue {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 4)
                                } else if isLowest && maxValue != minValue {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                        .frame(width: 150)
                        
                        Spacer()
                        
                        // 差值显示
                        if maxValue != minValue {
                            let diff = ((value - minValue) / (maxValue - minValue)) * 100
                            Text("\(Int(diff))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if isPercent {
            return String(format: "%.1f%%", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private func getBarColor(isHighest: Bool, isLowest: Bool) -> LinearGradient {
        if isHighest {
            return LinearGradient(
                colors: [.green, .mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if isLowest {
            return LinearGradient(
                colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func getAttributeIcon() -> String {
        switch attributeName {
        case let name where name.contains("攻击"):
            return "sword.fill"
        case let name where name.contains("防御"):
            return "shield.fill"
        case let name where name.contains("血"):
            return "heart.fill"
        case let name where name.contains("命中"):
            return "target"
        case let name where name.contains("闪避"):
            return "figure.run"
        case let name where name.contains("暴击"):
            return "bolt.fill"
        case let name where name.contains("速度"):
            return "speedometer"
        default:
            return "chart.bar.fill"
        }
    }
}


// MARK: - 角色管理视图
struct CharacterManagementView: View {
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var showingAddCharacter = false
    @State private var showingCharacterDetail = false
    @State private var showingAttributeComparison = false
    @State private var selectedCharacterForDetail: GameCharacter?
    @State private var selectedCharacterForEquipment: GameCharacter?
    @State private var selectedCharactersForComparison: Set<GameCharacter> = []
    @State private var characterDetailData: CharacterDetailData?
    @State private var isLoadingDetail = false
    @State private var showingAchievementAnalyzer = false
    @State private var selectedCharacterForAchievement: GameCharacter?
    
    // 搜索和对比状态
    @State private var searchText = ""
    @State private var isComparisonMode = false
    
    // 筛选后的角色列表
    private var filteredCharacters: [GameCharacter] {
        dungeonManager.characters.filter { character in
            searchText.isEmpty ||
                character.name.localizedCaseInsensitiveContains(searchText) ||
                character.school.localizedCaseInsensitiveContains(searchText) ||
                character.server.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(filteredCharacters) { gameCharacter in
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
                                
                                // 对比模式下的选择器
                                if isComparisonMode {
                                    if selectedCharactersForComparison.contains(gameCharacter) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .onTapGesture {
                                                selectedCharactersForComparison.remove(gameCharacter)
                                            }
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .onTapGesture {
                                                if selectedCharactersForComparison.count < 4 {
                                                    selectedCharactersForComparison.insert(gameCharacter)
                                                }
                                            }
                                    }
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
                            if !isComparisonMode {
                                dungeonManager.selectCharacter(gameCharacter)
                            }
                        }
                        .onLongPressGesture {
                            if !isComparisonMode {
                                selectedCharacterForDetail = gameCharacter
                                loadCharacterDetail(for: gameCharacter)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !isComparisonMode {
                                // 删除按钮
                                Button {
                                    dungeonManager.deleteCharacter(gameCharacter)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)

                                // 副本资历统计按钮
                                Button {
                                    selectedCharacterForAchievement = gameCharacter
                                    showingAchievementAnalyzer = true
                                } label: {
                                    Image(systemName: "star.circle")
                                }
                                .tint(.purple)

                                // 查看详情按钮
                                Button {
                                    selectedCharacterForDetail = gameCharacter
                                    loadCharacterDetail(for: gameCharacter)
                                } label: {
                                    Image(systemName: "info.circle")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "搜索角色名、门派或服务器")
                
                // 对比模式底部栏
                if isComparisonMode {
                    VStack(spacing: 12) {
                        if !selectedCharactersForComparison.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("已选择 \(selectedCharactersForComparison.count) 个角色进行比较")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(selectedCharactersForComparison.map { $0.name }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button("清空") {
                                    selectedCharactersForComparison.removeAll()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                
                                Button("开始比较") {
                                    showingAttributeComparison = true
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .disabled(selectedCharactersForComparison.count < 2)
                            }
                        } else {
                            // 显示对比模式说明
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("选择要对比的角色")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                Text("点击角色右侧的圆圈选择要对比的角色（2-4个），系统将自动比较所有角色的共同属性")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        HStack {
                            Button("取消") {
                                isComparisonMode = false
                                selectedCharactersForComparison.removeAll()
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text("对比模式")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("角色管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if isComparisonMode {
                            isComparisonMode = false
                            selectedCharactersForComparison.removeAll()
                        } else {
                            isComparisonMode = true
                        }
                    } label: {
                        Image(systemName: isComparisonMode ? "chart.bar.xaxis.descending" : "chart.bar.xaxis")
                            .foregroundColor(isComparisonMode ? .blue : .primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: BackupManagementView().environmentObject(dungeonManager)) {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.orange)
                        }
                        .disabled(isComparisonMode)
                        
                        Button("添加角色") {
                            showingAddCharacter = true
                        }
                        .disabled(isComparisonMode)
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
            .sheet(isPresented: $showingAttributeComparison) {
                AttributeComparisonSheet(characters: Array(selectedCharactersForComparison))
            }
            .sheet(isPresented: $showingAchievementAnalyzer) {
                if let character = selectedCharacterForAchievement {
                    AchievementAnalyzerView(character: character)
                }
            }
        }
    }
    
    func loadCharacterDetail(for character: GameCharacter) {
        isLoadingDetail = true
        showingCharacterDetail = true
        
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
                }
            } catch {
                await MainActor.run {
                    isLoadingDetail = false
                    characterDetailData = nil
                    print("角色数据加载失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 属性比较Sheet
struct AttributeComparisonSheet: View {
    let characters: [GameCharacter]
    @Environment(\.dismiss) private var dismiss
    @State private var characterDataList: [CharacterData] = []
    @State private var isLoading = false
    @State private var commonAttributes: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("加载角色数据中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if characterDataList.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("无法加载角色数据")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("重新加载") {
                            loadAllCharacterData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 角色卡片头部
                            CharacterCardsHeader(characters: characterDataList)
                            
                            // 装分对比特殊卡片
                            ScoreComparisonCard(characters: characterDataList)
                            
                            // 属性对比卡片
                            ForEach(commonAttributes, id: \.self) { attributeName in
                                if let firstAttribute = characterDataList.first?.panelList.panel.first(where: { $0.name == attributeName }) {
                                    AttributeComparisonCard(
                                        attributeName: attributeName,
                                        values: characterDataList.compactMap { data in
                                            data.panelList.panel.first(where: { $0.name == attributeName })?.value
                                        },
                                        isPercent: firstAttribute.percent,
                                        characters: characterDataList
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("属性对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAllCharacterData()
            }
        }
    }
    
    private func loadAllCharacterData() {
        isLoading = true
        characterDataList = []
        commonAttributes = []
        
        let group = DispatchGroup()
        var tempDataList: [CharacterData] = []
        
        for character in characters {
            group.enter()
            loadCharacterData(for: character) { data in
                if let data = data {
                    tempDataList.append(data)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            characterDataList = tempDataList.sorted { $0.panelList.score > $1.panelList.score }
            
            // 找出所有角色都有的属性
            if !characterDataList.isEmpty {
                let allAttributeNames = characterDataList.map { data in
                    Set(data.panelList.panel.map { $0.name })
                }
                
                // 取交集，找出所有角色都有的属性
                commonAttributes = Array(allAttributeNames.reduce(allAttributeNames[0]) { result, attributeSet in
                    result.intersection(attributeSet)
                }).sorted()
            }
        }
    }
    
    private func loadCharacterData(for character: GameCharacter, completion: @escaping (CharacterData?) -> Void) {
        Task {
            do {
                let data = try await JX3APIService.shared.fetchCharacterData(
                    server: character.server,
                    name: character.name
                )
                completion(data)
            } catch {
                completion(nil)
            }
        }
    }
}

// MARK: - 比较卡片
struct ComparisonCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                    
                    if let zoneName = data.zoneName {
                        Text("\(zoneName) - \(data.serverName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(data.serverName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
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
