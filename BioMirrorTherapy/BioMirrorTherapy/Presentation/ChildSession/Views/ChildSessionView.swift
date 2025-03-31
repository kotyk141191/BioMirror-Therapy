//
//  ChildSessionView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import ARKit
import RealityKit

struct ChildSessionView: View {
    @StateObject private var viewModel = ChildSessionViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Main session content
            VStack(spacing: 0) {
                // Session header
                sessionHeader
                
                // Character view
                characterView
                
                // Emotion feedback and controls
                controlPanel
            }
            
            // Safety overlay when needed
            if viewModel.showSafetyOverlay {
                safetyOverlay
            }
            
            // Loading overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.endSession()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - UI Components
    
    private var sessionHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text(viewModel.sessionTitle)
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleHelp()
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                }
                .padding(.trailing)
            }
            
            if !viewModel.sessionInstructions.isEmpty {
                Text(viewModel.sessionInstructions)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if viewModel.showPhaseProgress {
                ProgressView(value: viewModel.phaseProgress)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var characterView: some View {
        GeometryReader { geometry in
            ZStack {
                // AR character container
                ARViewContainer(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // Emotional feedback overlay
                if viewModel.showEmotionFeedback {
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Emotion: \(viewModel.currentEmotionName)")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                if let coherenceLevel = viewModel.coherenceLevel {
                                    Text("Coherence: \(coherenceLevel)")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Activity controls
            if let currentActivity = viewModel.currentActivity {
                Text(currentActivity.name)
                    .font(.headline)
                
                Text(currentActivity.instruction)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.previousActivity()
                    }) {
                        Label("Previous", systemImage: "chevron.backward")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .disabled(!viewModel.hasPreviousActivity)
                    
                    Button(action: {
                        viewModel.nextActivity()
                    }) {
                        Label("Next", systemImage: "chevron.forward")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .disabled(!viewModel.hasNextActivity)
                }
            }
            
            // Session controls
            HStack(spacing: 24) {
                Button(action: {
                    viewModel.pauseSession()
                }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    viewModel.needHelp()
                }) {
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    viewModel.endSession()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var safetyOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Let's take a moment to breathe")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Breathe in... and out...")
                    .font(.title3)
                
                // Breathing animation
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(viewModel.breathingAnimation ? 1.5 : 1.0)
                    .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: viewModel.breathingAnimation)
                    .onAppear {
                        viewModel.breathingAnimation = true
                    }
                
                Button(action: {
                    viewModel.dismissSafetyOverlay()
                }) {
                    Text("I feel better now")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text(viewModel.loadingMessage)
                    .font(.headline)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(15)
        }
    }
}

// ARViewContainer for rendering the character
struct ARViewContainer: UIViewRepresentable {
    var viewModel: ChildSessionViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Setup AR session
        let configuration = ARFaceTrackingConfiguration()
        arView.session.run(configuration)
        
        // Setup scene
        setupCharacter(arView)
        
        // Connect to view model
        viewModel.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update character based on view model state
        if viewModel.characterNeedsUpdate {
            updateCharacter(uiView)
            viewModel.characterNeedsUpdate = false
        }
    }
    
    private func setupCharacter(_ arView: ARView) {
        // In a real implementation, this would load and configure
        // the 3D character model
        
        // Create a simple placeholder entity
        let boxMesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [material])
        
        // Add to scene
        let anchorEntity = AnchorEntity(world: [0, 0, -0.5])
        anchorEntity.addChild(boxEntity)
        arView.scene.addAnchor(anchorEntity)
    }
    
    private func updateCharacter(_ arView: ARView) {
        // Update character appearance based on emotional state
        // In a real implementation, this would animate the character
        // to show appropriate emotions and actions
    }
}

// Preview provider
struct ChildSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ChildSessionView()
    }
}
