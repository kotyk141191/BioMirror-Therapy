//
//  FacialEmotionClassifier.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import CoreML
import Vision
import Combine

class FacialEmotionClassifier {
    // MARK: - Properties
    
    private let modelManager = MLModelManager.shared
    private var model: MLModel?
    private var visionModel: VNCoreMLModel?
    
    private static let modelName = "EmotionClassifier"
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load model
        loadModel()
    }
    
    // MARK: - Public Methods
    
    /// Classify emotions in a facial image
    /// - Parameter pixelBuffer: Image pixel buffer
    /// - Returns: Emotion classification result
    func classifyEmotion(in pixelBuffer: CVPixelBuffer) -> AnyPublisher<EmotionClassificationResult, Error> {
        // Check if model is loaded
        guard let visionModel = visionModel else {
            return loadModel()
                .flatMap { [weak self] _ -> AnyPublisher<EmotionClassificationResult, Error> in
                    guard let self = self else {
                        return Fail(error: ClassifierError.modelNotLoaded).eraseToAnyPublisher()
                    }
                    
                    return self.performClassification(on: pixelBuffer)
                }
                .eraseToAnyPublisher()
        }
        
        return performClassification(on: pixelBuffer)
    }
    
    /// Update the classifier model
    /// - Returns: Publisher with update result
    func updateModel() -> AnyPublisher<ModelUpdateResult, Error> {
        return modelManager.forceUpdate(Self.modelName)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Reload model after update
                self?.loadModel()
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Load the emotion classifier model
    /// - Returns: Publisher that completes when model is loaded
    private func loadModel() -> AnyPublisher<Void, Error> {
        return modelManager.loadModel(Self.modelName)
            .tryMap { [weak self] mlModel -> Void in
                guard let self = self else { throw ClassifierError.unknown }
                
                self.model = mlModel
                
                // Create Vision model
                self.visionModel = try VNCoreMLModel(for: mlModel)
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    /// Perform emotion classification on an image
    /// - Parameter pixelBuffer: Image pixel buffer
    /// - Returns: Emotion classification result
    private func performClassification(on pixelBuffer: CVPixelBuffer) -> AnyPublisher<EmotionClassificationResult, Error> {
        guard let visionModel = visionModel else {
            return Fail(error: ClassifierError.modelNotLoaded).eraseToAnyPublisher()
        }
        
        return Future<EmotionClassificationResult, Error> { promise in
            // Create request
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    promise(.failure(ClassifierError.invalidResults))
                    return
                }
                
                // Process results
                var emotionProbabilities: [String: Float] = [:]
                
                for result in results {
                    emotionProbabilities[result.identifier] = result.confidence
                }
                
                // Find dominant emotion
                let dominantEmotion = results.max(by: { $0.confidence < $1.confidence })
                
                // Create result
                let result = EmotionClassificationResult(
                    dominantEmotion: dominantEmotion?.identifier ?? "unknown",
                    dominantEmotionProbability: dominantEmotion?.confidence ?? 0.0,
                    emotionProbabilities: emotionProbabilities,
                    timestamp: Date()
                )
                
                promise(.success(result))
            }
            
            // Configure request
            request.imageCropAndScaleOption = .centerCrop
            
            // Perform request
            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                try handler.perform([request])
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum ClassifierError: Error {
    case modelNotLoaded
    case invalidResults
    case unknown
}

struct EmotionClassificationResult {
    let dominantEmotion: String
    let dominantEmotionProbability: Float
    let emotionProbabilities: [String: Float]
    let timestamp: Date
}
