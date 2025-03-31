//
//  LiDARFacialAnalysisService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import ARKit
import Vision
import Combine

class LiDARFacialAnalysisService: NSObject, FacialAnalysisService {
    // MARK: - Properties
    
    private var arSession: ARSession?
    private let facialAnalysisQueue = DispatchQueue(label: "com.biomirror.facialanalysis", qos: .userInteractive)
    private let emotionalStateSubject = PassthroughSubject<EmotionalState, Never>()
    private let statusSubject = PassthroughSubject<FacialAnalysisStatus, Never>()
    
    private var _currentEmotionalState: EmotionalState?
    private var _status: FacialAnalysisStatus = .notStarted
    private var _isRunning = false
    
    private var faceAnchors: [ARFaceAnchor] = []
    private var blendShapeHistory: [[ARFaceAnchor.BlendShapeLocation: NSNumber]] = []
    private let historySize = 10 // Track last 10 frames for micro-expressions
    
    // MARK: - FacialAnalysisService Protocol Properties
    
    var isRunning: Bool {
        return _isRunning
    }
    
    var status: FacialAnalysisStatus {
        return _status
    }
    
    var statusPublisher: AnyPublisher<FacialAnalysisStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    var currentEmotionalState: EmotionalState? {
        return _currentEmotionalState
    }
    
    var emotionalStatePublisher: AnyPublisher<EmotionalState, Never> {
        return emotionalStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkDeviceCapabilities()
    }
    
    // MARK: - FacialAnalysisService Protocol Methods
    
    func startAnalysis() throws {
        guard !_isRunning else { return }
        
        // Check if device supports face tracking
        guard ARFaceTrackingConfiguration.isSupported else {
            throw FacialAnalysisError.deviceNotSupported
        }
        
        updateStatus(.initializing)
        
        // Create and configure AR session
        let arSession = ARSession()
        arSession.delegate = self
        self.arSession = arSession
        
        // Configure face tracking
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = 1
        
        // Run the session
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        _isRunning = true
        updateStatus(.running)
    }
    
    func stopAnalysis() {
        guard _isRunning else { return }
        
        arSession?.pause()
        arSession = nil
        faceAnchors.removeAll()
        blendShapeHistory.removeAll()
        _isRunning = false
        updateStatus(.notStarted)
    }
    
    func pauseAnalysis() {
        guard _isRunning else { return }
        
        arSession?.pause()
        updateStatus(.paused)
    }
    
    func resumeAnalysis() {
        guard status == .paused, let arSession = arSession else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        arSession.run(configuration, options: [])
        updateStatus(.running)
    }
    
    func configure(with options: FacialAnalysisOptions) {
        // Configure face tracking based on options
        guard let arSession = arSession, _isRunning else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        
        // Set capture frequency
        switch options.captureFrequency {
        case .low:
            configuration.videoFormat = findClosestVideoFormat(targetFPS: 10)
        case .medium:
            configuration.videoFormat = findClosestVideoFormat(targetFPS: 30)
        case .high:
            configuration.videoFormat = findClosestVideoFormat(targetFPS: 60)
        }
        
        // Apply configuration
        arSession.run(configuration, options: [])
    }
    
    // MARK: - Private Methods
    
    private func updateStatus(_ newStatus: FacialAnalysisStatus) {
        _status = newStatus
        statusSubject.send(newStatus)
    }
    
    private func checkDeviceCapabilities() {
        guard ARFaceTrackingConfiguration.isSupported else {
            updateStatus(.failed(FacialAnalysisError.deviceNotSupported))
            return
        }
    }
    
    private func findClosestVideoFormat(targetFPS: Int) -> ARConfiguration.VideoFormat {
        let availableFormats = ARFaceTrackingConfiguration.supportedVideoFormats
        
        return availableFormats.min { format1, format2 in
            abs(Int(format1.framesPerSecond) - targetFPS) < abs(Int(format2.framesPerSecond) - targetFPS)
        } ?? availableFormats.first!
    }
    
