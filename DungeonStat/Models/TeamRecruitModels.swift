//
//  TeamRecruitModels.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
//

import Foundation
import SwiftUI

// MARK: - 团队招募数据模型
struct TeamRecruitResponse: Codable {
    let code: Int
    let msg: String
    let data: TeamRecruitData
    let time: Int
}

struct TeamRecruitData: Codable {
    let zone: String
    let server: String
    let time: Int
    let data: [TeamRecruitItem]
}

struct TeamRecruitItem: Codable, Identifiable, Equatable {
    let id = UUID()
    let activity: String
    let leader: String
    let number: Int
    let maxNumber: Int
    let content: String
    
    // 其他字段，全部设为可选以避免解析错误
    let crossServer: Bool?
    let activityId: Int?
    let level: Int?
    let pushId: Int?
    let roomID: String?
    let roleId: Int?
    let createTime: Int?
    let label: [String]?
    
    enum CodingKeys: String, CodingKey {
        case activity
        case leader
        case number
        case maxNumber
        case content
        case crossServer
        case activityId
        case level
        case pushId
        case roomID
        case roleId
        case createTime
        case label
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 必需字段
        activity = try container.decode(String.self, forKey: .activity)
        leader = try container.decode(String.self, forKey: .leader)
        number = try container.decode(Int.self, forKey: .number)
        maxNumber = try container.decode(Int.self, forKey: .maxNumber)
        content = try container.decode(String.self, forKey: .content)
        
        // 可选字段，容忍类型不匹配
        crossServer = try? container.decode(Bool.self, forKey: .crossServer)
        activityId = try? container.decode(Int.self, forKey: .activityId)
        level = try? container.decode(Int.self, forKey: .level)
        pushId = try? container.decode(Int.self, forKey: .pushId)
        roomID = try? container.decode(String.self, forKey: .roomID)
        roleId = try? container.decode(Int.self, forKey: .roleId)
        createTime = try? container.decode(Int.self, forKey: .createTime)
        label = try? container.decode([String].self, forKey: .label)
    }
    
    static func == (lhs: TeamRecruitItem, rhs: TeamRecruitItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 人数状态
    var memberStatus: String {
        return "\(number)/\(maxNumber)"
    }
    
    // 是否已满员
    var isFull: Bool {
        return number >= maxNumber
    }
    
    // 缺人数量
    var neededMembers: Int {
        return max(0, maxNumber - number)
    }
}

// MARK: - 团队招募搜索类型
enum TeamRecruitSearchType: Int, CaseIterable {
    case all = 1        // 本服+跨服
    case local = 2      // 仅本服
    case cross = 3      // 仅跨服
    
    var displayName: String {
        switch self {
        case .all:
            return "本服+跨服"
        case .local:
            return "仅本服"
        case .cross:
            return "仅跨服"
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "globe"
        case .local:
            return "house"
        case .cross:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - 团队分类和识别扩展
extension TeamRecruitItem {
    
    /// 是否为金团
    var isGoldTeam: Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        
        // 扩展的金团关键字
        let goldKeywords = [
            "0抵消", "来打手", "包团", "老板", "需求老板", "来老板",
            "躺拍", "包牌子武器", "包大小铁", "低消", "包铁", "金团",
            "躺老板", "包牌子", "包武器", "抵消", "来装备需求"
        ]
        
        let hasGoldKeywords = goldKeywords.contains { keyword in
            content.contains(keyword) || content.contains(keyword.replacingOccurrences(of: "z", with: ""))
        }
        
        // 检查数字+z模式 (如"2z", "3z"等)
        let digitZPattern = "\\d+z"
        let hasDigitZ = content.range(of: digitZPattern, options: .regularExpression) != nil
        
        // 只有当content满足金团条件且number为1时才判断为金团
        return (hasGoldKeywords || hasDigitZ) && number == 1
    }
    
    /// 是否为教学团
    var isTeachingTeam: Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        return content.contains("教学") || content.contains("萌新") || 
               activity.contains("教学") || content.contains("带新手")
    }
    
    /// 是否为开荒团
    var isPioneerTeam: Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        return content.contains("开荒") || activity.contains("开荒")
    }
    
    /// 是否有补贴
    var hasSubsidy: Bool {
        let content = self.content
        // 匹配"补"字后跟数字的模式，如"补1"、"补500"等
        let subsidyPattern = "补\\d+"
        let range = content.range(of: subsidyPattern, options: .regularExpression)
        return range != nil
    }
    
