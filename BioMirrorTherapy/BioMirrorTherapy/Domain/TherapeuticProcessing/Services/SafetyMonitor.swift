//
//  SafetyMonitor.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

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
//    
////    private func isExtremeArousal(_ state: IntegratedEmotionalState) -> Bool {
////        // Check for extreme physiological arousal
////        if state.physiologicalState.arousalLevel > arousalThreshold {
////            // Also check heart rate is very high
////            if state.physiologicalState.hrvMetrics.heartRate > 110 {
////                return true
////            }
////        }
////        
////        return false
////    }
//    
////    private func handleSafetyEvent(_ event: SafetyEvent) {
////        // Determine appropriate alert level
////        let newAlertLevel: AlertLevel
////        
////        switch event {
////        case .severeDistress:
////            newAlertLevel = .high
////        case .severeDissociation:
////            newAlertLevel = currentAlertLevel == .none ? .medium : .high
////        case .extremeArousal:
////            newAlertLevel = currentAlertLevel == .none ? .medium : .high
////        case .prolongedNegativeState:
////            newAlertLevel = currentAlertLevel == .none ? .low : .medium
////        }
////        
////        // Only escalate alert level, never downgrade during an event
////        if newAlertLevel.rawValue > currentAlertLevel.rawValue {
////            currentAlertLevel = newAlertLevel
////            triggerAlert(level: newAlertLevel, event: event)
////        }
////    }
//    
   
//   }

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

//import Foundation
//
class SafetyMonitor {
    // MARK: - Properties
    
    // Thresholds for intervention
    private let distressArousalThreshold: Float = 0.9
    private let distressDurationThreshold: TimeInterval = 120 // 2 minutes
    private let dissociationSevereThreshold: Float = 0.8
    
    // Current session tracking
    private var distressStartTime: Date?
    private var isInDistress = false
    private var parentAlertSent = false
    private var sessionTerminated = false
    
        private let emotionalIntegrationService: EmotionalIntegrationService
        private var cancellables = Set<AnyCancellable>()
    
        private let arousalThreshold: Float = 0.9
        private let distressThreshold: Float = 0.8
        private let dissociationThreshold: Float = 0.8
    
        private let emergencyContactManager = EmergencyContactManager()
        private let systemAlertsManager = SystemAlertsManager()
    
        private var currentAlertLevel: AlertLevel = .none
        private var sessionStartTime: Date?
    
    // MARK: - Public Methods
    
    // MARK: - Initialization
   //
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
    
    func needsIntervention(_ state: IntegratedEmotionalState) -> Bool {
        // Check arousal level
        if state.arousalLevel > distressArousalThreshold {
            if !isInDistress {
                distressStartTime = state.timestamp
                isInDistress = true
            } else if let startTime = distressStartTime {
                let distressDuration = state.timestamp.timeIntervalSince(startTime)
                
                // Extended distress requires intervention
                if distressDuration > distressDurationThreshold {
                    if !parentAlertSent {
                        sendParentAlert()
                    }
                    return true
                }
            }
            
            return true // Immediate regulation for high arousal
        } else {
            // Reset distress tracking if arousal has decreased
            if isInDistress && state.arousalLevel < distressArousalThreshold - 0.2 {
                isInDistress = false
                distressStartTime = nil
            }
        }
        
        // Check for severe dissociation
        if state.dissociationIndex > dissociationSevereThreshold {
            if !parentAlertSent {
                sendParentAlert()
            }
            return true
        }
        
        return false
    }
    
    func shouldTerminateSession(_ state: IntegratedEmotionalState) -> Bool {
        // Check if session should be terminated for safety
        
        // Terminate if extremely high distress persists
        if isInDistress,
           let startTime = distressStartTime,
           state.timestamp.timeIntervalSince(startTime) > distressDurationThreshold * 2,
           state.arousalLevel > distressArousalThreshold {
            
            if !sessionTerminated {
                sessionTerminated = true
                sendTherapistAlert(state)
            }
            
            return true
        }
        
        // Terminate if severe dissociation persists
        if state.dissociationIndex > dissociationSevereThreshold,
           state.dataQuality != .poor {
            
            if !sessionTerminated {
                sessionTerminated = true
                sendTherapistAlert(state)
            }
            
            return true
        }
        
        return false
    }
    
    func reset() {
        distressStartTime = nil
        isInDistress = false
        parentAlertSent = false
        sessionTerminated = false
    }
    
    // MARK: - Private Methods
    
    private func sendParentAlert() {
        // Send alert to parent/caregiver
        parentAlertSent = true
        print("🚨 SAFETY ALERT: Parent/caregiver notification sent")
        
        // In a real implementation, this would trigger a notification
        // to the parent's device or interface
    }
    
    private func sendTherapistAlert(_ state: IntegratedEmotionalState) {
        // Send detailed alert to therapist
        print("🚨🚨 URGENT SAFETY ALERT: Therapist notification sent")
        print("Arousal level: \(state.arousalLevel)")
        print("Dissociation index: \(state.dissociationIndex)")
        
        // In a real implementation, this would send detailed data
        // to the therapist dashboard and potentially a direct alert
    }
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
