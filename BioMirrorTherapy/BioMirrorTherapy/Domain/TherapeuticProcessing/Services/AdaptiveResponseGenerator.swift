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
    private let dissociationDetector: DissociationDetector
    
    private var preferences: ResponsePreferences = .default
    private var activeSessions: [UUID: TherapeuticSession] = [:]
    
    private var titrationLevel: Float = 0.2 // How much to modify mirrored emotions
    
    // MARK: - Initialization
    
    init(emotionalIntegrationService: EmotionalIntegrationService, dissociationDetector: DissociationDetector) {
        self.emotionalIntegrationService = emotionalIntegrationService
        self.dissociationDetector = dissociationDetector
    }
    
    // MARK: - TherapeuticResponseService Methods
    
    func startSession(phase: SessionPhase = .connection) -> TherapeuticSession {
        let session = TherapeuticSession(phase: phase)
        activeSessions[session.id] = session
        return session
    }
    
    func endSession(_ session: TherapeuticSession) {
        session.endSession()
        // Store session data for later analysis
        activeSessions.removeValue(forKey: session.id)
    }
    
    func generateResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Update session with new state
        session.addEmotionalState(state)
        
        // Check for dissociation first - highest priority
        let dissociationStatus = dissociationDetector.processDissociationState(state)
        if case .active(let severity, _, _) = dissociationStatus, severity != .potential {
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
    
    func generateGroundingResponse(for dissociationStatus: DissociationStatus, in session: TherapeuticSession) -> TherapeuticResponse {
        // Generate grounding response based on dissociation severity
        
        // Get severity details
        let severity: DissociationSeverity
        var intensity: Float = 0.0
        
        switch dissociationStatus {
        case .active(let activeSeverity, _, let activeIntensity):
            severity = activeSeverity
            intensity = activeIntensity
        case .recent(let recentSeverity, _, let recentIntensity):
            severity = recentSeverity
            intensity = recentIntensity
        case .none:
            // Shouldn't happen, but provide a default mild grounding response
            return createGenericGroundingResponse(in: session)
        }
        
        // Select appropriate technique based on severity
        let technique = selectGroundingTechnique(for: severity, intensity: intensity)
        
        // Create verbal instruction
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
            verbal = "Can you name something you see that is [color]?"
        }
        
        // Create character action
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
    
    func setResponsePreferences(_ preferences: ResponsePreferences) {
        self.preferences = preferences
        
        // Update titration level based on mirroring sensitivity
        titrationLevel = 0.4 * (1.0 - preferences.emotionalMirroringSensitivity)
    }
    
    // MARK: - Private Response Generation Methods
    
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
    
    private func generateAwarenessResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // In awareness phase, help child recognize and name emotions
        
        // Mirror emotion with slight titration (adjustment)
        let emotion = state.dominantEmotion
        let intensity = state.emotionalIntensity
        
        // Verbal response focused on naming the emotion
        let verbal = "I notice you might be feeling \(emotion.rawValue.lowercased()). " +
                    "I sometimes feel that way too."
        
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
                responseType: .integration,
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
            responseType: .transfer,
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
    
    private func createGenericGroundingResponse(in session: TherapeuticSession) -> TherapeuticResponse {
        // Create a gentle default grounding response
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .grounding,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: .breathing(speed: 0.4, depth: 0.6),
            verbal: "Let's take a moment to notice where we are right now. Can you feel your feet on the ground?",
            nonverbal: "Calm, grounding presence",
            interventionLevel: .minimal,
            targetEmotionalState: .neutral,
            duration: 10.0
        )
    }
}
