//
//  CharacterConfiguration.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import UIKit

struct CharacterConfiguration {
    let characterType: CharacterType
    let primaryColor: UIColor
    let secondaryColor: UIColor
    let accessoryItems: [AccessoryItem]
    let voiceType: VoiceType
    let expressiveness: Float // 0.0-1.0, how expressive animations should be
    
    static let `default` = CharacterConfiguration(
        characterType: .friendly,
        primaryColor: .systemBlue,
        secondaryColor: .systemTeal,
        accessoryItems: [],
        voiceType: .neutral,
        expressiveness: 0.8
    )
}

enum CharacterType: String {
    case friendly
    case protective
    case calm
    case playful
    case wise
    
    var defaultName: String {
        switch self {
        case .friendly: return "Buddy"
        case .protective: return "Guardian"
        case .calm: return "Serene"
        case .playful: return "Sparkle"
        case .wise: return "Sage"
        }
    }
}

enum VoiceType: String {
    case neutral
    case gentle
    case energetic
    case calm
    case soft
}

enum AccessoryItem: String {
    case hat
    case glasses
    case scarf
    case badge
    case backpack
}
