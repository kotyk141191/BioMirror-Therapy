//
//  ChildSessionViewModel.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine
import SwiftUI

class ChildSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentEmotionalState: IntegratedEmotionalState?
    @Published var currentResponse: TherapeuticResponse?
    @Published var sessionActive: Bool = false
    @Published var sessionPhase: SessionPhase = .connection
    @Published var characterName: String = "Buddy"
    @Published var characterType: CharacterType = .friendly
    @Published var dissociationStatus: DissociationStatus = .none
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    
    // MARK: - Private Properties
    
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    private let integrationService: EmotionalIntegrationService
    private let therapeuticService: TherapeuticResponseService
    private let safetyMonitor: SafetyMonitor
    private let progressTracker: ProgressTracker
    
    private var currentSession: TherapeuticSession?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Initialize services from dependency container
        let serviceLocator = ServiceLocator.shared
        self.facialAnalysisService = serviceLocator.resolve()
        self.biometricAnalysisService = serviceLocator.resolve()
        self.integrationService = serviceLocator.resolve()
        self.therapeuticService = serviceLocator.resolve()
        self.safetyMonitor = serviceLocator.resolve()
        self.progressTracker = serviceLocator.resolve()
        
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        guard !sessionActive else { return }
        
        do {
            // Start data collection
            try facialAnalysisService.startAnalysis()
            try biometricAnalysisService.startMonitoring()
            
            // Start integration
            integrationService.startIntegration()
            
            // Create therapeutic session
            currentSession = therapeuticService.startSession(phase: sessionPhase)
            
            // Start safety monitoring
            safetyMonitor.startMonitoring()
            
            // Register session with progress tracker
            if let session = currentSession {
                progressTracker.registerSession(session)
            }
            
            sessionActive = true
        } catch {
            handleError(error)
        }
    }
    
    func stopSession() {
        guard sessionActive else { return }
        
        // Stop data collection
        facialAnalysisService.stopAnalysis()
        biometricAnalysisService.stopMonitoring()
        
        // Stop integration
        integrationService.stopIntegration()
        
        // End therapeutic session
        if let session = currentSession {
            therapeuticService.endSession(session)
            
            // Finalize session with progress tracker
            progressTracker.finalizeSession(session)
            
            currentSession = nil
        }
        
        // Stop safety monitoring
        safetyMonitor.stopMonitoring()
        
        sessionActive = false
    }
    
    func setSessionPhase(_ phase: SessionPhase) {
        self.sessionPhase = phase
        
        // Update current session if active
        currentSession?.advancePhase(to: phase)
    }
    
    func setCharacterPreferences(name: String, type: CharacterType) {
        self.characterName = name
        self.characterType = type
        
        // Update therapeutic response preferences
        therapeuticService.setResponsePreferences(
            ResponsePreferences(
                characterType: type,
                responsivenessSensitivity: 0.7,
                emotionalMirroringSensitivity: 0.8,
                preferredInterventionLevel: .moderate,
                preferredGroundingTechniques: [.breathing, .sensory]
            )
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to integrated emotional state updates
        integrationService.integratedStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self, self.sessionActive else { return }
                
                self.currentEmotionalState = state
                
                // Generate therapeutic response
                if let session = self.currentSession {
                    let response = self.therapeuticService.generateResponse(for: state, in: session)
                    self.currentResponse = response
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to safety alerts
        NotificationCenter.default.publisher(for: .sessionTerminationRequired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                if let reason = notification.userInfo?["reason"] as? String {
                    self.showAlert(message: "Session needs to end: \(reason)")
                    self.stopSession()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .calmingInterventionRequired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                if let reason = notification.userInfo?["reason"] as? String {
                    self.triggerCalmingIntervention(reason: reason)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        var message = "An error occurred. Please try again."
        
        if let facialError = error as? FacialAnalysisError {
            switch facialError {
            case .deviceNotSupported:
                message = "This device doesn't support facial analysis. Please use a device with a TrueDepth camera."
            case .cameraPermissionDenied:
                message = "Camera permission is required for facial analysis."
            case .arSessionFailed:
                message = "Face tracking session failed. Please try again."
            case .modelLoadingFailed:
                message = "Could not load facial analysis models. Please try again."
            case .internalError(let details):
                message = "Facial analysis error: \(details)"
            }
        } else if let biometricError = error as? BiometricAnalysisError {
            switch biometricError {
            case .watchNotConnected:
                message = "Apple Watch is not connected. Please connect your watch."
            case .watchNotSupported:
                message = "Your device doesn't support Watch connectivity."
            case .missingPermissions:
                message = "Health data permissions are required for biometric analysis."
            case .sensorUnavailable:
                message = "Required sensors are not available."
            case .internalError(let details):
                message = "Biometric analysis error: \(details)"
            }
        }
        
        showAlert(message: message)
    }
    
    private func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
    
    private func triggerCalmingIntervention(reason: String) {
        // In a real implementation, this would trigger special calming animations
        // and interactions for the character
        print("Calming intervention triggered: \(reason)")
        
        // Generate a calming response if we have an active session
        if let session = currentSession, let state = currentEmotionalState {
            // Create a calming-focused response
            let calmingResponse = TherapeuticResponse(
                timestamp: Date(),
                responseType: .regulation,
                characterEmotionalState: .neutral,
                characterEmotionalIntensity: 0.3,
                characterAction: .breathing(speed: 0.3, depth: 0.8),
                verbal: "Let's take a moment to breathe together. Slow and gentle.",
                nonverbal: "Calm, steady breathing with gentle movements",
                interventionLevel: .significant,
                targetEmotionalState: .neutral,
                duration: 30.0
            )
            
            self.currentResponse = calmingResponse
        }
    }
}
