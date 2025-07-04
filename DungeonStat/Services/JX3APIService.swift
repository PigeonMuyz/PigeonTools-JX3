//
//  JX3APIService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - API响应模型
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
    let gameClient: String?
    let gameMode: String?
    let kungfuType: String?
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
    
    // 从AppStorage获取API令牌
    private var ticket: String {
        UserDefaults.standard.string(forKey: "jx3api_ticket") ?? ""
    }
    
    private var token: String {
        UserDefaults.standard.string(forKey: "jx3api_token") ?? ""
    }
    
    private var tokenV2: String {
        UserDefaults.standard.string(forKey: "jx3api_tokenv2") ?? ""
    }
    
    func fetchRoleDetails(server: String, name: String) async throws -> DetailedRoleData {
        // 检查是否有配置的令牌
        guard !ticket.isEmpty || !token.isEmpty else {
            throw APIError.apiError("请先在设置中配置JX3API令牌")
        }
        
        // URL编码服务器名和角色名
        guard let encodedServer = server.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidParameters
        }
        
        // 构建URL参数
        var urlComponents = URLComponents(string: "https://www.jx3api.com/data/role/attribute")!
        var queryItems = [
            URLQueryItem(name: "server", value: encodedServer),
            URLQueryItem(name: "name", value: encodedName)
        ]
        
        // 优先使用ticket，其次使用token
        if !ticket.isEmpty {
            queryItems.append(URLQueryItem(name: "ticket", value: ticket))
        }
        
        if !token.isEmpty {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
    
    // 检查API配置状态
    func isConfigured() -> Bool {
        return !ticket.isEmpty || !token.isEmpty || !tokenV2.isEmpty
    }
    
    // 获取配置状态描述
    func getConfigurationStatus() -> String {
        var status: [String] = []
        
        if !token.isEmpty {
            status.append("Token V1")
        }
        if !tokenV2.isEmpty {
            status.append("Token V2")
        }
        if !ticket.isEmpty {
            status.append("Ticket")
        }
        
        if status.isEmpty {
            return "未配置"
        } else {
            return "已配置: \(status.joined(separator: ", "))"
        }
    }
    
    func fetchCharacterData(server: String, name: String) async throws -> CharacterData {
        let detailedData = try await fetchRoleDetails(server: server, name: name)
        
        // 转换为 CharacterData 类型
        return CharacterData(
            zoneName: detailedData.zoneName,
            serverName: detailedData.serverName,
            roleName: detailedData.roleName,
            roleId: detailedData.roleId,
            globalRoleId: detailedData.globalRoleId,
            forceName: detailedData.forceName,
            forceId: detailedData.forceId,
            bodyName: detailedData.bodyName,
            bodyId: detailedData.bodyId,
            tongName: detailedData.tongName,
            tongId: detailedData.tongId,
            campName: detailedData.campName,
            campId: detailedData.campId,
            personName: detailedData.personName ?? "",
            personId: detailedData.personId,
            personAvatar: detailedData.personAvatar,
            gameClient: detailedData.gameClient,
            gameMode: detailedData.gameMode,
            kungfuType: detailedData.kungfuType,
            kungfuName: detailedData.kungfuName,
            kungfuId: detailedData.kungfuId,
            equipList: detailedData.equipList.map { equipInfo in
                Equipment(
                    name: equipInfo.name,
                    class: equipInfo.class,
                    icon: equipInfo.icon,
                    kind: equipInfo.kind,
                    subKind: equipInfo.subKind,
                    quality: equipInfo.quality,
                    strengthLevel: equipInfo.strengthLevel,
                    maxStrengthLevel: equipInfo.maxStrengthLevel,
                    color: equipInfo.color,
                    desc: equipInfo.desc
                )
            },
            qixueList: detailedData.qixueList.map { qixueInfo in
                Qixue(
                    name: qixueInfo.name,
                    level: qixueInfo.level,
                    icon: qixueInfo.icon,
                    kind: qixueInfo.kind,
                    subKind: qixueInfo.subKind,
                    desc: qixueInfo.desc
                )
            },
            panelList: PanelList(
                score: detailedData.panelList.score,
                panel: detailedData.panelList.panel.map { panelInfo in
                    PanelAttribute(
                        name: panelInfo.name,
                        percent: panelInfo.percent,
                        value: panelInfo.value
                    )
                }
            )
        )
    }
}
