//
//  UserSessionManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

enum UserType {
    case child
    case parent
    case therapist
    case none
}

class UserSessionManager {
    static let shared = UserSessionManager()
    
    private let defaults = UserDefaults.standard
    
    var userType: UserType {
        get {
            guard let rawValue = defaults.string(forKey: "userType") else {
                return .none
            }
            
            switch rawValue {
            case "child": return .child
            case "parent": return .parent
            case "therapist": return .therapist
            default: return .none
            }
        }
        set {
            let rawValue: String
            
            switch newValue {
            case .child: rawValue = "child"
            case .parent: rawValue = "parent"
            case .therapist: rawValue = "therapist"
            case .none: rawValue = ""
            }
            
            defaults.set(rawValue, forKey: "userType")
        }
    }
    
    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: "isOnboardingCompleted") }
        set { defaults.set(newValue, forKey: "isOnboardingCompleted") }
    }
    
    var userId: String? {
        get { defaults.string(forKey: "userId") }
        set { defaults.set(newValue, forKey: "userId") }
    }
    
    var selectedCharacter: String? {
        get { defaults.string(forKey: "selectedCharacter") }
        set { defaults.set(newValue, forKey: "selectedCharacter") }
    }
    
    var analyticsEnabled: Bool {
        get { defaults.bool(forKey: "analyticsEnabled") }
        set { defaults.set(newValue, forKey: "analyticsEnabled") }
    }
    
    private init() {}
    
    func clearSession() {
        userType = .none
        isOnboardingCompleted = false
        userId = nil
        
        // Keep preferences and selected character
    }
}
