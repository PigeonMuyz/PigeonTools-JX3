//
//  APIError.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/4.
//

import Foundation

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
