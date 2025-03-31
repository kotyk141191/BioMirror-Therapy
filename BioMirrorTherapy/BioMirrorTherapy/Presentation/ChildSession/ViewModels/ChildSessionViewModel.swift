//
//  ChildSessionViewModel.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

//import Foundation
//import Combine
//import SwiftUI
//
//class ChildSessionViewModel: ObservableObject {
//    // MARK: - Published Properties
//    
//    @Published var currentEmotionalState: IntegratedEmotionalState?
//    @Published var currentResponse: TherapeuticResponse?
//    @Published var sessionActive: Bool = false
//    @Published var sessionPhase: SessionPhase = .connection
//    @Published var characterName: String = "Buddy"
//    @Published var characterType: CharacterType = .friendly
//    @Published var dissociationStatus: DissociationStatus = .none
//    @Published var alertMessage: String?
//    @Published var showAlert: Bool = false
//    
//    // MARK: - Private Properties
//    
//    private let facialAnalysisService: FacialAnalysisService
//    private let biometricAnalysisService: BiometricAnalysisService
//    private let integrationService: EmotionalIntegrationService
//    private let therapeuticService: TherapeuticResponseService
//    private let safetyMonitor: SafetyMonitor
//    private let progressTracker: ProgressTracker
//    
//    private var currentSession: TherapeuticSession?
//    private var cancellables = Set<AnyCancellable>()
//    
//    // MARK: - Initialization
//    
//    init() {
//        // Initialize services from dependency container
//        let serviceLocator = ServiceLocator.shared
//        self.facialAnalysisService = serviceLocator.resolve()
//        self.biometricAnalysisService = serviceLocator.resolve()
//        self.integrationService = serviceLocator.resolve()
//        self.therapeuticService = serviceLocator.resolve()
//        self.safetyMonitor = serviceLocator.resolve()
//        self.progressTracker = serviceLocator.resolve()
//        
//        setupSubscriptions()
//    }
//    
//    // MARK: - Public Methods
//    
//    func startSession() {
//        guard !sessionActive else { return }
//        
//        do {
//            // Start data collection
//            try facialAnalysisService.startAnalysis()
//            try biometricAnalysisService.startMonitoring()
//            
//            // Start integration
//            integrationService.startIntegration()
//            
//            // Create therapeutic session
//            currentSession = therapeuticService.startSession(phase: sessionPhase)
//            
//            // Start safety monitoring
//            safetyMonitor.startMonitoring()
//            
//            // Register session with progress tracker
//            if let session = currentSession {
//                progressTracker.registerSession(session)
//            }
//            
//            sessionActive = true
//        } catch {
//            handleError(error)
//        }
//    }
//    
//    func stopSession() {
//        guard sessionActive else { return }
//        
//        // Stop data collection
//        facialAnalysisService.stopAnalysis()
//        biometricAnalysisService.stopMonitoring()
//        
//        // Stop integration
//        integrationService.stopIntegration()
//        
//        // End therapeutic session
//        if let session = currentSession {
//            therapeuticService.endSession(session)
//            
//            // Finalize session with progress tracker
//            progressTracker.finalizeSession(session)
//            
//            currentSession = nil
//        }
//        
//        // Stop safety monitoring
//        safetyMonitor.stopMonitoring()
//        
//        sessionActive = false
//    }
//    
//    func setSessionPhase(_ phase: SessionPhase) {
//        self.sessionPhase = phase
//        
//        // Update current session if active
//        currentSession?.advancePhase(to: phase)
//    }
//    
//    func setCharacterPreferences(name: String, type: CharacterType) {
//        self.characterName = name
//        self.characterType = type
//        
//        // Update therapeutic response preferences
//        therapeuticService.setResponsePreferences(
//            ResponsePreferences(
//                characterType: type,
//                responsivenessSensitivity: 0.7,
//                emotionalMirroringSensitivity: 0.8,
//                preferredInterventionLevel: .moderate,
//                preferredGroundingTechniques: [.breathing, .sensory]
//            )
//        )
//    }
//    
//    // MARK: - Private Methods
//    
//    private func setupSubscriptions() {
//        // Subscribe to integrated emotional state updates
//        integrationService.integratedStatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                guard let self = self, self.sessionActive else { return }
//                
//                self.currentEmotionalState = state
//                
//                // Generate therapeutic response
//                if let session = self.currentSession {
//                    let response = self.therapeuticService.generateResponse(for: state, in: session)
//                    self.currentResponse = response
//                }
//            }
//            .store(in: &cancellables)
//        
//        // Subscribe to safety alerts
//        NotificationCenter.default.publisher(for: .sessionTerminationRequired)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] notification in
//                guard let self = self else { return }
//                
//                if let reason = notification.userInfo?["reason"] as? String {
//                    self.showAlert(message: "Session needs to end: \(reason)")
//                    self.stopSession()
//                }
//            }
//            .store(in: &cancellables)
//        
//        NotificationCenter.default.publisher(for: .calmingInterventionRequired)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] notification in
//                guard let self = self else { return }
//                
//                if let reason = notification.userInfo?["reason"] as? String {
//                    self.triggerCalmingIntervention(reason: reason)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func handleError(_ error: Error) {
//        var message = "An error occurred. Please try again."
//        
//        if let facialError = error as? FacialAnalysisError {
//            switch facialError {
//            case .deviceNotSupported:
//                message = "This device doesn't support facial analysis. Please use a device with a TrueDepth camera."
//            case .cameraPermissionDenied:
//                message = "Camera permission is required for facial analysis."
//            case .arSessionFailed:
//                message = "Face tracking session failed. Please try again."
//            case .modelLoadingFailed:
//                message = "Could not load facial analysis models. Please try again."
//            case .internalError(let details):
//                message = "Facial analysis error: \(details)"
//            }
//        } else if let biometricError = error as? BiometricAnalysisError {
//            switch biometricError {
//            case .watchNotConnected:
//                message = "Apple Watch is not connected. Please connect your watch."
//            case .watchNotSupported:
//                message = "Your device doesn't support Watch connectivity."
//            case .missingPermissions:
//                message = "Health data permissions are required for biometric analysis."
//            case .sensorUnavailable:
//                message = "Required sensors are not available."
//            case .internalError(let details):
//                message = "Biometric analysis error: \(details)"
//            }
//        }
//        
//        showAlert(message: message)
//    }
//    
//    private func showAlert(message: String) {
//        self.alertMessage = message
//        self.showAlert = true
//    }
//    
//    private func triggerCalmingIntervention(reason: String) {
//        // In a real implementation, this would trigger special calming animations
//        // and interactions for the character
//        print("Calming intervention triggered: \(reason)")
//        
//        // Generate a calming response if we have an active session
//        if let session = currentSession, let state = currentEmotionalState {
//            // Create a calming-focused response
//            let calmingResponse = TherapeuticResponse(
//                timestamp: Date(),
//                responseType: .regulation,
//                characterEmotionalState: .neutral,
//                characterEmotionalIntensity: 0.3,
//                characterAction: .breathing(speed: 0.3, depth: 0.8),
//                verbal: "Let's take a moment to breathe together. Slow and gentle.",
//                nonverbal: "Calm, steady breathing with gentle movements",
//                interventionLevel: .significant,
//                targetEmotionalState: .neutral,
//                duration: 30.0
//            )
//            
//            self.currentResponse = calmingResponse
//        }
//    }
//}


