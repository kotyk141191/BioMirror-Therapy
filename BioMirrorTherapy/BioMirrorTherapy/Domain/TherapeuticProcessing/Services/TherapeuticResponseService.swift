//
//  TherapeuticResponseService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol TherapeuticResponseService {
    // Session management
    func startSession(phase: SessionPhase) -> TherapeuticSession
    func endSession(_ session: TherapeuticSession)
    
    // Response generation
    func generateResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse
    func generateGroundingResponse(for dissociationStatus: DissociationStatus, in session: TherapeuticSession) -> TherapeuticResponse
    
    // Customization
    func setResponsePreferences(_ preferences: ResponsePreferences)
}

struct ResponsePreferences {
    let characterType: CharacterType
    let responsivenessSensitivity: Float // 0.0 to 1.0, how quickly character responds
    let emotionalMirroringSensitivity: Float // 0.0 to 1.0, how closely character mirrors emotions
    let preferredInterventionLevel: InterventionLevel
    let preferredGroundingTechniques: [GroundingTechnique]
    
    static let `default` = ResponsePreferences(
        characterType: .friendly,
        responsivenessSensitivity: 0.7,
        emotionalMirroringSensitivity: 0.8,
        preferredInterventionLevel: .moderate,
        preferredGroundingTechniques: [.breathing, .sensory]
    )
}

//enum CharacterType {
//    case friendly
//    case calm
//    case energetic
//    case nurturing
//    case playful
//}
//
enum GroundingTechnique {
    case breathing
    case sensory
    case movement
    case cognitive
    case naming
}
