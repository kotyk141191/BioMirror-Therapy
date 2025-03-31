//
//  ChildSessionCoordinator.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import UIKit
import SwiftUI

protocol ChildSessionCoordinatorDelegate: AnyObject {
    func childSessionDidComplete(_ coordinator: ChildSessionCoordinator)
    func childSessionDidRequestHelp(_ coordinator: ChildSessionCoordinator)
}

class ChildSessionCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: ChildSessionCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let childSessionView = ChildSessionView()
        let hostingController = UIHostingController(rootView: childSessionView)
        navigationController.setViewControllers([hostingController], animated: true)
    }
}
