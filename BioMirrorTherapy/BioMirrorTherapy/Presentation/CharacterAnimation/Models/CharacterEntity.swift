//
//  CharacterEntity.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import RealityKit
import ARKit
import SwiftUI

class CharacterEntity: Entity {
    // MARK: - Properties
    
    private var configuration: CharacterConfiguration
    private var animationController: CharacterAnimationController?
    
    private var headEntity: Entity?
    private var bodyEntity: Entity?
    private var faceEntity: Entity?
    
    private var currentAnimationType: CharacterAnimationType = .idle
    private var isBreathing = false
    private var isSpeaking = false
    
    // MARK: - Initialization
    
    init(configuration: CharacterConfiguration) {
        self.configuration = configuration
        super.init()
        
        loadModel()
    }
    
    required init() {
        self.configuration = .default
        super.init()
        
        loadModel()
    }
    
    // MARK: - Public Methods
    
    /// Play an animation on the character
    /// - Parameter animationType: Animation to play
    func playAnimation(_ animationType: CharacterAnimationType) {
        currentAnimationType = animationType
        
        // Stop any current animations
        stopAllAnimations()
        
        // Load and play the animation resource
        if let animation = loadAnimation(for: animationType) {
            // Play the animation
            playAnimation(animation)
        }
    }
    
    /// Animate breathing motion
    /// - Parameters:
    ///   - speed: Breathing speed (0.0-1.0, higher is faster)
    ///   - depth: Breathing depth (0.0-1.0, higher is deeper)
    func animateBreathing(speed: Float, depth: Float) {
        guard let bodyEntity = bodyEntity else { return }
        
        // Convert speed to duration (0.5 = fast, 4.0 = slow)
        let duration = 4.0 - (speed * 3.5)
        
        // Convert depth to scale factor
        let scaleFactor = 1.0 + (depth * 0.1)
        
        // Stop if already breathing
        if isBreathing {
            bodyEntity.removeAnimation(for: "breathing")
        }
        
        // Create breathing animation
        var breathingTransforms: [Transform] = []
        
        // Original transform
        let originalTransform = bodyEntity.transform
        breathingTransforms.append(originalTransform)
        
        // Inhale transform (expand chest)
        var inhaleTransform = originalTransform
        inhaleTransform.scale = SIMD3<Float>(
            x: originalTransform.scale.x * scaleFactor,
            y: originalTransform.scale.y,
            z: originalTransform.scale.z * scaleFactor
        )
        breathingTransforms.append(inhaleTransform)
        
        // Back to original
        breathingTransforms.append(originalTransform)
        
        // Play animation with autoreverse and repeat
        let breathingAnimation = Animation(
            name: "breathing",
            transforms: breathingTransforms,
            relativeTimes: [0, 0.5, 1],
            duration: duration,
            blendMode: .linear
        )
        
        bodyEntity.playAnimation(breathingAnimation, repeating: .repeat, autoreverses: true)
        isBreathing = true
    }
    
