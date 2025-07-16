//
//  CoreMLImageProcessor.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/14.
//

import Foundation
import CoreML
import Vision
import UIKit
import Combine
import VideoToolbox

enum ImageProcessingType: String, CaseIterable {
    case animeToSketch = "AnimeToSketch"
    
    var displayName: String {
        switch self {
        case .animeToSketch:
            return "转换为素描"
        }
    }
    
    var description: String {
        switch self {
        case .animeToSketch:
            return "将动漫风格图像转换为线条素描"
        }
    }
}

struct SketchProcessingParams {
    var contrast: Float = 1.0           // 对比度 (0.5 - 2.0)
    var brightness: Float = 0.0         // 亮度 (-0.5 - 0.5)
    var lineIntensity: Float = 1.0      // 线条强度 (0.5 - 2.0)
    var backgroundWhiteness: Float = 0.9 // 背景白化程度 (0.0 - 1.0)
    var enablePreprocessing: Bool = true // 启用智能预处理
    
    static let `default` = SketchProcessingParams()
    
    // 预设配置（已针对智能预处理优化）
    static let presets: [SketchPreset] = [
        SketchPreset(
            name: "智能默认",
            description: "自适应处理，适用于大部分照片",
            params: SketchProcessingParams(contrast: 1.0, brightness: 0.0, lineIntensity: 1.0, backgroundWhiteness: 0.85)
        ),
        SketchPreset(
            name: "人像专用",
            description: "专为人物照片设计，强化面部轮廓",
            params: SketchProcessingParams(contrast: 1.1, brightness: 0.05, lineIntensity: 1.1, backgroundWhiteness: 0.7)
        ),
        SketchPreset(
            name: "细节增强",
            description: "最大化保留细节，减少空白区域",
            params: SketchProcessingParams(contrast: 1.2, brightness: 0.0, lineIntensity: 1.3, backgroundWhiteness: 0.6)
        ),
        SketchPreset(
            name: "艺术风格",
            description: "生成更具艺术感的素描效果",
            params: SketchProcessingParams(contrast: 0.9, brightness: -0.05, lineIntensity: 0.9, backgroundWhiteness: 0.9)
        ),
        SketchPreset(
            name: "高清锐化",
            description: "强化线条清晰度和边缘定义",
            params: SketchProcessingParams(contrast: 1.3, brightness: -0.1, lineIntensity: 1.5, backgroundWhiteness: 0.75)
        ),
        SketchPreset(
            name: "柔和自然",
            description: "自然柔和的素描风格",
            params: SketchProcessingParams(contrast: 0.8, brightness: 0.1, lineIntensity: 0.8, backgroundWhiteness: 0.95)
        )
    ]
}

struct SketchPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let params: SketchProcessingParams
}

enum ImageProcessingError: Error, LocalizedError {
    case modelNotFound(String)
    case invalidInput
    case processingFailed
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelName):
            return "找不到模型文件: \(modelName)"
        case .invalidInput:
            return "输入图像格式无效"
        case .processingFailed:
            return "图像处理失败"
        case .memoryError:
            return "内存不足，请尝试处理较小的图像"
        }
    }
}

