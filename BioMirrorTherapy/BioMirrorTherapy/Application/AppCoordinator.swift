//
//  AppCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }
    
    func start()
    func addChildCoordinator(_ coordinator: Coordinator)
    func removeChildCoordinator(_ coordinator: Coordinator)
}

extension Coordinator {
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

enum AppRoute {
    case onboarding
    case childSession
    case parentDashboard
    case therapistDashboard
    case settings
}

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let userSessionManager = UserSessionManager.shared
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Check if device has required capabilities
        guard DeviceCapabilityVerifier.hasRequiredCapabilities() else {
            showUnsupportedDeviceScreen()
            return
        }
        
        // Check if user is logged in and has completed onboarding
        if userSessionManager.isOnboardingCompleted {
            switch userSessionManager.userType {
            case .child:
                navigateToChildSession()
            case .parent:
                navigateToParentDashboard()
            case .therapist:
                navigateToTherapistDashboard()
            case .none:
                startOnboarding()
            }
        } else {
            startOnboarding()
        }
    }
    
    func navigate(to route: AppRoute) {
        switch route {
        case .onboarding:
            startOnboarding()
        case .childSession:
            navigateToChildSession()
        case .parentDashboard:
            navigateToParentDashboard()
        case .therapistDashboard:
            navigateToTherapistDashboard()
        case .settings:
            navigateToSettings()
        }
    }
    
    // MARK: - Private Navigation Methods
    
    private func startOnboarding() {
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        addChildCoordinator(onboardingCoordinator)
        onboardingCoordinator.delegate = self
        onboardingCoordinator.start()
    }
    
    private func navigateToChildSession() {
        let childSessionCoordinator = ChildSessionCoordinator(navigationController: navigationController)
        addChildCoordinator(childSessionCoordinator)
        childSessionCoordinator.start()
    }
    
    private func navigateToParentDashboard() {
        let parentDashboardCoordinator = ParentDashboardCoordinator(navigationController: navigationController)
        addChildCoordinator(parentDashboardCoordinator)
        parentDashboardCoordinator.start()
    }
    
    private func navigateToTherapistDashboard() {
        let therapistDashboardCoordinator = TherapistDashboardCoordinator(navigationController: navigationController)
        addChildCoordinator(therapistDashboardCoordinator)
        therapistDashboardCoordinator.start()
    }
    
    private func navigateToSettings() {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController)
        addChildCoordinator(settingsCoordinator)
        settingsCoordinator.start()
    }
    
    private func showUnsupportedDeviceScreen() {
        let viewController = UnsupportedDeviceViewController()
        navigationController.setViewControllers([viewController], animated: true)
    }
}

// MARK: - OnboardingCoordinatorDelegate

extension AppCoordinator: OnboardingCoordinatorDelegate {
    func onboardingCoordinatorDidFinish(_ coordinator: OnboardingCoordinator, withUserType userType: UserType) {
        removeChildCoordinator(coordinator)
        
        // Navigate to the appropriate screen based on user type
        switch userType {
        case .child:
            navigateToChildSession()
        case .parent:
            navigateToParentDashboard()
        case .therapist:
            navigateToTherapistDashboard()
        }
    }
}
