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
    
    @Published var filterPioneerTeams: Bool {
        didSet {
            UserDefaults.standard.set(filterPioneerTeams, forKey: "teamRecruit_filterPioneerTeams")
        }
    }
    
    
    @Published var filterTeachingTeams: Bool {
        didSet {
            UserDefaults.standard.set(filterTeachingTeams, forKey: "teamRecruit_filterTeachingTeams")
        }
    }
    
    @Published var showOnlyTeachingTeams: Bool {
        didSet {
            UserDefaults.standard.set(showOnlyTeachingTeams, forKey: "teamRecruit_showOnlyTeachingTeams")
        }
    }
    
    @Published var showOnlyPioneerTeams: Bool {
        didSet {
            UserDefaults.standard.set(showOnlyPioneerTeams, forKey: "teamRecruit_showOnlyPioneerTeams")
        }
    }
    
    @Published var selectedTags: [String] {
        didSet {
            UserDefaults.standard.set(selectedTags, forKey: "teamRecruit_selectedTags")
        }
    }
    
    private init() {
        self.showGoldTeamsInSearch = UserDefaults.standard.object(forKey: "teamRecruit_showGoldTeamsInSearch") as? Bool ?? false
        self.filterGoldTeams = UserDefaults.standard.object(forKey: "teamRecruit_filterGoldTeams") as? Bool ?? true
        self.filterPioneerTeams = UserDefaults.standard.object(forKey: "teamRecruit_filterPioneerTeams") as? Bool ?? true
        self.filterTeachingTeams = UserDefaults.standard.object(forKey: "teamRecruit_filterTeachingTeams") as? Bool ?? false
        self.showOnlyTeachingTeams = UserDefaults.standard.object(forKey: "teamRecruit_showOnlyTeachingTeams") as? Bool ?? false
        self.showOnlyPioneerTeams = UserDefaults.standard.object(forKey: "teamRecruit_showOnlyPioneerTeams") as? Bool ?? false
        self.selectedTags = UserDefaults.standard.object(forKey: "teamRecruit_selectedTags") as? [String] ?? []
    }
}

