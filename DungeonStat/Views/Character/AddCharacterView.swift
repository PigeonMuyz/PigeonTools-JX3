//
//  AddCharacterView.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/6/30.
//

import SwiftUI


// MARK: - 添加角色视图
struct AddCharacterView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dungeonManager: DungeonManager
    @State private var server = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // 用于显示获取到的角色信息
    @State private var fetchedRoleData: DetailedRoleData?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("角色信息")) {
                    TextField("服务器", text: $server)
                        .disabled(isLoading)
                    TextField("角色名", text: $name)
                        .disabled(isLoading)
                }
                
                // 如果获取到了角色信息，显示确认信息
                if let roleData = fetchedRoleData {
                    Section(header: Text("角色详情")) {
                        HStack {
                            Text("服务器:")
                            Spacer()
                            Text(roleData.serverName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("角色名:")
                            Spacer()
                            Text(roleData.roleName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("门派:")
                            Spacer()
                            Text(roleData.forceName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("心法:")
                            Spacer()
                            Text(roleData.kungfuName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("体型:")
                            Spacer()
                            Text(roleData.bodyName)
                                .foregroundColor(.secondary)
                        }
                        
                        // 显示装分
                        HStack {
                            Text("装分:")
                            Spacer()
                            Text("\(roleData.panelList.score)")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        
                        // 显示客户端类型
                        if let gameClient = roleData.gameClient {
                            HStack {
                                Text("客户端:")
                                Spacer()
                                Text(gameClient)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let gameMode = roleData.gameMode {
                            HStack {
                                Text("装备分类:")
                                Spacer()
                                Text(gameMode)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let kungfuType = roleData.kungfuType {
                            HStack {
                                Text("装备类型:")
                                Spacer()
                                Text(kungfuType)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let tongName = roleData.tongName, !tongName.isEmpty {
                            HStack {
                                Text("帮会:")
                                Spacer()
                                Text(tongName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在获取角色信息...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("添加角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if fetchedRoleData != nil {
                        Button("确认添加") {
                            addCharacterWithFetchedData()
                        }
                        .disabled(isLoading)
                    } else {
                        Button("获取信息") {
                            Task {
                                await fetchRoleInfo()
                            }
                        }
                        .disabled(server.isEmpty || name.isEmpty || isLoading)
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 获取角色信息
    @MainActor
    private func fetchRoleInfo() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let roleData = try await JX3APIService.shared.fetchRoleDetails(
                server: server.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            fetchedRoleData = roleData
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            fetchedRoleData = nil
        }
        
        isLoading = false
    }
    
    // MARK: - 添加角色
    private func addCharacterWithFetchedData() {
        guard let roleData = fetchedRoleData else { return }
        
        dungeonManager.addCharacter(
            server: roleData.serverName,
            name: roleData.roleName,
            school: roleData.forceName,
            bodyType: roleData.bodyName
        )
        
        isPresented = false
    }
}
