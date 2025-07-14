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
    let zoneName: String?        // 修改为可选类型
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

// MARK: - Token Usage API Models
struct TokenUsageResponse: Codable {
    let code: Int
    let msg: String
    let data: TokenUsageData?
    let time: Int
}

struct TokenUsageData: Codable {
    let id: Int
    let user: Int
    let token: String
    let host: String
    let banned: String?
    let level: Int
    let num: Int
    let limit: Int
    let count: Int
    let status: Int
    let datetime: String
}

// MARK: - Achievement API Models
struct AchievementResponse: Codable {
    let code: Int
    let msg: String
    let data: AchievementData?
    let time: Int
}

struct AchievementData: Codable {
    let roleName: String
    let serverName: String
    let data: AchievementStatistics
}

struct AchievementStatistics: Codable {
    let dungeons: [String: [String: DungeonStats]]
}

struct DungeonStats: Codable {
    let seniority: SeniorityInfo
    let pieces: PiecesInfo
}

struct SeniorityInfo: Codable {
    let total: Int
    let speed: Int
}

struct PiecesInfo: Codable {
    let total: Int
    let speed: Int
}

// MARK: - Arena Battle Record API Models
struct ArenaRecordResponse: Codable {
    let code: Int
    let msg: String
    let data: ArenaRecordData?
    let time: Int
}

struct ArenaRecordData: Codable {
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
    let personId: String
    let personAvatar: String?
    let performance: [String: ArenaPerformance]
    let history: [ArenaHistoryRecord]
    let trend: [ArenaTrendData]
}

struct ArenaPerformance: Codable {
    let mmr: Int
    let grade: Int
    let ranking: String
    let winCount: Int
    let totalCount: Int
    let mvpCount: Int
    let pvpType: String
    let winRate: Int
}

struct ArenaHistoryRecord: Codable {
    let zone: String
    let server: String
    let avgGrade: Int
    let totalMmr: Int
    let mmr: Int
    let kungfu: String
    let pvpType: Int
    let won: Bool
    let mvp: Bool
    let startTime: Int
    let endTime: Int
}

struct ArenaTrendData: Codable {
    let matchDate: Int
    let mmr: Int
    let winRate: Double
}

// MARK: - Arena Mode Enum
enum ArenaMode: Int, CaseIterable {
    case twoVTwo = 22
    case threeVThree = 33
    case fiveVFive = 55
    
    var displayName: String {
        switch self {
        case .twoVTwo:
            return "2v2"
        case .threeVThree:
            return "3v3"
        case .fiveVFive:
            return "5v5"
        }
    }
    
    var apiKey: String {
        switch self {
        case .twoVTwo:
            return "2v2"
        case .threeVThree:
            return "3v3"
        case .fiveVFive:
            return "5v5"
        }
    }
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
        
        // 构建URL参数 - URLQueryItem会自动处理编码，不需要手动编码
        var urlComponents = URLComponents(string: "https://www.jx3api.com/data/role/attribute")!
        var queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "name", value: name)
        ]
        
        // 角色装备信息需要ticket和token v1
        if !ticket.isEmpty {
            queryItems.append(URLQueryItem(name: "ticket", value: ticket))
        }
        
        if !token.isEmpty {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        
        // 如果没有必要的令牌，抛出错误
        if ticket.isEmpty || token.isEmpty {
            throw APIError.apiError("获取角色装备信息需要配置Ticket和Token V1")
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        print(url);
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse: JX3APIDetailResponse
        do {
            apiResponse = try JSONDecoder().decode(JX3APIDetailResponse.self, from: data)
        } catch {
            throw APIError.apiError("数据解析失败")
        }
        
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
    
    // MARK: - Token Usage API
    func fetchTokenUsage(token: String) async throws -> TokenUsageData {
        guard !token.isEmpty else {
            throw APIError.apiError("Token不能为空")
        }
        
        let urlString = "https://seasun.nicemoe.cn/data/token/web/token?token=\(token)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(TokenUsageResponse.self, from: data)
        
        guard apiResponse.code == 200, let usageData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return usageData
    }
    
    // MARK: - Achievement API
    func fetchAchievementData(server: String, name: String) async throws -> AchievementData {
        guard !tokenV2.isEmpty else {
            throw APIError.apiError("获取资历统计需要配置Token V2")
        }
        
        let urlString = "https://www.jx3api.com/data/tuilan/achievement"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "class", value: "3"),
            URLQueryItem(name: "subclass", value: "秘境"),
            URLQueryItem(name: "token", value: tokenV2),
            URLQueryItem(name: "ticket", value: ticket)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(AchievementResponse.self, from: data)
        
        guard apiResponse.code == 200, let achievementData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return achievementData
    }
    
    // MARK: - Arena Battle Record API
    func fetchArenaRecord(server: String, name: String, mode: ArenaMode) async throws -> ArenaRecordData {
        guard !token.isEmpty || !ticket.isEmpty else {
            throw APIError.apiError("获取名剑大会战绩需要配置Token V1和Ticket")
        }
        
        let urlString = "https://www.jx3api.com/data/arena/recent"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "mode", value: String(mode.rawValue))
        ]
        
        if !token.isEmpty {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        
        if !ticket.isEmpty {
            queryItems.append(URLQueryItem(name: "ticket", value: ticket))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(ArenaRecordResponse.self, from: data)
        
        guard apiResponse.code == 200, let arenaData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return arenaData
    }
    
    // MARK: - Character Card API
    func fetchCharacterCard(server: String, name: String) async throws -> CharacterCardData {
        guard !tokenV2.isEmpty else {
            throw APIError.apiError("获取角色名片需要配置Token V2")
        }
        
        let urlString = "https://www.jx3api.com/data/show/card"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "token", value: tokenV2)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(CharacterCardResponse.self, from: data)
        
        guard apiResponse.code == 200, let cardData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return cardData
    }
    
    // MARK: - Character Achievement Detail API
    func fetchCharacterAchievementDetail(server: String, role: String, name: String) async throws -> CharacterAchievementDetailData {
        guard !ticket.isEmpty || !token.isEmpty else {
            throw APIError.apiError("获取角色成就详情需要配置Ticket和Token V1")
        }
        
        let urlString = "https://www.jx3api.com/data/role/achievement"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "role", value: role),
            URLQueryItem(name: "name", value: name)
        ]
        
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
        
        print("请求角色成就详情URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(CharacterAchievementDetailResponse.self, from: data)
        
        guard apiResponse.code == 200, let detailData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return detailData
    }
}
