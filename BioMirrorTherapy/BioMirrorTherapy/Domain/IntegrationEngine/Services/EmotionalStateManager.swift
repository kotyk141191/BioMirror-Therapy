//
//  EmotionalStateManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

// Domain/IntegrationEngine/Services/EmotionalStateManager.swift

import Foundation
import Combine
import CoreData

class EmotionalStateManager {
    // MARK: - Singleton
    
    static let shared = EmotionalStateManager()
    
    // MARK: - Properties
    
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    private let persistenceService: PersistenceService
    
    private var facialStateSubscription: AnyCancellable?
    private var biometricStateSubscription: AnyCancellable?
    
    private var latestFacialState: EmotionalState?
    private var latestPhysiologicalState: PhysiologicalState?
    
    // Internal timer for state integration
    private var integrationTimer: Timer?
    private let integrationInterval: TimeInterval = 0.2 // 5Hz integration rate
    
    // Publisher for integrated state
    private let integratedStateSubject = PassthroughSubject<IntegratedEmotionalState, Never>()
    
    // State history
    private var stateHistory: [IntegratedEmotionalState] = []
    private let maxHistorySize = 1000 // Keep last 1000 states
    
    // Additional analyzers
    private let coherenceAnalyzer = EmotionalCoherenceAnalyzer()
    private let dissociationDetector = DissociationDetector()
    
    // Current session
    private var currentSessionId: String?
    
    // State tracking
    private var isRunning = false
    private var isPaused = false
    
    // MARK: - Public Properties
    
    /// Publisher for integrated emotional states
    var integratedStatePublisher: AnyPublisher<IntegratedEmotionalState, Never> {
        return integratedStateSubject.eraseToAnyPublisher()
    }
    
    /// Most recent integrated emotional state
    private(set) var currentIntegratedState: IntegratedEmotionalState?
    
    /// Current dissociation status
    private(set) var dissociationStatus: DissociationStatus = .none
    
    // MARK: - Initialization
    
    private init() {
        // Resolve services from DI container
        self.facialAnalysisService = ServiceLocator.shared.resolve()
        self.biometricAnalysisService = ServiceLocator.shared.resolve()
        self.persistenceService = ServiceLocator.shared.resolve()
    }
    
    // For testing and dependency injection
    init(facialAnalysisService: FacialAnalysisService,
         biometricAnalysisService: BiometricAnalysisService,
         persistenceService: PersistenceService) {
        self.facialAnalysisService = facialAnalysisService
        self.biometricAnalysisService = biometricAnalysisService
        self.persistenceService = persistenceService
    }
    
    // MARK: - Public Methods
    
    /// Start emotional state integration
    /// - Parameter sessionId: Optional session ID to associate with states
    func startIntegration(sessionId: String? = nil) {
        guard !isRunning else { return }
        
        // Store session ID
        currentSessionId = sessionId
        
        // Reset state
        isPaused = false
        
        // Subscribe to facial analysis updates
        facialStateSubscription = facialAnalysisService.emotionalStatePublisher
            .sink { [weak self] emotionalState in
                self?.latestFacialState = emotionalState
            }
        
        // Subscribe to biometric analysis updates
        biometricStateSubscription = biometricAnalysisService.physiologicalStatePublisher
            .sink { [weak self] physiologicalState in
                self?.latestPhysiologicalState = physiologicalState
            }
        
        // Start integration timer
        setupIntegrationTimer()
        
        isRunning = true
    }
    
    /// Stop emotional state integration
    func stopIntegration() {
        guard isRunning else { return }
        
        // Cancel subscriptions
        facialStateSubscription?.cancel()
        facialStateSubscription = nil
        
        biometricStateSubscription?.cancel()
        biometricStateSubscription = nil
        
        // Stop integration timer
        integrationTimer?.invalidate()
        integrationTimer = nil
        
        // Clear session ID
        currentSessionId = nil
        
        isRunning = false
        isPaused = false
    }
    
    /// Pause emotional state integration
    func pauseIntegration() {
        guard isRunning && !isPaused else { return }
        
        // Stop timer but keep subscriptions
        integrationTimer?.invalidate()
        integrationTimer = nil
        
        isPaused = true
    }
    
    /// Resume emotional state integration
    func resumeIntegration() {
        guard isRunning && isPaused else { return }
        
        // Restart timer
        setupIntegrationTimer()
        
        isPaused = false
    }
    
    /// Get recent emotional state history
    /// - Parameter limit: Maximum number of states to return
    /// - Returns: Array of recent integrated emotional states
    func getRecentStates(limit: Int = 10) -> [IntegratedEmotionalState] {
        let count = min(limit, stateHistory.count)
        return Array(stateHistory.suffix(count))
    }
    
    /// Get the dominant emotion over a time period
    /// - Parameter seconds: Time period in seconds
    /// - Returns: Dominant emotion type and its prevalence
    func getDominantEmotion(over seconds: TimeInterval) -> (emotion: EmotionType, prevalence: Float)? {
        // Calculate cutoff time
        let cutoffTime = Date().addingTimeInterval(-seconds)
        
        // Filter recent states
        let recentStates = stateHistory.filter { $0.timestamp > cutoffTime }
        
        // Count occurrences of each emotion
        var emotionCounts: [EmotionType: Int] = [:]
        for state in recentStates {
            let emotion = state.dominantEmotion
            emotionCounts[emotion, default: 0] += 1
        }
        
        // Find most common emotion
        guard let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key,
              !recentStates.isEmpty else {
            return nil
        }
        
        // Calculate prevalence
        let prevalence = Float(emotionCounts[dominantEmotion] ?? 0) / Float(recentStates.count)
        
        return (dominantEmotion, prevalence)
    }
    
