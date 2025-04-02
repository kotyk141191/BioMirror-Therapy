//
//  TherapistDashboardCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import UIKit
import SwiftUI
import ObjectiveC

protocol TherapistDashboardCoordinatorDelegate: AnyObject {
    func therapistDashboardDidRequestSignOut(_ coordinator: TherapistDashboardCoordinator)
    func therapistDashboardDidRequestSettings(_ coordinator: TherapistDashboardCoordinator)
    func therapistDashboardDidRequestPatientDetail(_ coordinator: TherapistDashboardCoordinator, patientId: String)
}

class TherapistDashboardCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: TherapistDashboardCoordinatorDelegate?
    private let userSessionManager = UserSessionManager.shared
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Create view model
        let viewModel = TherapistDashboardViewModel()
        
        // Configure callbacks
        viewModel.onSignOut = { [weak self] in
            guard let self = self else { return }
            self.userSessionManager.clearSession()
            self.delegate?.therapistDashboardDidRequestSignOut(self)
        }
        
        viewModel.onSettingsTap = { [weak self] in
            guard let self = self else { return }
            self.delegate?.therapistDashboardDidRequestSettings(self)
        }
        
        viewModel.onPatientSelect = { [weak self] patientId in
            guard let self = self else { return }
            self.showPatientDetail(patientId: patientId)
        }
        
        // Create view with view model
        let therapistDashboardView = TherapistDashboardView()
            .environmentObject(viewModel)
        
        // Update navigation bar appearance for therapist dashboard
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemIndigo]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemIndigo]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.prefersLargeTitles = true
        
        // Add right bar buttons
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        let exportButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportTapped)
        )
        
        let hostingController = UIHostingController(rootView: therapistDashboardView)
        hostingController.navigationItem.rightBarButtonItems = [settingsButton, exportButton]
        
        navigationController.setViewControllers([hostingController], animated: true)
        
        // Load initial data
        viewModel.loadData()
    }
    
    // Action handlers
    @objc private func settingsTapped() {
        delegate?.therapistDashboardDidRequestSettings(self)
    }
    
    @objc private func exportTapped() {
        // Implementation for exporting reports or data
    }
    
    // Navigation methods
    func showPatientDetail(patientId: String) {
        delegate?.therapistDashboardDidRequestPatientDetail(self, patientId: patientId)
    }
    
    func showSessionDetail(sessionId: String) {
        // Implementation for showing session details
    }
    
    func showAddNotesUI(patientId: String) {
        // Implementation for showing add notes UI
    }
    
    func showReportGenerationUI(patientId: String) {
        // Implementation for showing report generation UI
    }
}

// Extend TherapistDashboardViewModel to include necessary callback properties
extension TherapistDashboardViewModel {
    // These properties would be defined in the actual view model class
    var onSignOut: (() -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.signOutCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.signOutCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var onSettingsTap: (() -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.settingsCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.settingsCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var onPatientSelect: ((String) -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.patientSelectCallback) as? ((String) -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.patientSelectCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    private struct AssociatedKeys {
        static var signOutCallback = "therapistDashboard_signOutCallback"
        static var settingsCallback = "therapistDashboard_settingsCallback"
        static var patientSelectCallback = "therapistDashboard_patientSelectCallback"
    }
}
