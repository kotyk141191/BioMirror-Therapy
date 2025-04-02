//
//  File.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol EmotionalIntegrationService {
    // State
    var currentIntegratedState: IntegratedEmotionalState? { get }
    var integratedStatePublisher: AnyPublisher<IntegratedEmotionalState, Never> { get }
    var stateChangePublisher: AnyPublisher<EmotionalStateChange, Never> { get }
    
    // Control
    func startIntegration()
    func startIntegration(sessionId: String?)
    func stopIntegration()
    
    // Analysis
    func detectDissociation(in state: IntegratedEmotionalState) -> Bool
    func calculateEmotionalMasking(in state: IntegratedEmotionalState) -> Float
}
