//
//  TherapeuticResponseScheduler.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class TherapeuticResponseScheduler {
    // MARK: - Properties
    
    private let therapeuticResponseService: TherapeuticResponseService
    private let emotionalStateManager: EmotionalStateManager
    
    private var session: TherapeuticSession?
    private var emotionalStateSubscription: AnyCancellable?
    private var stateChangeSubscription: AnyCancellable?
    
    private let responseSubject = PassthroughSubject<TherapeuticResponse, Never>()
    
    private var lastResponseTime: Date = Date.distantPast
    private var responseDelay: TimeInterval = 1.0
    private var responseSensitivity: Float = 0.5  // 0.0 to 1.0
    
    private var scheduledResponses: [TherapeuticResponse] = []
    private var activeResponse: TherapeuticResponse?
    private var responseTimer: Timer?
    
    // MARK: - Public Access
    
    var responsePublisher: AnyPublisher<TherapeuticResponse, Never> {
        return responseSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(therapeuticResponseService: TherapeuticResponseService, emotionalStateManager: EmotionalStateManager) {
        self.therapeuticResponseService = therapeuticResponseService
        self.emotionalStateManager = emotionalStateManager
    }
    
    // MARK: - Public Methods
    
    func startScheduling(session: TherapeuticSession, sensitivity: Float = 0.5) {
        self.session = session
        self.responseSensitivity = sensitivity
        
        // Update response delay based on sensitivity (more sensitive = shorter delay)
        responseDelay = calculateResponseDelay(sensitivity: sensitivity)
        
        // Subscribe to emotional state changes
        stateChangeSubscription = emotionalStateManager.stateChangePublisher
            .sink { [weak self] stateChange in
                self?.handleStateChange(stateChange)
            }
        
        // Start timer to check scheduled responses
        startResponseTimer()
    }
    
    func stopScheduling() {
        // Stop subscriptions
        stateChangeSubscription?.cancel()
        stateChangeSubscription = nil
        
        // Clear scheduled responses
        scheduledResponses.removeAll()
        
        // Stop timer
        responseTimer?.invalidate()
        responseTimer = nil
        
        // Clear active response
        activeResponse = nil
        session = nil
    }
    
    func scheduleResponse(_ response: TherapeuticResponse) {
        scheduledResponses.append(response)
    }
    
    func setResponseSensitivity(_ sensitivity: Float) {
        responseSensitivity = max(0, min(1, sensitivity))
        responseDelay = calculateResponseDelay(sensitivity: sensitivity)
    }
    
    // MARK: - Private Methods
    
    private func handleStateChange(_ stateChange: EmotionalStateChange) {
        guard let session = session else { return }
        
        // Decide whether to respond based on the type and significance of the change
        if shouldRespondToStateChange(stateChange) {
            // Generate appropriate response
            let response = therapeuticResponseService.generateResponse(for: stateChange.to, in: session)
            
            // Schedule response
            scheduleResponse(response)
        }
    }
    
    private func shouldRespondToStateChange(_ stateChange: EmotionalStateChange) -> Bool {
        // Don't respond if not significant
        if !stateChange.isSignificant {
            return false
        }
        
        // Always respond to dissociation changes
        if stateChange.dissociationChanged {
            return true
        }
        
        // Always respond to regulation state changes
        if stateChange.regulationChanged {
            return true
        }
        
        // Respond to emotion changes based on sensitivity
        if stateChange.emotionChanged {
            return Float.random(in: 0...1) < responseSensitivity
        }
        
        // Respond to large arousal changes based on sensitivity
        if stateChange.arousalChanged {
            let arousalDiff = abs(stateChange.from.arousalLevel - stateChange.to.arousalLevel)
            return arousalDiff > 0.3 && Float.random(in: 0...1) < responseSensitivity
        }
        
        // Respond to coherence changes less frequently
        if stateChange.coherenceChanged {
            return Float.random(in: 0...1) < (responseSensitivity * 0.7)
        }
        
        return false
    }
    
    private func startResponseTimer() {
        responseTimer?.invalidate()
        
        // Create timer to check and deliver scheduled responses
        responseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processScheduledResponses()
        }
    }
    
    private func processScheduledResponses() {
        // If there's an active response and it's not time to end it, do nothing
        if let activeResponse = activeResponse {
            let expirationTime = activeResponse.timestamp.addingTimeInterval(activeResponse.duration)
            if Date() < expirationTime {
                return
            }
            
            // Clear active response
            self.activeResponse = nil
        }
        
        // Check if we have scheduled responses and enough time has passed since last response
        if !scheduledResponses.isEmpty && Date().timeIntervalSince(lastResponseTime) >= responseDelay {
            // Get next response
            let response = scheduledResponses.removeFirst()
            
            // Update timestamp to now
            let updatedResponse = TherapeuticResponse(
                timestamp: Date(),
                responseType: response.responseType,
                characterEmotionalState: response.characterEmotionalState,
                characterEmotionalIntensity: response.characterEmotionalIntensity,
                characterAction: response.characterAction,
                verbal: response.verbal,
                nonverbal: response.nonverbal,
                interventionLevel: response.interventionLevel,
                targetEmotionalState: response.targetEmotionalState,
                duration: response.duration
            )
            
            // Set as active response
            activeResponse = updatedResponse
            
            // Update last response time
            lastResponseTime = Date()
            
            // Publish response
            responseSubject.send(updatedResponse)
        }
    }
    
    private func calculateResponseDelay(sensitivity: Float) -> TimeInterval {
        // Map sensitivity (0.0-1.0) to delay (3.0-0.5 seconds)
        // Higher sensitivity = shorter delay
        return TimeInterval(3.0 - (sensitivity * 2.5))
    }
}