import Foundation
import Combine
import ARKit
import RealityKit

class ChildSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Session state
    @Published var isLoading = true
    @Published var loadingMessage = "Setting up your session..."
    @Published var isPaused = false
    @Published var sessionTitle = "Connection Phase"
    @Published var sessionInstructions = "Let's get to know each other"
    
    // Activity state
    @Published var currentActivity: TherapeuticActivity?
    @Published var hasNextActivity = false
    @Published var hasPreviousActivity = false
    
    // UI state
    @Published var showEmotionFeedback = false
    @Published var currentEmotionName = "Neutral"
    @Published var coherenceLevel: String?
    @Published var phaseProgress: Float = 0.0
    @Published var showPhaseProgress = true
    @Published var breathingAnimation = false
    
    // Safety state
    @Published var showSafetyOverlay = false
    
    // Alerts
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // AR state
    @Published var characterNeedsUpdate = false
    
    // MARK: - Private Properties
    
    // Services
    private var facialAnalysisService: FacialAnalysisService?
    private var biometricAnalysisService: BiometricAnalysisService?
    private var emotionalIntegrationService: EmotionalIntegrationService?
    private var interventionService: TherapeuticInterventionService?
    private var safetyMonitor: SafetyMonitor?
    
    // Session
    private var currentSession: TherapeuticSession?
    
    // Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Character animation
    private var currentTherapeuticResponse: TherapeuticResponse?
    
    // MARK: - Internal Properties
    
    var arView: ARView?
    
    // MARK: - Initialization
    
    init() {
        // In a real implementation, these would be injected
        setupServices()
    }
    
    // MARK: - Public Methods
    
