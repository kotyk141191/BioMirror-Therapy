//
//  EmotionalCoherenceAnalyzer.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

// Forward declaration to resolve circular reference
// The actual implementation
class EmotionalCoherenceAnalyzer: EmotionalIntegrationService {
    // MARK: - Properties
    
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    
    private var emotionalStateSubscription: AnyCancellable?
    private var physiologicalStateSubscription: AnyCancellable?
    
    private var latestEmotionalState: EmotionalState?
    private var latestPhysiologicalState: PhysiologicalState?
    
    private let integratedStateSubject = PassthroughSubject<IntegratedEmotionalState, Never>()
    private let stateChangeSubject = PassthroughSubject<EmotionalStateChange, Never>()
    private var _currentIntegratedState: IntegratedEmotionalState?
    
    private var integrationTimer: Timer?
    private let integrationInterval: TimeInterval = 0.2 // 5Hz integration rate
    
    private var isRunning = false
    private var previousIntegratedState: IntegratedEmotionalState?
    
    // MARK: - EmotionalIntegrationService Protocol
    
    var currentIntegratedState: IntegratedEmotionalState? {
        return _currentIntegratedState
    }
    
    var integratedStatePublisher: AnyPublisher<IntegratedEmotionalState, Never> {
        return integratedStateSubject.eraseToAnyPublisher()
    }
    
