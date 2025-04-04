//
//  AdaptiveResponseGenerator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class AdaptiveResponseGenerator: TherapeuticResponseService {
    // MARK: - Properties
    
    private let emotionalIntegrationService: EmotionalIntegrationService
    private let safetyMonitor: SafetyMonitor
    
    private var preferences: ResponsePreferences = .default
    private var activeSessions: [UUID: TherapeuticSession] = [:]
    
    private var titrationLevel: Float = 0.2 // How much to modify mirrored emotions
    private var responseTimers: [UUID: Timer] = [:] // Track response timers by session ID
    
    // MARK: - Initialization
    
    init(emotionalIntegrationService: EmotionalIntegrationService, safetyMonitor: SafetyMonitor) {
        self.emotionalIntegrationService = emotionalIntegrationService
        self.safetyMonitor = safetyMonitor
    }
    
    // MARK: - TherapeuticResponseService Methods
    
    func startSession(phase: SessionPhase = .connection) -> TherapeuticSession {
        let session = TherapeuticSession(phase: phase)
        activeSessions[session.id] = session
        return session
    }
    
    func endSession(_ session: TherapeuticSession) {
        session.endSession()
        
        // Stop any response timers for this session
        if let timer = responseTimers[session.id] {
            timer.invalidate()
            responseTimers.removeValue(forKey: session.id)
        }
        
        activeSessions.removeValue(forKey: session.id)
    }
    
    func generateResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Update session with new state
        session.addEmotionalState(state)
        
        // Check for safety concerns first
        if safetyMonitor.needsIntervention(state) {
            return generateSafetyResponse(for: state, in: session)
        }
        
        // Check for dissociation - highest priority after safety
        if state.dissociationIndex > 0.6 {
            let dissociationStatus = DissociationStatus.active(
                severity: determineDissociationSeverity(state.dissociationIndex),
                duration: estimateDissociationDuration(for: session),
                intensity: state.dissociationIndex
            )
            return generateGroundingResponse(for: dissociationStatus, in: session)
        }
        
        // Generate appropriate therapeutic response based on session phase and emotional state
        switch session.sessionPhase {
        case .connection:
            return generateConnectionResponse(for: state, in: session)
        case .awareness:
            return generateAwarenessResponse(for: state, in: session)
        case .integration:
            return generateIntegrationResponse(for: state, in: session)
        case .regulation:
            return generateRegulationResponse(for: state, in: session)
        case .transfer:
            return generateTransferResponse(for: state, in: session)
        }
    }
    
