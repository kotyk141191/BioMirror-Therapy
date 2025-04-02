//
//  ParentDashboardCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import UIKit
import SwiftUI
import ObjectiveC

protocol ParentDashboardCoordinatorDelegate: AnyObject {
    func parentDashboardDidRequestSignOut(_ coordinator: ParentDashboardCoordinator)
    func parentDashboardDidRequestSettings(_ coordinator: ParentDashboardCoordinator)
    func parentDashboardDidRequestChildSession(_ coordinator: ParentDashboardCoordinator)
}

class ParentDashboardCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: ParentDashboardCoordinatorDelegate?
    private let userSessionManager = UserSessionManager.shared
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Create view model
        let viewModel = ParentDashboardViewModel()
        
        // Configure callbacks
        viewModel.onSignOut = { [weak self] in
            guard let self = self else { return }
            self.userSessionManager.clearSession()
            self.delegate?.parentDashboardDidRequestSignOut(self)
        }
        
        viewModel.onSettingsTap = { [weak self] in
            guard let self = self else { return }
            self.delegate?.parentDashboardDidRequestSettings(self)
        }
        
        viewModel.onSessionRequest = { [weak self] in
            guard let self = self else { return }
            self.delegate?.parentDashboardDidRequestChildSession(self)
        }
        
        // Create view with view model
        let parentDashboardView = ParentDashboardView()
            .environmentObject(viewModel)
        
        // Update navigation bar appearance for parent dashboard
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.prefersLargeTitles = true
        
        // Add right bar button for settings
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        let hostingController = UIHostingController(rootView: parentDashboardView)
        hostingController.navigationItem.rightBarButtonItem = settingsButton
        
        navigationController.setViewControllers([hostingController], animated: true)
        
        // Load initial data
        viewModel.loadData()
    }
    
    @objc private func settingsTapped() {
        delegate?.parentDashboardDidRequestSettings(self)
    }
    
    // Handle child detail
    func showChildSessionDetail(sessionId: String) {
        // Implementation for showing child session details
        // This would create a detail view and push it onto the navigation stack
    }
    
    // Handle session scheduling
    func showScheduleSession() {
        // Implementation for showing session scheduling UI
        // This would present a modal for scheduling a new session
    }
}

// Extend ParentDashboardViewModel to include necessary callback properties
extension ParentDashboardViewModel {
    // These properties would be defined in the actual view model class
    var onSignOut: (() -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.signOutCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.signOutCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var onSettingsTap: (() -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.settingsCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.settingsCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var onSessionRequest: (() -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.sessionRequestCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &AssociatedKeys.sessionRequestCallback, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    private struct AssociatedKeys {
        static var signOutCallback = "parentDashboard_signOutCallback"
        static var settingsCallback = "parentDashboard_settingsCallback"
        static var sessionRequestCallback = "parentDashboard_sessionRequestCallback"
    }
}
