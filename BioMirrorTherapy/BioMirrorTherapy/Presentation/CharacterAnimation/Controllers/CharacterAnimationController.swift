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
    
    
    // Character components
    private var headEntity: ModelEntity?
    private var faceEntity: ModelEntity?
    private var bodyEntity: ModelEntity?
    
    // Animation state
    private var currentAnimationType: CharacterAnimationType = .idle
    private var currentEmotion: EmotionType = .neutral
    private var currentIntensity: Float = 0.0
    private var isBreathing = false
    private var isSpeaking = false
    
    // Animation subscribers
    private var cancellables = Set<AnyCancellable>()
    
    // Animation timing
    private var blendDuration: TimeInterval = 0.3
    // MARK: - Initialization
    
    init(arView: ARView, configuration: CharacterConfiguration = .default) {
        self.arView = arView
        self.characterConfiguration = configuration
        
        setupAREnvironment()
        loadCharacterModel()
    }
    
    // MARK: - Public Methods
    
    /// Load character with the specified configuration
    /// - Parameter completion: Called when character is loaded
    
    
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
    
    
    
    // MARK: - Public Methods
    
    /// Load character with the specified configuration
    /// - Parameter completion: Called when character is loaded
    func loadCharacter(completion: @escaping (Bool) -> Void) {
        // Remove existing character if any
        characterEntity?.removeFromParent()
        
        // Load the character model based on configuration
        loadCharacterModel()
        
        // Set initial idle state
        playAnimation(.idle)
        
        completion(true)
    }
    
    /// Express an emotion on the character
    /// - Parameters:
    ///   - emotion: Emotion to express
    ///   - intensity: Intensity of the emotion (0.0-1.0)
    ///   - duration: Duration of the expression
    ///   - completion: Called when animation is complete
    func expressEmotion(_ emotion: EmotionType, intensity: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        // Save current emotion state
        currentEmotion = emotion
        currentIntensity = intensity
        
        // Map emotion to character animation
        let animation = mapEmotionToAnimation(emotion, intensity: intensity)
        
        // Apply facial blend shapes for the emotion
        updateFacialBlendShapes(for: emotion, intensity: intensity)
        
        // Play emotion animation
        playAnimation(animation)
        
        // Adjust body posture for emotion
        adjustBodyPosture(for: emotion, intensity: intensity)
        
        // Schedule return to idle after duration if specified
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self else { return }
                
                // Transition back to idle
                self.playAnimation(.idle)
                self.updateFacialBlendShapes(for: .neutral, intensity: 0.3)
                self.adjustBodyPosture(for: .neutral, intensity: 0.3)
                
                // Reset current emotion
                self.currentEmotion = .neutral
                self.currentIntensity = 0.3
                
                completion?()
            }
        } else if let completion = completion {
            // Call completion immediately if no duration
            completion()
        }
    }
    
    /// Perform a character action
    /// - Parameters:
    ///   - action: Action to perform
    ///   - completion: Called when animation is complete
    func performAction(_ action: CharacterAction, completion: (() -> Void)? = nil) {
        switch action {
        case .breathing(let speed, let depth):
            animateBreathing(speed: speed, depth: depth)
            completion?()
            
        case .facialExpression(let emotion, let intensity):
            expressEmotion(emotion, intensity: intensity, duration: 0, completion: completion)
            
        case .bodyMovement(let type, let intensity):
            performBodyMovement(type: type, intensity: intensity, completion: completion)
            
        case .vocalization(let type):
            playVocalization(type, completion: completion)
            
        case .attention(let focus):
            setAttentionFocus(focus, completion: completion)
        }
    }
    
    /// Update character configuration
    /// - Parameter configuration: New configuration
    func updateConfiguration(_ configuration: CharacterConfiguration) {
        self.characterConfiguration = configuration
        
        // Apply configuration changes to character appearance
        updateCharacterAppearance()
    }
    
    /// Implement a therapeutic response with the character
    /// - Parameter response: Therapeutic response to implement
    func implementTherapeuticResponse(_ response: TherapeuticResponse) {
        // Set character's emotional state
        expressEmotion(
            response.characterEmotionalState,
            intensity: response.characterEmotionalIntensity,
            duration: 0
        )
        
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
        // Animate speaking
        animateSpeaking(text: text)
        
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
    
    private func loadCharacterModel() {
        // In a real application, this would load a 3D character model from a USDZ file
        // or create it from primitives. For this example, we'll create a simple character.
        
        // Create a root entity for the character
        let character = Entity()
        
        // Create body
        let bodyMesh = MeshResource.generateBox(size: 0.2)
        let bodyMaterial = SimpleMaterial(color: characterConfiguration.primaryColor, roughness: 0.5, isMetallic: false)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        body.position = [0, -0.1, 0]
        character.addChild(body)
        bodyEntity = body
        
        // Create head
        let headMesh = MeshResource.generateSphere(radius: 0.1)
        let headMaterial = SimpleMaterial(color: characterConfiguration.secondaryColor, roughness: 0.3, isMetallic: false)
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = [0, 0.15, 0]
        character.addChild(head)
        headEntity = head
        
        // Create face
        let faceMesh = MeshResource.generatePlane(width: 0.1, height: 0.1)
        let faceMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
        let face = ModelEntity(mesh: faceMesh, materials: [faceMaterial])
        face.position = [0, 0, 0.051] // Slightly in front of head sphere
        head.addChild(face)
        faceEntity = face
        
        // Add to scene with anchor
        let anchor = AnchorEntity(world: [0, 0, -0.5])
        anchor.addChild(character)
        arView.scene.addAnchor(anchor)
        
        characterEntity = character
        
        // Start idle animation
        playAnimation(.idle)
    }
    
    func updateCharacterAppearance(_ state: IntegratedEmotionalState) {
        // Update character based on emotional state
        if let characterState = determineCharacterState(from: state) {
            characterNeedsUpdate = true
            
            // Apply expression to character
            expressEmotion(
                characterState.emotion,
                intensity: characterState.intensity,
                duration: 0
            )
        }
    }
    
    
    private func determineCharacterState(from state: IntegratedEmotionalState) -> (emotion: EmotionType, intensity: Float)? {
        if state.dataQuality == .poor || state.dataQuality == .invalid {
            return nil
        }
        
        // For mirroring, return the dominant emotion with slightly reduced intensity
        return (state.dominantEmotion, state.emotionalIntensity * 0.7)
    }
    
    private func playAnimation(_ animationType: CharacterAnimationType) {
        // Stop any current animations first
        stopAllAnimations()
        
        currentAnimationType = animationType
        
        // Create and play appropriate animation
        switch animationType {
        case .idle:
            playIdleAnimation()
        case .happy, .happyIntense:
            playEmotionAnimation(scale: [1.05, 1.05, 1.05], positionOffset: [0, 0.02, 0])
        case .sad, .sadIntense:
            playEmotionAnimation(scale: [0.95, 0.95, 0.95], positionOffset: [0, -0.02, 0])
        case .angry, .angryIntense:
            playEmotionAnimation(scale: [1.05, 0.95, 1.05], positionOffset: [0, 0, 0.02])
        case .fear, .fearIntense:
            playEmotionAnimation(scale: [0.9, 0.9, 0.9], positionOffset: [0, -0.01, -0.01])
        default:
            playEmotionAnimation(scale: [1.0, 1.0, 1.0], positionOffset: [0, 0, 0])
        }
    }
    
    private func playIdleAnimation() {
        guard let characterEntity = characterEntity else { return }
        
        // Create subtle idle animation
        let duration: Double = 3.0
        
        // Subtle up and down movement
        let originalPosition = characterEntity.position
        let upPosition = SIMD3<Float>(
            x: originalPosition.x,
            y: originalPosition.y + 0.005,
            z: originalPosition.z
        )
        
        // Animate position
        let animation = Transform(
            scale: characterEntity.scale,
            rotation: characterEntity.orientation,
            translation: upPosition
        )
        
        characterEntity.move(
            to: animation,
            relativeTo: characterEntity.parent,
            duration: duration / 2,
            timingFunction: .easeInOut
        )
        
        // Return to original position
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.currentAnimationType == .idle else { return }
            
            characterEntity.move(
                to: Transform(
                    scale: characterEntity.scale,
                    rotation: characterEntity.orientation,
                    translation: originalPosition
                ),
                relativeTo: characterEntity.parent,
                duration: duration / 2,
                timingFunction: .easeInOut
            )
            
            // Loop the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
                guard let self = self, self.currentAnimationType == .idle else { return }
                self.playIdleAnimation()
            }
        }
    }
    
    private func playEmotionAnimation(scale: SIMD3<Float>, positionOffset: SIMD3<Float>) {
        guard let characterEntity = characterEntity,
              let originalPosition = characterEntity.parent?.convert(position: .zero, to: nil) else { return }
        
        // Apply scale and position changes
        let targetPosition = SIMD3<Float>(
            x: originalPosition.x + positionOffset.x,
            y: originalPosition.y + positionOffset.y,
            z: originalPosition.z + positionOffset.z
        )
        
        let animation = Transform(
            scale: scale,
            rotation: characterEntity.orientation,
            translation: targetPosition
        )
        
        // Animate to target transform
        characterEntity.move(
            to: animation,
            relativeTo: nil,
            duration: blendDuration,
            timingFunction: .easeInOut
        )
    }
    
    // Complete implementation for updateFacialBlendShapes in CharacterAnimationController
    func updateFacialBlendShapes(for emotion: EmotionType, intensity: Float) {
        guard let faceEntity = faceEntity else { return }
        
        switch emotion {
        case .happiness:
            // Smile expression - adjust mouth corners up
            let smileTransform = simd_quatf(angle: Float(intensity * 0.3), axis: [0, 0, 1])
            faceEntity.transform.rotation = smileTransform
            faceEntity.scale = [1.0 + (0.2 * intensity), 1.0 - (0.1 * intensity), 1.0]
            
        case .sadness:
            // Sad expression - adjust mouth corners down
            let sadTransform = simd_quatf(angle: Float(-intensity * 0.2), axis: [0, 0, 1])
            faceEntity.transform.rotation = sadTransform
            faceEntity.scale = [1.0, 1.0 - (0.2 * intensity), 1.0]
            
        case .anger:
            // Anger expression - furrow brow, narrow eyes
            let angerTransform = simd_quatf(angle: Float(intensity * 0.1), axis: [1, 0, 0])
            faceEntity.transform.rotation = angerTransform
            faceEntity.scale = [1.0 + (0.1 * intensity), 1.0 - (0.15 * intensity), 1.0]
            
        case .fear:
            // Fear expression - widened eyes, raised brows
            let fearTransform = simd_quatf(angle: Float(-intensity * 0.15), axis: [1, 0, 0])
            faceEntity.transform.rotation = fearTransform
            faceEntity.scale = [1.0 - (0.1 * intensity), 1.0 + (0.1 * intensity), 1.0]
            
        case .surprise:
            // Surprise expression - wide eyes, raised brows, open mouth
            let surpriseTransform = simd_quatf(angle: Float(-intensity * 0.2), axis: [1, 0, 0])
            faceEntity.transform.rotation = surpriseTransform
            faceEntity.scale = [1.0 + (0.1 * intensity), 1.0 + (0.2 * intensity), 1.0]
            
        case .neutral:
            // Reset to neutral
            faceEntity.transform.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
            faceEntity.scale = [1.0, 1.0, 1.0]
            
        default:
            // Default to neutral
            faceEntity.transform.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
            faceEntity.scale = [1.0, 1.0, 1.0]
        }
    }

    // Implement animateBreathing method
    func animateBreathing(speed: Float, depth: Float) {
        guard let bodyEntity = bodyEntity else { return }
        
        // Convert speed to duration (lower speed = longer duration)
        let duration = 4.0 - (Double(speed) * 3.0)
        
        // Calculate breathing amplitude based on depth
        let amplitude = 0.02 + (Double(depth) * 0.05)
        
        // Create animation
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.duration = duration / 2
        animation.fromValue = bodyEntity.position.y
        animation.toValue = bodyEntity.position.y + amplitude
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Apply animation
        bodyEntity.addAnimation(animation, forKey: "breathing")
    }
    
    private func adjustBodyPosture(for emotion: EmotionType, intensity: Float) {
        guard let bodyEntity = bodyEntity else { return }
        
        // Apply appropriate body posture for emotion
        switch emotion {
        case .happiness:
            // Upright, slightly expanded posture for happiness
            bodyEntity.scale = [1.0 + (0.1 * intensity), 1.0 + (0.1 * intensity), 1.0]
            
        case .sadness:
            // Slumped, contracted posture for sadness
            bodyEntity.scale = [1.0, 1.0 - (0.1 * intensity), 1.0]
            
        case .anger:
            // Tense, expanded posture for anger
            bodyEntity.scale = [1.0 + (0.15 * intensity), 1.0 - (0.05 * intensity), 1.0 + (0.1 * intensity)]
            
        case .fear:
            // Contracted, protective posture for fear
            bodyEntity.scale = [1.0 - (0.1 * intensity), 1.0 - (0.1 * intensity), 1.0 - (0.05 * intensity)]
            
        case .neutral:
            // Reset to neutral
            bodyEntity.scale = [1.0, 1.0, 1.0]
            
        default:
            // Default neutral posture
            bodyEntity.scale = [1.0, 1.0, 1.0]
        }
    }
    
    private func animateBreathing(speed: Float, depth: Float) {
        guard let bodyEntity = bodyEntity else { return }
        
        // Stop any current breathing animation
        if isBreathing {
            // Reset breathing animation
            bodyEntity.stopAllAnimations()
        }
        
        isBreathing = true
        
        // Convert speed to duration (0.5 = fast, 4.0 = slow)
        let duration = 4.0 - (Double(speed) * 3.5)
        
        // Create breathing animation
        // Inhale - expand chest
        let originalScale = bodyEntity.scale
        let inhaleScale = SIMD3<Float>(
            x: originalScale.x * (1.0 + (depth * 0.1)),
            y: originalScale.y,
            z: originalScale.z * (1.0 + (depth * 0.1))
        )
        
        // Animate inhale
        let inhaleAnimation = Transform(
            scale: inhaleScale,
            rotation: bodyEntity.orientation,
            translation: bodyEntity.position
        )
        
        // Start breathing cycle
        animateBreathingCycle(entity: bodyEntity,
                              originalScale: originalScale,
                              targetScale: inhaleScale,
                              duration: duration)
    }
    
    private func animateBreathingCycle(entity: ModelEntity,
                                       originalScale: SIMD3<Float>,
                                       targetScale: SIMD3<Float>,
                                       duration: Double,
                                       isInhale: Bool = true) {
        // Stop if no longer breathing
        guard isBreathing else { return }
        
        // Determine target scale for this phase
        let targetTransform = Transform(
            scale: isInhale ? targetScale : originalScale,
            rotation: entity.orientation,
            translation: entity.position
        )
        
        // Animate to target
        entity.move(
            to: targetTransform,
            relativeTo: entity.parent,
            duration: duration / 2,
            timingFunction: .easeInOut
        )
        
        // Schedule next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.isBreathing else { return }
            
            // Continue cycle with opposite phase
            self.animateBreathingCycle(
                entity: entity,
                originalScale: originalScale,
                targetScale: targetScale,
                duration: duration,
                isInhale: !isInhale
            )
        }
    }
    
    private func animateSpeaking(text: String) {
        guard let faceEntity = faceEntity else { return }
        
        // Stop any current speaking animation
        if isSpeaking {
            faceEntity.stopAllAnimations()
        }
        
        isSpeaking = true
        
        // Estimate duration based on text length
        let wordCount = text.split(separator: " ").count
        let duration = max(1.0, Double(wordCount) * 0.3) // Approx 0.3 seconds per word
        
        // Create speaking animation sequence
        let mouthMovementCount = Int(duration * 4) // 4 movements per second
        
        // Start mouth movement sequence
        animateMouthMovement(entity: faceEntity,
                             movementIndex: 0,
                             totalMovements: mouthMovementCount,
                             duration: duration / Double(mouthMovementCount))
        
        // Reset flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isSpeaking = false
        }
    }
    
    private func animateMouthMovement(entity: ModelEntity,
                                      movementIndex: Int,
                                      totalMovements: Int,
                                      duration: Double) {
        // Stop if no longer speaking
        guard isSpeaking else { return }
        
        // Original scale
        let originalScale = entity.scale
        
        // Open mouth
        let openAmount = Float.random(in: 0.01...0.05)
        let mouthOpenScale = SIMD3<Float>(
            x: originalScale.x,
            y: originalScale.y * (1.0 + openAmount),
            z: originalScale.z
        )
        
        // Animate mouth opening
        entity.move(
            to: Transform(
                scale: mouthOpenScale,
                rotation: entity.orientation,
                translation: entity.position
            ),
            relativeTo: entity.parent,
            duration: duration / 2,
            timingFunction: .easeInOut
        )
    }
    
}
