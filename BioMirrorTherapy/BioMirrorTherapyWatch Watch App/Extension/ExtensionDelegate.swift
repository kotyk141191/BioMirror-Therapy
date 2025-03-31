//
//  ExtensionDelegate.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import WatchKit
import WatchConnectivity
import HealthKit
import CoreMotion

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    // Core services
    let connectivityManager = WatchConnectivityManager.shared
    let biometricMonitor = WatchBiometricMonitor.shared
    let sessionManager = WatchSessionManager.shared
    
    func applicationDidFinishLaunching() {
        // Initialize core services
        initializeServices()
        
        // Register for background tasks
        registerBackgroundTasks()
    }
    
    func applicationDidBecomeActive() {
        // Update connection status
        connectivityManager.sendStatusUpdate()
        
        // Resume any active session
        sessionManager.resumeSessionIfNeeded()
    }
    
    func applicationWillResignActive() {
        // Prepare for background operation
        sessionManager.prepareForBackground()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Handle URL session background tasks
                URLSession.shared.getAllTasks { tasks in
                    if tasks.isEmpty {
                        urlSessionTask.setTaskCompletedWithSnapshot(false)
                    }
                }
                
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Handle Watch Connectivity background tasks
                connectivityTask.setTaskCompletedWithSnapshot(false)
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot for app switcher
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date(timeIntervalSinceNow: 60 * 60),
                    userInfo: nil
                )
                
            // Remove or comment out the case for WKHealthKitWorkoutRouteRefreshBackgroundTask
            // case let healthKitTask as WKHealthKitWorkoutRouteRefreshBackgroundTask:
            //     // Not used in this app
            //     healthKitTask.setTaskCompleted()
                
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeServices() {
        // Initialize Watch Connectivity
        connectivityManager.startSession()
        
        // Initialize HealthKit
        biometricMonitor.requestAuthorization { success, error in
            if !success {
                print("Failed to get HealthKit authorization: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func registerBackgroundTasks() {
        // Register for HealthKit background delivery
        WKExtension.shared().registerForRemoteNotifications()
    }
}
