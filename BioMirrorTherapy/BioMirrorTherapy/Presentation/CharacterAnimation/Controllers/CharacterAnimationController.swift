//
//  CharacterAnimationController.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import ARKit
import RealityKit
import Combine

class CharacterAnimationController {
    // MARK: - Properties
    
    private var arView: ARView
    private var characterEntity: CharacterEntity?
    private var animationCancellables = Set<AnyCancellable>()
    
    private var characterConfiguration: CharacterConfiguration
    
    // MARK: - Initialization
    
    init(arView: ARView, configuration: CharacterConfiguration = .default) {
        self.arView = arView
        self.characterConfiguration = configuration
        setupAREnvironment()
    }
    
    // MARK: - Public Methods
    
    /// Load character with the specified configuration
    /// - Parameter completion: Called when character is loaded
    func loadCharacter(completion: @escaping (Bool) -> Void) {
        // Remove existing character if any
        characterEntity?.removeFromParent()
        
        // Create a new character entity
        let entity = CharacterEntity(configuration: characterConfiguration)
        
        // Create anchor 0.5 meters in front of camera
        let anchor = AnchorEntity(world: [0, -0.1, -0.5])
        anchor.addChild(entity)
        
        // Add to scene
        arView.scene.addAnchor(anchor)
        characterEntity = entity
        
        // Set initial idle state
        entity.playAnimation(.idle)
        
        completion(true)
    }
    
    /// Express an emotion on the character
    /// - Parameters:
    ///   - emotion: Emotion to express
    ///   - intensity: Intensity of the emotion (0.0-1.0)
    ///   - duration: Duration of the expression
    ///   - completion: Called when animation is complete
    func expressEmotion(_ emotion: EmotionType, intensity: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let entity = characterEntity else { return }
        
        // Map emotion to character animation
        let animation = mapEmotionToAnimation(emotion, intensity: intensity)
        
        // Play emotion animation
        entity.playAnimation(animation)
        
        // Schedule return to idle after duration
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                entity.playAnimation(.idle)
                completion?()
            }
        }
    }
    
    /// Perform a character action
    /// - Parameters:
    ///   - action: Action to perform
    ///   - completion: Called when animation is complete
    func performAction(_ action: CharacterAction, completion: (() -> Void)? = nil) {
        guard let entity = characterEntity else { return }
        
        switch action {
        case .breathing(let speed, let depth):
            entity.animateBreathing(speed: speed, depth: depth)
            
        case .facialExpression(let emotion, let intensity):
            expressEmotion(emotion, intensity: intensity, duration: 0)
            
        case .bodyMovement(let type, let intensity):
            let animation = mapMovementTypeToAnimation(type, intensity: intensity)
            entity.playAnimation(animation)
            
        case .vocalization(let type):
            playVocalization(type)
            
        case .attention(let focus):
            entity.setAttentionFocus(focus)
        }
        
        completion?()
    }
    
    /// Update character configuration
    /// - Parameter configuration: New configuration
    func updateConfiguration(_ configuration: CharacterConfiguration) {
        self.characterConfiguration = configuration
        characterEntity?.updateConfiguration(configuration)
    }
    
    /// Implement a therapeutic response with the character
    /// - Parameter response: Therapeutic response to implement
    func implementTherapeuticResponse(_ response: TherapeuticResponse) {
        guard let entity = characterEntity else { return }
        
        // Set character's emotional state
        expressEmotion(response.characterEmotionalState,
                       intensity: response.characterEmotionalIntensity,
                       duration: 0)
        
        // Perform character action if specified
        if let action = response.characterAction {
            performAction(action)
        }
        
        // Speak verbalization if provided
        if let verbal = response.verbal {
            speak(verbal)
        }
    }
    
    /// Have the character speak text
    /// - Parameter text: Text to speak
    func speak(_ text: String) {
        guard let entity = characterEntity else { return }
        
        // Animate speaking
        entity.animateSpeaking(text: text)
        
        // Use speech synthesis to speak the text
        let speechSynthesizer = SpeechSynthesizer.shared
        speechSynthesizer.speak(text, voice: characterConfiguration.voiceType)
    }
    
    // MARK: - Private Methods
    
    private func setupAREnvironment() {
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // Run the session
        arView.session.run(configuration)
        
        // Add coaching overlay if needed
        if ARWorldTrackingConfiguration.isSupported {
            let coachingOverlay = ARCoachingOverlayView()
            coachingOverlay.session = arView.session
            coachingOverlay.goal = .horizontalPlane
            coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            arView.addSubview(coachingOverlay)
        }
    }
    
    private func mapEmotionToAnimation(_ emotion: EmotionType, intensity: Float) -> CharacterAnimationType {
        // Map emotion types to character animations
        switch emotion {
        case .happiness:
            return intensity > 0.7 ? .happyIntense : .happy
        case .sadness:
            return intensity > 0.7 ? .sadIntense : .sad
        case .anger:
            return intensity > 0.7 ? .angryIntense : .angry
        case .fear:
            return intensity > 0.7 ? .fearIntense : .fear
        case .surprise:
            return intensity > 0.7 ? .surpriseIntense : .surprise
        case .disgust:
            return intensity > 0.7 ? .disgustIntense : .disgust
        case .neutral:
            return .neutral
        case .contempt:
            return .contempt
        default:
            return .neutral
        }
    }
    
    private func mapMovementTypeToAnimation(_ movementType: MovementType, intensity: Float) -> CharacterAnimationType {
        // Map movement types to character animations
        switch movementType {
        case .gentle:
            return .gentleMovement
        case .energetic:
            return .energeticMovement
        case .protective:
            return .protectiveMovement
        case .playful:
            return .playfulMovement
        case .freeze:
            return .freezeResponse
        case .rhythmic:
            return .rhythmicMovement
        }
    }
    
    private func playVocalization(_ type: VocalizationType) {
        // Map vocalization type to sound file
        let soundFileName: String
        
        switch type {
        case .laugh:
            soundFileName = "character_laugh"
        case .sigh:
            soundFileName = "character_sigh"
        case .hum:
            soundFileName = "character_hum"
        case .gasp:
            soundFileName = "character_gasp"
        }
        
        // Play sound
        if let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") {
            SoundManager.shared.playSound(at: soundURL)
        }
    }
}
