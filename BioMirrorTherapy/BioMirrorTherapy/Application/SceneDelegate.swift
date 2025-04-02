//
//  SceneDelegate.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    
    // SceneDelegate.swift
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Initialize main coordinator
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        
        window.rootViewController = navigationController
        
        appCoordinator = AppCoordinator(navigationController: navigationController)
        appCoordinator?.start()
        
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Resume ongoing tasks
        NotificationCenter.default.post(name: .applicationDidBecomeActive, object: nil)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // Pause ongoing tasks
        NotificationCenter.default.post(name: .applicationWillResignActive, object: nil)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        NotificationCenter.default.post(name: .applicationWillEnterForeground, object: nil)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Save changes in the application's managed object context
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        NotificationCenter.default.post(name: .applicationDidEnterBackground, object: nil)
    }
}

extension Notification.Name {
    static let applicationDidBecomeActive = Notification.Name("applicationDidBecomeActive")
    static let applicationWillResignActive = Notification.Name("applicationWillResignActive")
    static let applicationWillEnterForeground = Notification.Name("applicationWillEnterForeground")
    static let applicationDidEnterBackground = Notification.Name("applicationDidEnterBackground")
}
