//
//  AddCharacterView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/6/30.
//

import SwiftUI

// MARK: - API响应模型 (使用详细属性接口)
struct JX3APIDetailResponse: Codable {
    let code: Int
    let msg: String
    let data: DetailedRoleData?
    let time: Int?
}

struct DetailedRoleData: Codable {
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
    let personName: String?
    let personId: String?
    let personAvatar: String?
    let gameClient: String?      // 客户端类型
    let gameMode: String?        // 游戏模式
    let kungfuType: String?      // 功夫类型
    let kungfuName: String
    let kungfuId: String
    let equipList: [EquipmentInfo]
    let qixueList: [QixueInfo]
    let panelList: PanelInfo
}

struct EquipmentInfo: Codable {
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
}

struct QixueInfo: Codable {
    let name: String
    let level: Int
    let icon: String
    let kind: String
    let subKind: String
    let desc: String
}

struct PanelInfo: Codable {
    let score: Int
    let panel: [PanelAttributeInfo]
}

struct PanelAttributeInfo: Codable {
    let name: String
    let percent: Bool
    let value: Double
}

// MARK: - 网络服务
class JX3APIService {
    static let shared = JX3APIService()
    private init() {}
    
    private let ticket = "[REDACTED_TICKET]"
    private let token = "[REDACTED_TOKEN]"
    
    func fetchRoleDetails(server: String, name: String) async throws -> DetailedRoleData {
        // URL编码服务器名和角色名
        guard let encodedServer = server.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidParameters
        }
        
        // 使用 attribute 接口获取详细信息包括装分
        let urlString = "https://www.jx3api.com/data/role/attribute?server=\(encodedServer)&name=\(encodedName)&ticket=\(ticket)&token=\(token)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(JX3APIDetailResponse.self, from: data)
        
        guard apiResponse.code == 200, let roleData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return roleData
    }
}

// MARK: - API错误类型
enum APIError: LocalizedError {
    case invalidURL
    case invalidParameters
    case networkError
    case apiError(String)
    case roleNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidParameters:
            return "无效的参数"
        case .networkError:
            return "网络请求失败"
        case .apiError(let message):
            return "API错误: \(message)"
        case .roleNotFound:
            return "角色不存在或信息获取失败"
        }
    }
}

// MARK: - 添加角色视图
struct AddCharacterView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var server = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // 用于显示获取到的角色信息
    @State private var fetchedRoleData: DetailedRoleData?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("角色信息")) {
                    TextField("服务器", text: $server)
                        .disabled(isLoading)
                    TextField("角色名", text: $name)
                        .disabled(isLoading)
                }
                
                // 如果获取到了角色信息，显示确认信息
                if let roleData = fetchedRoleData {
                    Section(header: Text("角色详情")) {
                        HStack {
                            Text("服务器:")
                            Spacer()
                            Text(roleData.serverName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("角色名:")
                            Spacer()
                            Text(roleData.roleName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("门派:")
                            Spacer()
                            Text(roleData.forceName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("心法:")
                            Spacer()
                            Text(roleData.kungfuName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("体型:")
                            Spacer()
                            Text(roleData.bodyName)
                                .foregroundColor(.secondary)
                        }
                        
                        // 显示装分
                        HStack {
                            Text("装分:")
                            Spacer()
                            Text("\(roleData.panelList.score)")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        
                        // 显示客户端类型
                        if let gameClient = roleData.gameClient {
                            HStack {
                                Text("客户端:")
                                Spacer()
                                Text(gameClient)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let gameMode = roleData.gameMode {
                            HStack {
                                Text("装备分类:")
                                Spacer()
                                Text(gameMode)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let kungfuType = roleData.kungfuType {
                            HStack {
                                Text("装备类型:")
                                Spacer()
                                Text(kungfuType)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let tongName = roleData.tongName, !tongName.isEmpty {
                            HStack {
                                Text("帮会:")
                                Spacer()
                                Text(tongName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在获取角色信息...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("添加角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if fetchedRoleData != nil {
                        Button("确认添加") {
                            addCharacterWithFetchedData()
                        }
                        .disabled(isLoading)
                    } else {
                        Button("获取信息") {
                            Task {
                                await fetchRoleInfo()
                            }
                        }
                        .disabled(server.isEmpty || name.isEmpty || isLoading)
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 获取角色信息
    @MainActor
    private func fetchRoleInfo() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let roleData = try await JX3APIService.shared.fetchRoleDetails(
                server: server.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            fetchedRoleData = roleData
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            fetchedRoleData = nil
        }
        
        isLoading = false
    }
    
    // MARK: - 添加角色
    private func addCharacterWithFetchedData() {
        guard let roleData = fetchedRoleData else { return }
        
        dungeonManager.addCharacter(
            server: roleData.serverName,
            name: roleData.roleName,
            school: roleData.forceName,
            bodyType: roleData.bodyName
        )
        
        isPresented = false
    }
}
