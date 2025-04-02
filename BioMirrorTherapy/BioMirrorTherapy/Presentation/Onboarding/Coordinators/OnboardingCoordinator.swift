//
//  OnboardingCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import UIKit
import SwiftUI

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator, withUserType userType: UserType)
}

class OnboardingCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: OnboardingCoordinatorDelegate?
    private let userSessionManager = UserSessionManager.shared
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Create the view model with completion handler
        let viewModel = OnboardingViewModel(completion: { [weak self] userType in
            guard let self = self else { return }
            
            // Save onboarding completion status and user type
            self.userSessionManager.isOnboardingCompleted = true
            self.userSessionManager.userType = userType
            
            // Notify delegate to navigate to appropriate screen
            self.delegate?.onboardingCoordinatorDidFinish(self, withUserType: userType)
        })
        
        // Create the onboarding view with view model
        let onboardingView = OnboardingView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: onboardingView)
        navigationController.setViewControllers([hostingController], animated: true)
    }
}

// MARK: - View Model

class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var selectedUserType: UserType = .none
    
    // Steps in the onboarding process
    let steps = ["Welcome", "Privacy", "Device Capabilities", "User Type"]
    
    private let completion: (UserType) -> Void
    
    init(completion: @escaping (UserType) -> Void) {
        self.completion = completion
    }
    
    func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    func selectUserType(_ type: UserType) {
        selectedUserType = type
    }
    
    func completeOnboarding() {
        guard selectedUserType != .none else { return }
        completion(selectedUserType)
    }
}

// MARK: - Main View

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

struct UserTypeSelectionView: View {
    @Binding var selectedType: UserType
    
    var body: some View {
        VStack(spacing: 25) {
            Text("How will you use BioMirror Therapy?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            UserTypeSelectionButton(
                title: "Child",
                description: "I am the child who will use therapy sessions",
                icon: "face.smiling",
                isSelected: selectedType == .child
            ) {
                selectedType = .child
            }
            
            UserTypeSelectionButton(
                title: "Parent",
                description: "I am a parent monitoring my child's progress",
                icon: "person.2",
                isSelected: selectedType == .parent
            ) {
                selectedType = .parent
            }
            
            UserTypeSelectionButton(
                title: "Therapist",
                description: "I am a therapist working with patients",
                icon: "stethoscope",
                isSelected: selectedType == .therapist
            ) {
                selectedType = .therapist
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct FeatureItem: View {
    let iconName: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PrivacyBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct DeviceCapabilityRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct UserTypeSelectionButton: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .padding(.trailing, 5)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .padding(.horizontal)
    }
}