    // MARK: - Emotion Detection
    
    private func processBlendShapes(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], anchor: ARFaceAnchor) -> EmotionalState {
        // Store blend shapes in history for micro-expression detection
        blendShapeHistory.append(blendShapes)
        if blendShapeHistory.count > historySize {
            blendShapeHistory.removeFirst()
        }
        
        // Extract key blend shape values
        let browInnerUp = blendShapes[.browInnerUp]?.floatValue ?? 0
        let browDownLeft = blendShapes[.browDownLeft]?.floatValue ?? 0
        let browDownRight = blendShapes[.browDownRight]?.floatValue ?? 0
        let browOuterUpLeft = blendShapes[.browOuterUpLeft]?.floatValue ?? 0
        let browOuterUpRight = blendShapes[.browOuterUpRight]?.floatValue ?? 0
        let eyeBlinkLeft = blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let eyeBlinkRight = blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        let eyeSquintLeft = blendShapes[.eyeSquintLeft]?.floatValue ?? 0
        let eyeSquintRight = blendShapes[.eyeSquintRight]?.floatValue ?? 0
        let eyeWideLeft = blendShapes[.eyeWideLeft]?.floatValue ?? 0
        let eyeWideRight = blendShapes[.eyeWideRight]?.floatValue ?? 0
        let jawOpen = blendShapes[.jawOpen]?.floatValue ?? 0
        let mouthFunnel = blendShapes[.mouthFunnel]?.floatValue ?? 0
        let mouthPucker = blendShapes[.mouthPucker]?.floatValue ?? 0
        let mouthSmileLeft = blendShapes[.mouthSmileLeft]?.floatValue ?? 0
        let mouthSmileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0
        let mouthFrownLeft = blendShapes[.mouthFrownLeft]?.floatValue ?? 0
        let mouthFrownRight = blendShapes[.mouthFrownRight]?.floatValue ?? 0
        let mouthDimpleLeft = blendShapes[.mouthDimpleLeft]?.floatValue ?? 0
        let mouthDimpleRight = blendShapes[.mouthDimpleRight]?.floatValue ?? 0
        let mouthStretchLeft = blendShapes[.mouthStretchLeft]?.floatValue ?? 0
        let mouthStretchRight = blendShapes[.mouthStretchRight]?.floatValue ?? 0
        let mouthRollLower = blendShapes[.mouthRollLower]?.floatValue ?? 0
        let mouthRollUpper = blendShapes[.mouthRollUpper]?.floatValue ?? 0
        let mouthClose = blendShapes[.mouthClose]?.floatValue ?? 0
        let mouthPressLeft = blendShapes[.mouthPressLeft]?.floatValue ?? 0
        let mouthPressRight = blendShapes[.mouthPressRight]?.floatValue ?? 0
        let noseSneerLeft = blendShapes[.noseSneerLeft]?.floatValue ?? 0
        let noseSneerRight = blendShapes[.noseSneerRight]?.floatValue ?? 0
        let cheekPuff = blendShapes[.cheekPuff]?.floatValue ?? 0
        let cheekSquintLeft = blendShapes[.cheekSquintLeft]?.floatValue ?? 0
        let cheekSquintRight = blendShapes[.cheekSquintRight]?.floatValue ?? 0
        
        // Calculate emotion scores
        
        // Happiness score: smile expressions, cheek raising
        let happiness = calculateAverageWithWeights([
            (mouthSmileLeft + mouthSmileRight) / 2, 2.0,
            (cheekSquintLeft + cheekSquintRight) / 2, 1.0,
            (mouthDimpleLeft + mouthDimpleRight) / 2, 0.5
        ])
        
        // Sadness score: frown, brow inner raise, mouth corners down
        let sadness = calculateAverageWithWeights([
            (mouthFrownLeft + mouthFrownRight) / 2, 2.0,
            browInnerUp, 1.0,
            1 - (mouthSmileLeft + mouthSmileRight) / 2, 0.5
        ])
        
        // Anger score: brow lowering, nose wrinkle, eye narrowing
        let anger = calculateAverageWithWeights([
            (browDownLeft + browDownRight) / 2, 2.0,
            (noseSneerLeft + noseSneerRight) / 2, 1.0,
            (eyeSquintLeft + eyeSquintRight) / 2, 1.0,
            (mouthPressLeft + mouthPressRight) / 2, 0.5
        ])
        
        // Fear score: brow raise, eye widening, mouth stretch
        let fear = calculateAverageWithWeights([
            (eyeWideLeft + eyeWideRight) / 2, 2.0,
            browInnerUp, 1.5,
            (browOuterUpLeft + browOuterUpRight) / 2, 1.0,
            (mouthStretchLeft + mouthStretchRight) / 2, 0.5
        ])
        
        // Surprise score: eye widening, brow raising, jaw drop
        let surprise = calculateAverageWithWeights([
            (eyeWideLeft + eyeWideRight) / 2, 2.0,
            (browOuterUpLeft + browOuterUpRight) / 2, 1.5,
            browInnerUp, 1.0,
            jawOpen, 1.0
        ])
        
        // Disgust score: nose wrinkle, upper lip raise, brow lowering
        let disgust = calculateAverageWithWeights([
            (noseSneerLeft + noseSneerRight) / 2, 2.0,
            mouthRollUpper, 1.0,
            (browDownLeft + browDownRight) / 2, 0.5
        ])
        
        // Contempt score: mouth dimple and asymmetric smile
        let contempt = calculateAverageWithWeights([
            abs(mouthSmileLeft - mouthSmileRight), 2.0,
            (mouthDimpleLeft + mouthDimpleRight) / 2, 1.0,
            (noseSneerLeft + noseSneerRight) / 2, 0.5
        ])
        
        // Neutral score: lack of strong expressions
        let expressiveness = max(happiness, sadness, anger, fear, surprise, disgust, contempt)
        let neutral = 1.0 - expressiveness
        
        // Map scores to emotion types and intensities
        var emotionScores: [(EmotionType, Float)] = [
            (.happiness, happiness),
            (.sadness, sadness),
            (.anger, anger),
            (.fear, fear),
            (.surprise, surprise),
            (.disgust, disgust),
            (.contempt, contempt),
            (.neutral, neutral)
        ]
        
        // Sort by intensity
        emotionScores.sort { $0.1 > $1.1 }
        
        // Primary emotion
        let primaryEmotion = emotionScores[0].0
        let primaryIntensity = emotionScores[0].1
        
        // Secondary emotions (any with at least 30% intensity)
        var secondaryEmotions: [EmotionType: Float] = [:]
        for (emotion, intensity) in emotionScores.dropFirst() {
            if intensity > 0.3 {
                secondaryEmotions[emotion] = intensity
            }
        }
        
        // Detect micro-expressions
        let microExpressions = detectMicroExpressions()
        
        // Calculate confidence based on face tracking quality
        let confidence = anchor.isTracked ? Float(min(1.0, 0.5 + anchor.trackingState.rawValue * 0.25)) : 0.0
        
        // Determine face detection quality
        let detectionQuality: DetectionQuality
        if !anchor.isTracked {
            detectionQuality = .noFace
        } else if confidence > 0.9 {
            detectionQuality = .excellent
        } else if confidence > 0.7 {
            detectionQuality = .good
        } else if confidence > 0.5 {
            detectionQuality = .fair
        } else {
            detectionQuality = .poor
        }
        
        // Create emotional state
        return EmotionalState(
            timestamp: Date(),
            primaryEmotion: primaryEmotion,
            primaryIntensity: primaryIntensity,
            secondaryEmotions: secondaryEmotions,
            microExpressions: microExpressions,
            confidence: confidence,
            faceDetectionQuality: detectionQuality
        )
    }
    
    private func calculateAverageWithWeights(_ valuesAndWeights: [Float]) -> Float {
        var sum: Float = 0
        var totalWeight: Float = 0
        
        for i in stride(from: 0, to: valuesAndWeights.count, by: 2) {
            let value = valuesAndWeights[i]
            let weight = i + 1 < valuesAndWeights.count ? valuesAndWeights[i + 1] : 1.0
            
            sum += value * weight
            totalWeight += weight
        }
        
        return totalWeight > 0 ? sum / totalWeight : 0
    }
    
    private func detectMicroExpressions() -> [MicroExpression] {
        // Need at least a few frames of history
        guard blendShapeHistory.count > 3 else { return [] }
        
        var microExpressions: [MicroExpression] = []
        
        // Key locations to monitor for micro-expressions
        let keyLocations: [ARFaceAnchor.BlendShapeLocation] = [
            .browInnerUp, .browDownLeft, .browDownRight,
            .eyeWideLeft, .eyeWideRight, .eyeSquintLeft, .eyeSquintRight,
            .noseSneerLeft, .noseSneerRight,
            .mouthSmileLeft, .mouthSmileRight, .mouthFrownLeft, .mouthFrownRight
        ]
        
        // Look for rapid changes across frames
        for i in 1..<blendShapeHistory.count {
            for location in keyLocations {
                let prevValue = blendShapeHistory[i-1][location]?.floatValue ?? 0
                let currentValue = blendShapeHistory[i][location]?.floatValue ?? 0
                
                // Detect significant, rapid changes
                if abs(currentValue - prevValue) > 0.3 && currentValue > 0.4 {
                    // Determine which emotion this might represent
                    let microEmotion = emotionForFacialAction(location, intensity: currentValue)
                    
                    // Create facial action unit
                    let actionUnit = FacialActionUnit(
                        id: facialActionUnitIdForLocation(location),
                        name: facialActionUnitNameForLocation(location),
                        intensity: currentValue
                    )
                    
                    // Create micro-expression with estimated duration (typically 0.04-0.2 seconds)
                    let microExpression = MicroExpression(
                        timestamp: Date().addingTimeInterval(-0.1 * Double(blendShapeHistory.count - i)),
                        duration: 0.1, // Approximate
                        emotionType: microEmotion,
                        intensity: currentValue,
                        facialActionUnits: [actionUnit]
                    )
                    
                    microExpressions.append(microExpression)
                }
            }
        }
        
        return microExpressions
    }
    
    private func emotionForFacialAction(_ location: ARFaceAnchor.BlendShapeLocation, intensity: Float) -> EmotionType {
        switch location {
        case .browInnerUp:
            return .sadness
        case .browDownLeft, .browDownRight:
            return .anger
        case .eyeWideLeft, .eyeWideRight:
            return .fear
        case .noseSneerLeft, .noseSneerRight:
            return .disgust
        case .mouthSmileLeft, .mouthSmileRight:
            return .happiness
        case .mouthFrownLeft, .mouthFrownRight:
            return .sadness
        default:
            return .neutral
        }
    }
    
    private func facialActionUnitIdForLocation(_ location: ARFaceAnchor.BlendShapeLocation) -> Int {
        // Map ARKit blend shapes to FACS Action Units
        switch location {
        case .browInnerUp: return 1
        case .browDownLeft, .browDownRight: return 4
        case .browOuterUpLeft, .browOuterUpRight: return 2
        case .eyeBlinkLeft, .eyeBlinkRight: return 45
        case .eyeSquintLeft, .eyeSquintRight: return 7
        case .eyeWideLeft, .eyeWideRight: return 5
        case .jawOpen: return 26
        case .mouthFunnel: return 22
        case .mouthPucker: return 18
        case .mouthSmileLeft, .mouthSmileRight: return 12
        case .mouthFrownLeft, .mouthFrownRight: return 15
        case .mouthDimpleLeft, .mouthDimpleRight: return 14
        case .mouthStretchLeft, .mouthStretchRight: return 20
        case .mouthRollLower: return 16
        case .mouthRollUpper: return 17
        case .mouthClose: return 24
        case .mouthPressLeft, .mouthPressRight: return 23
        case .noseSneerLeft, .noseSneerRight: return 9
        case .cheekPuff: return 34
        case .cheekSquintLeft, .cheekSquintRight: return 6
        default: return 0
        }
    }
    
    private func facialActionUnitNameForLocation(_ location: ARFaceAnchor.BlendShapeLocation) -> String {
        // Names of FACS Action Units
        switch location {
        case .browInnerUp: return "Inner Brow Raiser"
        case .browDownLeft, .browDownRight: return "Brow Lowerer"
        case .browOuterUpLeft, .browOuterUpRight: return "Outer Brow Raiser"
        case .eyeBlinkLeft, .eyeBlinkRight: return "Eye Blink"
        case .eyeSquintLeft, .eyeSquintRight: return "Lid Tightener"
        case .eyeWideLeft, .eyeWideRight: return "Upper Lid Raiser"
        case .jawOpen: return "Jaw Drop"
        case .mouthFunnel: return "Lip Funneler"
        case .mouthPucker: return "Lip Puckerer"
        case .mouthSmileLeft, .mouthSmileRight: return "Lip Corner Puller"
        case .mouthFrownLeft, .mouthFrownRight: return "Lip Corner Depressor"
        case .mouthDimpleLeft, .mouthDimpleRight: return "Dimpler"
        case .mouthStretchLeft, .mouthStretchRight: return "Lip Stretcher"
        case .mouthRollLower: return "Lower Lip Depressor"
        case .mouthRollUpper: return "Upper Lip Raiser"
        case .mouthClose: return "Lips Closed"
        case .mouthPressLeft, .mouthPressRight: return "Lip Presser"
        case .noseSneerLeft, .noseSneerRight: return "Nose Wrinkler"
        case .cheekPuff: return "Cheek Puffer"
        case .cheekSquintLeft, .cheekSquintRight: return "Cheek Raiser"
        default: return "Unknown Action"
        }
    }
}