    /// Animate speaking
    /// - Parameter text: Text being spoken
    func animateSpeaking(text: String) {
        guard let faceEntity = faceEntity else { return }
        
        // Stop if already speaking
        if isSpeaking {
            faceEntity.removeAnimation(for: "speaking")
        }
        
        // Estimate duration based on text length
        let wordCount = text.split(separator: " ").count
        let duration = max(1.0, Double(wordCount) * 0.3) // Approx 0.3 seconds per word
        
        // Create mouth movement animation
        var mouthTransforms: [Transform] = []
        
        // Original transform
        let originalTransform = faceEntity.transform
        mouthTransforms.append(originalTransform)
        
        // Generate random mouth movements
        let mouthMovementCount = Int(duration * 4) // 4 movements per second
        for _ in 0..<mouthMovementCount {
            var mouthTransform = originalTransform
            let openAmount = Float.random(in: 0.01...0.05)
            
            mouthTransform.scale = SIMD3<Float>(
                x: originalTransform.scale.x,
                y: originalTransform.scale.y * (1.0 + openAmount),
                z: originalTransform.scale.z
            )
            
            mouthTransforms.append(mouthTransform)
            mouthTransforms.append(originalTransform) // Close mouth between openings
        }
        
        // Relative times for mouth transforms
        var relativeTimes: [Double] = []
        for i in 0..<mouthTransforms.count {
            relativeTimes.append(Double(i) / Double(mouthTransforms.count - 1))
        }
        
        // Play speaking animation
        let speakingAnimation = Animation(
            name: "speaking",
            transforms: mouthTransforms,
            relativeTimes: relativeTimes,
            duration: duration
        )
        
        faceEntity.playAnimation(speakingAnimation)
        isSpeaking = true
        
        // Reset flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isSpeaking = false
        }
    }
    
    /// Set the character's attention focus
    /// - Parameter focus: Direction of attention
    func setAttentionFocus(_ focus: AttentionFocus) {
        guard let headEntity = headEntity else { return }
        
        // Define rotation for different focus types
        var targetRotation: simd_quatf
        
        switch focus {
        case .direct:
            // Looking directly at the user
            targetRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
            
        case .away:
            // Looking away (to the side)
            let angle = Float.random(in: 0.3...0.6) * (Bool.random() ? 1 : -1)
            targetRotation = simd_quatf(angle: angle, axis: [0, 1, 0])
            
        case .shared:
            // Looking in the same direction as user (downward)
            targetRotation = simd_quatf(angle: 0.3, axis: [1, 0, 0])
            
        case .scanning:
            // Scanning around
            animateScanningAttention()
            return
        }
        
        // Animate head rotation
        let headAnimation = Animation(
            name: "attention",
            from: headEntity.orientation,
            to: targetRotation,
            duration: 0.5
        )
        
        headEntity.playAnimation(headAnimation)
    }
    
    /// Update character configuration
    /// - Parameter configuration: New configuration
    func updateConfiguration(_ configuration: CharacterConfiguration) {
        self.configuration = configuration
        
        // Apply updated configuration
        // In a real implementation, this would update materials, colors, etc.
        
        // Reload model if character type changed
        if self.configuration.characterType != configuration.characterType {
            loadModel()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadModel() {
        // In a real implementation, this would load the 3D model
        // based on the character type from a USDZ file or Reality Composer project
        
        // For now, we'll create a simple entity hierarchy
        
        // Create body
        let bodyMesh = MeshResource.generateBox(size: 0.2)
        let bodyMaterial = SimpleMaterial(color: configuration.primaryColor, roughness: 0.5, isMetallic: false)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        body.position = [0, -0.1, 0]
        addChild(body)
        bodyEntity = body
        
        // Create head
        let headMesh = MeshResource.generateSphere(radius: 0.1)
        let headMaterial = SimpleMaterial(color: configuration.secondaryColor, roughness: 0.3, isMetallic: false)
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = [0, 0.15, 0]
        addChild(head)
        headEntity = head
        
        // Create face
        let faceMesh = MeshResource.generatePlane(width: 0.1, height: 0.1)
        let faceMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
        let face = ModelEntity(mesh: faceMesh, materials: [faceMaterial])
        face.position = [0, 0, 0.051] // Slightly in front of head sphere
        head.addChild(face)
        faceEntity = face
        
        // Set initial scale
        scale = [1, 1, 1]
    }
    
    private func loadAnimation(for animationType: CharacterAnimationType) -> Animation? {
        // In a real implementation, animations would be loaded from a library
        // or created programmatically based on the animation type
        
        // For this example, we'll create a simple animation:
        switch animationType {
        case .idle:
            return createIdleAnimation()
            
        case .happy, .happyIntense:
            return createEmotionAnimation(scale: [1.1, 1.1, 1.1],
                                         bounce: true,
                                         intensity: animationType == .happyIntense ? 1.5 : 1.0)
            
        case .sad, .sadIntense:
            return createEmotionAnimation(scale: [1.0, 0.9, 1.0],
                                         bounce: false,
                                         intensity: animationType == .sadIntense ? 1.5 : 1.0)
            
        case .angry, .angryIntense:
            return createEmotionAnimation(scale: [1.1, 0.95, 1.1],
                                         bounce: false,
                                         intensity: animationType == .angryIntense ? 1.5 : 1.0)
            
        default:
            // Create a generic animation for other types
            return createGenericAnimation(for: animationType)
        }
    }
    
    private func createIdleAnimation() -> Animation {
        // Create a subtle breathing/idle animation
        
        // Define keyframes for the animation
        var transforms: [Transform] = []
        
        // Starting transform
        let startTransform = self.transform
        transforms.append(startTransform)
        
        // Slight up movement
        var upTransform = startTransform
        upTransform.translation.y += 0.005
        transforms.append(upTransform)
        
        // Back to start
        transforms.append(startTransform)
        
        // Create and return the animation
        return Animation(
            name: "idle",
            transforms: transforms,
            relativeTimes: [0, 0.5, 1],
            duration: 2.0,
            blendMode: .linear
        )
    }
    
    private func createEmotionAnimation(scale: SIMD3<Float>, bounce: Bool, intensity: Float) -> Animation {
        // Create an animation for an emotion
        
        // Define keyframes for the animation
        var transforms: [Transform] = []
        
        // Starting transform
        let startTransform = self.transform
        transforms.append(startTransform)
        
        // Target transform with scaling
        var targetTransform = startTransform
        targetTransform.scale = scale * intensity
        transforms.append(targetTransform)
        
        // If bounce, add middle keyframe
        if bounce {
            var bounceTransform = targetTransform
            bounceTransform.scale *= 1.1
            
            transforms = [startTransform, bounceTransform, targetTransform]
        }
        
        // Create and return the animation
        let relativeTimes = bounce ?
            [0.0, 0.6, 1.0] :
            [0.0, 1.0]
        
        return Animation(
            name: "emotion",
            transforms: transforms,
            relativeTimes: relativeTimes,
            duration: 0.5,
            blendMode: .linear
        )
    }
    
    private func createGenericAnimation(for animationType: CharacterAnimationType) -> Animation {
        // Create a simple animation for the given type
        
        // Define keyframes for the animation
        var transforms: [Transform] = []
        
        // Starting transform
        let startTransform = self.transform
        transforms.append(startTransform)
        
        // Target transform with simple modification
        var targetTransform = startTransform
        
        // Modify transform based on animation type
        switch animationType {
        case .gentleMovement:
            targetTransform.translation.y += 0.02
            
        case .energeticMovement:
            targetTransform.translation.y += 0.05
            targetTransform.scale = [1.1, 1.1, 1.1]
            
        case .protectiveMovement:
            targetTransform.scale = [0.9, 0.9, 0.9]
            
        case .playfulMovement:
            targetTransform.translation.y += 0.03
            targetTransform.rotation = simd_quatf(angle: 0.2, axis: [0, 0, 1])
            
        case .freezeResponse:
            targetTransform.scale = [0.95, 0.95, 0.95]
            
        case .rhythmicMovement:
            // This will be handled differently with multiple keyframes
            return createRhythmicAnimation()
            
        default:
            // Slight generic movement
            targetTransform.translation.y += 0.01
        }
        
        // Add target transform
        transforms.append(targetTransform)
        
        // Create and return the animation
        return Animation(
            name: String(describing: animationType),
            transforms: transforms,
            relativeTimes: [0, 1],
            duration: 0.5,
            blendMode: .linear
        )
    }
    
    private func createRhythmicAnimation() -> Animation {
        // Create a rhythmic, repeating animation
        
        // Define keyframes for the animation
        var transforms: [Transform] = []
        var relativeTimes: [Double] = []
        
        // Starting transform
        let startTransform = self.transform
        
        // Create a series of transforms for rhythmic movement
        for i in 0...10 {
            var transform = startTransform
            
            // Sinusoidal movement
            let factor = sin(Double(i) * .pi / 5)
            transform.translation.y += Float(factor) * 0.02
            
            transforms.append(transform)
            relativeTimes.append(Double(i) / 10.0)
        }
        
        // Create and return the animation
        return Animation(
            name: "rhythmic",
            transforms: transforms,
            relativeTimes: relativeTimes,
            duration: 2.0,
            blendMode: .linear
        )
    }
    
    private func animateScanningAttention() {
        guard let headEntity = headEntity else { return }
        
        // Create a series of head rotations for scanning
        var rotations: [simd_quatf] = []
        var relativeTimes: [Double] = []
        
        // Start with current rotation
        rotations.append(headEntity.orientation)
        relativeTimes.append(0)
        
        // Generate 4 random look points
        for i in 1...4 {
            let xAngle = Float.random(in: -0.3...0.3)
            let yAngle = Float.random(in: -0.6...0.6)
            
            let rotation = simd_quatf(angle: xAngle, axis: [1, 0, 0]) *
                          simd_quatf(angle: yAngle, axis: [0, 1, 0])
            
            rotations.append(rotation)
            relativeTimes.append(Double(i) / 5.0)
        }
        
        // End by looking forward again
        rotations.append(simd_quatf(angle: 0, axis: [0, 1, 0]))
        relativeTimes.append(1.0)
        
        // Create animation
        var transforms: [Transform] = []
        for rotation in rotations {
            var transform = headEntity.transform
            transform.rotation = rotation
            transforms.append(transform)
        }
        
        let scanningAnimation = Animation(
            name: "scanning",
            transforms: transforms,
            relativeTimes: relativeTimes,
            duration: 3.0,
            blendMode: .linear
        )
        
        headEntity.playAnimation(scanningAnimation)
    }
    
    private func stopAllAnimations() {
        // Stop animations on all parts
        removeAnimation(for: currentAnimationType.rawValue)
        
        if let bodyEntity = bodyEntity {
            bodyEntity.removeAnimation(for: "breathing")
        }
        
        if let headEntity = headEntity {
            headEntity.removeAnimation(for: "attention")
            headEntity.removeAnimation(for: "scanning")
        }
        
        if let faceEntity = faceEntity, !isSpeaking {
            faceEntity.removeAnimation(for: "speaking")
        }
        
        isBreathing = false
    }
}