@MainActor
class CoreMLImageProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var lastError: ImageProcessingError?
    @Published var isModelLoaded = false
    
    private var models: [ImageProcessingType: MLModel] = [:]
    private var loadingTask: Task<Void, Never>?
    
    init() {
        // 异步加载模型以避免阻塞UI
        loadingTask = Task {
            await loadModelsAsync()
            await MainActor.run {
                self.isModelLoaded = true
            }
        }
    }
    
    deinit {
        loadingTask?.cancel()
    }
    
    private func loadModelsAsync() async {
        await withTaskGroup(of: Void.self) { group in
            for type in ImageProcessingType.allCases {
                group.addTask {
                    await self.loadSingleModel(type: type)
                }
            }
        }
        
        print("Total models loaded: \(models.count)")
        print("Available models: \(models.keys.map { $0.rawValue })")
    }
    
    private func loadSingleModel(type: ImageProcessingType) async {
        do {
            // 首先尝试从Bundle中加载编译后的模型
            if let compiledModel = Bundle.main.url(forResource: type.rawValue, withExtension: "mlmodelc") {
                print("Found compiled model at: \(compiledModel)")
                
                // 配置模型使用所有可用的计算资源
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .all  // 使用CPU + 神经引擎 + GPU
                configuration.allowLowPrecisionAccumulationOnGPU = true  // 允许GPU低精度加速
                
                let model = try MLModel(contentsOf: compiledModel, configuration: configuration)
                await MainActor.run {
                    self.models[type] = model
                }
                print("Successfully loaded compiled model with full compute units: \(type.rawValue)")
                return
            }
            
            print("No compiled model found for: \(type.rawValue)")
            
            // 尝试在不同位置查找原始模型文件
            var modelURL: URL?
            
            // 首先在根目录查找
            modelURL = Bundle.main.url(forResource: type.rawValue, withExtension: "mlmodel")
            
            // 如果没找到，在子目录中查找
            if modelURL == nil {
                modelURL = Bundle.main.url(forResource: type.rawValue, withExtension: "mlmodel", subdirectory: "CoreML/superresolution")
            }
            
            guard let url = modelURL else {
                print("Model file not found anywhere: \(type.rawValue)")
                return
            }
            
            print("Found original model at: \(url)")
            let compiledURL = try await MLModel.compileModel(at: url)
            
            // 配置模型使用所有可用的计算资源
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all  // 使用CPU + 神经引擎 + GPU
            configuration.allowLowPrecisionAccumulationOnGPU = true  // 允许GPU低精度加速
            
            let model = try MLModel(contentsOf: compiledURL, configuration: configuration)
            await MainActor.run {
                self.models[type] = model
            }
            print("Successfully compiled and loaded model with full compute units: \(type.rawValue)")
        } catch {
            print("Failed to load model \(type.rawValue): \(error)")
        }
    }
    
    func processImage(_ image: UIImage, type: ImageProcessingType, params: SketchProcessingParams = .default) async throws -> UIImage {
        guard let model = models[type] else {
            throw ImageProcessingError.modelNotFound(type.rawValue)
        }
        
        isProcessing = true
        progress = 0.0
        lastError = nil
        
        defer {
            isProcessing = false
            progress = 0.0
        }
        
        do {
            progress = 0.05
            
            // 可选的智能预处理
            let enhancedImage: UIImage
            if params.enablePreprocessing {
                print("📸 启用智能预处理 - 优化图像质量中...")
                enhancedImage = enhanceImageForModelProcessing(image, params: params)
                print("✅ 预处理完成 - 图像已优化")
            } else {
                print("⚡ 跳过预处理 - 直接使用原始图像")
                enhancedImage = image
            }
            
            progress = 0.15
            
            // 根据模型类型预处理图像尺寸
            let preprocessedImage = preprocessImageForModel(enhancedImage, type: type)
            
            progress = 0.25
            
            // 准备输入图像
            guard let pixelBuffer = preprocessedImage.toPixelBuffer() else {
                throw ImageProcessingError.invalidInput
            }
            
            progress = 0.4
            
            // 处理图像
            let modelResult: UIImage
            switch type {
            case .animeToSketch:
                modelResult = try await processAnimeToSketch(model: model, pixelBuffer: pixelBuffer)
            }
            
            progress = 0.8
            
            // 应用后处理参数
            let finalResult = applySketchPostProcessing(modelResult, params: params)
            
            progress = 1.0
            return finalResult
            
        } catch {
            if let processingError = error as? ImageProcessingError {
                lastError = processingError
                throw processingError
            } else {
                print("Image processing failed: \(error.localizedDescription)")
                lastError = .processingFailed
                throw ImageProcessingError.processingFailed
            }
        }
    }
    
    /// 预处理图像以优化模型输入质量
    private func enhanceImageForModelProcessing(_ image: UIImage, params: SketchProcessingParams) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        var processedImage = ciImage
        
        // 分析原始图像特征
        let originalBrightness = calculateImageBrightness(ciImage)
        print("🔍 图像分析 - 亮度: \(String(format: "%.2f", originalBrightness))")
        
        // 1. 直方图均衡化 - 增强对比度和细节
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(processedImage, forKey: kCIInputImageKey)
            // 根据图像亮度自动调整曝光
            let exposureAdjustment = originalBrightness < 0.3 ? 0.5 : (originalBrightness > 0.7 ? -0.3 : 0.0)
            exposureFilter.setValue(exposureAdjustment, forKey: kCIInputEVKey)
            if let result = exposureFilter.outputImage {
                processedImage = result
                print("⚡ 曝光调整: \(String(format: "%.2f", exposureAdjustment))")
            }
        }
        
        // 2. 局部对比度增强 - 增强边缘和细节
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            // 根据图像特征自动调整对比度
            let autoContrast = calculateOptimalContrast(ciImage)
            contrastFilter.setValue(autoContrast, forKey: kCIInputContrastKey)
            if let result = contrastFilter.outputImage {
                processedImage = result
            }
        }
        
        // 3. 锐化处理 - 增强边缘检测效果
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.8, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage {
                processedImage = result
            }
        }
        
        // 4. 去噪处理 - 减少噪点干扰
        if let noiseReductionFilter = CIFilter(name: "CINoiseReduction") {
            noiseReductionFilter.setValue(processedImage, forKey: kCIInputImageKey)
            noiseReductionFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseReductionFilter.setValue(0.40, forKey: "inputSharpness")
            if let result = noiseReductionFilter.outputImage {
                processedImage = result
            }
        }
        
        // 5. 伽马校正 - 优化中间调
        if let gammaFilter = CIFilter(name: "CIGammaAdjust") {
            gammaFilter.setValue(processedImage, forKey: kCIInputImageKey)
            // 根据图像特征调整伽马值
            let gamma = calculateOptimalGamma(ciImage)
            gammaFilter.setValue(gamma, forKey: "inputPower")
            if let result = gammaFilter.outputImage {
                processedImage = result
            }
        }
        
        // 6. 阴影高光调整 - 保留细节
        if let shadowHighlightFilter = CIFilter(name: "CIShadowHighlight") {
            shadowHighlightFilter.setValue(processedImage, forKey: kCIInputImageKey)
            shadowHighlightFilter.setValue(0.3, forKey: "inputShadowAmount")  // 提亮阴影
            shadowHighlightFilter.setValue(-0.2, forKey: "inputHighlightAmount")  // 降低高光
            if let result = shadowHighlightFilter.outputImage {
                processedImage = result
            }
        }
        
        // 转换回UIImage
        guard let finalCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: finalCGImage)
    }
    
    /// 计算图像亮度
    private func calculateImageBrightness(_ image: CIImage) -> Float {
        let extent = image.extent
        let inputKeys = [kCIInputImageKey: image, kCIInputExtentKey: CIVector(cgRect: extent)]
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: inputKeys),
              let outputImage = filter.outputImage else {
            return 0.5 // 默认中等亮度
        }
        
        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        // 计算感知亮度
        let r = Float(bitmap[0]) / 255.0
        let g = Float(bitmap[1]) / 255.0
        let b = Float(bitmap[2]) / 255.0
        
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
    
    /// 计算最优对比度
    private func calculateOptimalContrast(_ image: CIImage) -> Float {
        let brightness = calculateImageBrightness(image)
        
        // 根据亮度自适应调整对比度
        if brightness < 0.3 {
            return 1.4  // 暗图增强对比度
        } else if brightness > 0.7 {
            return 1.1  // 亮图轻微增强
        } else {
            return 1.2  // 中等亮度适中增强
        }
    }
    
    /// 计算最优伽马值
    private func calculateOptimalGamma(_ image: CIImage) -> Float {
        let brightness = calculateImageBrightness(image)
        
        // 根据亮度调整伽马值
        if brightness < 0.3 {
            return 0.8  // 暗图降低伽马，提亮中间调
        } else if brightness > 0.7 {
            return 1.2  // 亮图提高伽马，压暗中间调
        } else {
            return 1.0  // 中等亮度保持原样
        }
    }
    
    private func applySketchPostProcessing(_ image: UIImage, params: SketchProcessingParams) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        var outputImage = ciImage
        
        // 1. 调整对比度
        if params.contrast != 1.0 {
            let contrastFilter = CIFilter(name: "CIColorControls")!
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(params.contrast, forKey: kCIInputContrastKey)
            if let result = contrastFilter.outputImage {
                outputImage = result
            }
        }
        
        // 2. 调整亮度
        if params.brightness != 0.0 {
            let brightnessFilter = CIFilter(name: "CIColorControls")!
            brightnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(params.brightness, forKey: kCIInputBrightnessKey)
            if let result = brightnessFilter.outputImage {
                outputImage = result
            }
        }
        
        // 3. 增强线条（使用锐化）
        if params.lineIntensity != 1.0 {
            let sharpenFilter = CIFilter(name: "CISharpenLuminance")!
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(params.lineIntensity, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage {
                outputImage = result
            }
        }
        
        // 4. 背景白化处理
        if params.backgroundWhiteness > 0.0 {
            let exposureFilter = CIFilter(name: "CIExposureAdjust")!
            exposureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(params.backgroundWhiteness, forKey: kCIInputEVKey)
            if let result = exposureFilter.outputImage {
                outputImage = result
            }
        }
        
        // 转换回UIImage
        guard let finalCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: finalCGImage)
    }
    
    private func preprocessImageForModel(_ image: UIImage, type: ImageProcessingType) -> UIImage {
        switch type {
        case .animeToSketch:
            // AnimeToSketch 需要 512x512，使用智能填充避免空白区域
            let targetSize = CGSize(width: 512, height: 512)
            print("AnimeToSketch - Original size: \(image.size), Target size: \(targetSize)")
            return image.resizedWithPadding(to: targetSize)
        }
    }
    
    private func processAnimeToSketch(model: MLModel, pixelBuffer: CVPixelBuffer) async throws -> UIImage {
        progress = 0.5
        
        // 打印模型信息以便调试
        print("AnimeToSketch model inputs: \(model.modelDescription.inputDescriptionsByName.keys)")
        print("AnimeToSketch model outputs: \(model.modelDescription.outputDescriptionsByName.keys)")
        
        // 尝试不同的输入参数名
        var input: MLDictionaryFeatureProvider
        
        // 首先尝试 "input_1"（从错误信息看这是必需的）
        if let _ = model.modelDescription.inputDescriptionsByName["input_1"] {
            input = try MLDictionaryFeatureProvider(dictionary: ["input_1": MLFeatureValue(pixelBuffer: pixelBuffer)])
        } else if let _ = model.modelDescription.inputDescriptionsByName["input"] {
            input = try MLDictionaryFeatureProvider(dictionary: ["input": MLFeatureValue(pixelBuffer: pixelBuffer)])
        } else {
            // 如果都没有，使用第一个输入
            let firstInputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "input"
            input = try MLDictionaryFeatureProvider(dictionary: [firstInputName: MLFeatureValue(pixelBuffer: pixelBuffer)])
            print("Using input name: \(firstInputName)")
        }
        
        progress = 0.7
        
        let output = try await model.prediction(from: input)
        
        progress = 0.9
        
        // 尝试不同的输出参数名
        var outputBuffer: CVPixelBuffer?
        
        if let buffer = output.featureValue(for: "output")?.imageBufferValue {
            outputBuffer = buffer
        } else if let buffer = output.featureValue(for: "output_1")?.imageBufferValue {
            outputBuffer = buffer
        } else {
            // 使用第一个输出
            let firstOutputName = model.modelDescription.outputDescriptionsByName.keys.first ?? "output"
            outputBuffer = output.featureValue(for: firstOutputName)?.imageBufferValue
            print("Using output name: \(firstOutputName)")
        }
        
        guard let buffer = outputBuffer else {
            throw ImageProcessingError.processingFailed
        }
        
        guard let resultImage = UIImage(pixelBuffer: buffer) else {
            throw ImageProcessingError.processingFailed
        }
        
        return resultImage
    }
    
    
    func isModelAvailable(_ type: ImageProcessingType) -> Bool {
        return models[type] != nil
    }
    
    func availableModels() -> [ImageProcessingType] {
        return ImageProcessingType.allCases.filter { isModelAvailable($0) }
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// 智能填充调整：保持宽高比，使用边缘像素填充空白区域
    func resizedWithPadding(to targetSize: CGSize) -> UIImage {
        let sourceSize = self.size
        let sourceAspectRatio = sourceSize.width / sourceSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        // 计算缩放后的尺寸（保持宽高比，确保图像完全显示）
        let scaledSize: CGSize
        if sourceAspectRatio > targetAspectRatio {
            // 源图像更宽，以宽度为准
            scaledSize = CGSize(width: targetSize.width, height: targetSize.width / sourceAspectRatio)
        } else {
            // 源图像更高，以高度为准
            scaledSize = CGSize(width: targetSize.height * sourceAspectRatio, height: targetSize.height)
        }
        
        // 计算图像在目标画布中的位置（居中）
        let x = (targetSize.width - scaledSize.width) / 2
        let y = (targetSize.height - scaledSize.height) / 2
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 首先用边缘像素颜色填充整个画布
            if let cgImage = self.cgImage {
                // 获取边缘像素颜色作为背景色
                let backgroundColor = self.getEdgeColor()
                cgContext.setFillColor(backgroundColor)
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                
                // 然后绘制缩放后的图像
                self.draw(in: CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height))
            } else {
                // 如果无法获取CGImage，使用灰色背景
                cgContext.setFillColor(UIColor.gray.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                self.draw(in: CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height))
            }
        }
    }
    
    /// 获取图像边缘的平均颜色
    private func getEdgeColor() -> CGColor {
        guard let cgImage = self.cgImage else {
            return UIColor.gray.cgColor
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0 && height > 0 else {
            return UIColor.gray.cgColor
        }
        
        // 创建1x1的上下文来获取平均颜色
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return UIColor.gray.cgColor
        }
        
        // 绘制整个图像到1x1上下文中，得到平均颜色
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        guard let data = context.data else {
            return UIColor.gray.cgColor
        }
        
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        let red = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue = CGFloat(pixelData[2]) / 255.0
        let alpha = CGFloat(pixelData[3]) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
    }
    
    /// 中心裁剪到256×256，保持颜色不变，避免KMEM错误
    func resizedToFit512x512() -> UIImage {
        let targetSize = CGSize(width: 256, height: 256)  // 使用256避免内存问题
        let sourceSize = self.size
        
        // 计算缩放比例（取较大的比例以填满目标尺寸）
        let scale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        
        // 计算缩放后的尺寸
        let scaledSize = CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
        
        // 计算裁剪区域（居中）
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            // 先将图像绘制到放大的尺寸
            let drawRect = CGRect(
                x: -cropRect.minX,
                y: -cropRect.minY,
                width: scaledSize.width,
                height: scaledSize.height
            )
            self.draw(in: drawRect)
        }
    }
    
    /// 调整到指定尺寸，使用中心裁剪
    func resizedToSpecificSize(_ targetSize: CGSize) -> UIImage {
        let sourceSize = self.size
        
        // 计算缩放比例（取较大的比例以填满目标尺寸）
        let scale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        
        // 计算缩放后的尺寸
        let scaledSize = CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
        
        // 计算裁剪区域（居中）
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            // 先将图像绘制到放大的尺寸
            let drawRect = CGRect(
                x: -cropRect.minX,
                y: -cropRect.minY,
                width: scaledSize.width,
                height: scaledSize.height
            )
            self.draw(in: drawRect)
        }
    }
    
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let status = CVPixelBufferCreate(
            nil,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        guard let cgContext = context, let cgImage = self.cgImage else {
            return nil
        }
        
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
    
    convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        guard let cgImg = cgImage else {
            return nil
        }
        
        self.init(cgImage: cgImg)
    }
}
