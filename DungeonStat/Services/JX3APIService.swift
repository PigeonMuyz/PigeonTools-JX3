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
