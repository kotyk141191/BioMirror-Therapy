//
//  OnboardingView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack {
            // Progress indicator
            if viewModel.currentStep > 0 {
                HStack {
                    Button(action: { viewModel.previousStep() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Text("Step \(viewModel.currentStep + 1) of \(viewModel.steps.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                        .padding(.trailing)
                }
                .padding(.top)
            }
            
            // Header
            Text(viewModel.steps[viewModel.currentStep])
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, viewModel.currentStep == 0 ? 40 : 20)
                .padding(.bottom, 20)
            
            // Content based on step
            switch viewModel.currentStep {
            case 0:
                WelcomeView()
            case 1:
                PrivacyView()
            case 2:
                DeviceCapabilitiesView()
            case 3:
                UserTypeSelectionView(selectedType: $viewModel.selectedUserType)
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Navigation buttons
            if viewModel.currentStep < viewModel.steps.count - 1 {
                Button(viewModel.currentStep == 0 ? "Get Started" : "Continue") {
                    withAnimation {
                        viewModel.nextStep()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 20)
            } else {
                Button("Complete Setup") {
                    viewModel.completeOnboarding()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.selectedUserType == .none)
                .padding(.bottom, 20)
            }
        }
        .padding()
    }
}

// MARK: - Step Views

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)
                .padding()
            
            Text("Emotional Integration for Children")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("BioMirror Therapy helps children understand and process their emotions through advanced biometric analysis and responsive feedback.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            // Key features
            VStack(alignment: .leading, spacing: 10) {
                FeatureItem(iconName: "faceid", text: "Facial emotion recognition")
                FeatureItem(iconName: "heart.text.square", text: "Biometric monitoring integration")
                FeatureItem(iconName: "brain", text: "Adaptive therapeutic responses")
                FeatureItem(iconName: "chart.line.uptrend.xyaxis", text: "Progress tracking & insights")
            }
            .padding()
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Privacy & Security")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your privacy is our priority. All data is encrypted and stored securely. Biometric data never leaves your device without explicit consent.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                PrivacyBulletPoint(text: "End-to-end encryption for all data")
                PrivacyBulletPoint(text: "Biometrics processed on-device")
                PrivacyBulletPoint(text: "Parental controls & monitoring")
                PrivacyBulletPoint(text: "HIPAA compliant for therapist access")
            }
            .padding()
        }
    }
}

struct DeviceCapabilitiesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.gen3")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Device Capabilities")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("BioMirror Therapy works best with these capabilities:")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                DeviceCapabilityRow(icon: "faceid", title: "Face ID or LiDAR", description: "For facial emotion analysis")
                DeviceCapabilityRow(icon: "applewatch", title: "Apple Watch (optional)", description: "For heart rate and biometric monitoring")
                DeviceCapabilityRow(icon: "wifi", title: "Internet Connection", description: "For synchronization with therapists")
                DeviceCapabilityRow(icon: "lock.icloud", title: "iCloud Account", description: "For secure data backup")
            }
            .padding()
        }
    }
}


// MARK: - Supporting Views