//    func startSession() {
//        isLoading = true
//        loadingMessage = "Setting up your session..."
//        
//        // Start required services
//        startServices()
//        
//        // Create session
//        createSession()
//        
//        // Simulate loading delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isLoading = false
//            self.showEmotionFeedback = true
//        }
//    }
    
    func endSession() {
        // End the session
        if let session = currentSession {
            interventionService?.endSession(session)
        }
        
        // Stop services
        stopServices()
        
        // Reset state
        currentSession = nil
        currentTherapeuticResponse = nil
    }
    
    func pauseSession() {
        if isPaused {
            // Resume session
            facialAnalysisService?.resumeAnalysis()
            biometricAnalysisService?.resumeMonitoring()
            isPaused = false
        } else {
            // Pause session
            facialAnalysisService?.pauseAnalysis()
            biometricAnalysisService?.pauseMonitoring()
            isPaused = true
        }
    }
    
    func toggleHelp() {
        showAlert = true
        alertTitle = "Help"
        alertMessage = "This is your therapeutic session. The character will mirror your expressions and help you explore your emotions. Use the buttons below to navigate activities or take a break."
    }
    
    func needHelp() {
        showAlert = true
        alertTitle = "Do you need help?"
        alertMessage = "Would you like to take a break or speak with your parent/caregiver?"
    }
    
    func nextActivity() {
        // In a real implementation, this would get the next activity
        // from the intervention service
        
        // For now, just update the placeholder activity
        currentActivity = TherapeuticActivity(
            type: .emotionalMatching,
            name: "Emotion Matching Game",
            description: "Try to match these emotions"
        )
    }
    
    func previousActivity() {
        // In a real implementation, this would get the previous activity
        // from the intervention service
    }
    
    func dismissSafetyOverlay() {
        breathingAnimation = false
        showSafetyOverlay = false
    }
    
    // MARK: - Private Methods
    
    private func setupServices() {
        // In a real implementation, these would be resolved from ServiceLocator
        
        // Create services
        facialAnalysisService = LiDARFacialAnalysisService()
        biometricAnalysisService = AppleWatchBiometricService()
        
        
        // Safety monitor needs to be created before other services that depend on it
       
        
        // Create integration service
        if let facialService = facialAnalysisService,
           let biometricService = biometricAnalysisService {
            emotionalIntegrationService = EmotionalCoherenceAnalyzer(
                facialAnalysisService: facialService,
                biometricAnalysisService: biometricService
            )
            
            safetyMonitor = SafetyMonitor(emotionalIntegrationService: EmotionalCoherenceAnalyzer(facialAnalysisService: facialService, biometricAnalysisService: biometricService))
        }
        
        // Create intervention service
        if let integrationService = emotionalIntegrationService,
           let safetyMonitor = safetyMonitor {
            interventionService = InterventionSelector(
                emotionalIntegrationService: integrationService,
                safetyMonitor: safetyMonitor
            )
        }
    }
    
    private func startServices() {
        // Start facial analysis
        do {
            try facialAnalysisService?.startAnalysis()
        } catch {
            handleServiceError(error, service: "Facial Analysis")
        }
        
        // Start biometric monitoring
        do {
            try biometricAnalysisService?.startMonitoring()
        } catch {
            handleServiceError(error, service: "Biometric Analysis")
        }
        
        // Start integration service
        emotionalIntegrationService?.startIntegration()
        
        // Subscribe to integrated emotional state updates
        emotionalIntegrationService?.integratedStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleIntegratedEmotionalStateUpdate(state)
            }
            .store(in: &cancellables)
    }
    
    private func stopServices() {
        // Stop all services
        facialAnalysisService?.stopAnalysis()
        biometricAnalysisService?.stopMonitoring()
        emotionalIntegrationService?.stopIntegration()
        
        // Cancel subscriptions
        cancellables.removeAll()
    }
    
    private func createSession() {
        // Create a new session starting with the connection phase
        currentSession = interventionService?.startSession(phase: .connection)
        
        // Set initial activity
        currentActivity = currentSession?.sessionPhase.recommendedActivities.first
        
        // Update UI
        sessionTitle = currentSession?.sessionPhase.name ?? "Therapy Session"
        sessionInstructions = currentActivity?.instruction ?? ""
    }
    
    private func handleServiceError(_ error: Error, service: String) {
        // Display error alert
        showAlert = true
        alertTitle = "\(service) Error"
        alertMessage = "Could not start \(service): \(error.localizedDescription)"
        
        print("Error starting \(service): \(error)")
    }
    
    private func handleIntegratedEmotionalStateUpdate(_ state: IntegratedEmotionalState) {
        guard let session = currentSession, !isPaused else { return }
        
        // Add state to session
        session.addEmotionalState(state)
        
        // Update UI with emotional state
        currentEmotionName = state.dominantEmotion.rawValue
        
        // Format coherence level
        let coherencePercentage = Int(state.coherenceIndex * 100)
        coherenceLevel = "\(coherencePercentage)%"
        
        // Check safety
        if safetyMonitor?.shouldTerminateSession(state) == true {
            endSession()
            showAlert = true
            alertTitle = "Session Ended"
            alertMessage = "The session has been ended for safety. Please talk with your parent or therapist."
            return
        }
        
        if safetyMonitor?.needsIntervention(state) == true {
            showSafetyOverlay = true
            breathingAnimation = true
        }
        
        // Generate therapeutic response if needed
        if currentTherapeuticResponse == nil || shouldGenerateNewResponse() {
            let response = interventionService?.generateResponse(for: state, in: session)
            handleTherapeuticResponse(response)
        }
        
        // Update progress
        if let interventionService = interventionService {
            phaseProgress = interventionService.evaluatePhaseProgress(session)
            
            // Check phase advancement
            if interventionService.shouldAdvanceToNextPhase(session),
               let nextPhase = session.sessionPhase.nextPhase {
                advanceToPhase(nextPhase)
            }
        }
        
        // Update character based on emotional state
        updateCharacterAppearance(state)
    }
    
    private func shouldGenerateNewResponse() -> Bool {
        // Check if we need a new therapeutic response
        guard let response = currentTherapeuticResponse else { return true }
        
        // Check if current response has expired
        let responseAge = Date().timeIntervalSince(response.timestamp)
        return responseAge > response.duration
    }
    
    private func handleTherapeuticResponse(_ response: TherapeuticResponse?) {
        guard let response = response else { return }
        
        // Store current response
        currentTherapeuticResponse = response
        
        // Update character based on response
        characterNeedsUpdate = true
    }
    
    private func advanceToPhase(_ phase: SessionPhase) {
        // Update current session phase
        currentSession?.advanceToPhase(phase)
        
        // Update UI
        sessionTitle = phase.name
        sessionInstructions = phase.description
        
        // Reset activity
        currentActivity = phase.recommendedActivities.first
        
        // Show phase transition notification
        showAlert = true
        alertTitle = "Phase Complete!"
        alertMessage = "Great job! You're now moving to the \(phase.name)."
    }
    
