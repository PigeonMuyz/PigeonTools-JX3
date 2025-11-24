//
//  NetworkRetryService.swift
//  DungeonStat
//
//  网络请求重试服务 - 提供统一的重试机制
//

import Foundation

// MARK: - 重试配置
struct RetryConfiguration: Sendable {
    let maxRetries: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double

    nonisolated(unsafe) static let `default` = RetryConfiguration(
        maxRetries: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        backoffMultiplier: 2.0
    )

    nonisolated(unsafe) static let aggressive = RetryConfiguration(
        maxRetries: 5,
        initialDelay: 0.5,
        maxDelay: 30.0,
        backoffMultiplier: 2.0
    )

    nonisolated(unsafe) static let gentle = RetryConfiguration(
        maxRetries: 2,
        initialDelay: 2.0,
        maxDelay: 5.0,
        backoffMultiplier: 1.5
    )
}

// MARK: - 网络重试服务
class NetworkRetryService {

    // MARK: - 通用重试方法

    /// 执行带重试的异步操作
    static func executeWithRetry<T>(
        config: RetryConfiguration = .default,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = config.initialDelay

        for attempt in 0..<config.maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error

                // 检查是否应该重试
                if !shouldRetry(error: error) {
                    throw error
                }

                // 最后一次尝试不需要等待
                if attempt < config.maxRetries - 1 {
                    let jitter = Double.random(in: 0.0...0.3) * currentDelay
                    let delayWithJitter = currentDelay + jitter

                    print("[Retry] 请求失败 (尝试 \(attempt + 1)/\(config.maxRetries))，\(delayWithJitter)秒后重试")
                    print("[Retry] 错误: \(error.localizedDescription)")

                    try await Task.sleep(nanoseconds: UInt64(delayWithJitter * 1_000_000_000))

                    // 指数退避
                    currentDelay = min(currentDelay * config.backoffMultiplier, config.maxDelay)
                }
            }
        }

        // 所有重试都失败
        print("[Retry] 所有重试都失败")
        throw lastError ?? NSError(domain: "NetworkRetryService", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "所有重试都失败"])
    }

    /// 判断错误是否应该重试
    private static func shouldRetry(error: Error) -> Bool {
        // 网络错误通常可以重试
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .notConnectedToInternet:
                return true
            default:
                return false
            }
        }

        // API 错误
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return true
            case .apiError(let message):
                // 某些 API 错误可以重试（如服务器繁忙）
                return message.contains("繁忙") || message.contains("超时")
            default:
                return false
            }
        }

        return false
    }

    // MARK: - 批量请求支持

    /// 批量执行请求（带并发限制）
    static func executeBatch<T>(
        items: [T],
        maxConcurrent: Int = 3,
        config: RetryConfiguration = .default,
        operation: @escaping (T) async throws -> Void
    ) async throws {
        var errors: [Error] = []

        await withTaskGroup(of: Void.self) { group in
            var iterator = items.makeIterator()
            var activeCount = 0

            while let item = iterator.next() {
                // 控制并发数量
                if activeCount >= maxConcurrent {
                    await group.next()
                    activeCount -= 1
                }

                group.addTask {
                    do {
                        try await executeWithRetry(config: config) {
                            try await operation(item)
                        }
                    } catch {
                        errors.append(error)
                    }
                }
                activeCount += 1
            }

            // 等待所有任务完成
            await group.waitForAll()
        }

        // 如果有错误，抛出第一个错误
        if let firstError = errors.first {
            throw firstError
        }
    }
}

// MARK: - JX3APIService 扩展（使用重试机制）

extension JX3APIService {

    /// 带重试的角色详情获取
    func fetchRoleDetailsWithRetry(server: String, name: String) async throws -> DetailedRoleData {
        return try await NetworkRetryService.executeWithRetry {
            try await self.fetchRoleDetails(server: server, name: name)
        }
    }

    /// 带重试的成就数据获取
    func fetchAchievementDataWithRetry(server: String, name: String) async throws -> AchievementData {
        return try await NetworkRetryService.executeWithRetry {
            try await self.fetchAchievementData(server: server, name: name)
        }
    }

    /// 带重试的竞技场记录获取
    func fetchArenaRecordWithRetry(server: String, name: String, mode: ArenaMode) async throws -> ArenaRecordData {
        return try await NetworkRetryService.executeWithRetry {
            try await self.fetchArenaRecord(server: server, name: name, mode: mode)
        }
    }

    /// 带重试的副本 CD 获取
    func fetchTeamCdListWithRetry(server: String, name: String) async throws -> TeamCdData {
        return try await NetworkRetryService.executeWithRetry {
            try await self.fetchTeamCdList(server: server, name: name)
        }
    }
}
