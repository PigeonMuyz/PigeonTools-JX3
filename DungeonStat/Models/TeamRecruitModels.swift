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
        
        // 强金团标识 - 明确的金团关键字
        let strongGoldKeywords = [
            "金团", "包团", "躺老板", "需求老板", "来老板", "躺拍",
            "包牌子武器", "包大小铁", "包铁", "包牌子", "包武器",
            "来装备需求", "上车", "免躺", "跟躺", "可躺", "代开"
        ]
        
        // 检查强金团标识
        for keyword in strongGoldKeywords {
            if content.contains(keyword) {
                return true
            }
        }
        
        // 抵消相关的金团标识（需要结合数字）
        let offsetPatterns = ["\\d+z抵消", "\\d+抵消", "0抵消", "抵消送", "抵消包"]
        for pattern in offsetPatterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        // 检查数字+z或数字+w模式 (如"2z", "55w", "59.5w"等) - 价格标识
        let pricePatterns = ["\\d+z", "\\d+w", "\\d+\\.\\d+w"]
        var hasPrice = false
        for pattern in pricePatterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                hasPrice = true
                break
            }
        }
        
        // 如果有价格标识，并且有其他金团相关词汇
        if hasPrice {
            let contextKeywords = ["老板", "抵消", "速刷", "效率", "送牌", "送武器", "来需求"]
            for keyword in contextKeywords {
                if content.contains(keyword) {
                    return true
                }
            }
        }
        
        return false
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
        
        // 补贴搜索（支持 "补"、"TN补"、"tn补"、"xxx补" 格式）
        if enableSubsidySearch {
            // 检查是否是补贴搜索格式
            if searchLower == "补" || searchLower.hasSuffix("补") || searchLower == "tn" {
                // 更精确的补贴匹配
                let subsidyPatterns = ["补\\d", "tn补", "tk补", "n补", "t补", "k补", "d补", "控补", "奶补", "车补"]
                for pattern in subsidyPatterns {
                    if content.range(of: pattern, options: .regularExpression) != nil {
                        return true
                    }
                }
                return false
            }
        }
        
        // 职业快速搜索
        if enableProfessionSearch {
            // 先进行游戏缩写匹配
            let abbreviationMappings: [String: [String]] = [
                "t": ["来t", "缺t", "求t", "要t", "tn", "tk", "td", "喵t", "策t", "苍t", "和尚t", "喵策", "铁牢"],
                "n": ["来n", "缺n", "求n", "要n", "tn", "nk", "nd", "dn", "奶"],
                "d": ["来d", "缺d", "求d", "要d", "td", "nd", "dk", "dn", "dps", "输出"],
                "奶": ["奶", "来奶", "缺奶", "求奶", "要奶", "治疗", "tn", "dn", "n补"]
            ]
            
            // 检查缩写匹配
            if let patterns = abbreviationMappings[searchLower] {
                for pattern in patterns {
                    // 使用单词边界匹配，避免误匹配
                    let regex = "\\b\(pattern)\\b"
                    if content.range(of: regex, options: [.regularExpression, .caseInsensitive]) != nil {
                        return true
                    }
                }
            }
            
            // 精确职业搜索映射
            let professionMappings: [String: [String]] = [
                "奶歌": ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"],
                "歌奶": ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"],
                "奶毒": ["奶毒", "毒奶"],
                "毒奶": ["奶毒", "毒奶"],
                "奶秀": ["奶秀", "秀奶"],
                "秀奶": ["奶秀", "秀奶"],
                "奶花": ["奶花", "花奶"],
                "花奶": ["奶花", "花奶"],
                "奶药": ["奶药", "药奶", "药宗"],
                "药奶": ["奶药", "药奶", "药宗"],
                "策t": ["策t", "天策t", "铁牢", "策"],
                "苍t": ["苍t", "苍云t", "王八t"],
                "和尚t": ["和尚t", "秃t", "大师t", "少林t"],
                "喵t": ["喵t", "明教t", "喵喵t", "喵策"]
            ]
            
            // 检查精确职业匹配
            if let patterns = professionMappings[searchLower] {
                for pattern in patterns {
                    if content.contains(pattern) ||
                       content.contains("来\(pattern)") ||
                       content.contains("求\(pattern)") ||
                       content.contains("缺\(pattern)") ||
                       content.contains("要\(pattern)") {
                        return true
                    }
                }
            }
        }
        
        // 直接匹配搜索词
        return content.contains(searchLower) || 
               leader.contains(searchLower) || 
               activity.contains(searchLower)
    }
    
    /// 提取职业标签（参照JSX的extractTags函数）
    var extractedTags: [ProfessionTag] {
        let content = self.content.lowercased()
        var tags: [ProfessionTag] = []
        var addedTags = Set<String>() // 用于去重
        
        // 检测金团标签
        if isGoldTeam && !addedTags.contains("金团") {
            tags.append(ProfessionTag(label: "金团", color: .orange))
            addedTags.insert("金团")
        }
        
        // 检测教学团标签  
        if isTeachingTeam && !addedTags.contains("教学团") {
            tags.append(ProfessionTag(label: "教学团", color: .blue))
            addedTags.insert("教学团")
        }
        
        // 检测开荒团标签
        if isPioneerTeam && !addedTags.contains("开荒团") {
            tags.append(ProfessionTag(label: "开荒团", color: .green))
            addedTags.insert("开荒团")
        }
        
        // 检测浪客行标签
        if activity.contains("浪客行") && !addedTags.contains("浪客行") {
            tags.append(ProfessionTag(label: "浪客行", color: .purple))
            addedTags.insert("浪客行")
        }
        
        // 检测缩写职业需求（如 TND、TNK 等）
        let abbreviationPatterns: [(label: String, color: Color, patterns: [String])] = [
            ("需T", .orange, ["来t", "缺t", "求t", "要t", "tn", "tk", "td", "t补"]),
            ("需奶", .green, ["来奶", "缺奶", "求奶", "要奶", "来n", "缺n", "tn", "dn", "n补", "奶补", "治疗"]),
            ("需输出", .red, ["来d", "缺d", "求d", "dps", "输出", "td", "dn", "d补", "来输出", "缺输出"]),
            ("需控", .blue, ["来控", "缺控", "控补", "k补", "tk", "nk", "dk"])
        ]
        
        for (label, color, patterns) in abbreviationPatterns {
            if !addedTags.contains(label) {
                for pattern in patterns {
                    // 使用单词边界匹配
                    let regex = "\\b\(pattern)\\b"
                    if content.range(of: regex, options: [.regularExpression, .caseInsensitive]) != nil {
                        tags.append(ProfessionTag(label: label, color: color))
                        addedTags.insert(label)
                        break
                    }
                }
            }
        }
        
        // 职业标签配置（精确职业）
        let professionPatterns: [(label: String, color: Color, patterns: [String])] = [
            ("奶歌", .cyan, ["奶歌", "歌奶", "奶咕", "咕奶", "奶鸽", "鸽奶"]),
            ("奶毒", .purple, ["奶毒", "毒奶"]),
            ("奶秀", .red, ["奶秀", "秀奶"]),
            ("奶花", .green, ["奶花", "花奶"]),
            ("奶药", .yellow, ["奶药", "药奶", "药宗"]),
            ("策T", .orange, ["策t", "天策t", "铁牢", "喵策"]),
            ("苍T", .gray, ["苍t", "苍云t", "王八t"]),
            ("和尚T", .brown, ["和尚t", "秃t", "大师t", "少林t"]),
            ("喵T", .pink, ["喵t", "明教t", "喵喵t"])
        ]
        
        // 检测具体职业标签
        for (label, color, patterns) in professionPatterns {
            if !addedTags.contains(label) {
                for pattern in patterns {
                    if content.contains(pattern) ||
                       content.contains("来\(pattern)") ||
                       content.contains("求\(pattern)") ||
                       content.contains("缺\(pattern)") ||
                       content.contains("要\(pattern)") {
                        tags.append(ProfessionTag(label: label, color: color))
                        addedTags.insert(label)
                        break // 找到一个匹配就跳出内层循环
                    }
                }
            }
        }
        
        // 检测补贴标签
        if hasSubsidy && !addedTags.contains("有补贴") {
            tags.append(ProfessionTag(label: "有补贴", color: .green))
            addedTags.insert("有补贴")
        }
        
        return tags
    }
}

// MARK: - 职业标签模型
struct ProfessionTag: Hashable, Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}