    /// Get the average coherence over a time period
    /// - Parameter seconds: Time period in seconds
    /// - Returns: Average coherence index
    func getAverageCoherence(over seconds: TimeInterval) -> Float? {
        // Calculate cutoff time
        let cutoffTime = Date().addingTimeInterval(-seconds)
        
        // Filter recent states
        let recentStates = stateHistory.filter { $0.timestamp > cutoffTime }
        guard !recentStates.isEmpty else { return nil }
        
        // Calculate average coherence
        let totalCoherence = recentStates.reduce(0.0) { $0 + $1.coherenceIndex }
        return totalCoherence / Float(recentStates.count)
    }
    
    /// Get the emotional volatility over a time period
    /// - Parameter seconds: Time period in seconds
    /// - Returns: Volatility index (0.0-1.0)
    func getEmotionalVolatility(over seconds: TimeInterval) -> Float? {
        // Calculate cutoff time
        let cutoffTime = Date().addingTimeInterval(-seconds)
        
        // Filter recent states
        let recentStates = stateHistory.filter { $0.timestamp > cutoffTime }
        guard recentStates.count > 2 else { return nil }
        
        // Calculate emotion changes
        var changes = 0
        var previousEmotion = recentStates.first?.dominantEmotion
        
        for state in recentStates.dropFirst() {
            if state.dominantEmotion != previousEmotion {
                changes += 1
                previousEmotion = state.dominantEmotion
            }
        }
        
        // Calculate volatility as ratio of changes to opportunities for change
        return Float(changes) / Float(recentStates.count - 1)
    }
    
    // MARK: - Private Methods
    
    private func setupIntegrationTimer() {
        integrationTimer?.invalidate()
        
        // Create timer that integrates emotional and physiological data
        integrationTimer = Timer.scheduledTimer(withTimeInterval: integrationInterval, repeats: true) { [weak self] _ in
            self?.performIntegration()
        }
    }
    
    private func performIntegration() {
        // Check if we have both required states
        guard let facialState = latestFacialState,
              let physiologicalState = latestPhysiologicalState else {
            return
        }
        
        // Create integrated state by combining facial and physiological data
        let integratedState = createIntegratedState(
            emotionalState: facialState,
            physiologicalState: physiologicalState
        )
        
        // Update internal state
        currentIntegratedState = integratedState
        
        // Add to history
        stateHistory.append(integratedState)
        
        // Limit history size
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst(stateHistory.count - maxHistorySize)
        }
        
        // Analyze for dissociation
        dissociationStatus = dissociationDetector.processDissociationState(integratedState)
        
        // Save to database if in session
        if let sessionId = currentSessionId {
            saveStateToDatabase(integratedState, sessionId: sessionId)
        }
        
        // Notify subscribers
        integratedStateSubject.send(integratedState)
    }
    
    private func createIntegratedState(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> IntegratedEmotionalState {
        // Calculate coherence index - how well facial expressions match physiological state
        let coherenceIndex = coherenceAnalyzer.calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate emotional masking - when face is neutral but physiology shows activation
        let emotionalMaskingIndex = coherenceAnalyzer.calculateEmotionalMaskingIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
        // Calculate dissociation index - signs of emotional numbing or disconnection
        let dissociationIndex = coherenceAnalyzer.calculateDissociationIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
        
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
        if coherenceAnalyzer.calculateDissociationIndex(emotionalState: emotionalState, physiologicalState: physiologicalState) > 0.7 {
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
        let coherence = coherenceAnalyzer.calculateCoherenceIndex(emotionalState: emotionalState, physiologicalState: physiologicalState)
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
    
    private func saveStateToDatabase(_ state: IntegratedEmotionalState, sessionId: String) {
        // Create background context for saving
        let context = persistenceService.createBackgroundContext()
        
        context.perform {
            do {
                // Create new emotional state entity
                let entityDescription = NSEntityDescription.entity(forEntityName: "EmotionalState", in: context)!
                let emotionalState = NSManagedObject(entity: entityDescription, insertInto: context)
                
                // Set properties
                emotionalState.setValue(UUID().uuidString, forKey: "id")
                emotionalState.setValue(state.timestamp, forKey: "timestamp")
                emotionalState.setValue(state.dominantEmotion.rawValue, forKey: "dominantEmotion")
                emotionalState.setValue(state.emotionalIntensity, forKey: "emotionalIntensity")
                emotionalState.setValue(state.arousalLevel, forKey: "arousalLevel")
                emotionalState.setValue(state.coherenceIndex, forKey: "coherenceIndex")
                emotionalState.setValue(state.dissociationIndex, forKey: "dissociationIndex")
                emotionalState.setValue(state.dataQuality.rawValue, forKey: "dataQuality")
                emotionalState.setValue(sessionId, forKey: "sessionId")
                emotionalState.setValue(true, forKey: "needsSync") // Mark for synchronization
                
                // Save raw data (optional, can be large)
                // We could save the complete state data for deeper analysis if needed
                // emotionalState.setValue(rawData, forKey: "rawData")
                
                // Save context
                try context.save()
            } catch {
                print("Failed to save emotional state: \(error)")
            }
        }
    }
}

// Supporting helper class for analysis
private class EmotionalCoherenceAnalyzer {
    // Calculate coherence between facial and physiological states
    func calculateCoherenceIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
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
    
    // Calculate emotional masking index
    func calculateEmotionalMaskingIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
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
    
    // Calculate dissociation index
    func calculateDissociationIndex(emotionalState: EmotionalState, physiologicalState: PhysiologicalState) -> Float {
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
}