//    private func updateCharacterAppearance(_ state: IntegratedEmotionalState) {
//        // This would update the character's appearance based on
//        // the current therapeutic response and emotional state
//        
//        // Mark character for update
//        characterNeedsUpdate = true
//    }
}


// Complete implementation for ChildSessionViewModel session handling
extension ChildSessionViewModel {
    func startSession() {
        isLoading = true
        loadingMessage = "Setting up your session..."
        
        // Initialize services
        do {
            // Start facial analysis
            try facialAnalysisService?.startAnalysis()
            
            // Start biometric monitoring
            try biometricAnalysisService?.startMonitoring()
            
            // Create a new session
            currentSession = TherapeuticSession(phase: .connection)
            
            // Initialize character
            updateCharacterConfiguration(CharacterConfiguration.default)
            
            // Set initial activity
            currentActivity = currentSession?.sessionPhase.recommendedActivities.first
            
            // Update UI after delay to show loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isLoading = false
                self.showEmotionFeedback = true
                
                // Start emotional integration
                self.emotionalIntegrationService?.startIntegration(sessionId: self.currentSession?.id.uuidString)
            }
        } catch {
            isLoading = false
            showAlert = true
            alertTitle = "Session Error"
            alertMessage = "Could not start session: \(error.localizedDescription)"
        }
    }
    
    private func updateCharacterAppearance(_ state: IntegratedEmotionalState) {
        // Update character based on emotional state
        if let characterState = determineCharacterState(from: state) {
            characterNeedsUpdate = true
            
            // Only perform character animation if we have an ARView
            if let arView = arView {
                // Find all entities in the scene
                let entities = arView.scene.anchors.flatMap { $0.children }
                
                // Find the character entity (in a real app, you would have a reference to it)
                if let characterEntity = entities.first(where: { $0 is ModelEntity }) as? ModelEntity {
                    // Set character expression
                    let facialExpression = CharacterAction.facialExpression(
                        emotion: characterState.emotion,
                        intensity: characterState.intensity
                    )
                    
                    // Animate the character
                    switch facialExpression {
                    case .facialExpression(let emotion, let intensity):
                        // Apply scaling based on emotion
                        var scaleFactor: SIMD3<Float> = [1.0, 1.0, 1.0]
                        
                        switch emotion {
                        case .happiness:
                            scaleFactor = [1.0 + Float(intensity * 0.1), 1.0, 1.0]
                        case .sadness:
                            scaleFactor = [1.0, 1.0 - Float(intensity * 0.1), 1.0]
                        case .anger:
                            scaleFactor = [1.0 + Float(intensity * 0.1), 1.0 - Float(intensity * 0.05), 1.0]
                        case .fear:
                            scaleFactor = [1.0 - Float(intensity * 0.1), 1.0, 1.0]
                        default:
                            break
                        }
                        
                        // Apply scale animation
                        characterEntity.scale = scaleFactor
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func determineCharacterState(from state: IntegratedEmotionalState) -> (emotion: EmotionType, intensity: Float)? {
        if state.dataQuality == .poor || state.dataQuality == .invalid {
            return nil
        }
        
        // If character should mirror the child
        return (state.dominantEmotion, state.emotionalIntensity * 0.7) // Reduce intensity slightly
    }
}
