//
//  DailyTaskService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/4.
//

import Foundation

// MARK: - 日常任务服务
class DailyTaskService {
    static let shared = DailyTaskService()
    private init() {}
    
    // 获取指定服务器的日常活动数据
    func fetchDailyActivities(server: String) async throws -> JX3DailyActivityData {
        
        // URL编码服务器名
        guard let encodedServer = server.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidParameters
        }
        
        // 构建URL参数
        var urlComponents = URLComponents(string: "https://www.jx3api.com/data/active/calendar")!
        var queryItems = [
            URLQueryItem(name: "server", value: encodedServer),
            URLQueryItem(name: "num", value: "0")
        ]
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(JX3DailyActivityResponse.self, from: data)
        
        guard apiResponse.code == 200, let activityData = apiResponse.data else {
            throw APIError.apiError(apiResponse.msg)
        }
        
        return activityData
    }
    
    // 根据API数据创建日常任务
    func createDailyTasks(from activityData: JX3DailyActivityData) -> [DailyTask] {
        var tasks: [DailyTask] = []
        let refreshTime = CharacterDailyTasks.getRefreshTime()
        
        // 大战 - 有具体内容
        if let war = activityData.war {
            tasks.append(DailyTask(
                type: .war,
                name: war,
                refreshDate: refreshTime
            ))
        }
        
        // 积分日常 - 固定任务，无具体目标
        tasks.append(DailyTask(
            type: .battle,
            name: "积分日常",
            refreshDate: refreshTime
        ))
        
        // 牛车 - 有具体内容
        if let orecar = activityData.orecar {
            tasks.append(DailyTask(
                type: .orecar,
                name: orecar,
                refreshDate: refreshTime
            ))
        }
        
        // 家园祈福 - 固定任务，无具体参数
        tasks.append(DailyTask(
            type: .luck,
            name: "家园祈福",
            refreshDate: refreshTime
        ))
        
        // 跑商 - 固定任务，无具体目标
        tasks.append(DailyTask(
            type: .trade,
            name: "跑商",
            refreshDate: refreshTime
        ))
        
        return tasks
    }
    
}
