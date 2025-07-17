//
//  CharacterCardView.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/8.
//

import SwiftUI
import UIKit

struct CharacterCardView: View {
    let server: String
    let name: String
    
    @StateObject private var cacheService = CharacterCardCacheService.shared
    @State private var cardCache: CharacterCardCache?
    @State private var cardImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingHistoricalCards = false
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("正在加载名片...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let cardImage = cardImage {
                        VStack(spacing: 12) {
                            Image(uiImage: cardImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                                .contextMenu {
                                    Button(action: {
                                        shareImage()
                                    }) {
                                        Label("分享", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(action: {
                                        saveImageToPhotos()
                                    }) {
                                        Label("保存到相册", systemImage: "square.and.arrow.down")
                                    }
                                    
                                    Button(action: {
                                        copyImage()
                                    }) {
                                        Label("复制", systemImage: "doc.on.doc")
                                    }
                                }
                            
                            if let cache = cardCache {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(cache.roleName)")
                                        .font(.headline)
                                    Text("\(cache.zoneName) - \(cache.serverName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("缓存时间: \(formatDate(cache.lastUpdated))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("暂无名片数据")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    
                    Button(action: {
                        showingHistoricalCards = true
                    }) {
                        HStack {
                            Image(systemName: "clock")
                            Text("查看历史名片")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .navigationTitle("角色名片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        Task {
                            await refreshCard()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingHistoricalCards) {
                HistoricalCardsView(server: server, name: name)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let cardImage = cardImage {
                    ShareSheet(items: [cardImage])
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
        .task {
            await loadCard()
        }
    }
    
    private func loadCard() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cache = try await cacheService.fetchAndCacheCard(server: server, name: name)
            let image = cacheService.getCachedImage(for: cache)
            
            await MainActor.run {
                self.cardCache = cache
                self.cardImage = image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func refreshCard() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cache = try await cacheService.fetchAndCacheCard(server: server, name: name, forceRefresh: true)
            let image = cacheService.getCachedImage(for: cache)
            
            await MainActor.run {
                self.cardCache = cache
                self.cardImage = image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func shareImage() {
        guard let cardImage = cardImage else { return }
        showingShareSheet = true
    }
    
    private func saveImageToPhotos() {
        guard let cardImage = cardImage else { return }
        
        ImageCacheService.shared.saveImageToPhotos(cardImage) { success, error in
            DispatchQueue.main.async {
                if success {
                    alertMessage = "图片已保存到相册"
                } else {
                    alertMessage = "保存失败: \(error?.localizedDescription ?? "未知错误")"
                }
                showingAlert = true
            }
        }
    }
    
    private func copyImage() {
        guard let cardImage = cardImage else { return }
        
        UIPasteboard.general.image = cardImage
        alertMessage = "图片已复制到剪贴板"
        showingAlert = true
    }
}

struct HistoricalCardsView: View {
    let server: String
    let name: String
    
    @StateObject private var cacheService = CharacterCardCacheService.shared
    @Environment(\.dismiss) private var dismiss
    
    private var historicalCards: [CharacterCardCache] {
        cacheService.getHistoricalCards(server: server, name: name)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(historicalCards) { card in
                    HistoricalCardRow(card: card)
                }
                .onDelete(perform: deleteCards)
            }
            .navigationTitle("历史名片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        for index in offsets {
            let card = historicalCards[index]
            cacheService.deleteCachedCard(card)
        }
    }
}

struct HistoricalCardRow: View {
    let card: CharacterCardCache
    @StateObject private var cacheService = CharacterCardCacheService.shared
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        HStack {
            if let image = cacheService.getCachedImage(for: card) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .contextMenu {
                        Button(action: {
                            shareImage(image)
                        }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            saveImageToPhotos(image)
                        }) {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: {
                            copyImage(image)
                        }) {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.roleName)
                    .font(.headline)
                Text("\(card.zoneName) - \(card.serverName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("更新时间: \(formatDate(card.lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingShareSheet) {
            if let image = cacheService.getCachedImage(for: card) {
                ShareSheet(items: [image])
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func shareImage(_ image: UIImage) {
        showingShareSheet = true
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        ImageCacheService.shared.saveImageToPhotos(image) { success, error in
            DispatchQueue.main.async {
                if success {
                    alertMessage = "图片已保存到相册"
                } else {
                    alertMessage = "保存失败: \(error?.localizedDescription ?? "未知错误")"
                }
                showingAlert = true
            }
        }
    }
    
    private func copyImage(_ image: UIImage) {
        UIPasteboard.general.image = image
        alertMessage = "图片已复制到剪贴板"
        showingAlert = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