//    func generateGroundingResponse(for dissociationStatus: DissociationStatus, in session: TherapeuticSession) -> TherapeuticResponse {
//        // Generate grounding response based on dissociation severity
//        
//        // Get severity details
//        let severity: DissociationSeverity
//        var intensity: Float = 0.0
//        
//        switch dissociationStatus {
//        case .active(let activeSeverity, _, let activeIntensity):
//            severity = activeSeverity
//            intensity = activeIntensity
//        case .recent(let recentSeverity, _, let recentIntensity):
//            severity = recentSeverity
//            intensity = recentIntensity
//        case .none:
//            // Shouldn't happen, but provide a default mild grounding response
//            return createGenericGroundingResponse(in: session)
//        }
//        
//        // Select appropriate technique based on severity
//        let technique = selectGroundingTechnique(for: severity, intensity: intensity)
//        
//        // Create verbal instruction
//        let verbal: String
//        switch technique {
//        case .breathing:
//            verbal = "Let's take a deep breath together. Breathe in... and out..."
//        case .sensory:
//            verbal = "Can you notice something you can see right now? What colors do you notice?"
//        case .movement:
//            verbal = "Let's gently move our hands. Can you wiggle your fingers?"
//        case .cognitive:
//            verbal = "Let's count together. One, two, three..."
//        case .naming:
//            verbal = "Can you name something you can see that is blue?"
//        }
//        
//        // Create character action
//        let action: CharacterAction
//        switch technique {
//        case .breathing:
//            action = .breathing(speed: 0.3, depth: 0.8)
//        case .sensory, .naming:
//            action = .attention(focus: .direct)
//        case .movement:
//            action = .bodyMovement(type: .gentle, intensity: 0.6)
//        case .cognitive:
//            action = .facialExpression(emotion: .interest, intensity: 0.7)
//        }
//        
//        // Set intervention level based on severity
//        let interventionLevel: InterventionLevel
//        switch severity {
//        case .potential, .mild:
//            interventionLevel = .minimal
//        case .moderate:
//            interventionLevel = .moderate
//        case .severe:
//            interventionLevel = .intensive
//        }
//        
//        return TherapeuticResponse(
//            timestamp: Date(),
//            responseType: .grounding,
//            characterEmotionalState: .neutral,
//            characterEmotionalIntensity: 0.3,
//            characterAction: action,
//            verbal: verbal,
//            nonverbal: "Maintains calm presence with grounding focus",
//            interventionLevel: interventionLevel,
//            targetEmotionalState: .neutral,
//            duration: 15.0
//        )
//    }
    
    func setResponsePreferences(_ preferences: ResponsePreferences) {
        self.preferences = preferences
        
        // Update titration level based on mirroring sensitivity
        titrationLevel = 0.4 * (1.0 - preferences.emotionalMirroringSensitivity)
    }
    
    // MARK: - Private Response Generation Methods
    
    private func generateSafetyResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Create a calming response for safety situations
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .regulation,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: .breathing(speed: 0.3, depth: 0.8),
            verbal: "Let's take a moment to breathe together. Slow and gentle.",
            nonverbal: "Calm, steady breathing with gentle movements",
            interventionLevel: .intensive,
            targetEmotionalState: .neutral,
            duration: 20.0
        )
    }
    
    private func generateConnectionResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In connection phase, focus on building rapport with gentle mirroring
        
        // Start with basic mirroring but with reduced intensity
        let mirroredEmotion = state.dominantEmotion
        let mirroredIntensity = state.emotionalIntensity * 0.7
        
        // For negative emotions, reduce intensity further
        let characterIntensity: Float
        switch mirroredEmotion {
        case .sadness, .anger, .fear, .disgust:
            characterIntensity = mirroredIntensity * 0.5
        default:
            characterIntensity = mirroredIntensity
        }
        
        // Generate verbal response based on emotion
        let verbal = generateVerbalConnectionResponse(for: mirroredEmotion)
        
        // Create appropriate character action
        let action = CharacterAction.facialExpression(
            emotion: mirroredEmotion,
            intensity: characterIntensity
        )
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .mirroring,
            characterEmotionalState: mirroredEmotion,
            characterEmotionalIntensity: characterIntensity,
            characterAction: action,
            verbal: verbal,
            nonverbal: "Gentle mirroring of emotional state",
            interventionLevel: .minimal,
            targetEmotionalState: nil,
            duration: 5.0
        )
    }
    
    // Complete implementation for generateGroundingResponse in AdaptiveResponseGenerator

    func createGenericGroundingResponse(in session: TherapeuticSession) -> TherapeuticResponse {
        // Generate a structured response for grounding
        let verbal = "Let's take a moment to breathe together. Notice how the air feels coming in and out."
        
        // Select appropriate action based on session phase
        let action: CharacterAction
        switch session.sessionPhase {
        case .connection, .awareness:
            // Gentle approach for early phases
            action = .breathing(speed: 0.3, depth: 0.5)
        case .integration, .regulation:
            // More structured approach for later phases
            action = .breathing(speed: 0.4, depth: 0.7)
        case .transfer:
            // Encourage self-regulation
            action = .attention(focus: .direct)
        }
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .grounding,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: action,
            verbal: verbal,
            nonverbal: "Calm, grounding presence with steady breathing",
            interventionLevel: .moderate,
            targetEmotionalState: .neutral,
            duration: 15.0
        )
    }
    
    private func generateAwarenessResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In awareness phase, help child recognize and name emotions
        
        // Mirror emotion with slight titration (adjustment)
        let emotion = state.dominantEmotion
        let intensity = state.emotionalIntensity
        
        // Create verbal response for emotion awareness
        let verbal = generateVerbalAwarenessResponse(for: emotion, intensity: intensity)
        
        // Create character action
        let action = CharacterAction.facialExpression(
            emotion: emotion,
            intensity: intensity * (1.0 - titrationLevel)
        )
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .exploration,
            characterEmotionalState: emotion,
            characterEmotionalIntensity: intensity * (1.0 - titrationLevel),
            characterAction: action,
            verbal: verbal,
            nonverbal: "Curious and attentive posture",
            interventionLevel: .moderate,
            targetEmotionalState: emotion, // Reinforce accurate recognition
            duration: 10.0
        )
    }
    
    private func generateIntegrationResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In integration phase, help connect facial and physiological aspects of emotion
        
        // Check if there's emotional masking (face doesn't match physiology)
        if state.emotionalMaskingIndex > 0.6 {
            // Address the masking by gently bringing attention to body
            let verbal = "I wonder if your body is feeling something different? " +
                        "Sometimes our face shows one thing, but our body feels another."
            
            // Character shows a blend of facial emotion and physiological state
            let facialEmotion = state.emotionalState.primaryEmotion
            let physiologicalEmotion = inferEmotionFromPhysiology(state.physiologicalState)
            
            // Use the physiological emotion with moderate intensity
            let characterEmotion = physiologicalEmotion
            let characterIntensity: Float = 0.6
            
            let action = CharacterAction.facialExpression(
                emotion: characterEmotion,
                intensity: characterIntensity
            )
            
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .mirroring,
                characterEmotionalState: characterEmotion,
                characterEmotionalIntensity: characterIntensity,
                characterAction: action,
                verbal: verbal,
                nonverbal: "Attentive to both facial and bodily cues",
                interventionLevel: .moderate,
                targetEmotionalState: physiologicalEmotion,
                duration: 12.0
            )
        } else {
            // For coherent emotions, reinforce the connection
            let verbal = "I can see you're feeling \(state.dominantEmotion.rawValue.lowercased()) " +
                        "in your face and your body."
            
            let action = CharacterAction.facialExpression(
                emotion: state.dominantEmotion,
                intensity: state.emotionalIntensity * 0.8
            )
            
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .validation,
                characterEmotionalState: state.dominantEmotion,
                characterEmotionalIntensity: state.emotionalIntensity * 0.8,
                characterAction: action,
                verbal: verbal,
                nonverbal: "Matching emotional expression",
                interventionLevel: .minimal,
                targetEmotionalState: state.dominantEmotion,
                duration: 8.0
            )
        }
    }
    
    private func generateRegulationResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In regulation phase, help modulate intense emotions
        
        // Check if the child is dysregulated
        if state.emotionalRegulation != .regulated && state.emotionalIntensity > 0.7 {
            // Generate regulatory response
            let emotion = state.dominantEmotion
            
            // Character shows slightly calmer version of the emotion
            let characterEmotion = emotion
            let characterIntensity = max(0.3, state.emotionalIntensity - 0.3)
            
            // Select regulation strategy based on emotion
            let (verbal, action) = selectRegulationStrategy(for: emotion, intensity: state.emotionalIntensity)
            
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .regulation,
                characterEmotionalState: characterEmotion,
                characterEmotionalIntensity: characterIntensity,
                characterAction: action,
                verbal: verbal,
                nonverbal: "Calming presence with regulatory focus",
                interventionLevel: .significant,
                targetEmotionalState: emotion, // Same emotion but regulated
                duration: 15.0
            )
        } else {
            // Child is already regulated - reinforce
            let verbal = "You're handling your feelings really well right now."
            
            let action = CharacterAction.facialExpression(
                emotion: .happiness,
                intensity: 0.6
            )
            
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .celebration,
                characterEmotionalState: .happiness,
                characterEmotionalIntensity: 0.6,
                characterAction: action,
                verbal: verbal,
                nonverbal: "Warm, affirming presence",
                interventionLevel: .minimal,
                targetEmotionalState: state.dominantEmotion,
                duration: 5.0
            )
        }
    }
    
    private func generateTransferResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In transfer phase, connect skills to real-world situations
        
        // Start with basic mirroring
        let emotion = state.dominantEmotion
        let intensity = state.emotionalIntensity
        
        // Create verbal response focused on applying skills
        let verbal = generateTransferVerbalResponse(for: emotion, regulation: state.emotionalRegulation)
        
        // Create character action
        let action = CharacterAction.facialExpression(
            emotion: emotion,
            intensity: intensity * 0.7
        )
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .transition,
            characterEmotionalState: emotion,
            characterEmotionalIntensity: intensity * 0.7,
            characterAction: action,
            verbal: verbal,
            nonverbal: "Encouraging stance with real-world focus",
            interventionLevel: .moderate,
            targetEmotionalState: emotion,
            duration: 10.0
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateVerbalConnectionResponse(for emotion: EmotionType) -> String {
        // Generate appropriate verbal response for connection phase
        switch emotion {
        case .happiness:
            return "I see your smile! It's nice to be happy together."
        case .sadness:
            return "I notice you might be feeling a bit sad. That's okay."
        case .anger:
            return "I can see you might be feeling frustrated. I understand."
        case .fear:
            return "It's okay if you're feeling worried. I'm here with you."
        case .surprise:
            return "Oh! That seemed surprising to you."
        case .neutral:
            return "It's nice to be here together."
        default:
            return "I'm here with you."
        }
    }
    
    private func generateVerbalAwarenessResponse(for emotion: EmotionType, intensity: Float) -> String {
        // Generate verbal response for awareness phase
        let intensityWord = intensity > 0.7 ? "very " : (intensity > 0.4 ? "" : "a little ")
        
        switch emotion {
        case .happiness:
            return "I notice you're feeling \(intensityWord)happy. I can see it in your smile!"
        case .sadness:
            return "I see that you might be feeling \(intensityWord)sad. I can tell from your expression."
        case .anger:
            return "It looks like you're feeling \(intensityWord)frustrated or angry. I can see it in your eyebrows."
        case .fear:
            return "I notice you might be feeling \(intensityWord)worried or scared. I can see it in your eyes."
        case .surprise:
            return "You look \(intensityWord)surprised! I can tell from your wide eyes."
        case .disgust:
            return "It seems like you're feeling \(intensityWord)uncomfortable with something. I can see it in your expression."
        case .neutral:
            return "You're looking calm right now. How are you feeling inside?"
        default:
            return "I'm noticing your feelings. Can you tell me about them?"
        }
    }
    
    private func selectGroundingTechnique(for severity: DissociationSeverity, intensity: Float) -> GroundingTechnique {
        // First check user preferences
        let availableTechniques = preferences.preferredGroundingTechniques
        
        // Select appropriate technique based on severity
        switch severity {
        case .severe:
            // For severe dissociation, prioritize sensory and breathing techniques
            if availableTechniques.contains(.sensory) {
                return .sensory
            } else if availableTechniques.contains(.breathing) {
                return .breathing
            } else {
                return availableTechniques.first ?? .sensory
            }
            
        case .moderate:
            // For moderate dissociation, consider movement or breathing
            if availableTechniques.contains(.movement) {
                return .movement
            } else if availableTechniques.contains(.breathing) {
                return .breathing
            } else {
                return availableTechniques.first ?? .breathing
            }
            
        case .mild, .potential:
            // For mild dissociation, cognitive techniques can be effective
            if availableTechniques.contains(.cognitive) {
                return .cognitive
            } else if availableTechniques.contains(.naming) {
                return .naming
            } else {
                return availableTechniques.first ?? .naming
            }
        }
    }
    
    private func inferEmotionFromPhysiology(_ physiologicalState: PhysiologicalState) -> EmotionType {
        // Simplified inference of emotional state from physiological data
        let arousal = physiologicalState.arousalLevel
        let heartRate = physiologicalState.hrvMetrics.heartRate
        let freezeIndex = physiologicalState.motionMetrics.freezeIndex
        
        if freezeIndex > 0.7 {
            return .fear // High freeze response indicates fear
        }
        
        if arousal > 0.8 {
            // High arousal could be anger, fear, or excitement
            if heartRate > 100 {
                return .anger // High heart rate with high arousal suggests anger
            } else {
                return .fear // High arousal without very high heart rate might be fear
            }
        } else if arousal > 0.6 {
            return .surprise // Moderate-high arousal could be surprise
        } else if arousal < 0.3 {
            return .sadness // Low arousal often indicates sadness
        } else {
            return .neutral // Moderate arousal without other indicators
        }
    }
    
    private func selectRegulationStrategy(for emotion: EmotionType, intensity: Float) -> (String, CharacterAction) {
        // Select appropriate regulation strategy based on the emotion
        switch emotion {
        case .anger:
            let verbal = "I can see you're feeling really strong emotions. " +
                         "Let's take a deep breath together."
            let action = CharacterAction.breathing(speed: 0.3, depth: 0.8)
            return (verbal, action)
            
        case .fear:
            let verbal = "It's okay to feel scared sometimes. " +
                         "Let's find some calm together. What's one thing you can see right now?"
            let action = CharacterAction.attention(focus: .shared)
            return (verbal, action)
            
        case .sadness:
            let verbal = "It's okay to feel sad. " +
                         "I'm here with you. Would you like to take a gentle breath with me?"
            let action = CharacterAction.facialExpression(emotion: .sadness, intensity: 0.4)
            return (verbal, action)
            
        default:
            let verbal = "Let's notice how we're feeling right now. " +
                         "Can we take a moment to breathe together?"
            let action = CharacterAction.breathing(speed: 0.5, depth: 0.6)
            return (verbal, action)
        }
    }
    
    private func generateTransferVerbalResponse(for emotion: EmotionType, regulation: RegulationState) -> String {
        // Generate verbal response focused on real-world application
        switch emotion {
        case .happiness:
            return "You're feeling happy! What helps you feel this way outside our sessions too?"
            
        case .sadness:
            if regulation == .regulated {
                return "You're handling your sad feelings really well. What strategy could help you next time you feel sad at home or school?"
            } else {
                return "When you feel sad at home, what helps you feel a little better?"
            }
            
        case .anger:
            if regulation == .regulated {
                return "You're managing your strong feelings well. What could you do when you feel frustrated at school?"
            } else {
                return "When you feel angry outside our sessions, what might help you calm down?"
            }
            
        case .fear:
            return "When you feel scared at home or school, what could help you feel safer?"
            
        default:
            return "How could you use what we're learning together when you're at home or school?"
        }
    }
    
