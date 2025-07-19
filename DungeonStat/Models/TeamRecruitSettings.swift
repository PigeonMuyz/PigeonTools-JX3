//
//  TeamRecruitSettings.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/19.
//

import Foundation
import SwiftUI
import Combine
// MARK: - 团队招募设置
class TeamRecruitSettings: ObservableObject {
    static let shared = TeamRecruitSettings()
    
    @Published var showGoldTeamsInSearch: Bool {
        didSet {
            UserDefaults.standard.set(showGoldTeamsInSearch, forKey: "teamRecruit_showGoldTeamsInSearch")
        }
    }
    
    @Published var filterGoldTeams: Bool {
        didSet {
            UserDefaults.standard.set(filterGoldTeams, forKey: "teamRecruit_filterGoldTeams")
        }
    }
    
    @Published var enableSubsidySearch: Bool {
        didSet {
            UserDefaults.standard.set(enableSubsidySearch, forKey: "teamRecruit_enableSubsidySearch")
        }
    }
    
    @Published var enableProfessionSearch: Bool {
        didSet {
            UserDefaults.standard.set(enableProfessionSearch, forKey: "teamRecruit_enableProfessionSearch")
        }
    }
    
    private init() {
        self.showGoldTeamsInSearch = UserDefaults.standard.object(forKey: "teamRecruit_showGoldTeamsInSearch") as? Bool ?? false
        self.filterGoldTeams = UserDefaults.standard.object(forKey: "teamRecruit_filterGoldTeams") as? Bool ?? true
        self.enableSubsidySearch = UserDefaults.standard.object(forKey: "teamRecruit_enableSubsidySearch") as? Bool ?? true
        self.enableProfessionSearch = UserDefaults.standard.object(forKey: "teamRecruit_enableProfessionSearch") as? Bool ?? true
    }
}

