//
//  EmergencyContactManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import UserNotifications

class EmergencyContactManager {
    // MARK: - Properties
    
    var hasEmergencyContact: Bool {
        return emergencyContactName != nil && emergencyContactPhone != nil
    }
    
    private var emergencyContactName: String? {
        return UserDefaults.standard.string(forKey: "emergencyContactName")
    }
    
    private var emergencyContactPhone: String? {
        return UserDefaults.standard.string(forKey: "emergencyContactPhone")
    }
    
    private var emergencyContactPreferredMethod: ContactMethod {
        let rawValue = UserDefaults.standard.integer(forKey: "emergencyContactMethod")
        return ContactMethod(rawValue: rawValue) ?? .notification
    }
    
    // MARK: - Public Methods
    
    func setEmergencyContact(name: String, phone: String, method: ContactMethod) {
        UserDefaults.standard.set(name, forKey: "emergencyContactName")
        UserDefaults.standard.set(phone, forKey: "emergencyContactPhone")
        UserDefaults.standard.set(method.rawValue, forKey: "emergencyContactMethod")
    }
    
    func clearEmergencyContact() {
        UserDefaults.standard.removeObject(forKey: "emergencyContactName")
        UserDefaults.standard.removeObject(forKey: "emergencyContactPhone")
    }
    
    func sendEmergencyNotification(message: String) {
        guard hasEmergencyContact else { return }
        
        switch emergencyContactPreferredMethod {
        case .notification:
            sendPushNotification(message: message)
        case .sms:
            sendSMS(message: message)
        case .both:
            sendPushNotification(message: message)
            sendSMS(message: message)
        }
    }
    
    // MARK: - Private Methods
    
    private func sendPushNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "BioMirror Safety Alert"
        content.body = message
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "emergency-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending emergency notification: \(error)")
            }
        }
    }
    
    private func sendSMS(message: String) {
        guard let phone = emergencyContactPhone else { return }
        
        // In a real implementation, this would integrate with an SMS service
        // For now, we'll just log that an SMS would be sent
        print("Would send SMS to \(phone): \(message)")
    }
}

enum ContactMethod: Int {
    case notification = 0
    case sms = 1
    case both = 2
}
