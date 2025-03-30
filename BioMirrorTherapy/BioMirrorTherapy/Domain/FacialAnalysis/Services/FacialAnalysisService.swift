//
//  FacialAnalysisService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine
import ARKit

protocol FacialAnalysisService {
    // Status
    var isRunning: Bool { get }
    var status: FacialAnalysisStatus { get }
    var statusPublisher: AnyPublisher<FacialAnalysisStatus, Never> { get }
    
    // Emotional state
    var currentEmotionalState: EmotionalState? { get }
    var emotionalStatePublisher: AnyPublisher<EmotionalState, Never> { get }
    
    // Control
    func startAnalysis() throws
    func stopAnalysis()
    func pauseAnalysis()
    func resumeAnalysis()
    
    // Configuration
    func configure(with options: FacialAnalysisOptions)
}

enum FacialAnalysisStatus {
    case notStarted
    case initializing
    case running
    case paused
    case failed(Error)
}

enum FacialAnalysisError: Error {
    case deviceNotSupported
    case cameraPermissionDenied
    case arSessionFailed
    case modelLoadingFailed
    case internalError(String)
}

struct FacialAnalysisOptions {
    let captureFrequency: CaptureFrequency
    let includeMicroExpressions: Bool
    let trackFacialActionUnits: Bool
    let emotionDetectionThreshold: Float // 0.0 to 1.0
    
    static let `default` = FacialAnalysisOptions(
        captureFrequency: .high,
        includeMicroExpressions: true,
        trackFacialActionUnits: true,
        emotionDetectionThreshold: 0.6
    )
}

enum CaptureFrequency {
    case low      // 10 fps
    case medium   // 30 fps
    case high     // 60 fps
}
