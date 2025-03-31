//
//  WatchBiometricMonitor.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import HealthKit
import CoreMotion

class WatchBiometricMonitor {
    // MARK: - Singleton
    
    static let shared = WatchBiometricMonitor()
    
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    
    // Latest values
    private(set) var latestHeartRate: Double?
    private(set) var latestHRV: Double?
    private(set) var latestAcceleration: CMAcceleration?
    private(set) var latestRespirationRate: Double?
    
    // Callbacks
    var heartRateUpdated: ((Double) -> Void)?
    var hrvUpdated: ((Double) -> Void)?
    var accelerationUpdated: ((CMAcceleration) -> Void)?
    var respirationRateUpdated: ((Double) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        // Setup motion manager
        motionManager.accelerometerUpdateInterval = 0.1
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Define the health data types we want to access
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func startMonitoring(options: SessionConfiguration) {
        // Start monitoring based on configuration
        
        // Start heart rate monitoring
        startHeartRateMonitoring()
        
        // Start HRV monitoring if enabled
        if options.includeHRV {
            startHRVMonitoring()
        }
        
        // Start motion monitoring if enabled
        if options.includeMotion {
            startMotionMonitoring()
        }
        
        // Respiration rate is estimated from other sensors in a real implementation
    }
    
    func stopMonitoring() {
        // Stop heart rate monitoring
        if let heartRateQuery = heartRateQuery {
            healthStore.stop(heartRateQuery)
            self.heartRateQuery = nil
        }
        
        // Stop HRV monitoring
        if let hrvQuery = hrvQuery {
            healthStore.stop(hrvQuery)
            self.hrvQuery = nil
        }
        
        // Stop motion monitoring
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    // MARK: - Private Methods
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Create heart rate query
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Heart rate query error: \(error)")
                return
            }
            
            self.processHeartRateSamples(samples)
        }
        
        // Configure query to update with new samples
        
        //TODO: - uncomment
//        heartRateQuery?.updateHandler = { [weak self] query, samples, newAnchor, error in            guard let self = self else { return }
//            
//            if let error = error {
//                print("Heart rate update error: \(error)")
//                return
//            }
//            
//            self.processHeartRateSamples(samples)
//        }
        
        // Execute the query
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }
    
    private func startHRVMonitoring() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        // Create HRV query
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("HRV query error: \(error)")
                return
            }
            
            self.processHRVSamples(samples)
        }
        
        //TODO: - uncomment
        // Configure query to update with new samples
//        hrvQuery?.updateHandler = { [weak self] query, samples, newAnchor, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("HRV update error: \(error)")
//                return
//            }
//            
//            self.processHRVSamples(samples)
//        }
        
        // Execute the query
        if let query = hrvQuery {
            healthStore.execute(query)
        }
    }
    
    private func startMotionMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        // Start accelerometer updates
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else {
                if let error = error {
                    print("Accelerometer error: \(error)")
                }
                return
            }
            
            // Update latest acceleration
            self.latestAcceleration = data.acceleration
            self.accelerationUpdated?(data.acceleration)
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let lastSample = samples.last else { return }
        
        // Extract heart rate value
        let heartRate = lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        
        // Update latest value
        latestHeartRate = heartRate
        
        // Notify callback
        DispatchQueue.main.async {
            self.heartRateUpdated?(heartRate)
        }
    }
    
    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let lastSample = samples.last else { return }
        
        // Extract HRV value
        let hrv = lastSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        
        // Update latest value
        latestHRV = hrv
        
        // Notify callback
        DispatchQueue.main.async {
            self.hrvUpdated?(hrv)
        }
    }
    
    // MARK: - Helper Methods
    
    func getCurrentBiometricState() -> BiometricDataState {
        return BiometricDataState(
            heartRate: latestHeartRate,
            heartRateVariability: latestHRV,
            acceleration: latestAcceleration,
            respirationRate: latestRespirationRate
        )
    }
}

struct BiometricDataState {
    let heartRate: Double?
    let heartRateVariability: Double?
    let acceleration: CMAcceleration?
    let respirationRate: Double?
    let timestamp = Date()
    
    var dataQuality: String {
        if heartRate == nil && acceleration == nil {
            return "poor"
        } else if heartRate != nil && heartRateVariability != nil && acceleration != nil {
            return "excellent"
        } else if heartRate != nil && (heartRateVariability != nil || acceleration != nil) {
            return "good"
        } else {
            return "fair"
        }
    }
}
