//
//  ChivalrousEventService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/18.
//

import Foundation
import Combine

// MARK: - 行侠事件服务
class ChivalrousEventService: ObservableObject {
    static let shared = ChivalrousEventService()
    
    @Published var events: [ChivalrousEvent] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 公共方法
    
    /// 获取指定组织的行侠事件
    func fetchChivalrousEvents(for organization: ChivalrousOrganization) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 构建GET请求URL，将参数添加到查询字符串
        guard var urlComponents = URLComponents(string: "https://www.jx3api.com/data/active/celebs") else {
            handleError("无效的API地址")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "name", value: organization.rawValue)
        ]
        
        guard let url = urlComponents.url else {
            handleError("无法构建请求URL")
            return
        }
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ChivalrousEventResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError("获取行侠事件失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 手动刷新事件
    func refreshEvents(for organization: ChivalrousOrganization) {
        fetchChivalrousEvents(for: organization)
    }
    
    // MARK: - 私有方法
    
    private func handleResponse(_ response: ChivalrousEventResponse) {
        if response.code == 200 {
            events = response.data
            lastUpdateTime = Date()
            errorMessage = nil
        } else {
            handleError(response.msg)
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        events = []
        isLoading = false
        print("行侠事件服务错误: \(message)")
    }
    
    /// 根据地图名称对事件进行分组
    func groupEventsByMap() -> [String: [ChivalrousEvent]] {
        Dictionary(grouping: events) { $0.mapName }
    }
    
    /// 获取所有地图名称
    func getAllMapNames() -> [String] {
        Array(Set(events.map { $0.mapName })).sorted()
    }
}
