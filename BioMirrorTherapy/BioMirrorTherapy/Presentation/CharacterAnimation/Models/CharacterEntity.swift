//
//  CharacterEntity.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import Foundation
import UIKit
import RealityKit

//enum CharacterType {
//    case friendly
//    case calming
//    case playful
//    case supportive
//}
//
enum CharacterAction {
    case facialExpression(emotion: EmotionType, intensity: Float)
    case breathing(speed: Float, depth: Float)
    case grounding(type: GroundingType)
    case attention(focus: AttentionFocus)
    case bodyMovement(type: MovementType, intensity: Float)
    
    enum GroundingType {
        case tactile
        case visual
        case auditory
    }
    
    enum AttentionFocus {
        case direct
        case averted
        case shared
    }
    
    enum MovementType {
        case gentle
        case energetic
        case rhythmic
        case protective
    }
}
