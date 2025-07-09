//
//  ImageCacheService.swift
//  DungeonStat
//
//  Created by 黄天晨 on 2025/7/8.
//

import Foundation
import UIKit

class ImageCacheService {
    static let shared = ImageCacheService()
    private init() {}
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cacheDir = documentsPath.appendingPathComponent("CharacterCards")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    func saveImage(_ image: UIImage, filename: String) -> String? {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let imageData = image.pngData() else {
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func loadImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    func downloadAndSaveImage(from urlString: String, filename: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        guard let image = UIImage(data: data) else {
            throw APIError.apiError("无法解析图片数据")
        }
        
        guard let savedPath = saveImage(image, filename: filename) else {
            throw APIError.apiError("保存图片失败")
        }
        
        return savedPath
    }
    
    func getCachedImagePath(filename: String) -> String? {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        return nil
    }
    
    func deleteImage(filename: String) {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func cleanupOldCaches(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                if let creationDate = try file.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup old caches: \(error)")
        }
    }
}