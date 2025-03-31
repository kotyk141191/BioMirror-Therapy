//
//  TherapeuticInterventionService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol TherapeuticInterventionService {
    // Session management
    func startSession(phase: SessionPhase) -> TherapeuticSession
    func endSession(_ session: TherapeuticSession)
    
    // Intervention generation
    func generateResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse
    func generateDissociationResponse(for state: IntegratedEmotionalState, in session: TherapeuticSession) -> TherapeuticResponse
    
    // Progress tracking
    func evaluatePhaseProgress(_ session: TherapeuticSession) -> Float
    func shouldAdvanceToNextPhase(_ session: TherapeuticSession) -> Bool
    
    // Activity recommendations
    func recommendActivity(for session: TherapeuticSession) -> TherapeuticActivity
}
