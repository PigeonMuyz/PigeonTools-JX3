//
//  ImageProcessingView.swift
//  DungeonStat
//
//  Created by Claude on 2025/7/14.
//

import SwiftUI
import Photos

struct ImageProcessingView: View {
    let originalImage: UIImage
    let onDismiss: () -> Void
    
    @StateObject private var processor = CoreMLImageProcessor()
    @State private var processedImage: UIImage?
    @State private var selectedProcessingType: ImageProcessingType?
    @State private var showingResult = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isComparing = false
    @State private var sketchParams = SketchProcessingParams.default
    @State private var showingParamsAdjustment = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 原始图片预览
                VStack(alignment: .leading, spacing: 8) {
                    Text("原始图片")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                }
                
                // 处理选项
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择处理方式")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if !processor.isModelLoaded {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("正在加载AI模型...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding()
                    } else if processor.availableModels().isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text("没有可用的AI模型")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            // 处理选项
                            ForEach(processor.availableModels(), id: \.self) { type in
                                ProcessingOptionCard(
                                    type: type,
                                    isSelected: selectedProcessingType == type,
                                    isProcessing: processor.isProcessing && selectedProcessingType == type
                                ) {
                                    selectedProcessingType = type
                                    if type == .animeToSketch {
                                        showingParamsAdjustment = true
                                    } else {
                                        Task {
                                            await processImage(type: type)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // 处理进度
                if processor.isProcessing {
                    VStack(spacing: 8) {
                        ProgressView(value: processor.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("处理中... \(Int(processor.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 错误信息
                if let error = processor.lastError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("图片后处理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("对比") {
                        if processedImage != nil {
                            isComparing = true
                        }
                    }
                    .disabled(processedImage == nil)
                }
            }
            .sheet(isPresented: $showingResult) {
                if let processedImage = processedImage {
                    ImageResultView(
                        originalImage: originalImage,
                        processedImage: processedImage,
                        processingType: selectedProcessingType
                    )
                }
            }
            .sheet(isPresented: $isComparing) {
                if let processedImage = processedImage {
                    ImageComparisonView(
                        originalImage: originalImage,
                        processedImage: processedImage,
                        processingType: selectedProcessingType
                    )
                }
            }
            .sheet(isPresented: $showingParamsAdjustment) {
                SketchParametersView(
                    params: $sketchParams,
                    originalImage: originalImage
                ) { finalParams in
                    showingParamsAdjustment = false
                    Task {
                        await processImage(type: .animeToSketch, params: finalParams)
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func processImage(type: ImageProcessingType, params: SketchProcessingParams = .default) async {
        do {
            let result = try await processor.processImage(originalImage, type: type, params: params)
            await MainActor.run {
                self.processedImage = result
                self.showingResult = true
            }
        } catch {
            await MainActor.run {
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
}

struct ProcessingOptionCard: View {
    let type: ImageProcessingType
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                }
                
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(isProcessing)
    }
    
    private var iconName: String {
        switch type {
        case .animeToSketch:
            return "scribble.variable"
        }
    }
}

struct ImageResultView: View {
    let originalImage: UIImage
    let processedImage: UIImage
    let processingType: ImageProcessingType?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("处理结果")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if let type = processingType {
                            Text("处理方式: \(type.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                            .padding(.horizontal)
                            .contextMenu {
                                Button(action: {
                                    saveToPhotos()
                                }) {
                                    Label("保存到相册", systemImage: "square.and.arrow.down")
                                }
                                
                                Button(action: {
                                    copyImage()
                                }) {
                                    Label("复制", systemImage: "doc.on.doc")
                                }
                            }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            saveToPhotos()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("保存到相册")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            copyImage()
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("复制")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("处理结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveToPhotos() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil)
                DispatchQueue.main.async {
                    alertMessage = "图片已保存到相册"
                    showingAlert = true
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "需要相册访问权限"
                    showingAlert = true
                }
            }
        }
    }
    
    private func copyImage() {
        UIPasteboard.general.image = processedImage
        alertMessage = "图片已复制到剪贴板"
        showingAlert = true
    }
}

struct ImageComparisonView: View {
    let originalImage: UIImage
    let processedImage: UIImage
    let processingType: ImageProcessingType?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingOriginal = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 切换按钮
                HStack {
                    Button(action: { showingOriginal = true }) {
                        Text("原始图片")
                            .font(.headline)
                            .foregroundColor(showingOriginal ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showingOriginal ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { showingOriginal = false }) {
                        Text("处理后")
                            .font(.headline)
                            .foregroundColor(!showingOriginal ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!showingOriginal ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // 图片显示
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: showingOriginal ? originalImage : processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                
                // 信息栏
                VStack(spacing: 4) {
                    Text(showingOriginal ? "原始图片" : (processingType?.displayName ?? "处理后"))
                        .font(.headline)
                    
                    let image = showingOriginal ? originalImage : processedImage
                    Text("尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .navigationTitle("图片对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SketchParametersView: View {
    @Binding var params: SketchProcessingParams
    let originalImage: UIImage
    let onApply: (SketchProcessingParams) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var processor = CoreMLImageProcessor()
    @State private var previewImage: UIImage?
    @State private var isGeneratingPreview = false
    @State private var selectedPreset: SketchPreset?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 预设选择
                    VStack(alignment: .leading, spacing: 16) {
                        Text("快速预设")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SketchProcessingParams.presets) { preset in
                                    PresetCard(
                                        preset: preset,
                                        isSelected: selectedPreset?.id == preset.id
                                    ) {
                                        selectedPreset = preset
                                        params = preset.params
                                        generatePreview()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 预处理设置
                    VStack(alignment: .leading, spacing: 16) {
                        Text("处理设置")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Toggle("启用智能预处理", isOn: $params.enablePreprocessing)
                            .padding(.horizontal)
                            .onChange(of: params.enablePreprocessing) { _, _ in
                                selectedPreset = nil
                            }
                        
                        Text(params.enablePreprocessing ? 
                            "✅ 自动优化图像质量，提升素描效果" : 
                            "⚡ 快速处理，使用原始图像")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // 参数调整界面
                    VStack(alignment: .leading, spacing: 16) {
                        Text("细节调整")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 20) {
                            ParameterSlider(
                                title: "对比度",
                                value: $params.contrast,
                                range: 0.5...2.0,
                                step: 0.1
                            )
                            .onChange(of: params.contrast) { _, _ in
                                selectedPreset = nil
                            }
                            
                            ParameterSlider(
                                title: "亮度",
                                value: $params.brightness,
                                range: -0.5...0.5,
                                step: 0.1
                            )
                            .onChange(of: params.brightness) { _, _ in
                                selectedPreset = nil
                            }
                            
                            ParameterSlider(
                                title: "线条强度",
                                value: $params.lineIntensity,
                                range: 0.5...2.0,
                                step: 0.1
                            )
                            .onChange(of: params.lineIntensity) { _, _ in
                                selectedPreset = nil
                            }
                            
                            ParameterSlider(
                                title: "背景白化",
                                value: $params.backgroundWhiteness,
                                range: 0.0...1.0,
                                step: 0.1
                            )
                            .onChange(of: params.backgroundWhiteness) { _, _ in
                                selectedPreset = nil
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 预览区域
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("效果预览")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("刷新预览") {
                                generatePreview()
                            }
                            .disabled(isGeneratingPreview)
                        }
                        .padding(.horizontal)
                        
                        ZStack {
                            if let previewImage = previewImage {
                                Image(uiImage: previewImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                            } else {
                                Image(uiImage: originalImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .shadow(radius: 4)
                                    .overlay(
                                        Rectangle()
                                            .fill(Color.black.opacity(0.3))
                                            .cornerRadius(12)
                                    )
                                    .overlay(
                                        Text("点击刷新预览生成效果")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    )
                            }
                            
                            if isGeneratingPreview {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button("取消") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        
                        Button("应用") {
                            onApply(params)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("素描参数调整")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generatePreview()
            }
        }
    }
    
    private func generatePreview() {
        guard !isGeneratingPreview else { return }
        
        isGeneratingPreview = true
        
        Task {
            do {
                let result = try await processor.processImage(originalImage, type: .animeToSketch, params: params)
                await MainActor.run {
                    self.previewImage = result
                    self.isGeneratingPreview = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingPreview = false
                }
            }
        }
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            HStack {
                Text(String(format: "%.1f", range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(value: $value, in: range, step: step)
                
                Text(String(format: "%.1f", range.upperBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PresetCard: View {
    let preset: SketchPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // 参数指示器
                HStack(spacing: 4) {
                    ParameterIndicator(label: "对比", value: preset.params.contrast, max: 2.0)
                    ParameterIndicator(label: "亮度", value: preset.params.brightness + 0.5, max: 1.0)
                    ParameterIndicator(label: "线条", value: preset.params.lineIntensity, max: 2.0)
                    ParameterIndicator(label: "背景", value: preset.params.backgroundWhiteness, max: 1.0)
                }
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ParameterIndicator: View {
    let label: String
    let value: Float
    let max: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(value / max) * 30, height: 4)
                    .cornerRadius(2)
            }
        }
    }
}
