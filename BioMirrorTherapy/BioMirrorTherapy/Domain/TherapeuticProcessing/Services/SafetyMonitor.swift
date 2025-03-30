//
//  SafetyMonitor.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class SafetyMonitor {
    // MARK: - Properties
    
    private let emotionalIntegrationService: EmotionalIntegrationService
    private var cancellables = Set<AnyCancellable>()
    
    private let arousalThreshold: Float = 0.9
    private let distressThreshold: Float = 0.8
    private let dissociationThreshold: Float = 0.8
    
    private let emergencyContactManager = EmergencyContactManager()
    private let systemAlertsManager = SystemAlertsManager()
    
    private var currentAlertLevel: AlertLevel = .none
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    
    init(emotionalIntegrationService: EmotionalIntegrationService) {
        self.emotionalIntegrationService = emotionalIntegrationService
        setupSubscriptions()
    }
    
    // MARK: - Session Management
    
    func startMonitoring() {
        sessionStartTime = Date()
        currentAlertLevel = .none
    }
    
    func stopMonitoring() {
        sessionStartTime = nil
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to emotional state updates
        emotionalIntegrationService.integratedStatePublisher
            .sink { [weak self] state in
                self?.assessSafety(state)
            }
            .store(in: &cancellables)
    }
    
    private func assessSafety(_ state: IntegratedEmotionalState) {
        // Check data quality first
        guard state.dataQuality != .invalid && state.dataQuality != .poor else {
            return // Don't make safety decisions on poor quality data
        }
        
        // Check for severe distress
        if isSevereDistress(state) {
            handleSafetyEvent(.severeDistress)
            return
        }
        
        // Check for severe dissociation
        if isSevereDissociation(state) {
            handleSafetyEvent(.severeDissociation)
            return
        }
        
        // Check for extreme physiological arousal
        if isExtremeArousal(state) {
            handleSafetyEvent(.extremeArousal)
            return
        }
        
        // If we reach here, downgrade alert level if needed
        if currentAlertLevel != .none {
            // Only downgrade after several consecutive normal readings
            // Implementation would track this with a counter
            currentAlertLevel = .none
        }
    }
    
    private func isSevereDistress(_ state: IntegratedEmotionalState) -> Bool {
        // Check for indicators of severe emotional distress
        
        // High intensity negative emotion
        let isNegativeEmotion = [
            EmotionType.sadness,
            EmotionType.anger,
            EmotionType.fear,
            EmotionType.disgust
        ].contains(state.dominantEmotion)
        
        if isNegativeEmotion && state.emotionalIntensity > distressThreshold {
            // Also check if physiological state confirms the distress
            if state.physiologicalState.arousalLevel > 0.7 {
                return true
            }
        }
        
        return false
    }
    
    private func isSevereDissociation(_ state: IntegratedEmotionalState) -> Bool {
        // Check for indicators of severe dissociation
        return state.dissociationIndex > dissociationThreshold
    }
    
    private func isExtremeArousal(_ state: IntegratedEmotionalState) -> Bool {
        // Check for extreme physiological arousal
        if state.physiologicalState.arousalLevel > arousalThreshold {
            // Also check heart rate is very high
            if state.physiologicalState.hrvMetrics.heartRate > 110 {
                return true
            }
        }
        
        return false
    }
    
    private func handleSafetyEvent(_ event: SafetyEvent) {
        // Determine appropriate alert level
        let newAlertLevel: AlertLevel
        
        switch event {
        case .severeDistress:
            newAlertLevel = .high
        case .severeDissociation:
            newAlertLevel = currentAlertLevel == .none ? .medium : .high
        case .extremeArousal:
            newAlertLevel = currentAlertLevel == .none ? .medium : .high
        }
        
        // Only escalate alert level, never downgrade during an event
        if newAlertLevel.rawValue > currentAlertLevel.rawValue {
            currentAlertLevel = newAlertLevel
            triggerAlert(level: newAlertLevel, event: event)
        }
    }
    
    private func triggerAlert(level: AlertLevel, event: SafetyEvent) {
        switch level {
        case .low:
            // Generate in-app notification for therapist
            systemAlertsManager.showTherapistAlert(
                message: "Minor safety concern detected: \(event.description)"
            )
            
        case .medium:
            // Generate in-app notification and sound alert
            systemAlertsManager.showTherapistAlert(
                message: "Moderate safety concern: \(event.description)",
                playSound: true
            )
            
            // Suggest session pause
            systemAlertsManager.suggestSessionPause()
            
        case .high:
            // Generate urgent notification with sound
            systemAlertsManager.showTherapistAlert(
                message: "URGENT: Significant safety concern: \(event.description)",
                playSound: true,
                requireAcknowledgment: true
            )
            
            // Suggest session termination
            systemAlertsManager.suggestSessionTermination()
            
            // Notify emergency contact if configured
            if emergencyContactManager.hasEmergencyContact {
                emergencyContactManager.sendEmergencyNotification(
                    message: "Safety concern during BioMirror session. Please check on your child."
                )
            }
            
        case .none:
            // No alert needed
            break
        }
    }
    private func isExtremeArousal(_ state: IntegratedEmotionalState) -> Bool {
           // Check for extremely high physiological arousal
           if state.physiologicalState.arousalLevel > arousalThreshold {
               // Also check heart rate
               if state.physiologicalState.hrvMetrics.heartRate > 120 {
                   return true
               }
           }
           
           return false
       }
       
       private func handleSafetyEvent(_ event: SafetyEvent) {
           // Determine appropriate alert level for the event
           let newAlertLevel: AlertLevel
           
           switch event {
           case .severeDistress:
               newAlertLevel = .high
           case .severeDissociation:
               newAlertLevel = .medium
           case .extremeArousal:
               newAlertLevel = .medium
           case .prolongedNegativeState:
               newAlertLevel = .low
           }
           
           // Only escalate alert level, never downgrade automatically
           if newAlertLevel.rawValue > currentAlertLevel.rawValue {
               currentAlertLevel = newAlertLevel
               triggerSafetyProtocol(for: event, level: newAlertLevel)
           }
       }
       
       private func triggerSafetyProtocol(for event: SafetyEvent, level: AlertLevel) {
           // Take appropriate action based on alert level
           switch level {
           case .high:
               // High alert: notify parent and trigger system intervention
               systemAlertsManager.triggerSessionTermination(reason: event.description)
               emergencyContactManager.notifyParent(event: event)
               
           case .medium:
               // Medium alert: flag for therapist review and notify parent if persistent
               systemAlertsManager.triggerCalming(reason: event.description)
               
               // Only notify parent if persistent
               if sessionStartTime != nil && Date().timeIntervalSince(sessionStartTime!) > 300 {
                   emergencyContactManager.notifyParent(event: event)
               }
               
           case .low:
               // Low alert: flag for therapist review
               systemAlertsManager.logSafetyEvent(event: event)
               
           case .none:
               // No action needed
               break
           }
       }
   }

   enum SafetyEvent {
       case severeDistress
       case severeDissociation
       case extremeArousal
       case prolongedNegativeState
       
       var description: String {
           switch self {
           case .severeDistress:
               return "Severe emotional distress detected"
           case .severeDissociation:
               return "Severe dissociative state detected"
           case .extremeArousal:
               return "Extreme physiological arousal detected"
           case .prolongedNegativeState:
               return "Prolonged negative emotional state detected"
           }
       }
   }

   enum AlertLevel: Int {
       case none = 0
       case low = 1
       case medium = 2
       case high = 3
   }




