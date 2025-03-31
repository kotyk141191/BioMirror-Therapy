//
//  SessionPhase.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

enum SessionPhase: Int, CaseIterable {
    case connection = 0
    case awareness = 1
    case integration = 2
    case regulation = 3
    case transfer = 4
    
    var name: String {
        switch self {
        case .connection: return "Connection"
        case .awareness: return "Emotional Awareness"
        case .integration: return "Emotional Integration"
        case .regulation: return "Emotional Regulation"
        case .transfer: return "Skill Transfer"
        }
    }
    
    var description: String {
        switch self {
        case .connection:
            return "Building relationship and establishing baseline"
        case .awareness:
            return "Developing emotional recognition and vocabulary"
        case .integration:
            return "Connecting emotions with sensations and experiences"
        case .regulation:
            return "Modulating intense emotions through adaptive strategies"
        case .transfer:
            return "Applying skills to daily life scenarios"
        }
    }
    
    var objectives: [String] {
        switch self {
        case .connection:
            return [
                "Establish comfort with technology",
                "Build relationship with mirroring character",
                "Establish emotional baseline",
                "Introduce basic emotional vocabulary"
            ]
        case .awareness:
            return [
                "Increase recognition of emotional states",
                "Connect physical sensations to emotions",
                "Identify personal triggers",
                "Develop ability to name emotional states"
            ]
        case .integration:
            return [
                "Strengthen connection between felt and expressed emotions",
                "Reduce dissociative responses",
                "Build regulation strategies",
                "Practice emotional communication"
            ]
        case .regulation:
            return [
                "Detect and address emotional dysregulation",
                "Apply tailored regulation strategies",
                "Modulate high emotional intensity",
                "Reinforce adaptive emotional responses"
            ]
        case .transfer:
            return [
                "Apply skills to daily scenarios",
                "Reduce dependency on the system",
                "Develop sustainable regulation strategies",
                "Plan for continued practice"
            ]
        }
    }
    
    var recommendedActivities: [TherapeuticActivity] {
        switch self {
        case .connection:
            return [
                TherapeuticActivity(type: .characterCustomization, name: "Character Creation", description: "Personalize your character"),
                TherapeuticActivity(type: .emotionalMatching, name: "Emotion Matching", description: "Match basic emotions with the character"),
                TherapeuticActivity(type: .basicMirroring, name: "Mirror Play", description: "Simple mirroring interactions"),
                TherapeuticActivity(type: .bodyAwareness, name: "Body Check-In", description: "Notice how your body feels")
            ]
        case .awareness:
            return [
                TherapeuticActivity(type: .emotionalExploration, name: "Emotion Explorer", description: "Explore different emotions"),
                TherapeuticActivity(type: .bodyMapping, name: "Emotion Body Map", description: "Identify where emotions are felt in your body"),
                TherapeuticActivity(type: .emotionalVocabulary, name: "Emotion Words", description: "Learn words for different feelings"),
                TherapeuticActivity(type: .mirroring, name: "Mirror My Feelings", description: "See the character mirror your emotions")
            ]
        case .integration:
            return [
                TherapeuticActivity(type: .coherenceBuilding, name: "Match Yourself", description: "Align your face with your feelings"),
                TherapeuticActivity(type: .grounding, name: "Grounding Tools", description: "Use tools to stay present"),
                TherapeuticActivity(type: .coRegulation, name: "Breathe Together", description: "Breathe in sync with the character"),
                TherapeuticActivity(type: .emotionalNarrative, name: "My Feelings Story", description: "Create a narrative about your emotions")
            ]
        case .regulation:
            return [
                TherapeuticActivity(type: .regulationToolkit, name: "Calming Strategies", description: "Explore techniques to modulate strong emotions"),
                TherapeuticActivity(type: .mindfulness, name: "Mindful Breathing", description: "Practice calming breathing exercises"),
                TherapeuticActivity(type: .soothingVisuals, name: "Soothing Imagery", description: "View calming images to help regulate emotions"),
                TherapeuticActivity(type: .guidedRelaxation, name: "Guided Relaxation", description: "Follow a guided session to reduce emotional intensity")
            ]
        case .transfer:
            return [
                TherapeuticActivity(type: .scenarioSimulation, name: "Real Life Practice", description: "Practice skills in everyday situations"),
                TherapeuticActivity(type: .regulationToolkit, name: "My Feelings Toolkit", description: "Develop your personal coping tools"),
                TherapeuticActivity(type: .progressCelebration, name: "Celebration Journey", description: "Celebrate your progress"),
                TherapeuticActivity(type: .independentPractice, name: "Practice On My Own", description: "Apply skills independently")
            ]
        }
    }
    
    var nextPhase: SessionPhase? {
        return SessionPhase(rawValue: self.rawValue + 1)
    }
    
    var previousPhase: SessionPhase? {
        return rawValue > 0 ? SessionPhase(rawValue: self.rawValue - 1) : nil
    }
}
