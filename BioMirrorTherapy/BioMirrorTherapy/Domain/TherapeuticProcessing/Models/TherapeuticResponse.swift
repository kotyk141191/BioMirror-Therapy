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
    let characterAction: CharacterAction?
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

enum CharacterAction {
    case breathing(speed: Float, depth: Float)
    case facialExpression(emotion: EmotionType, intensity: Float)
    case bodyMovement(type: MovementType, intensity: Float)
    case vocalization(type: VocalizationType)
    case attention(focus: AttentionFocus)
}

enum MovementType {
    case gentle
    case energetic
    case protective
    case playful
    case freeze
    case rhythmic
}

enum VocalizationType {
    case laugh
    case sigh
    case hum
    case gasp
}

enum AttentionFocus {
    case direct // Looking at child
    case away // Looking away
    case shared // Looking at same thing as child
    case scanning // Looking around
}

enum InterventionLevel {
    case minimal
    case moderate
    case significant
    case intensive
}