    /// 获取补贴信息
    var subsidyInfo: String? {
        guard hasSubsidy else { return nil }
        let content = self.content
        let subsidyPattern = "补\\d+"
        if let range = content.range(of: subsidyPattern, options: .regularExpression) {
            return String(content[range])
        }
        return nil
    }
    
    /// 简单的文本匹配（参考JSX实现）
    func matchesSearchText(_ searchText: String, enableSubsidySearch: Bool = true, enableProfessionSearch: Bool = true) -> Bool {
        let content = self.content.lowercased()
        let activity = self.activity.lowercased()
        let leader = self.leader.lowercased()
        let searchLower = searchText.lowercased()
        
        // 补贴搜索（支持 "TN补"、"tn补"、"xxx补" 格式）
        if enableSubsidySearch {
            // 检查是否是补贴搜索格式
            if searchLower.hasSuffix("补") || searchLower == "tn补" || searchLower == "tn" {
                return hasSubsidy
            }
        }
        
        // 职业快速搜索
        if enableProfessionSearch {
            // 定义职业搜索映射
            let professionMappings: [String: [String]] = [
                "歌奶": ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"],
                "奶歌": ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"],
                "毒奶": ["奶毒", "毒奶"],
                "奶毒": ["奶毒", "毒奶"],
                "秀奶": ["奶秀", "秀奶"],
                "奶秀": ["奶秀", "秀奶"],
                "花奶": ["奶花", "花奶"],
                "奶花": ["奶花", "花奶"],
                "药奶": ["奶药", "药奶"],
                "奶药": ["奶药", "药奶"],
                "策t": ["策t", "天策t", "铁牢"],
                "苍t": ["苍t", "王八t"],
                "和尚t": ["和尚t", "秃t", "大师t"],
                "喵t": ["喵t", "明教t"]
            ]
            
            // 检查是否匹配职业关键词
            if let patterns = professionMappings[searchLower] {
                for pattern in patterns {
                    if content.contains(pattern) ||
                       content.contains("来\(pattern)") ||
                       content.contains("求\(pattern)") ||
                       content.contains("缺\(pattern)") {
                        return true
                    }
                }
                // 没有找到职业匹配，不继续其他搜索
                return false
            }
        }
        
        // 直接匹配搜索词，类似JSX的实现
        return content.contains(searchLower) || 
               leader.contains(searchLower) || 
               activity.contains(searchLower)
    }
    
    /// 提取职业标签（参照JSX的extractTags函数）
    var extractedTags: [ProfessionTag] {
        let content = self.content
        var tags: [ProfessionTag] = []
        
        // 检测金团标签
        if isGoldTeam {
            tags.append(ProfessionTag(label: "金团", color: .orange))
        }
        
        // 检测教学团标签  
        if isTeachingTeam {
            tags.append(ProfessionTag(label: "教学团", color: .blue))
        }
        
        // 检测开荒团标签
        if isPioneerTeam {
            tags.append(ProfessionTag(label: "开荒团", color: .green))
        }
        
        // 职业标签配置（参照JSX的professionTags）
        let professionPatterns: [(label: String, color: Color, patterns: [String])] = [
            ("奶歌", .cyan, ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"]),
            ("奶毒", .purple, ["奶毒", "毒奶"]),
            ("奶秀", .red, ["奶秀", "秀奶"]),
            ("奶花", .green, ["奶花", "花奶"]),
            ("奶药", .yellow, ["奶药", "药奶"]),
            ("策T", .orange, ["策t", "天策t", "铁牢"]),
            ("苍T", .gray, ["苍t", "王八t"]),
            ("和尚T", .brown, ["和尚t", "秃t", "大师t"]),
            ("喵T", .pink, ["喵t", "明教t"])
        ]
        
        // 检测职业标签
        for profession in professionPatterns {
            // 检查是否匹配任一模式
            let hasMatch = profession.patterns.contains { pattern in
                // 使用正则表达式确保精确匹配，避免误匹配
                let regex = "(^|[^\\u4e00-\\u9fa5])\(pattern)($|[^\\u4e00-\\u9fa5])"
                return content.range(of: regex, options: .regularExpression) != nil ||
                       content.contains("来\(pattern)") ||
                       content.contains("求\(pattern)") ||
                       content.contains("缺\(pattern)")
            }
            
            if hasMatch {
                tags.append(ProfessionTag(label: profession.label, color: profession.color))
            }
        }
        
        // 去重
        return Array(Set(tags))
    }
}

// MARK: - 职业标签模型
struct ProfessionTag: Hashable, Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}