// MARK: - ARSessionDelegate

extension LiDARFacialAnalysisService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Process face anchors in background queue to avoid blocking main thread
        facialAnalysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get face anchors from frame
            let faceAnchors = frame.anchors.compactMap { $0 as? ARFaceAnchor }
            self.faceAnchors = faceAnchors
            
            // Process the first face anchor
            if let faceAnchor = faceAnchors.first {
                // Get blend shapes
                let blendShapes = faceAnchor.blendShapes
                
                // Process facial expressions
                let emotionalState = self.processBlendShapes(blendShapes, anchor: faceAnchor)
                
                // Update current state and notify observers on main thread
                DispatchQueue.main.async {
                    self._currentEmotionalState = emotionalState
                    self.emotionalStateSubject.send(emotionalState)
                }
            } else if self.faceAnchors.isEmpty {
                // No face detected
                let noFaceState = EmotionalState(
                    timestamp: Date(),
                    primaryEmotion: .neutral,
                    primaryIntensity: 0.0,
                    secondaryEmotions: [:],
                    microExpressions: [],
                    confidence: 0.0,
                    faceDetectionQuality: .noFace
                )
                
                DispatchQueue.main.async {
                    self._currentEmotionalState = noFaceState
                    self.emotionalStateSubject.send(noFaceState)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session failed: \(error)")
        updateStatus(.failed(FacialAnalysisError.arSessionFailed))
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        updateStatus(.paused)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        if _isRunning {
            updateStatus(.running)
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Remove any face anchors that are no longer tracked
        faceAnchors.removeAll { anchor in
            return anchors.contains { $0.identifier == anchor.identifier }
        }
    }
}
