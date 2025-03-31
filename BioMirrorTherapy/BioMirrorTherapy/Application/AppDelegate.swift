//
//  AppDelegate.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

// AppDelegate.swift

import UIKit
import CoreData

//@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize core services
        initializeServices()
        
        // Setup crash reporting and analytics
        setupAnalytics()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BioMirror")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Security settings for Core Data
            container.viewContext.automaticallyMergesChangesFromParent = true
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreFileProtectionKey)
        }
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    func initializeServices() {
        // Register services in dependency container
        ServiceLocator.shared.register(PersistenceService.self) { [weak self] in
            guard let self = self else { fatalError("AppDelegate deallocated") }
            return CoreDataPersistenceService(container: self.persistentContainer)
        }
        
        // Register facial analysis service
        ServiceLocator.shared.register(FacialAnalysisService.self) {
            return LiDARFacialAnalysisService()
        }
        
        // Register biometric analysis service
        ServiceLocator.shared.register(BiometricAnalysisService.self) {
            return AppleWatchBiometricService()
        }
        
        // Register safety monitor (needed by other services)
        let safetyMonitor = SafetyMonitor()
        ServiceLocator.shared.register(SafetyMonitor.self) {
            return safetyMonitor
        }
        
        // Register emotional integration service
        ServiceLocator.shared.register(EmotionalIntegrationService.self) {
            let facialService: FacialAnalysisService = ServiceLocator.shared.resolve()
            let biometricService: BiometricAnalysisService = ServiceLocator.shared.resolve()
            return EmotionalCoherenceAnalyzer(facialAnalysisService: facialService, biometricAnalysisService: biometricService)
        }
        
        // Register therapeutic response service
        ServiceLocator.shared.register(TherapeuticResponseService.self) {
            let integrationService: EmotionalIntegrationService = ServiceLocator.shared.resolve()
            let safetyMonitor: SafetyMonitor = ServiceLocator.shared.resolve()
            return AdaptiveResponseGenerator(emotionalIntegrationService: integrationService, safetyMonitor: safetyMonitor)
        }
        
        // Initialize device verification
        DeviceCapabilityVerifier.verify()
    }
    
    private func setupAnalytics() {
        // Initialize analytics with privacy-first approach
        AnalyticsManager.shared.initialize(isAnalyticsEnabled: UserDefaults.standard.bool(forKey: "analyticsEnabled"))
    }
}
