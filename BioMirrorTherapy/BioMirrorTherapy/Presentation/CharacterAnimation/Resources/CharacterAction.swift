//
//  CharacterAction.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import Foundation

enum CharacterAction {
    case facialExpression(emotion: EmotionType, intensity: Float)
    case breathing(speed: Float, depth: Float)
    case grounding(type: GroundingTechnique)
    case movement(direction: MovementDirection, speed: Float)
    case gesture(type: GestureType, speed: Float)
}

enum GroundingTechnique {
    case visual
    case auditory
    case tactile
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