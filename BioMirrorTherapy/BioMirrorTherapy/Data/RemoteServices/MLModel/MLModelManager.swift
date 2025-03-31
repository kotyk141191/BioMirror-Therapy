//
//  MLModelManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine
import CoreML

class MLModelManager {
    // MARK: - Singleton
    
    static let shared = MLModelManager()
    
    // MARK: - Properties
    
    private let apiClient = APIClient.shared
    private let fileManager = FileManager.default
    
    private var modelVersionCache: [String: String] = [:]
    private var loadedModels: [String: MLModel] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // Constants
    private let modelsDirectory: URL
    private let modelConfigFileName = "model_config.json"
    
    // Notification names
    static let modelUpdateStartedNotification = Notification.Name("ModelUpdateStartedNotification")
    static let modelUpdateCompletedNotification = Notification.Name("ModelUpdateCompletedNotification")
    static let modelUpdateFailedNotification = Notification.Name("ModelUpdateFailedNotification")
    
    // MARK: - Initialization
    
    private init() {
        // Create models directory if needed
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.modelsDirectory = documentsDirectory.appendingPathComponent("MLModels", isDirectory: true)
        
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            do {
                try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create ML models directory: \(error)")
            }
        }
        
        // Load cached model versions
        loadModelVersionCache()
    }
    
    // MARK: - Public Methods
    
    /// Check for model updates
    /// - Returns: Publisher with update results
    func checkForUpdates() -> AnyPublisher<[ModelUpdateResult], Error> {
        // Get all model information
        return apiClient.request(.mlModels)
            .flatMap { [weak self] (models: [ModelInfo]) -> AnyPublisher<[ModelUpdateResult], Error> in
                guard let self = self else {
                    return Fail(error: ModelError.unknown).eraseToAnyPublisher()
                }
                
                // Process each model
                let updatePublishers = models.map { self.checkAndUpdateModel($0) }
                
                // Combine all update publishers
                return Publishers.MergeMany(updatePublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Load a specific ML model
    /// - Parameter modelName: Name of the model to load
    /// - Returns: Publisher with loaded model or error
    func loadModel(_ modelName: String) -> AnyPublisher<MLModel, Error> {
        // Check if model is already loaded
        if let loadedModel = loadedModels[modelName] {
            return Just(loadedModel)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Check if model exists
        let modelURL = modelsDirectory.appendingPathComponent("\(modelName).mlmodel")
        let compiledModelURL = modelsDirectory.appendingPathComponent("\(modelName).mlmodelc")
        
        do {
            // Compile model if needed
            if fileManager.fileExists(atPath: modelURL.path) && !fileManager.fileExists(atPath: compiledModelURL.path) {
                try compileModel(at: modelURL)
            }
            
            // Check if compiled model exists
            guard fileManager.fileExists(atPath: compiledModelURL.path) else {
                return Fail(error: ModelError.modelNotFound(modelName)).eraseToAnyPublisher()
            }
            
            // Load model
            let model = try MLModel(contentsOf: compiledModelURL)
            
            // Cache the loaded model
            loadedModels[modelName] = model
            
            return Just(model)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    /// Get the version of a specific model
    /// - Parameter modelName: Name of the model
    /// - Returns: Version string or nil if model not found
    func getModelVersion(_ modelName: String) -> String? {
        return modelVersionCache[modelName]
    }
    
    /// Force update of a specific model
    /// - Parameter modelName: Name of the model to update
    /// - Returns: Publisher with update result
    func forceUpdate(_ modelName: String) -> AnyPublisher<ModelUpdateResult, Error> {
        // Remove current version from cache to force update
        modelVersionCache.removeValue(forKey: modelName)
        
        // Get model info
        return apiClient.request(.mlModelVersion(name: modelName))
            .flatMap { [weak self] (modelInfo: ModelInfo) -> AnyPublisher<ModelUpdateResult, Error> in
                guard let self = self else {
                    return Fail(error: ModelError.unknown).eraseToAnyPublisher()
                }
                
                return self.checkAndUpdateModel(modelInfo)
            }
            .eraseToAnyPublisher()
    }
    
    /// Clear model cache
    func clearModelCache() {
        // Clear loaded models
        loadedModels.removeAll()
        
        // Clear version cache
        modelVersionCache.removeAll()
        
        // Save empty cache
        saveModelVersionCache()
    }
    
    // MARK: - Private Methods
    
    /// Check and update a specific model if needed
    /// - Parameter modelInfo: Information about the model
    /// - Returns: Publisher with update result
    private func checkAndUpdateModel(_ modelInfo: ModelInfo) -> AnyPublisher<ModelUpdateResult, Error> {
        // Get current version
        let currentVersion = modelVersionCache[modelInfo.name]
        
        // If current version matches server version, no update needed
        if let currentVersion = currentVersion, currentVersion == modelInfo.version {
            let result = ModelUpdateResult(
                modelName: modelInfo.name,
                oldVersion: currentVersion,
                newVersion: modelInfo.version,
                updatePerformed: false,
                downloadSize: 0
            )
            
            return Just(result)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Notify update started
        NotificationCenter.default.post(
            name: Self.modelUpdateStartedNotification,
            object: nil,
            userInfo: ["modelName": modelInfo.name]
        )
        
        // Remove previous version if exists
        if loadedModels[modelInfo.name] != nil {
            loadedModels.removeValue(forKey: modelInfo.name)
        }
        
        // Download model
        return downloadModel(modelInfo)
            .flatMap { [weak self] fileURL -> AnyPublisher<ModelUpdateResult, Error> in
                guard let self = self else {
                    return Fail(error: ModelError.unknown).eraseToAnyPublisher()
                }
                
                do {
                    // Move downloaded file to models directory with correct name
                    let destinationURL = self.modelsDirectory.appendingPathComponent("\(modelInfo.name).mlmodel")
                    
                    // Remove existing model if any
                    if self.fileManager.fileExists(atPath: destinationURL.path) {
                        try self.fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Move downloaded file
                    try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                    
                    // Compile model
                    try self.compileModel(at: destinationURL)
                    
                    // Update version cache
                    self.modelVersionCache[modelInfo.name] = modelInfo.version
                    self.saveModelVersionCache()
                    
                    // Create result
                    let result = ModelUpdateResult(
                        modelName: modelInfo.name,
                        oldVersion: currentVersion,
                        newVersion: modelInfo.version,
                        updatePerformed: true,
                        downloadSize: modelInfo.size
                    )
                    
                    // Notify update completed
                    NotificationCenter.default.post(
                        name: Self.modelUpdateCompletedNotification,
                        object: nil,
                        userInfo: ["result": result]
                    )
                    
                    return Just(result)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    // Notify update failed
                    NotificationCenter.default.post(
                        name: Self.modelUpdateFailedNotification,
                        object: nil,
                        userInfo: ["error": error, "modelName": modelInfo.name]
                    )
                    
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Download a model from the server
    /// - Parameter modelInfo: Information about the model
    /// - Returns: Publisher with local file URL
    private func downloadModel(_ modelInfo: ModelInfo) -> AnyPublisher<URL, Error> {
        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mlmodel")
        
        // Download model
        let downloadURL = URL(string: modelInfo.downloadURL)!
        
        return URLSession.shared.dataTaskPublisher(for: downloadURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw ModelError.downloadFailed
                }
                
                return data
            }
            .tryMap { data -> URL in
                // Write data to temporary file
                try data.write(to: tempURL)
                return tempURL
            }
            .mapError { error -> Error in
                if let modelError = error as? ModelError {
                    return modelError
                }
                return ModelError.downloadFailed
            }
            .eraseToAnyPublisher()
    }
    
    /// Compile ML model
    /// - Parameter url: URL of the model file
    /// - Throws: Error if compilation fails
    private func compileModel(at url: URL) throws {
        // Create destination URL for compiled model
        let compiledURL = url.deletingPathExtension().appendingPathExtension("mlmodelc")
        
        // Remove existing compiled model if any
        if fileManager.fileExists(atPath: compiledURL.path) {
            try fileManager.removeItem(at: compiledURL)
        }
        
        // Compile model
        // Note: In a real app, you would use MLModel.compileModel(at:)
        // But we'll use a placeholder for this example
        
        // This is a placeholder for actual model compilation
        // Instead of actual compilation, we'll create a mock directory structure
        try fileManager.createDirectory(at: compiledURL, withIntermediateDirectories: true)
        
        // In a real app, you would use:
        // try MLModel.compileModel(at: url)
    }
    
    /// Load model version cache from disk
    private func loadModelVersionCache() {
        let configURL = modelsDirectory.appendingPathComponent(modelConfigFileName)
        
        if fileManager.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                let config = try JSONDecoder().decode([String: String].self, from: data)
                modelVersionCache = config
            } catch {
                print("Failed to load model config: \(error)")
                modelVersionCache = [:]
            }
        } else {
            modelVersionCache = [:]
        }
    }
    
    /// Save model version cache to disk
    private func saveModelVersionCache() {
        let configURL = modelsDirectory.appendingPathComponent(modelConfigFileName)
        
        do {
            let data = try JSONEncoder().encode(modelVersionCache)
            try data.write(to: configURL)
        } catch {
            print("Failed to save model config: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum ModelError: Error {
    case modelNotFound(String)
    case downloadFailed
    case compilationFailed
    case loadingFailed
    case unknown
}

struct ModelInfo: Codable {
    let name: String
    let version: String
    let description: String
    let size: Int64
    let downloadURL: String
    let requiredDeviceCapabilities: [String]
    let supportedOperatingSystems: [String]
    let releaseDate: Date
}

struct ModelUpdateResult {
    let modelName: String
    let oldVersion: String?
    let newVersion: String
    let updatePerformed: Bool
    let downloadSize: Int64
}
