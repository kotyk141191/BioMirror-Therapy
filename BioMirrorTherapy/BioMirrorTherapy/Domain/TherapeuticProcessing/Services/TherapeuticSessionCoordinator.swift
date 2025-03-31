//
//  TherapeuticSessionCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class TherapeuticSessionCoordinator {
    // MARK: - Properties
    
    private let therapeuticResponseService: TherapeuticResponseService
    private let emotionalIntegrationService: EmotionalIntegrationService
    private let facialAnalysisService: FacialAnalysisService
    private let biometricAnalysisService: BiometricAnalysisService
    private let emotionalStateManager: EmotionalStateManager
    private let responseScheduler: TherapeuticResponseScheduler
    private let safetyMonitor: SafetyMonitor
    
    private var activeSession: TherapeuticSession?
    private var sessionStartTime: Date?
    private var sessionDuration: TimeInterval = 1200 // 20 minutes default
    
    private let sessionStateSubject = PassthroughSubject<SessionState, Never>()
    private let responseSubject = PassthroughSubject<TherapeuticResponse, Never>()
    
    private var responseSubscription: AnyCancellable?
    private var sessionTimer: Timer?
    private var sessionPhaseTimer: Timer?
    
    // MARK: - Public Access
    
    var sessionStatePublisher: AnyPublisher<SessionState, Never> {
        return sessionStateSubject.eraseToAnyPublisher()
    }
    
    var responsePublisher: AnyPublisher<TherapeuticResponse, Never> {
        return responseSubject.eraseToAnyPublisher()
    }
    
    var currentSessionID: UUID? {
        return activeSession?.id
    }
    
    // MARK: - Initialization
    
    init(
        therapeuticResponseService: TherapeuticResponseService,
        emotionalIntegrationService: EmotionalIntegrationService,
        facialAnalysisService: FacialAnalysisService,
        biometricAnalysisService: BiometricAnalysisService,
        emotionalStateManager: EmotionalStateManager,
        responseScheduler: TherapeuticResponseScheduler,
        safetyMonitor: SafetyMonitor
    ) {
        self.therapeuticResponseService = therapeuticResponseService
        self.emotionalIntegrationService = emotionalIntegrationService
        self.facialAnalysisService = facialAnalysisService
        self.biometricAnalysisService = biometricAnalysisService
        self.emotionalStateManager = emotionalStateManager
        self.responseScheduler = responseScheduler
        self.safetyMonitor = safetyMonitor
    }
    
    // MARK: - Public Methods
    
    func startSession(phase: SessionPhase = .connection, duration: TimeInterval = 1200) throws {
        // Update state
        sessionStateSubject.send(.preparing)
        
        // Start facial analysis
        do {
            try facialAnalysisService.startAnalysis()
        } catch {
            sessionStateSubject.send(.error)
            throw error
        }
        
        // Start biometric analysis
        do {
            try biometricAnalysisService.startMonitoring()
        } catch {
            facialAnalysisService.stopAnalysis() // Clean up
            sessionStateSubject.send(.error)
            throw error
        }
        
        // Start integration
        emotionalIntegrationService.startIntegration()
        
        // Start emotional state monitoring
        emotionalStateManager.startMonitoring()
        
        // Create therapeutic session
        let session = therapeuticResponseService.startSession(phase: phase)
        activeSession = session
        
        // Set session duration
        sessionDuration = duration
        sessionStartTime = Date()
        
        // Start safety monitoring
        safetyMonitor.startMonitoring()
        
        // Start response scheduling
        responseScheduler.startScheduling(session: session, sensitivity: 0.7)
        
        // Subscribe to responses
        responseSubscription = responseScheduler.responsePublisher
            .sink { [weak self] response in
                self?.responseSubject.send(response)
            }
        
        // Start session timer
        startSessionTimer()
        
        // Start phase progression timer
        startPhaseProgressionTimer(initialPhase: phase)
        
        // Update state
        sessionStateSubject.send(.active)
    }
    
    func endSession() {
        guard let session = activeSession else {
            return
        }
        
        // End session in response service
        therapeuticResponseService.endSession(session)
        
        // Stop all services
        facialAnalysisService.stopAnalysis()
        biometricAnalysisService.stopMonitoring()
        emotionalIntegrationService.stopIntegration()
        emotionalStateManager.stopMonitoring()
        responseScheduler.stopScheduling()
        safetyMonitor.stopMonitoring()
        
        // Stop timers
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        sessionPhaseTimer?.invalidate()
        sessionPhaseTimer = nil
        
        // Clean up subscriptions
        responseSubscription?.cancel()
        responseSubscription = nil
        
        // Update state
        sessionStateSubject.send(.completed)
        
        // Clear active session
        activeSession = nil
        sessionStartTime = nil
    }
    
    func pauseSession() {
        guard activeSession != nil else { return }
        
        // Pause services
        facialAnalysisService.pauseAnalysis()
        biometricAnalysisService.pauseMonitoring()
        
        // Pause timers
        sessionTimer?.invalidate()
        sessionPhaseTimer?.invalidate()
        
        // Update state
        sessionStateSubject.send(.paused)
    }
    
    func resumeSession() {
        guard let session = activeSession, sessionStartTime != nil else { return }
        
        // Resume services
        facialAnalysisService.resumeAnalysis()
        biometricAnalysisService.resumeMonitoring()
        
        // Restart timers
        startSessionTimer()
        startPhaseProgressionTimer(initialPhase: session.sessionPhase)
        
        // Update state
        sessionStateSubject.send(.active)
    }
    
    func getCurrentSessionProgress() -> Float {
        guard let startTime = sessionStartTime, activeSession != nil else {
            return 0.0
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        return Float(min(1.0, elapsedTime / sessionDuration))
    }
    
    func advanceToPhase(_ phase: SessionPhase) {
        guard let session = activeSession else { return }
        
        // Update session phase
        session.advancePhase(to: phase)
        
        // Restart phase timer with new phase
        startPhaseProgressionTimer(initialPhase: phase)
    }
    
    // MARK: - Private Methods
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        
        // Create timer for session duration
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionDuration, repeats: false) { [weak self] _ in
            // Auto-end session when time expires
            self?.endSession()
        }
    }
    
    private func startPhaseProgressionTimer(initialPhase: SessionPhase) {
        sessionPhaseTimer?.invalidate()
        
        // Skip if already in transfer phase (final phase)
        if initialPhase == .transfer {
            return
        }
        
        // Calculate timing for phase progression
        // In a real app, this would be more sophisticated and based on the child's progress
        let phaseProgression: [(SessionPhase, TimeInterval)] = [
            (.connection, sessionDuration * 0.15),     // 15% of session
            (.awareness, sessionDuration * 0.30),      // 30% of session
            (.integration, sessionDuration * 0.30),    // 30% of session
            (.regulation, sessionDuration * 0.15),     // 15% of session
            (.transfer, sessionDuration * 0.10)        // 10% of session
        ]
        
        // Find current phase index
        guard let currentIndex = phaseProgression.firstIndex(where: { $0.0 == initialPhase }) else {
            return
        }
        
        // Calculate time to next phase
        var timeTillNextPhase: TimeInterval = 0
        for i in currentIndex..<(phaseProgression.count - 1) {
            timeTillNextPhase += phaseProgression[i].1
            
            // Create timer for next phase
            let nextPhase = phaseProgression[i + 1].0
            
            Timer.scheduledTimer(withTimeInterval: timeTillNextPhase, repeats: false) { [weak self] _ in
                guard let self = self, let session = self.activeSession else { return }
                
                // Only advance if session is still active
                if self.sessionStateSubject.value == .active {
                    session.advancePhase(to: nextPhase)
                }
            }
        }
    }
}