    var stateChangePublisher: AnyPublisher<EmotionalStateChange, Never> {
        return stateChangeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(facialAnalysisService: FacialAnalysisService, biometricAnalysisService: BiometricAnalysisService) {
        self.facialAnalysisService = facialAnalysisService
        self.biometricAnalysisService = biometricAnalysisService
    }
    
    // MARK: - EmotionalIntegrationService Methods
    
    func startIntegration() {
        guard !isRunning else { return }
        
        // Subscribe to facial analysis updates
        emotionalStateSubscription = facialAnalysisService.emotionalStatePublisher
            .sink { [weak self] emotionalState in
                self?.latestEmotionalState = emotionalState
            }
        
        // Subscribe to biometric analysis updates
        physiologicalStateSubscription = biometricAnalysisService.physiologicalStatePublisher
            .sink { [weak self] physiologicalState in
                self?.latestPhysiologicalState = physiologicalState
            }
        
        // Start integration timer
        setupIntegrationTimer()
        
        isRunning = true
    }
    
    func startIntegration(sessionId: String?) {
        startIntegration()
    }
    
    func stopIntegration() {
        guard isRunning else { return }
        
        // Cancel subscriptions
        emotionalStateSubscription?.cancel()
        emotionalStateSubscription = nil
        
        physiologicalStateSubscription?.cancel()
        physiologicalStateSubscription = nil
        
        // Stop integration timer
        integrationTimer?.invalidate()
        integrationTimer = nil
        
        isRunning = false
        previousIntegratedState = nil
    }
    
    func detectDissociation(in state: IntegratedEmotionalState) -> Bool {
        return state.dissociationIndex > 0.6
    }
    
    func calculateEmotionalMasking(in state: IntegratedEmotionalState) -> Float {
        return state.emotionalMaskingIndex
    }
    
    // MARK: - Private Methods
    
    private func setupIntegrationTimer() {
        integrationTimer?.invalidate()
        
        // Create timer to integrate emotional and physiological data
        integrationTimer = Timer.scheduledTimer(withTimeInterval: integrationInterval, repeats: true) { [weak self] _ in
            self?.processLatestData()
        }
    }
    
    private func processLatestData() {
        guard let emotionalState = latestEmotionalState,
              let physiologicalState = latestPhysiologicalState else { return }
        
        // Integrate data and calculate metrics
        let integratedState = integrateData(
            emotionalState: emotionalState,
            physiologicalState: physiologicalState
        )
        
        // Detect significant changes
        let stateChange = detectStateChanges(from: previousIntegratedState, to: integratedState)
        
        // Update state
        _currentIntegratedState = integratedState
        previousIntegratedState = integratedState
        
        // Notify subscribers
        integratedStateSubject.send(integratedState)
        
        // Notify about significant changes
        if stateChange.isSignificant {
            stateChangeSubject.send(stateChange)
        }
    }
    
    private func integrateData(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> IntegratedEmotionalState {
        // Calculate coherence index - how well facial expressions match physiological state
        let coherenceIndex = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate emotional masking - when face is neutral but physiology shows activation
        let emotionalMaskingIndex = calculateEmotionalMaskingIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate dissociation index - signs of emotional numbing or disconnection
        let dissociationIndex = calculateDissociationIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Determine dominant emotion by combining facial and physiological data
        let dominantEmotion = determineDominantEmotion(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate emotional intensity
        let emotionalIntensity = calculateEmotionalIntensity(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Determine regulation state
        let regulationState = determineRegulationState(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate data quality
        let dataQuality = calculateDataQuality(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        return IntegratedEmotionalState(
            timestamp: Date(),
            emotionalState: emotionalState,
            physiologicalState: physiologicalState,
            coherenceIndex: coherenceIndex,
            emotionalMaskingIndex: emotionalMaskingIndex,
            dissociationIndex: dissociationIndex,
            dominantEmotion: dominantEmotion,
            emotionalIntensity: emotionalIntensity,
            emotionalRegulation: regulationState,
            arousalLevel: physiologicalState.arousalLevel,
            dataQuality: dataQuality
        )
    }
    
    private func calculateDissociationIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Dissociation indicators include:
        // 1. Low facial expressivity (neutral, flat affect)
        // 2. Freeze response in motion metrics
        // 3. Disconnection between face and physiological response
        
        var dissociationScore: Float = 0.0
        
        // Check for flat affect (low intensity neutral face)
        if emotionalState.primaryEmotion == .neutral && emotionalState.primaryIntensity < 0.3 {
            dissociationScore += 0.4
        }
        
        // Check for freeze response
        if physiologicalState.motionMetrics.freezeIndex > 0.7 {
            dissociationScore += 0.4
        }
        
        // Check for characteristic dissociative HRV pattern
        if physiologicalState.hrvMetrics.heartRateVariability < 20 &&
           physiologicalState.hrvMetrics.heartRate < 70 {
            dissociationScore += 0.3
        }
        
        // Check for lack of micro-expressions
        if emotionalState.microExpressions.isEmpty && emotionalState.confidence > 0.7 {
            dissociationScore += 0.2
        }
        
        // Factor in coherence (low coherence can indicate dissociation)
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        if coherence < 0.3 {
            dissociationScore += 0.3 * (1.0 - coherence)
        }
        
        return min(1.0, dissociationScore)
    }
    
    func calculateCoherenceIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Get expected arousal range for the emotion
        let (minArousal, maxArousal) = expectedArousalRange(for: emotionalState.primaryEmotion)
        
        // Actual arousal
        let actualArousal = physiologicalState.arousalLevel
        
        // Base coherence score
        var coherence: Float = 0.5
        
        // If arousal is within expected range, increase coherence
        if actualArousal >= minArousal && actualArousal <= maxArousal {
            // Higher coherence when closer to the middle of the expected range
            let rangeCenter = (minArousal + maxArousal) / 2
            let distanceFromCenter = abs(actualArousal - rangeCenter)
            let rangeWidth = maxArousal - minArousal
            
            // Transform to 0-1 scale with higher values for better match
            coherence = 1.0 - (distanceFromCenter / (rangeWidth / 2))
        } else {
            // Lower coherence when outside expected range
            // How far outside the range?
            let distanceOutside = min(abs(actualArousal - minArousal), abs(actualArousal - maxArousal))
            coherence = max(0.1, 0.5 - distanceOutside)
        }
        
        // Check for physiological signs matching the emotion
        coherence = adjustCoherenceForPhysiologicalSigns(
            coherence: coherence,
            emotion: emotionalState.primaryEmotion,
            physiologicalState: physiologicalState
        )
        
        // Weight by confidence in emotional state detection
        coherence *= emotionalState.confidence
        
        // Weight by physiological data quality
        coherence *= min(1.0, physiologicalState.qualityIndex * 1.2)
        
        return min(1.0, coherence)
    }
    
    // Complete implementation for calculateDissociationIndex in EmotionalCoherenceAnalyzer
//    private func calculateDissociationIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
//        // Dissociation indicators include:
//        // 1. Low facial expressivity (neutral, flat affect)
//        // 2. Freeze response in motion metrics
//        // 3. Disconnection between face and physiological response
//        
//        var dissociationScore: Float = 0.0
//        
//        // Check for flat affect (low intensity neutral face)
//        if emotionalState.primaryEmotion == .neutral && emotionalState.primaryIntensity < 0.3 {
//            dissociationScore += 0.4
//        }
//        
//        // Check for freeze response
//        if physiologicalState.motionMetrics.freezeIndex > 0.7 {
//            dissociationScore += 0.4
//        }
//        
//        // Check for characteristic dissociative HRV pattern
//        if physiologicalState.hrvMetrics.heartRateVariability < 20 &&
//           physiologicalState.hrvMetrics.heartRate < 70 {
//            dissociationScore += 0.3
//        }
//        
//        // Check for lack of micro-expressions
//        if emotionalState.microExpressions.isEmpty && emotionalState.confidence > 0.7 {
//            dissociationScore += 0.2
//        }
//        
//        // Factor in coherence (low coherence can indicate dissociation)
//        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
//        if coherence < 0.3 {
//            dissociationScore += 0.3 * (1.0 - coherence)
//        }
//        
//        return min(1.0, dissociationScore)
//    }

    // Complete implementation for calculateEmotionalMaskingIndex
    private func calculateEmotionalMaskingIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Base masking score
        var masking: Float = 0.0
        
        // Check if face is neutral but arousal is high
        if emotionalState.primaryEmotion == .neutral && physiologicalState.arousalLevel > 0.6 {
            masking = min(1.0, physiologicalState.arousalLevel * 1.5)
        }
        
        // Check if face shows positive emotion but physiology suggests otherwise
        if emotionalState.primaryEmotion == .happiness {
            // High HRV typically indicates calm/positive state
            // If HRV is low but face shows happiness, might be masking
            let hrvNormalized = Float(physiologicalState.hrvMetrics.heartRateVariability / 100.0)
            if hrvNormalized < 0.3 && physiologicalState.arousalLevel > 0.7 {
                masking = max(masking, 0.8)
            }
        }
        
        // Check for mismatch between primary and secondary emotions
        if let secondaryEmotion = emotionalState.secondaryEmotions.max(by: { $0.value < $1.value })?.key,
           let secondaryIntensity = emotionalState.secondaryEmotions[secondaryEmotion] {
            
            if secondaryIntensity > emotionalState.primaryIntensity * 0.8 {
                // Secondary emotion is almost as strong as primary
                masking = max(masking, 0.4)
            }
        }
        
        // Calculate general mismatch between facial and physiological indicators
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        masking = max(masking, 1.0 - coherence)
        
        return min(1.0, masking)
    }
    
    private func adjustCoherenceForPhysiologicalSigns(coherence: Float, emotion: EmotionType, physiologicalState: PhysiologicalState) -> Float {
        var adjustedCoherence = coherence
        
        // Check specific physiological patterns for emotions
        switch emotion {
        case .fear:
            // Fear often shows increased heart rate and potential freeze response
            let heartRateElevated = physiologicalState.hrvMetrics.heartRate > 90
            let freezeResponse = physiologicalState.motionMetrics.freezeIndex > 0.6
            
            if heartRateElevated || freezeResponse {
                adjustedCoherence += 0.15
            }
            
        case .anger:
            // Anger typically shows high heart rate and reduced HRV
            let heartRateElevated = physiologicalState.hrvMetrics.heartRate > 90
            let hrvReduced = physiologicalState.hrvMetrics.heartRateVariability < 40
            
            if heartRateElevated && hrvReduced {
                adjustedCoherence += 0.2
            }
            
        case .happiness:
            // Happiness often shows moderate heart rate and good HRV
            let heartRateModerate = physiologicalState.hrvMetrics.heartRate > 65 &&
                                    physiologicalState.hrvMetrics.heartRate < 90
            let hrvModerate = physiologicalState.hrvMetrics.heartRateVariability > 50
            
            if heartRateModerate && hrvModerate {
                adjustedCoherence += 0.15
            }
            
        case .sadness:
            // Sadness may show reduced movement and slight respiratory changes
            let lowMovement = physiologicalState.motionMetrics.acceleration.x < 0.1 &&
                             physiologicalState.motionMetrics.acceleration.y < 0.1
            let respirationChanged = physiologicalState.respirationMetrics.irregularity > 0.4
            
            if lowMovement && respirationChanged {
                adjustedCoherence += 0.1
            }
            
        default:
            break
        }
        
        return adjustedCoherence
    }
    
    private func expectedArousalRange(for emotion: EmotionType) -> (Float, Float) {
        switch emotion {
        case .happiness:
            return (0.4, 0.8) // Moderate to high arousal
        case .sadness:
            return (0.1, 0.4) // Low to moderate arousal
        case .anger:
            return (0.7, 1.0) // High arousal
        case .fear:
            return (0.6, 0.9) // High arousal
        case .surprise:
            return (0.5, 0.9) // Moderate to high arousal
        case .disgust:
            return (0.3, 0.7) // Moderate arousal
        case .neutral:
            return (0.2, 0.5) // Low to moderate arousal
        case .contempt:
            return (0.3, 0.6) // Moderate arousal
        case .dissociation:
            return (0.1, 0.3) // Low arousal
        default:
            return (0.3, 0.7) // Default range
        }
    }
    
//    private func calculateEmotionalMaskingIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
//        // Base masking score
//        var masking: Float = 0.0
//        
//        // Check if face is neutral but arousal is high
//        if emotionalState.primaryEmotion == .neutral && physiologicalState.arousalLevel > 0.6 {
//            masking = min(1.0, physiologicalState.arousalLevel * 1.5)
//        }
//        
//        // Check if face shows positive emotion but physiology suggests otherwise
//        if emotionalState.primaryEmotion == .happiness {
//            // High HRV typically indicates calm/positive state
//            // If HRV is low but face shows happiness, might be masking
//            let hrvNormalized = Float(physiologicalState.hrvMetrics.heartRateVariability / 100.0) // Normalize to 0-1 range
//            if hrvNormalized < 0.3 && physiologicalState.arousalLevel > 0.7 {
//                masking = max(masking, 0.8)
//            }
//        }
//        
//        // Check for mismatch between primary and secondary emotions
//        if let secondaryEmotion = emotionalState.secondaryEmotions.max(by: { $0.value < $1.value })?.key,
//           let secondaryIntensity = emotionalState.secondaryEmotions[secondaryEmotion] {
//            
//            if secondaryIntensity > emotionalState.primaryIntensity * 0.8 {
//                // Secondary emotion is almost as strong as primary
//                masking = max(masking, 0.4)
//            }
//        }
//        
//        // Calculate general mismatch between facial and physiological indicators
//        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
//        masking = max(masking, 1.0 - coherence)
//        
//        return min(1.0, masking)
//    }
    
    private func calculateDissociationIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Dissociation indicators include:
        // 1. Low facial expressivity (neutral, flat affect)
        // 2. Freeze response in motion metrics
        // 3. Disconnection between face and physiological response
        
        var dissociationScore: Float = 0.0
        
        // Check for flat affect (low intensity neutral face)
        if emotionalState.primaryEmotion == .neutral && emotionalState.primaryIntensity < 0.3 {
            dissociationScore += 0.4
        }
        
        // Check for freeze response
        if physiologicalState.motionMetrics.freezeIndex > 0.7 {
            dissociationScore += 0.4
        }
        
        // Check for characteristic dissociative HRV pattern
        // (in a real implementation, this would use more sophisticated analysis)
        if physiologicalState.hrvMetrics.heartRateVariability < 20 &&
           physiologicalState.hrvMetrics.heartRate < 70 {
            dissociationScore += 0.3
        }
        
        // Check for lack of micro-expressions
        if emotionalState.microExpressions.isEmpty && emotionalState.confidence > 0.7 {
            dissociationScore += 0.2
        }
        
        // Factor in coherence (low coherence can indicate dissociation)
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        if coherence < 0.3 {
            dissociationScore += 0.3 * (1.0 - coherence)
        }
        
        return min(1.0, dissociationScore)
    }
    
    private func determineDominantEmotion(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> EmotionType {
        // In most cases, use the facial emotion as the primary indicator
        if emotionalState.confidence > 0.7 && emotionalState.primaryIntensity > 0.5 {
            return emotionalState.primaryEmotion
        }
        
        // If facial confidence is low but physiology shows clear patterns
        if emotionalState.confidence < 0.4 && physiologicalState.qualityIndex > 0.7 {
            // Infer emotion from physiological state
            if physiologicalState.arousalLevel > 0.8 {
                if physiologicalState.motionMetrics.freezeIndex > 0.7 {
                    return .fear // High arousal with freeze response
                } else {
                    // Could be anger, fear, or excitement - default to more common
                    return .anger
                }
            } else if physiologicalState.arousalLevel < 0.3 {
                // Low arousal could be sadness, neutral, or contentment
                return .sadness
            }
        }
        
        // Check for dissociation specifically
        if calculateDissociationIndex(emotionalState: emotionalState, physiologicalState: physiologicalState) > 0.7 {
            return .dissociation
        }
        
        // Default to facial emotion even if confidence is lower
        return emotionalState.primaryEmotion
    }
    
    private func calculateEmotionalIntensity(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Blend facial intensity with physiological arousal
        let facialIntensity = emotionalState.primaryIntensity
        let physiologicalIntensity = physiologicalState.arousalLevel
        
        // Weight based on confidence and quality
        let facialWeight = emotionalState.confidence
        let physiologicalWeight = physiologicalState.qualityIndex
        
        let totalWeight = facialWeight + physiologicalWeight
        if totalWeight > 0 {
            return (facialIntensity * facialWeight + physiologicalIntensity * physiologicalWeight) / totalWeight
        } else {
            return (facialIntensity + physiologicalIntensity) / 2
        }
    }
    
    private func determineRegulationState(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> RegulationState {
        // Assess regulation based on coherence and physiological indicators
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        let arousal = physiologicalState.arousalLevel
        
        // Check HRV as key regulation indicator
        let hrvNormalized = Float(min(100, physiologicalState.hrvMetrics.heartRateVariability) / 100.0)
        
        // High HRV typically indicates good regulation
        if hrvNormalized > 0.6 && coherence > 0.6 {
            return .regulated
        }
        
        // Very high arousal with low HRV indicates dysregulation
        if arousal > 0.8 && hrvNormalized < 0.3 {
            return .severeDysregulation
        }
        
        // Moderate dysregulation
        if arousal > 0.6 && hrvNormalized < 0.4 {
            return .moderateDysregulation
        }
        
        // Mild dysregulation
        if arousal > 0.5 && hrvNormalized < 0.5 {
            return .mildDysregulation
        }
        
        // Default to regulated
        return .regulated
    }
    
    private func calculateDataQuality(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> DataQuality {
        // Combine face detection quality and physiological data quality
        let faceQuality = emotionalState.faceDetectionQuality
        let bioQuality = physiologicalState.qualityIndex
        
        if faceQuality == .noFace || bioQuality < 0.2 {
            return .invalid
        }
        
        if (faceQuality == .excellent && bioQuality > 0.8) ||
           (faceQuality == .good && bioQuality > 0.9) {
            return .excellent
        }
        
        if (faceQuality == .excellent && bioQuality > 0.6) ||
           (faceQuality == .good && bioQuality > 0.7) ||
           (faceQuality == .fair && bioQuality > 0.8) {
            return .good
        }
        
        if (faceQuality == .poor && bioQuality < 0.5) ||
           (faceQuality == .fair && bioQuality < 0.4) {
            return .poor
        }
        
        return .fair
    }
    
    private func detectStateChanges(from previousState: IntegratedEmotionalState?, to currentState: IntegratedEmotionalState) -> EmotionalStateChange {
        guard let previous = previousState else {
            // First state, treat as significant by default
            return EmotionalStateChange(
                from: currentState, // No previous state, use current as placeholder
                to: currentState,
                emotionChanged: true,
                intensityChanged: true,
                arousalChanged: true,
                coherenceChanged: true,
                dissociationChanged: true,
                regulationChanged: true,
                isSignificant: true
            )
        }
        
        // Check for significant changes
        let emotionChanged = previous.dominantEmotion != currentState.dominantEmotion
        let intensityChanged = abs(previous.emotionalIntensity - currentState.emotionalIntensity) > 0.25
        let arousalChanged = abs(previous.arousalLevel - currentState.arousalLevel) > 0.2
        let coherenceChanged = abs(previous.coherenceIndex - currentState.coherenceIndex) > 0.2
        let dissociationChanged = abs(previous.dissociationIndex - currentState.dissociationIndex) > 0.2
        let regulationChanged = previous.emotionalRegulation != currentState.emotionalRegulation
        
        // Determine if change is significant enough to trigger response
        let isSignificant = emotionChanged ||
                           intensityChanged ||
                           regulationChanged ||
                           (dissociationChanged && currentState.dissociationIndex > 0.5) ||
                           (arousalChanged && currentState.arousalLevel > 0.7)
        
        return EmotionalStateChange(
            from: previous,
            to: currentState,
            emotionChanged: emotionChanged,
            intensityChanged: intensityChanged,
            arousalChanged: arousalChanged,
            coherenceChanged: coherenceChanged,
            dissociationChanged: dissociationChanged,
            regulationChanged: regulationChanged,
            isSignificant: isSignificant
        )
    }
}

struct EmotionalStateChange {
    let from: IntegratedEmotionalState
    let to: IntegratedEmotionalState
    let emotionChanged: Bool
    let intensityChanged: Bool
    let arousalChanged: Bool
    let coherenceChanged: Bool
    let dissociationChanged: Bool
    let regulationChanged: Bool
    let isSignificant: Bool
}