extension Notification.Name {
    static let sessionTerminationRequired = Notification.Name("sessionTerminationRequired")
    static let calmingInterventionRequired = Notification.Name("calmingInterventionRequired")
}

//
//import Foundation
//import Combine
//
//class SafetyMonitor {
//    // MARK: - Properties
//    
//    private let emotionalIntegrationService: EmotionalIntegrationService
//    private var cancellables = Set<AnyCancellable>()
//    
//    private let arousalThreshold: Float = 0.9
//    private let distressThreshold: Float = 0.8
//    private let dissociationThreshold: Float = 0.8
//    
//    private let emergencyContactManager = EmergencyContactManager()
//    private let systemAlertsManager = SystemAlertsManager()
//    
//    private var currentAlertLevel: AlertLevel = .none
//    private var sessionStartTime: Date?
//    
//    // MARK: - Initialization
//    
//    init(emotionalIntegrationService: EmotionalIntegrationService) {
//        self.emotionalIntegrationService = emotionalIntegrationService
//        setupSubscriptions()
//    }
//    
//    // MARK: - Session Management
//    
//    func startMonitoring() {
//        sessionStartTime = Date()
//        currentAlertLevel = .none
//    }
//    
//    func stopMonitoring() {
//        sessionStartTime = nil
//    }
//    
//    // MARK: - Private Methods
//    
//    private func setupSubscriptions() {
//        // Subscribe to emotional state updates
//        emotionalIntegrationService.integratedStatePublisher
//            .sink { [weak self] state in
//                self?.assessSafety(state)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func assessSafety(_ state: IntegratedEmotionalState) {
//        // Check data quality first
//        guard state.dataQuality != .invalid && state.dataQuality != .poor else {
//            return // Don't make safety decisions on poor quality data
//        }
//        
//        // Check for severe distress
//        if isSevereDistress(state) {
//            handleSafetyEvent(.severeDistress)
//            return
//        }
//        
//        // Check for severe dissociation
//        if isSevereDissociation(state) {
//            handleSafetyEvent(.severeDissociation)
//            return
//        }
//        
//        // Check for extreme physiological arousal
//        if isExtremeArousal(state) {
//            handleSafetyEvent(.extremeArousal)
//            return
//        }
//        
//        // If we reach here, downgrade alert level if needed
//        if currentAlertLevel != .none {
//            // Only downgrade after several consecutive normal readings
//            // Implementation would track this with a counter
//            currentAlertLevel = .none
//        }
//    }
//    
//    private func isSevereDistress(_ state: IntegratedEmotionalState) -> Bool {
//        // Check for indicators of severe emotional distress
//        
//        // High intensity negative emotion
//        let isNegativeEmotion = [
//            EmotionType.sadness,
//            EmotionType.anger,
//            EmotionType.fear,
//            EmotionType.disgust
//        ].contains(state.dominantEmotion)
//        
//        if isNegativeEmotion && state.emotionalIntensity > distressThreshold {
//            // Also check if physiological state confirms the distress
//            if state.physiologicalState.arousalLevel > 0.7 {
//                return true
//            }
//        }
//        
//        return false
//    }
//    
//    private func isSevereDissociation(_ state: IntegratedEmotionalState) -> Bool {
//        // Check for indicators of severe dissociation
//        return state.dissociationIndex > dissociationThreshold
//    }
