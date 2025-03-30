//
//  EmotionalCoherenceAnalyzer.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class EmotionalCoherenceAnalyzer: EmotionalIntegrationService {
    // MARK: - Properties
    
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    
    private var emotionalStateSubscription: AnyCancellable?
    private var physiologicalStateSubscription: AnyCancellable?
    
    private var latestEmotionalState: EmotionalState?
    private var latestPhysiologicalState: PhysiologicalState?
    
    private let integratedStateSubject = PassthroughSubject<IntegratedEmotionalState, Never>()
    private var _currentIntegratedState: IntegratedEmotionalState?
    
    private var integrationTimer: Timer?
    private let integrationInterval: TimeInterval = 0.2 // 5Hz integration rate
    
    private var isRunning = false
    
    // MARK: - EmotionalIntegrationService Protocol
    
    var currentIntegratedState: IntegratedEmotionalState? {
        return _currentIntegratedState
    }
    
    var integratedStatePublisher: AnyPublisher<IntegratedEmotionalState, Never> {
        return integratedStateSubject.eraseToAnyPublisher()
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
    
    func stopIntegration() {
        guard isRunning else { return }
        
        // Cancel subscriptions
        emotionalStateSubscription?.cancel()
        physiologicalStateSubscription?.cancel()
        
        // Stop integration timer
        integrationTimer?.invalidate()
        integrationTimer = nil
        
        isRunning = false
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
        
        // Create timer that integrates emotional and physiological data
        integrationTimer = Timer.scheduledTimer(withTimeInterval: integrationInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let emotionalState = self.latestEmotionalState,
                  let physiologicalState = self.latestPhysiologicalState else { return }
            
            // Integrate data and calculate metrics
            let integratedState = self.integrateData(
                emotionalState: emotionalState,
                physiologicalState: physiologicalState
            )
            
            self._currentIntegratedState = integratedState
            self.integratedStateSubject.send(integratedState)
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
    
    private func calculateCoherenceIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // This is a simplified placeholder implementation
        // In a real app, this would use more sophisticated algorithms to correlate
        // facial expressions with physiological arousal
        
        // For common emotions, check if physiological state matches expected pattern
        let facialEmotion = emotionalState.primaryEmotion
        let arousal = physiologicalState.arousalLevel
        
        // Check if arousal level matches expected pattern for the emotion
        var coherence: Float = 0.5 // Neutral starting point
        
        switch facialEmotion {
        case .happiness, .anger, .surprise:
            // High arousal emotions - higher coherence when arousal is high
            coherence = min(1.0, 0.5 + Float(arousal))
            
        case .sadness, .disgust:
            // Mixed arousal emotions - moderate coherence is best
            coherence = 1.0 - abs(Float(arousal) - 0.5) * 2
            
        case .fear:
            // High arousal emotion, but can also include freeze response
            if physiologicalState.motionMetrics.freezeIndex > 0.6 {
                // Fear with freeze - high coherence
                coherence = 0.8 + min(0.2, Float(arousal) * 0.2)
            } else {
                // Fear with fight/flight - high coherence with high arousal
                coherence = min(1.0, 0.4 + Float(arousal) * 0.6)
            }
            
        case .neutral:
            // Neutral should have low arousal for high coherence
            coherence = 1.0 - min(1.0, Float(arousal) * 2)
            
        default:
            // Other emotions - use moderate coherence
            coherence = 0.5
        }
        
        // Factor in confidence of facial expression detection
        coherence *= emotionalState.confidence
        
        // Factor in quality of physiological data
        coherence *= physiologicalState.qualityIndex
        
        return coherence
    }
    
    private func calculateEmotionalMaskingIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
        // Emotional masking occurs when the face appears neutral but physiology shows activation
        // or when facial emotion doesn't match physiological state
        
        // Check if face is neutral but arousal is high
        if emotionalState.primaryEmotion == .neutral && physiologicalState.arousalLevel > 0.6 {
            return min(1.0, physiologicalState.arousalLevel * 1.5)
        }
        
        // Check if face shows positive emotion but physiology suggests otherwise
        if emotionalState.primaryEmotion == .happiness {
            // High HRV typically indicates calm/positive state
            // If HRV is low but face shows happiness, might be masking
            let hrvNormalized = Float(physiologicalState.hrvMetrics.heartRateVariability / 100.0) // Normalize to 0-1 range
            if hrvNormalized < 0.3 && physiologicalState.arousalLevel > 0.7 {
                return 0.8
            }
        }
        
        // Calculate general mismatch between facial and physiological indicators
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        let masking = 1.0 - coherence
        
        return masking
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
        // (in a real implementation, this would use more sophisticated analysis)
        if physiologicalState.hrvMetrics.heartRateVariability < 20 &&
           physiologicalState.hrvMetrics.heartRate < 70 {
            dissociationScore += 0.3
        }
        
        // Factor in coherence (low coherence can indicate dissociation)
        let coherence = calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        if coherence < 0.3 {
            dissociationScore += 0.3 * (1.0 - coherence)
        }
        
        // Cap at 1.0
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
}
