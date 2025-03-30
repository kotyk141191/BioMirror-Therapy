//
//  SessionManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol SessionManagerDelegate: AnyObject {
    func sessionManager(_ manager: SessionManager, didUpdateState state: IntegratedEmotionalState)
    func sessionManager(_ manager: SessionManager, didGenerateResponse response: TherapeuticResponse)
    func sessionManager(_ manager: SessionManager, didChangeSessionPhase phase: SessionPhase)
    func sessionManager(_ manager: SessionManager, didDetectSafetyEvent event: SafetyEvent, withAlertLevel level: AlertLevel)
    func sessionManager(_ manager: SessionManager, didEncounterError error: Error)
}

class SessionManager {
    // MARK: - Properties
    
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    private let emotionalIntegrationService: EmotionalIntegrationService
    private let therapeuticResponseService: TherapeuticResponseService
    private let safetyMonitor: SafetyMonitor
    
    private var currentSession: TherapeuticSession?
    private var cancellables = Set<AnyCancellable>()
    
    weak var delegate: SessionManagerDelegate?
    
    // MARK: - Initialization
    
    init(
        facialAnalysisService: FacialAnalysisService,
        biometricAnalysisService: BiometricAnalysisService,
        emotionalIntegrationService: EmotionalIntegrationService,
        therapeuticResponseService: TherapeuticResponseService,
        safetyMonitor: SafetyMonitor
    ) {
        self.facialAnalysisService = facialAnalysisService
        self.biometricAnalysisService = biometricAnalysisService
        self.emotionalIntegrationService = emotionalIntegrationService
        self.therapeuticResponseService = therapeuticResponseService
        self.safetyMonitor = safetyMonitor
        
        setupSubscriptions()
    }
    
    // MARK: - Session Management
    
    func startSession(withPhase phase: SessionPhase = .connection) throws {
        guard currentSession == nil else {
            throw SessionError.sessionAlreadyInProgress
        }
        
        // Start services
        try facialAnalysisService.startAnalysis()
        try biometricAnalysisService.startMonitoring()
        emotionalIntegrationService.startIntegration()
        safetyMonitor.startMonitoring()
        
        // Create new session
        currentSession = therapeuticResponseService.startSession(phase: phase)
        
        delegate?.sessionManager(self, didChangeSessionPhase: phase)
    }
    
    func endSession() {
        guard let session = currentSession else {
            return
        }
        
        // Stop services
        facialAnalysisService.stopAnalysis()
        biometricAnalysisService.stopMonitoring()
        emotionalIntegrationService.stopIntegration()
        safetyMonitor.stopMonitoring()
        
        // End session
        therapeuticResponseService.endSession(session)
        currentSession = nil
    }
    
    func pauseSession() {
        facialAnalysisService.pauseAnalysis()
        biometricAnalysisService.pauseMonitoring()
    }
    
    func resumeSession() {
        facialAnalysisService.resumeAnalysis()
        biometricAnalysisService.resumeMonitoring()
    }
    
    func advanceToNextPhase() {
        guard let session = currentSession else {
            return
        }
        
        let currentPhase = session.sessionPhase
        let nextPhase: SessionPhase
        
        switch currentPhase {
        case .connection:
            nextPhase = .awareness
        case .awareness:
            nextPhase = .integration
        case .integration:
            nextPhase = .regulation
        case .regulation:
            nextPhase = .transfer
        case .transfer:
            // Already at final phase
            return
        }
        
        session.advancePhase(to: nextPhase)
        delegate?.sessionManager(self, didChangeSessionPhase: nextPhase)
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to integrated emotional state updates
        emotionalIntegrationService.integratedStatePublisher
            .sink { [weak self] state in
                guard let self = self, let session = self.currentSession else { return }
                
                // Notify delegate about state update
                self.delegate?.sessionManager(self, didUpdateState: state)
                
                // Generate therapeutic response
                let response = self.therapeuticResponseService.generateResponse(for: state, in: session)
                
                // Notify delegate about generated response
                self.delegate?.sessionManager(self, didGenerateResponse: response)
            }
            .store(in: &cancellables)
    }
}

enum SessionError: Error {
    case sessionAlreadyInProgress
    case noActiveSession
    case servicesNotAvailable
}
