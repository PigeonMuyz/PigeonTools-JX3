//
//  ImageCacheService.swift
//  DungeonStat
//
//  Created by PigeonMuyz on 2025/7/8.
//

import Foundation
import UIKit
import Photos

class ImageCacheService {
    static let shared = ImageCacheService()
    private init() {
        migrateCacheIfNeeded()
    }
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL = {
        // 使用Documents目录，更稳定的持久化存储
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("CharacterCards")
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
    
    func downloadAndConvertToBase64(from urlString: String) async throws -> String {
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
        
        return convertImageToBase64(image)
    }
    
    func convertImageToBase64(_ image: UIImage) -> String {
        guard let imageData = image.pngData() else {
            return ""
        }
        return imageData.base64EncodedString()
    }
    
    func convertBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
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
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            performSave(image: image, completion: completion)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.performSave(image: image, completion: completion)
                    } else {
                        completion(false, NSError(domain: "PhotoLibrary", code: 1, userInfo: [NSLocalizedDescriptionKey: "需要相册权限才能保存图片"]))
                    }
                }
            }
        case .denied, .restricted:
            completion(false, NSError(domain: "PhotoLibrary", code: 2, userInfo: [NSLocalizedDescriptionKey: "请在设置中允许访问相册"]))
        case .limited:
            performSave(image: image, completion: completion)
        @unknown default:
            completion(false, NSError(domain: "PhotoLibrary", code: 3, userInfo: [NSLocalizedDescriptionKey: "未知权限状态"]))
        }
    }
    
    private func performSave(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    private func migrateCacheIfNeeded() {
        let oldCacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CharacterCards")
        
        guard fileManager.fileExists(atPath: oldCacheDir.path) else {
            return
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: oldCacheDir, includingPropertiesForKeys: nil)
            
            for file in files {
                let destinationURL = cacheDirectory.appendingPathComponent(file.lastPathComponent)
                
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.moveItem(at: file, to: destinationURL)
                }
            }
            
            try fileManager.removeItem(at: oldCacheDir)
            print("Successfully migrated image cache to Documents directory")
        } catch {
            print("Failed to migrate image cache: \(error)")
        }
    }
}
