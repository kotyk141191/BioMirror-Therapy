//
//  TherapeuticResponse.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct TherapeuticResponse {
    let timestamp: Date
    let responseType: TherapeuticResponseType
    let characterEmotionalState: EmotionType
    let characterEmotionalIntensity: Float
    let characterAction: CharacterAction
    let verbal: String?
    let nonverbal: String?
    let interventionLevel: InterventionLevel
    let targetEmotionalState: EmotionType?
    let duration: TimeInterval
}

enum TherapeuticResponseType {
    case mirroring // Reflection of child's emotion
    case titration // Slightly modified version of child's emotion
    case regulation // Response to help regulate emotion
    case grounding // Response to address dissociation
    case validation // Emotional validation
    case exploration // Encourages emotional exploration
    case celebration // Positive reinforcement
    case transition // Help move between activities
}

enum InterventionLevel {
    case minimal
    case moderate
    case significant
    case intensive
}