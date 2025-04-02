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


import RealityKit
import SwiftUI
import ARKit
import Combine

class CharacterEntity: Entity {
    // MARK: - Properties
    
    // Component entities
    private var headEntity: ModelEntity?
    private var faceEntity: ModelEntity?
    private var bodyEntity: ModelEntity?
    
    // Animation state
    private var currentAnimationType: CharacterAnimationType = .idle
    private var currentEmotion: EmotionType = .neutral
    private var currentIntensity: Float = 0.0
    private var isBreathing = false
    private var isSpeaking = false
    
    // Configuration
    private var configuration: CharacterConfiguration = .default
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupCharacter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupCharacter() {
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
        
        // Start idle animation
        playAnimation(.idle)
    }
    
    // MARK: - Animation Methods
    
    func playAnimation(_ animationType: CharacterAnimationType) {
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
        case .surprise, .surpriseIntense:
            playEmotionAnimation(scale: [1.05, 1.05, 1.05], positionOffset: [0, 0.01, 0.01])
        case .gentleMovement:
            playGentleMovementAnimation()
        case .energeticMovement:
            playEnergeticMovementAnimation()
        default:
            playEmotionAnimation(scale: [1.0, 1.0, 1.0], positionOffset: [0, 0, 0])
        }
    }
    
    func stopAllAnimations() {
        // Stop all animations on entities
        bodyEntity?.stopAllAnimations()
        headEntity?.stopAllAnimations()
        faceEntity?.stopAllAnimations()
        
        // Reset animation flags
        isBreathing = false
        isSpeaking = false
    }
    
    private func playIdleAnimation() {
        guard let bodyEntity = bodyEntity else { return }
        
        // Create subtle idle animation
        let duration: Double = 3.0
        
        // Subtle up and down movement
        let originalPosition = bodyEntity.position
        let upPosition = SIMD3<Float>(
            x: originalPosition.x,
            y: originalPosition.y + 0.005,
            z: originalPosition.z
        )
        
        // Animate position
        let animation = Transform(
            scale: bodyEntity.scale,
            rotation: bodyEntity.orientation,
            translation: upPosition
        )
        
        bodyEntity.move(
            to: animation,
            relativeTo: bodyEntity.parent,
            duration: duration / 2,
            timingFunction: .easeInOut
        )
        
        // Return to original position
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.currentAnimationType == .idle else { return }
            
            bodyEntity.move(
                to: Transform(
                    scale: bodyEntity.scale,
                    rotation: bodyEntity.orientation,
                    translation: originalPosition
                ),
                relativeTo: bodyEntity.parent,
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
        guard let bodyEntity = bodyEntity,
              let headEntity = headEntity else { return }
        
        // Apply scale to body
        let bodyAnimation = Transform(
            scale: scale,
            rotation: bodyEntity.orientation,
            translation: bodyEntity.position
        )
        
        bodyEntity.move(
            to: bodyAnimation,
            relativeTo: bodyEntity.parent,
            duration: 0.5,
            timingFunction: .easeInOut
        )
        
        // Apply position offset to head
        let headPosition = headEntity.position
        let headAnimation = Transform(
            scale: headEntity.scale,
            rotation: headEntity.orientation,
            translation: SIMD3<Float>(
                x: headPosition.x + positionOffset.x,
                y: headPosition.y + positionOffset.y,
                z: headPosition.z + positionOffset.z
            )
        )
        
        headEntity.move(
            to: headAnimation,
            relativeTo: headEntity.parent,
            duration: 0.5,
            timingFunction: .easeInOut
        )
    }
    
    private func playGentleMovementAnimation() {
        guard let bodyEntity = bodyEntity else { return }
        
        // Create gentle swaying movement
        let duration: Double = 2.0
        
        // Original rotation
        let originalRotation = bodyEntity.orientation
        
        // Rotate slightly to one side
        let rotation1 = simd_quatf(angle: Float.pi / 36, axis: [0, 0, 1]) // 5 degrees
        
        bodyEntity.move(
            to: Transform(
                scale: bodyEntity.scale,
                rotation: rotation1,
                translation: bodyEntity.position
            ),
            relativeTo: bodyEntity.parent,
            duration: duration / 2,
            timingFunction: .easeInOut
        )
        
        // Return to original rotation, then rotate to the other side, then back to original
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.currentAnimationType == .gentleMovement else { return }
            
            // Rotate to the other side
            let rotation2 = simd_quatf(angle: -Float.pi / 36, axis: [0, 0, 1]) // -5 degrees
            
            bodyEntity.move(
                to: Transform(
                    scale: bodyEntity.scale,
                    rotation: rotation2,
                    translation: bodyEntity.position
                ),
                relativeTo: bodyEntity.parent,
                duration: duration,
                timingFunction: .easeInOut
            )
            
            // Return to original rotation
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self, self.currentAnimationType == .gentleMovement else { return }
                
                bodyEntity.move(
                    to: Transform(
                        scale: bodyEntity.scale,
                        rotation: originalRotation,
                        translation: bodyEntity.position
                    ),
                    relativeTo: bodyEntity.parent,
                    duration: duration / 2,
                    timingFunction: .easeInOut
                )
                
                // Loop the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
                    guard let self = self, self.currentAnimationType == .gentleMovement else { return }
                    self.playGentleMovementAnimation()
                }
            }
        }
    }
    
    private func playEnergeticMovementAnimation() {
        guard let bodyEntity = bodyEntity,
              let headEntity = headEntity else { return }
        
        // Create energetic bouncing movement
        let duration: Double = 0.4
        
        // Original positions
        let originalBodyPosition = bodyEntity.position
        let originalHeadPosition = headEntity.position
        
        // Move up
        bodyEntity.move(
            to: Transform(
                scale: bodyEntity.scale,
                rotation: bodyEntity.orientation,
                translation: SIMD3<Float>(
                    x: originalBodyPosition.x,
                    y: originalBodyPosition.y + 0.03,
                    z: originalBodyPosition.z
                )
            ),
            relativeTo: bodyEntity.parent,
            duration: duration / 2,
            timingFunction: .easeOut
        )
        
        headEntity.move(
            to: Transform(
                scale: headEntity.scale,
                rotation: headEntity.orientation,
                translation: SIMD3<Float>(
                    x: originalHeadPosition.x,
                    y: originalHeadPosition.y + 0.02,
                    z: originalHeadPosition.z
                )
            ),
            relativeTo: headEntity.parent,
            duration: duration / 2,
            timingFunction: .easeOut
        )
        
        // Move down
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.currentAnimationType == .energeticMovement else { return }
            
            bodyEntity.move(
                to: Transform(
                    scale: bodyEntity.scale,
                    rotation: bodyEntity.orientation,
                    translation: originalBodyPosition
                ),
                relativeTo: bodyEntity.parent,
                duration: duration / 2,
                timingFunction: .easeIn
            )
            
            headEntity.move(
                to: Transform(
                    scale: headEntity.scale,
                    rotation: headEntity.orientation,
                    translation: originalHeadPosition
                ),
                relativeTo: headEntity.parent,
                duration: duration / 2,
                timingFunction: .easeIn
            )
            
            // Loop the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
                guard let self = self, self.currentAnimationType == .energeticMovement else { return }
                self.playEnergeticMovementAnimation()
            }
        }
    }
    
    // MARK: - Character Action Methods
    
    func animateBreathing(speed: Float, depth: Float) {
        guard let bodyEntity = bodyEntity else { return }
        
        // Stop any current breathing animation
        if isBreathing {
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
    
    func animateSpeaking(text: String) {
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
        guard isSpeaking, movementIndex < totalMovements else { return }
        
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
        
        // Animate mouth closing
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            guard let self = self, self.isSpeaking else { return }
            
            entity.move(
                to: Transform(
                    scale: originalScale,
                    rotation: entity.orientation,
                    translation: entity.position
                ),
                relativeTo: entity.parent,
                duration: duration / 2,
                timingFunction: .easeInOut
            )
            
            // Continue to next mouth movement
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
                guard let self = self, self.isSpeaking else { return }
                
                self.animateMouthMovement(
                    entity: entity,
                    movementIndex: movementIndex + 1,
                    totalMovements: totalMovements,
                    duration: duration
                )
            }
        }
    }
    
    func updateFacialExpression(for emotion: EmotionType, intensity: Float) {
        guard let faceEntity = faceEntity else { return }
        
        // Update current emotion state
        currentEmotion = emotion
        currentIntensity = intensity
        
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
    
    func setAttentionFocus(_ focus: CharacterAction.AttentionFocus) {
        guard let headEntity = headEntity else { return }
        
        let duration = 0.5
        
        // Original rotation
        let originalRotation = headEntity.orientation
        
        // Determine rotation based on focus type
        var targetRotation: simd_quatf
        
        switch focus {
        case .direct:
            // Look directly at user
            targetRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case .averted:
            // Look slightly away
            targetRotation = simd_quatf(angle: Float.pi / 12, axis: [0, 1, 0]) // 15 degrees to side
        case .shared:
            // Look in a shared direction
            targetRotation = simd_quatf(angle: Float.pi / 24, axis: [1, 0, 0]) // 7.5 degrees down
        }
        
        // Animate to target rotation
        headEntity.move(
            to: Transform(
                scale: headEntity.scale,
                rotation: targetRotation,
                translation: headEntity.position
            ),
            relativeTo: headEntity.parent,
            duration: duration,
            timingFunction: .easeInOut
        )
    }
    
    // MARK: - Configuration Methods
    
    func updateConfiguration(_ configuration: CharacterConfiguration) {
        self.configuration = configuration
        
        // Update appearance based on configuration
        updateAppearance()
    }
    
    private func updateAppearance() {
        // Update body color
        if let bodyEntity = bodyEntity {
            var bodyMaterials = bodyEntity.model?.materials as? [SimpleMaterial] ?? []
            if let index = bodyMaterials.indices.first {
                bodyMaterials[index].baseColor = MaterialColorParameter.color(configuration.primaryColor)
                bodyEntity.model?.materials = bodyMaterials
            }
        }
        
        // Update head color
        if let headEntity = headEntity {
            var headMaterials = headEntity.model?.materials as? [SimpleMaterial] ?? []
            if let index = headMaterials.indices.first {
                headMaterials[index].baseColor = MaterialColorParameter.color(configuration.secondaryColor)
                headEntity.model?.materials = headMaterials
            }
        }
        
        // Scale based on expressiveness
        let expressiveness = configuration.expressiveness
        let expressionScale = 1.0 + (expressiveness - 0.5) * 0.1
        
        scale = [Float(expressionScale), Float(expressionScale), Float(expressionScale)]
    }
    
    // MARK: - Action Methods for TherapeuticResponse
    
    func performAction(_ action: CharacterAction) {
        switch action {
        case .breathing(let speed, let depth):
            animateBreathing(speed: speed, depth: depth)
            
        case .facialExpression(let emotion, let intensity):
            updateFacialExpression(for: emotion, intensity: intensity)
            let animationType = mapEmotionToAnimationType(emotion, intensity: intensity)
            playAnimation(animationType)
            
        case .bodyMovement(let type, let intensity):
            let animationType = mapMovementTypeToAnimationType(type)
            playAnimation(animationType)
            
        case .attention(let focus):
            setAttentionFocus(focus)
            
        case .grounding:
            // Default grounding animation
            playAnimation(.gentleMovement)
        }
    }
    
    private func mapEmotionToAnimationType(_ emotion: EmotionType, intensity: Float) -> CharacterAnimationType {
        // Map emotion to animation type
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
        default:
            return .neutral
        }
    }
    
}
