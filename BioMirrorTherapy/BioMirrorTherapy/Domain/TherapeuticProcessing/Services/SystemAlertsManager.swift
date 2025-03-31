//
//  SystemAlertsManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import UserNotifications

class SystemAlertsManager {
    // MARK: - Properties
    
    private var therapistAlertDelegate: TherapistAlertDelegate?
    
    // MARK: - Initialization
    
    func registerTherapistAlertDelegate(_ delegate: TherapistAlertDelegate) {
        self.therapistAlertDelegate = delegate
    }
    
    // MARK: - Public Methods
    
    func showTherapistAlert(message: String, playSound: Bool = false, requireAcknowledgment: Bool = false) {
        // Try to show alert through delegate first
        if let delegate = therapistAlertDelegate {
            delegate.showTherapistAlert(
                message: message,
                playSound: playSound,
                requireAcknowledgment: requireAcknowledgment
            )
            return
        }
        
        // Fallback to push notification if no delegate
        let content = UNMutableNotificationContent()
        content.title = "BioMirror Therapist Alert"
        content.body = message
        
        if playSound {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "therapist-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending therapist alert: \(error)")
            }
        }
    }
    
    func suggestSessionPause() {
        therapistAlertDelegate?.suggestSessionPause()
    }
    
    func suggestSessionTermination() {
        therapistAlertDelegate?.suggestSessionTermination()
    }
}

protocol TherapistAlertDelegate: AnyObject {
    func showTherapistAlert(message: String, playSound: Bool, requireAcknowledgment: Bool)
    func suggestSessionPause()
    func suggestSessionTermination()
}
