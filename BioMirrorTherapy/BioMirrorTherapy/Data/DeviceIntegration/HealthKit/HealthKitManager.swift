//
//  HealthKitManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager {
    // MARK: - Singleton
    
    static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    private let heartRateSubject = PassthroughSubject<HKQuantitySample, Error>()
    private let hrvSubject = PassthroughSubject<HKQuantitySample, Error>()
    private let respirationRateSubject = PassthroughSubject<HKQuantitySample, Error>()
    
    private var observerQueries: [HKObserverQuery] = []
    
    // MARK: - Public Properties
    
    var heartRatePublisher: AnyPublisher<HKQuantitySample, Error> {
        return heartRateSubject.eraseToAnyPublisher()
    }
    
    var hrvPublisher: AnyPublisher<HKQuantitySample, Error> {
        return hrvSubject.eraseToAnyPublisher()
    }
    
    var respirationRatePublisher: AnyPublisher<HKQuantitySample, Error> {
        return respirationRateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if HealthKit is available on this device
    /// - Returns: True if HealthKit is available
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization for required health data types
    /// - Parameter completion: Callback with success status and optional error
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Define the types we want to read from HealthKit
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// Start observing heart rate data
    /// - Returns: Success status
    func startHeartRateMonitoring() -> Bool {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return false
        }
        
        // Create heart rate observer query
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                self.heartRateSubject.send(completion: .failure(error))
                return
            }
            
            self.fetchLatestHeartRateSample()
            completionHandler()
        }
        
        // Execute the query
        healthStore.execute(query)
        observerQueries.append(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for heart rate: \(error)")
            }
        }
        
        // Fetch initial value
        fetchLatestHeartRateSample()
        
        return true
    }
    
    /// Start observing heart rate variability data
    /// - Returns: Success status
    func startHRVMonitoring() -> Bool {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return false
        }
        
        // Create HRV observer query
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                self.hrvSubject.send(completion: .failure(error))
                return
            }
            
            self.fetchLatestHRVSample()
            completionHandler()
        }
        
        // Execute the query
        healthStore.execute(query)
        observerQueries.append(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for HRV: \(error)")
            }
        }
        
        // Fetch initial value
        fetchLatestHRVSample()
        
        return true
    }
    
    /// Start observing respiration rate data
    /// - Returns: Success status
    func startRespirationRateMonitoring() -> Bool {
        guard let respirationType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            return false
        }
        
        // Create respiration rate observer query
        let query = HKObserverQuery(sampleType: respirationType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                self.respirationRateSubject.send(completion: .failure(error))
                return
            }
            
            self.fetchLatestRespirationRateSample()
            completionHandler()
        }
        
        // Execute the query
        healthStore.execute(query)
        observerQueries.append(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: respirationType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for respiration rate: \(error)")
            }
        }
        
        // Fetch initial value
        fetchLatestRespirationRateSample()
        
        return true
    }
    
    /// Stop all health monitoring
    func stopMonitoring() {
        // Stop all observer queries
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
    }
    
    /// Fetch historical heart rate data
    /// - Parameters:
    ///   - startDate: Start date for the query
    ///   - endDate: End date for the query
    ///   - completion: Callback with results and optional error
    func fetchHeartRateData(from startDate: Date, to endDate: Date, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                completion(nil, error)
                return
            }
            
            completion(samples, nil)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Private Methods
    
    private func fetchLatestHeartRateSample() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-10), end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let self = self else { return }
            
            if let error = error {
                self.heartRateSubject.send(completion: .failure(error))
                return
            }
            
            if let sample = results?.first as? HKQuantitySample {
                self.heartRateSubject.send(sample)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHRVSample() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let self = self else { return }
            
            if let error = error {
                self.hrvSubject.send(completion: .failure(error))
                return
            }
            
            if let sample = results?.first as? HKQuantitySample {
                self.hrvSubject.send(sample)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestRespirationRateSample() {
        guard let respirationType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: respirationType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let self = self else { return }
            
            if let error = error {
                self.respirationRateSubject.send(completion: .failure(error))
                return
            }
            
            if let sample = results?.first as? HKQuantitySample {
                self.respirationRateSubject.send(sample)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Helper Methods
    
    /// Extract heart rate value from HKQuantitySample
    /// - Parameter sample: Heart rate sample
    /// - Returns: Heart rate in BPM
    func heartRateFromSample(_ sample: HKQuantitySample) -> Double {
        return sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }
    
    /// Extract HRV value from HKQuantitySample
    /// - Parameter sample: HRV sample
    /// - Returns: HRV in milliseconds
    func hrvFromSample(_ sample: HKQuantitySample) -> Double {
        return sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }
    
    /// Extract respiration rate value from HKQuantitySample
    /// - Parameter sample: Respiration rate sample
    /// - Returns: Respiration rate in breaths per minute
    func respirationRateFromSample(_ sample: HKQuantitySample) -> Double {
        return sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }
}
