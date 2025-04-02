//
//  SettingsCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import UIKit
import SwiftUI

protocol SettingsCoordinatorDelegate: AnyObject {
    func settingsCoordinatorDidFinish(_ coordinator: SettingsCoordinator)
    func settingsCoordinatorDidRequestSignOut(_ coordinator: SettingsCoordinator)
}

class SettingsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: SettingsCoordinatorDelegate?
    private let userSessionManager = UserSessionManager.shared
    private var userType: UserType
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.userType = userSessionManager.userType
    }
    
    func start() {
        // Create view model
        let viewModel = SettingsViewModel(userType: userType)
        
        // Configure callbacks
        viewModel.onDone = { [weak self] in
            guard let self = self else { return }
            self.delegate?.settingsCoordinatorDidFinish(self)
        }
        
        viewModel.onSignOut = { [weak self] in
            guard let self = self else { return }
            self.userSessionManager.clearSession()
            self.delegate?.settingsCoordinatorDidRequestSignOut(self)
        }
        
        viewModel.onDataPrivacyTap = { [weak self] in
            guard let self = self else { return }
            self.showDataPrivacySettings()
        }
        
        viewModel.onProfileSettingsTap = { [weak self] in
            guard let self = self else { return }
            self.showProfileSettings()
        }
        
        viewModel.onChangePasswordTap = { [weak self] in
            guard let self = self else { return }
            self.showChangePassword()
        }
        
        viewModel.onHelpSupportTap = { [weak self] in
            guard let self = self else { return }
            self.showHelpSupport()
        }
        
        viewModel.onTermsOfServiceTap = { [weak self] in
            guard let self = self else { return }
            self.showTermsOfService()
        }
        
        viewModel.onPrivacyPolicyTap = { [weak self] in
            guard let self = self else { return }
            self.showPrivacyPolicy()
        }
        
        viewModel.onDataExportTap = { [weak self] in
            guard let self = self else { return }
            self.showDataExport()
        }
        
        // Create settings view with view model
        let settingsView = SettingsView(viewModel: viewModel)
        
        // Set up navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        
        let hostingController = UIHostingController(rootView: settingsView)
        hostingController.title = "Settings"
        
        // Add done button
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        hostingController.navigationItem.rightBarButtonItem = doneButton
        
        navigationController.setViewControllers([hostingController], animated: true)
    }
    
    @objc private func doneTapped() {
        delegate?.settingsCoordinatorDidFinish(self)
    }
    
    // Navigation methods
    private func showDataPrivacySettings() {
        let viewModel = DataPrivacyViewModel()
        let dataPrivacyView = DataPrivacySettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: dataPrivacyView)
        hostingController.title = "Data & Privacy"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showProfileSettings() {
        // Implementation for showing profile settings
        let profileView = Text("Profile Settings")
        let hostingController = UIHostingController(rootView: profileView)
        hostingController.title = "Profile"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showChangePassword() {
        // Implementation for showing change password UI
        let changePasswordView = Text("Change Password")
        let hostingController = UIHostingController(rootView: changePasswordView)
        hostingController.title = "Change Password"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showHelpSupport() {
        // Implementation for showing help & support
        let helpSupportView = Text("Help & Support")
        let hostingController = UIHostingController(rootView: helpSupportView)
        hostingController.title = "Help & Support"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showTermsOfService() {
        // Implementation for showing terms of service
        let tosView = Text("Terms of Service")
        let hostingController = UIHostingController(rootView: tosView)
        hostingController.title = "Terms of Service"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showPrivacyPolicy() {
        // Implementation for showing privacy policy
        let privacyPolicyView = Text("Privacy Policy")
        let hostingController = UIHostingController(rootView: privacyPolicyView)
        hostingController.title = "Privacy Policy"
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func showDataExport() {
        // Implementation for showing data export UI
        let dataExportView = Text("Export Your Data")
        let hostingController = UIHostingController(rootView: dataExportView)
        hostingController.title = "Export Data"
        navigationController.pushViewController(hostingController, animated: true)
    }
}

// MARK: - View Models

class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var biometricAuthEnabled = true
    @Published var shareDataWithTherapist = true
    @Published var darkModeEnabled = false
    @Published var selectedLanguage = "English"
    @Published var showSignOutConfirmation = false
    
    let userType: UserType
    
    // Callback properties
    var onDone: (() -> Void)?
    var onSignOut: (() -> Void)?
    var onDataPrivacyTap: (() -> Void)?
    var onProfileSettingsTap: (() -> Void)?
    var onChangePasswordTap: (() -> Void)?
    var onHelpSupportTap: (() -> Void)?
    var onTermsOfServiceTap: (() -> Void)?
    var onPrivacyPolicyTap: (() -> Void)?
    var onDataExportTap: (() -> Void)?
    
    init(userType: UserType) {
        self.userType = userType
        loadSettings()
    }
    
    private func loadSettings() {
        // Here we would load user settings from UserDefaults or other storage
    }
    
    func saveSettings() {
        // Here we would save settings back to storage
    }
    
    func confirmSignOut() {
        showSignOutConfirmation = true
    }
    
    func signOut() {
        onSignOut?()
    }
}

class DataPrivacyViewModel: ObservableObject {
    @Published var storeDataLocally = true
    @Published var anonymizeData = false
    @Published var retentionPeriod = "1 Year"
    @Published var shareAnalytics = true
    @Published var allowCrashReporting = true
    
    func deleteAllData() {
        // Implementation for deleting all user data
        print("Delete all data functionality would be implemented here")
    }
}

// MARK: - Views

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // App preferences section
            Section(header: Text("App Preferences")) {
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                Toggle("Use Biometric Authentication", isOn: $viewModel.biometricAuthEnabled)
                Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
                
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("German").tag("German")
                }
            }
            
            // Privacy section
            Section(header: Text("Privacy")) {
                if viewModel.userType == .child {
                    Toggle("Share Data with Therapist", isOn: $viewModel.shareDataWithTherapist)
                }
                
                Button(action: { viewModel.onDataPrivacyTap?() }) {
                    HStack {
                        Text("Data & Privacy Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { viewModel.onDataExportTap?() }) {
                    HStack {
                        Text("Export Your Data")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Account section
            Section(header: Text("Account")) {
                Button(action: { viewModel.onProfileSettingsTap?() }) {
                    HStack {
                        Text("Profile Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { viewModel.onChangePasswordTap?() }) {
                    HStack {
                        Text("Change Password")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { viewModel.confirmSignOut() }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            
            // About section
            Section(header: Text("About")) {
                Button(action: { viewModel.onHelpSupportTap?() }) {
                    HStack {
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { viewModel.onTermsOfServiceTap?() }) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { viewModel.onPrivacyPolicyTap?() }) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .alert(isPresented: $viewModel.showSignOutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign Out")) {
                    viewModel.signOut()
                },
                secondaryButton: .cancel()
            )
        }
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

struct DataPrivacySettingsView: View {
    @ObservedObject var viewModel: DataPrivacyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Data Storage")) {
                Toggle("Store Data Locally Only", isOn: $viewModel.storeDataLocally)
                Toggle("Anonymize Personal Data", isOn: $viewModel.anonymizeData)
                
                Picker("Data Retention Period", selection: $viewModel.retentionPeriod) {
                    Text("1 Month").tag("1 Month")
                    Text("6 Months").tag("6 Months")
                    Text("1 Year").tag("1 Year")
                    Text("Until Deleted").tag("Until Deleted")
                }
            }
            
            Section(header: Text("Usage Data")) {
                Toggle("Share Anonymous Usage Stats", isOn: $viewModel.shareAnalytics)
                Toggle("Allow Crash Reporting", isOn: $viewModel.allowCrashReporting)
            }
            
            Section {
                Button(action: { viewModel.deleteAllData() }) {
                    Text("Delete All Data")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
