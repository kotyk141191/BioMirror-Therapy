//
//  CharacterAction.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import Foundation


enum CharacterGroundingTechnique {
    case visual
    case auditory
    case tactile
}

enum CharacterAnimationAction {
    case facialExpression(emotion: EmotionType, intensity: Float)
    case breathing(speed: Float, depth: Float)
    case grounding(type: CharacterGroundingTechnique) // Updated type
    case movement(direction: MovementDirection, speed: Float)
    case gesture(type: GestureType, speed: Float)
}

enum MovementDirection {
    case up
    case down
    case left
    case right
    case forward
    case backward
}

enum GestureType {
    case wave
    case pointTo
    case nod
    case shake
}
