//
//  ServerStatusManager.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/18.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 服务器状态数据模型
struct ServerStatusResponse: Codable {
    let code: Int
    let msg: String
    let data: [ServerStatus]
    let time: Int
}

struct ServerStatus: Codable, Identifiable {
    let id: Int
    let zone: String
    let server: String
    let status: Int // 0: 维护中, 1: 正常
    let time: Int
    
    var isOnline: Bool {
        return status == 1
    }
    
    var statusText: String {
        return isOnline ? "正常" : "维护中"
    }
    
    var lastUpdateDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(time))
    }
}

// MARK: - 服务器状态管理器
class ServerStatusManager: ObservableObject {
    static let shared = ServerStatusManager()
    
    @Published var serverStatuses: [ServerStatus] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private var pollingTimer: Timer?
    
    // 服务器合并映射表
    private let serverMappings: [String: String] = [
        "万象长安": "眉间雪",
        "有人赴约": "山海相逢",
        "青梅煮酒": "飞龙在天"
    ]
    
    private init() {
        startPolling()
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - 公共方法
    
    /// 开始轮询服务器状态
    func startPolling() {
        stopPolling() // 先停止现有的轮询
        
        // 立即获取一次
        fetchServerStatus()
        
        // 每30秒轮询一次
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.fetchServerStatus()
        }
    }
    
    /// 停止轮询
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    /// 手动刷新服务器状态
    func refreshServerStatus() {
        fetchServerStatus()
    }
    
    /// 获取用户角色相关的服务器状态
    func getUserServerStatuses(for characters: [GameCharacter]) -> [ServerStatus] {
        let userServers = Set(characters.map { getMappedServerName($0.server) })
        return serverStatuses.filter { userServers.contains($0.server) }
    }
    
    /// 获取整体服务器状态
    func getOverallStatus(for characters: [GameCharacter]) -> ServerOverallStatus {
        guard !characters.isEmpty else { return .unknown }
        
        let userStatuses = getUserServerStatuses(for: characters)
        guard !userStatuses.isEmpty else { return .unknown }
        
        let offlineServers = userStatuses.filter { !$0.isOnline }
        
        if offlineServers.isEmpty {
            return .allOnline
        } else if offlineServers.count == userStatuses.count {
            return .allOffline
        } else {
            return .partialOffline
        }
    }
    
    // MARK: - 私有方法
    
    private func fetchServerStatus() {
        guard !isLoading else { return }
        
        isLoading = true
        print("检查服务器状态")
        guard let url = URL(string: "https://www.jx3api.com/data/server/check") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ServerStatusResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("获取服务器状态失败: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleServerStatusResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleServerStatusResponse(_ response: ServerStatusResponse) {
        // 过滤掉已合并的服务器，避免重复显示
        let filteredStatuses = response.data.filter { serverStatus in
            !serverMappings.keys.contains(serverStatus.server)
        }
        serverStatuses = filteredStatuses
        lastUpdateTime = Date()
    }
    
    private func getMappedServerName(_ originalName: String) -> String {
        return serverMappings[originalName] ?? originalName
    }
}

// MARK: - 服务器整体状态枚举
enum ServerOverallStatus {
    case allOnline      // 所有服务器正常
    case allOffline     // 所有服务器维护中
    case partialOffline // 部分服务器维护中
    case unknown        // 未知状态
    
    var indicatorColor: Color {
        switch self {
        case .allOnline:
            return .green
        case .allOffline:
            return .red
        case .partialOffline:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    var statusText: String {
        switch self {
        case .allOnline:
            return "所有服务器正常"
        case .allOffline:
            return "所有服务器维护中"
        case .partialOffline:
            return "部分服务器维护中"
        case .unknown:
            return "状态未知"
        }
    }
}

