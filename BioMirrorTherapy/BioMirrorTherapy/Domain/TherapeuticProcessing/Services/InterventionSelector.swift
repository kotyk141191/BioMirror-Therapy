//
//  InterventionSelector.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class InterventionSelector: TherapeuticInterventionService {
    // MARK: - Properties
    
    private let emotionalIntegrationService: EmotionalIntegrationService
    private let safetyMonitor: SafetyMonitor
    
    private var activeSessions: [UUID: TherapeuticSession] = [:]
    
    // MARK: - Initialization
    
    init(emotionalIntegrationService: EmotionalIntegrationService, safetyMonitor: SafetyMonitor) {
        self.emotionalIntegrationService = emotionalIntegrationService
        self.safetyMonitor = safetyMonitor
    }
    
    // MARK: - TherapeuticInterventionService Methods
    
    func startSession(phase: SessionPhase) -> TherapeuticSession {
        let session = TherapeuticSession(phase: phase)
        activeSessions[session.id] = session
        return session
    }
    
    func endSession(_ session: TherapeuticSession) {
        session.endSession()
        activeSessions.removeValue(forKey: session.id)
    }
    
    func generateResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // First check safety
        if safetyMonitor.needsIntervention(state) {
            return generateSafetyResponse(for: state, in: session)
        }
        
        // Check for dissociation
        if state.dissociationIndex > 0.6 {
            return generateDissociationResponse(for: state, in: session)
        }
        
        // Generate appropriate response based on phase and state
        switch session.sessionPhase {
        case .connection:
            return generateConnectionPhaseResponse(for: state, in: session)
        case .awareness:
            return generateAwarenessPhaseResponse(for: state, in: session)
        case .integration:
            return generateIntegrationPhaseResponse(for: state, in: session)
        case .transfer:
            return generateTransferPhaseResponse(for: state, in: session)
        case .regulation:
            return generateRegulationPhaseResponse(for: state, in: session)
        }
    }
    
    func generateDissociationResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Create grounding response to address dissociation
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .grounding,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.5,
            characterAction: CharacterAction.breathing(speed: 0.5, depth: 0.7),
            verbal: "Let's focus on what we can see and feel right now.",
            nonverbal: "Character makes gentle, rhythmic movements",
            interventionLevel: .moderate,
            targetEmotionalState: .neutral,
            duration: 30.0
        )
    }
    
    func evaluatePhaseProgress(_ session: TherapeuticSession) -> Float {
        // Simplified placeholder implementation
        // In a real app, this would analyze multiple metrics
        
        // For now, return random progress
        return Float.random(in: 0...1)
    }
    
    func shouldAdvanceToNextPhase(_ session: TherapeuticSession) -> Bool {
        let progress = evaluatePhaseProgress(session)
        return progress > 0.8 // 80% completion threshold
    }
    
    func recommendActivity(for session: TherapeuticSession) -> TherapeuticActivity {
        // Get available activities for current phase
        let activities = session.sessionPhase.recommendedActivities
        
        // In a real implementation, this would select based on
        // progress and specific needs
        
        // For now, return a random activity
        return activities.randomElement()!
    }
    
    // MARK: - Private Methods
    
    private func generateSafetyResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Generate safety intervention response
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .regulation,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: CharacterAction.breathing(speed: 0.3, depth: 0.8),
            verbal: "Let's take a moment to breathe together slowly.",
            nonverbal: "Character demonstrates deep, slow breathing",
            interventionLevel: .intensive,
            targetEmotionalState: .neutral,
            duration: 60.0
        )
    }
    
    private func generateConnectionPhaseResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Simple mirroring with slight modulation for connection phase
        let characterEmotion = state.dominantEmotion
        let intensity = max(0.3, state.emotionalIntensity * 0.8) // Slightly less intense
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .mirroring,
            characterEmotionalState: characterEmotion,
            characterEmotionalIntensity: intensity,
            characterAction: CharacterAction.facialExpression(emotion: characterEmotion, intensity: intensity),
            verbal: getVerbalResponse(for: characterEmotion, phase: .connection),
            nonverbal: "Character mirrors child with slightly reduced intensity",
            interventionLevel: .minimal,
            targetEmotionalState: nil,
            duration: 15.0
        )
    }
    
    private func generateAwarenessPhaseResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Naming and exploring emotions for awareness phase
        let characterEmotion = state.dominantEmotion
        let intensity = state.emotionalIntensity * 0.9
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .exploration,
            characterEmotionalState: characterEmotion,
            characterEmotionalIntensity: intensity,
            characterAction: CharacterAction.facialExpression(emotion: characterEmotion, intensity: intensity),
            verbal: getVerbalResponse(for: characterEmotion, phase: .awareness),
            nonverbal: "Character shows emotion and points to face/body",
            interventionLevel: .moderate,
            targetEmotionalState: nil,
            duration: 20.0
        )
    }
    
    private func generateRegulationPhaseResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Naming and exploring emotions for awareness phase
        let characterEmotion = state.dominantEmotion
        let intensity = state.emotionalIntensity * 0.9
        
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .regulation,
            characterEmotionalState: characterEmotion,
            characterEmotionalIntensity: intensity,
            characterAction: CharacterAction.facialExpression(emotion: characterEmotion, intensity: intensity),
            verbal: getVerbalResponse(for: characterEmotion, phase: .awareness),
            nonverbal: "Character shows emotion and points to face/body",
            interventionLevel: .moderate,
            targetEmotionalState: nil,
            duration: 20.0
        )
    }
    
    private func generateIntegrationPhaseResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Coherence and regulation focus for integration phase
        
        // If low coherence, focus on integration
        if state.coherenceIndex < 0.4 {
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .titration,
                characterEmotionalState: state.dominantEmotion,
                characterEmotionalIntensity: state.emotionalIntensity * 0.7,
                characterAction: CharacterAction.bodyMovement(type: .gentle, intensity: 0.5),
                verbal: "Notice how your face and body are feeling different things.",
                nonverbal: "Character demonstrates connecting face and body expression",
                interventionLevel: .moderate,
                targetEmotionalState: state.dominantEmotion,
                duration: 25.0
            )
        }
        // If high arousal, focus on regulation
        else if state.arousalLevel > 0.7 {
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .regulation,
                characterEmotionalState: state.dominantEmotion,
                characterEmotionalIntensity: state.emotionalIntensity * 0.6,
                characterAction: CharacterAction.breathing(speed: 0.4, depth: 0.7),
                verbal: "Let's notice this feeling and breathe with it.",
                nonverbal: "Character shows regulated version of emotion with breathing",
                interventionLevel: .moderate,
                targetEmotionalState: state.dominantEmotion,
                duration: 30.0
            )
        }
        // Default integration response
        else {
            return TherapeuticResponse(
                timestamp: Date(),
                responseType: .validation,
                characterEmotionalState: state.dominantEmotion,
                characterEmotionalIntensity: state.emotionalIntensity,
                characterAction: CharacterAction.attention(focus: .direct),
                verbal: getVerbalResponse(for: state.dominantEmotion, phase: .integration),
                nonverbal: "Character validates emotion with attentive gaze",
                interventionLevel: .moderate,
                targetEmotionalState: nil,
                duration: 20.0
            )
        }
    }
    
    private func generateTransferPhaseResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Focus on independent regulation for transfer phase
        
        // Create response with reduced support level
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .exploration,
            characterEmotionalState: .neutral,
            characterEmotionalIntensity: 0.3,
            characterAction: CharacterAction.attention(focus: .shared),
            verbal: "What might help with this feeling in everyday life?",
            nonverbal: "Character shows attentive, curious expression",
            interventionLevel: .minimal,
            targetEmotionalState: nil,
            duration: 20.0
        )
    }
    
    private func getVerbalResponse(for emotion: EmotionType, phase: SessionPhase) -> String {
        // Simplified placeholder implementation
        // In a real app, this would have a variety of responses for each emotion
        
        switch emotion {
        case .happiness:
            return "I see you're feeling happy right now."
        case .sadness:
            return "It looks like you might be feeling sad."
        case .anger:
            return "I notice that you seem angry or frustrated."
        case .fear:
            return "You seem worried or scared about something."
        case .surprise:
            return "That seems surprising to you."
        case .disgust:
            return "Something doesn't feel right to you."
        case .neutral:
            return "You're looking pretty calm right now."
        default:
            return "I'm noticing your feelings right now."
        }
    }
    
    
    private func generateCoherenceResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse {
        // Create a response focusing on connecting facial expressions with internal feelings
        return TherapeuticResponse(
            timestamp: Date(),
            responseType: .integration,
            characterEmotionalState: state.dominantEmotion,
            characterEmotionalIntensity: state.emotionalIntensity * 0.8,
            characterAction: CharacterAction.facialExpression(
                emotion: state.dominantEmotion,
                intensity: state.emotionalIntensity * 0.8
            ),
            verbal: "I notice your face and body might be feeling different things. Let's try to connect them.",
            nonverbal: "Shows empathetic expression with gentle movement",
            interventionLevel: .moderate,
            targetEmotionalState: state.dominantEmotion,
            duration: 15.0
        )
    }
}
