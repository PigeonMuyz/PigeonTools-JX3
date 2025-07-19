//
//  TeamRecruitService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/19.
//

import Foundation
import Combine

// MARK: - 团队招募服务
class TeamRecruitService: ObservableObject {
    static let shared = TeamRecruitService()
    
    @Published var recruitItems: [TeamRecruitItem] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    @Published var serverInfo: (zone: String, server: String)?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 公共方法
    
    /// 获取团队招募信息
    func fetchTeamRecruit(server: String, keyword: String = "", searchType: TeamRecruitSearchType = .all) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 构建请求参数
        var parameters: [String: Any] = [
            "server": server,
            "table": searchType.rawValue
        ]
        
        // 如果有关键词，添加到参数中
        if !keyword.isEmpty {
            parameters["keyword"] = keyword
        }
        
        // 从配置中获取token
        guard let token = getTokenV1() else {
            handleError("未找到有效的API Token")
            return
        }
        parameters["token"] = token
        
        // 构建请求
        guard let url = URL(string: "https://www.jx3api.com/data/member/recruit") else {
            handleError("无效的API地址")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            handleError("请求参数编码失败")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TeamRecruitResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("获取团队招募信息失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 手动刷新团队招募信息
    func refreshTeamRecruit(server: String, keyword: String = "", searchType: TeamRecruitSearchType = .all) {
        fetchTeamRecruit(server: server, keyword: keyword, searchType: searchType)
    }
    
    // MARK: - 私有方法
    
    private func handleResponse(_ response: TeamRecruitResponse) {
        if response.code == 200 {
            recruitItems = response.data.data
            serverInfo = (zone: response.data.zone, server: response.data.server)
            lastUpdateTime = Date()
            errorMessage = nil
        } else {
            handleError(response.msg)
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        recruitItems = []
        serverInfo = nil
        isLoading = false
        print("团队招募服务错误: \(message)")
    }
    
    private func getTokenV1() -> String? {
        // 从UserDefaults或其他配置中获取token
        // 这里需要根据你的实际token存储方式来实现
        return UserDefaults.standard.string(forKey: "jx3_token_v1")
    }
    
    /// 根据活动名称对招募信息进行分组
    func groupRecruitsByActivity() -> [String: [TeamRecruitItem]] {
        Dictionary(grouping: recruitItems) { $0.activity }
    }
    
    /// 获取所有活动名称
    func getAllActivities() -> [String] {
        Array(Set(recruitItems.map { $0.activity })).sorted()
    }
}