//    private func createGenericGroundingResponse(in session: TherapeuticSession) -> TherapeuticResponse {
//        // Create a gentle default grounding response
//        return TherapeuticResponse(
//            timestamp: Date(),
//            responseType: .grounding,
//            characterEmotionalState: .neutral,
//            characterEmotionalIntensity: 0.3,
//            characterAction: .breathing(speed: 0.4, depth: 0.6),
//            verbal: "Let's take a moment to notice where we are right now. Can you feel your feet on the ground?",
//            nonverbal: "Calm, grounding presence",
//            interventionLevel: .minimal,
//            targetEmotionalState: .neutral,
//            duration: 10.0
//        )
//    }
    
    private func determineDissociationSeverity(_ index: Float) -> DissociationSeverity {
        if index > 0.8 {
            return .severe
        } else if index > 0.6 {
            return .moderate
        } else {
            return .mild
        }
    }
    
    private func estimateDissociationDuration(for session: TherapeuticSession) -> TimeInterval {
        // Get recent emotional states
        let recentStates = session.emotionalStates.suffix(10)
        
        // Count how many consecutive states have high dissociation index
        var consecutiveCount = 0
        for state in recentStates.reversed() {
            if state.dissociationIndex > 0.5 {
                consecutiveCount += 1
            } else {
                break
            }
        }
        
        // Estimate duration based on consecutive states
        // Assuming states are collected at roughly 5Hz (0.2 seconds apart)
        return TimeInterval(consecutiveCount) * 0.2
    }
    
    // Add this method to AdaptiveResponseGenerator
    internal func generateGroundingResponse(for dissociationStatus: DissociationStatus, in session: TherapeuticSession) -> TherapeuticResponse {
        // Generate response based on dissociation severity
        let severity: DissociationSeverity
        let intensity: Float
        
        switch dissociationStatus {
        case .active(let activeSeverity, _, let activeIntensity):
            severity = activeSeverity
            intensity = activeIntensity
        case .recent(let recentSeverity, _, let recentIntensity):
            severity = recentSeverity
            intensity = recentIntensity
        case .none:
            return createGenericGroundingResponse(in: session)
        }
        
        // Select grounding technique based on severity
        let technique = selectGroundingTechnique(for: severity, intensity: intensity)
        
        // Create appropriate verbal response
        let verbal: String
        switch technique {
        case .breathing:
            verbal = "Let's take a deep breath together. Breathe in... and out..."
        case .sensory:
            verbal = "Can you notice something you can see right now? What colors do you notice?"
        case .movement:
            verbal = "Let's gently move our hands. Can you wiggle your fingers?"
        case .cognitive:
            verbal = "Let's count together. One, two, three..."
        case .naming:
            verbal = "Can you name something you can see that is blue?"
        }
        
        // Create appropriate character action
        let action: CharacterAction
        switch technique {
        case .breathing:
            action = .breathing(speed: 0.3, depth: 0.8)
        case .sensory, .naming:
            action = .attention(focus: .direct)
        case .movement:
            action = .bodyMovement(type: .gentle, intensity: 0.6)
        case .cognitive:
            action = .facialExpression(emotion: .interest, intensity: 0.7)
        }
        
        // Set intervention level based on severity
        let interventionLevel: InterventionLevel
        switch severity {
        case .potential, .mild:
            interventionLevel = .minimal
        case .moderate:
            interventionLevel = .moderate
        case .severe:
            interventionLevel = .intensive
        }
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .grounding,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: action,
            verbal: verbal,
            nonverbal: "Maintains calm presence with grounding focus",
            interventionLevel: interventionLevel,
            targetEmotionalState: .neutral,
            duration: 15.0
        )
    }

    // Add methods to implement safety protocols
    private func implementSafetyProtocols(_ integratedState: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse? {
        // Check for safety issues
        if integratedState.dissociationIndex > 0.8 {
            return generateSevereGroundingResponse(for: integratedState, in: session)
        }
        
        if integratedState.arousalLevel > 0.9 && integratedState.emotionalIntensity > 0.8 {
            return generateRegulationResponse(for: integratedState, in: session)
        }
        
        if integratedState.coherenceIndex < 0.2 {
            return generateCoherenceResponse(for: integratedState, in: session)
        }
        
        return nil
    }

    private func generateCoherenceResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // This response aims to help the child connect their facial expressions with their internal feelings
        // when there's a significant disconnect (low coherence)
        
        // Determine the source of incoherence - is it emotional masking or something else?
        let isEmotionalMasking = state.emotionalMaskingIndex > 0.6
        
        let verbal: String
        let action: CharacterAction
        
        if isEmotionalMasking {
            // Child's face doesn't show what they're feeling inside
            verbal = "I notice your face and your body might be feeling different things. It's okay to show how you really feel."
            action = CharacterAction.breathing(speed: 0.4, depth: 0.6)
        } else {
            // General incoherence - help connect mind and body
            verbal = "Let's take a moment to notice how your body is feeling and connect it with your face."
            action = CharacterAction.attention(focus: .shared)
        }
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .integration,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.5,
            characterAction: action,
            verbal: verbal,
            nonverbal: "Gentle, attentive presence focused on integration",
            interventionLevel: .moderate,
            targetEmotionalState: state.dominantEmotion,
            duration: 20.0
        )
    }
    
    private func generateSevereGroundingResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .grounding,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.2,
            characterAction: .breathing(speed: 0.2, depth: 0.9),
            verbal: "Let's take a moment to notice what's around us. Can you feel the ground beneath you?",
            nonverbal: "Calm, steady presence with slow movements",
            interventionLevel: .intensive,
            targetEmotionalState: .neutral,
            duration: 30.0
        )
    }
}
