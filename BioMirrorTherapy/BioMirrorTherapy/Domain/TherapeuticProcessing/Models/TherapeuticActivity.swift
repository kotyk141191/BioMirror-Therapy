//
//  TherapeuticActivity.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct TherapeuticActivity {
    let type: ActivityType
    let name: String
    let description: String
    let minDuration: TimeInterval = 60 // 1 minute minimum
    let maxDuration: TimeInterval = 300 // 5 minutes maximum
    
    var instruction: String {
        switch type {
        case .characterCustomization:
            return "Create a character that feels like a good friend to you."
        case .emotionalMatching:
            return "Match the emotions you see on the character's face."
        case .basicMirroring:
            return "Watch how the character copies your expressions."
        case .bodyAwareness:
            return "Notice how your body feels right now."
        case .emotionalExploration:
            return "Explore different emotions with your character."
        case .bodyMapping:
            return "Show where you feel different emotions in your body."
        case .emotionalVocabulary:
            return "Learn words for different kinds of feelings."
        case .mirroring:
            return "Notice how the character mirrors your feelings."
        case .coherenceBuilding:
            return "Practice matching your face to your feelings."
        case .grounding:
            return "Learn tools to help you feel present in your body."
        case .coRegulation:
            return "Breathe together with your character to feel calm."
        case .emotionalNarrative:
            return "Create a story about your emotional journey."
        case .scenarioSimulation:
            return "Practice using your skills in everyday situations."
        case .regulationToolkit:
            return "Create your own personal set of coping tools."
        case .progressCelebration:
            return "Celebrate all the progress you've made."
        case .independentPractice:
            return "Try using your skills without the character's help."
        case .mindfulness:
            return "Practice mindful breathing to calm your mind."
        case .soothingVisuals:
            return "Look at soothing images to ease your emotions."
        case .guidedRelaxation:
            return "Follow a guided relaxation to reduce stress."
        }
    }
    
    var isAvailable: Bool {
        return true // Override in subclass with actual availability logic
    }
}

enum ActivityType {
    // Connection Phase
    case characterCustomization
    case emotionalMatching
    case basicMirroring
    case bodyAwareness
    
    // Awareness Phase
    case emotionalExploration
    case bodyMapping
    case emotionalVocabulary
    case mirroring
    
    // Integration Phase
    case coherenceBuilding
    case grounding
    case coRegulation
    case emotionalNarrative
    
    // Regulation Phase
    case mindfulness
    case soothingVisuals
    case guidedRelaxation
    
    // Transfer Phase
    case scenarioSimulation
    case regulationToolkit
    case progressCelebration
    case independentPractice
}
