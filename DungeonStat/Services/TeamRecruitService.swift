//
//  TeamRecruitService.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
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
    func fetchTeamRecruit(server: String) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 从配置中获取token
        guard let token = getTokenV1() else {
            handleError("未找到有效的API Token")
            return
        }
        
        // 构建GET请求URL，table固定为1（全部查询）
        guard var urlComponents = URLComponents(string: "https://www.jx3api.com/data/member/recruit") else {
            handleError("无效的API地址")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "server", value: server),
            URLQueryItem(name: "table", value: "1"),
            URLQueryItem(name: "token", value: token)
        ]
        
        guard let url = urlComponents.url else {
            handleError("无法构建请求URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
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
    func refreshTeamRecruit(server: String) {
        fetchTeamRecruit(server: server)
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
        // 获取TokenV1，参考JX3APIService的实现
        let token = UserDefaults.standard.string(forKey: "jx3api_token") ?? ""
        return token.isEmpty ? nil : token
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
