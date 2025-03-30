//
//  AppleWatchBiometricService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine
import HealthKit
import WatchConnectivity
import CoreMotion

class AppleWatchBiometricService: NSObject, BiometricAnalysisService {
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private var session: WCSession?
    
    private var options: BiometricAnalysisOptions = .default
    
    private var _isRunning = false
    private var _status: BiometricAnalysisStatus = .notStarted
    private var _currentPhysiologicalState: PhysiologicalState?
    
    private let statusSubject = PassthroughSubject<BiometricAnalysisStatus, Never>()
    private let physiologicalStateSubject = PassthroughSubject<PhysiologicalState, Never>()
    
    private var heartRateQuery: HKQuery?
    private var hrvQuery: HKQuery?
    
    private var dataProcessingTimer: Timer?
    private var dataUpdateInterval: TimeInterval {
        switch options.samplingFrequency {
        case .low: return 1.0
        case .medium: return 0.2
        case .high: return 0.1
        }
    }
    
    private var isWatchConnected: Bool {
        guard WCSession.isSupported() else { return false }
        return session?.activationState == .activated && session?.isPaired == true && session?.isWatchAppInstalled == true
    }
    
    // MARK: - BiometricAnalysisService Protocol
    
    var isRunning: Bool {
        return _isRunning
    }
    
    var status: BiometricAnalysisStatus {
        return _status
    }
    
    var statusPublisher: AnyPublisher<BiometricAnalysisStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    var currentPhysiologicalState: PhysiologicalState? {
        return _currentPhysiologicalState
    }
    
    var physiologicalStatePublisher: AnyPublisher<PhysiologicalState, Never> {
        return physiologicalStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - BiometricAnalysisService Methods
    
    func startMonitoring() throws {
        guard !_isRunning else { return }
        
        updateStatus(.initializing)
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            throw BiometricAnalysisError.sensorUnavailable
        }
        
        // Check WatchConnectivity
        if !WCSession.isSupported() {
            throw BiometricAnalysisError.watchNotSupported
        }
        
        if !isWatchConnected {
            throw BiometricAnalysisError.watchNotConnected
        }
        
        // Request authorization for health data
        try requestHealthKitAuthorization()
        
        // Start monitoring the biometric data
        startBiometricMonitoring()
        
        _isRunning = true
        updateStatus(.running)
    }
    
    func stopMonitoring() {
        guard _isRunning else { return }
        
        // Stop all queries and sensors
        stopBiometricMonitoring()
        
        _isRunning = false
        updateStatus(.notStarted)
    }
    
    func pauseMonitoring() {
        guard _isRunning else { return }
        
        // Pause data collection but keep connections alive
        dataProcessingTimer?.invalidate()
        dataProcessingTimer = nil
        
        updateStatus(.paused)
    }
    
    func resumeMonitoring() {
        guard status == .paused else { return }
        
        // Resume data processing
        setupDataProcessingTimer()
        
        updateStatus(.running)
    }
    
    func configure(with options: BiometricAnalysisOptions) {
        self.options = options
        
        // If already running, restart with new options
        if _isRunning {
            stopMonitoring()
            do {
                try startMonitoring()
            } catch {
                updateStatus(.failed(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateStatus(_ newStatus: BiometricAnalysisStatus) {
        _status = newStatus
        statusSubject.send(newStatus)
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    private func requestHealthKitAuthorization() throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        ]
        
        var authorized = false
        let semaphore = DispatchSemaphore(value: 0)
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            authorized = success
            semaphore.signal()
        }
        
        // Wait for authorization response
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        if !authorized {
            throw BiometricAnalysisError.missingPermissions
        }
    }
    
    private func startBiometricMonitoring() {
        // Start heart rate monitoring
        startHeartRateMonitoring()
        
        // Start HRV monitoring if enabled
        if options.includeHeartRateVariability {
            startHRVMonitoring()
        }
        
        // Start motion monitoring
        if options.includeMotionAnalysis {
            startMotionMonitoring()
        }
        
        // Setup data processing timer
        setupDataProcessingTimer()
    }
    
    private func stopBiometricMonitoring() {
        // Stop all health queries
        if let heartRateQuery = heartRateQuery {
            healthStore.stop(heartRateQuery)
            self.heartRateQuery = nil
        }
        
        if let hrvQuery = hrvQuery {
            healthStore.stop(hrvQuery)
            self.hrvQuery = nil
        }
        
        // Stop motion manager
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        
        // Stop data processing timer
        dataProcessingTimer?.invalidate()
        dataProcessingTimer = nil
    }
    
    private func setupDataProcessingTimer() {
        dataProcessingTimer?.invalidate()
        
        // Create a timer that processes biometric data at the specified interval
        dataProcessingTimer = Timer.scheduledTimer(withTimeInterval: dataUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Process latest biometric data and generate a physiological state
            let physiologicalState = self.processLatestBiometricData()
            
            self._currentPhysiologicalState = physiologicalState
            self.physiologicalStateSubject.send(physiologicalState)
        }
    }
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Create heart rate query
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Heart rate observer query error: \(error)")
                return
            }
            
            // Execute heart rate sample query
            self.fetchLatestHeartRateSample()
            
            // Handle background delivery
            completionHandler()
        }
        
        healthStore.execute(query)
        heartRateQuery = query
        
        // Enable background delivery if necessary
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for heart rate: \(error)")
            }
        }
    }
    
    private func startHRVMonitoring() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        // Create HRV query
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            
            if let error = error {
                print("HRV observer query error: \(error)")
                return
            }
            
            // Execute HRV sample query
            self.fetchLatestHRVSample()
            
            // Handle background delivery
            completionHandler()
        }
        
        healthStore.execute(query)
        hrvQuery = query
        
        // Enable background delivery if necessary
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for HRV: \(error)")
            }
        }
    }
    
    private func startMotionMonitoring() {
        // Check if device motion is available
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // Set update interval based on sampling frequency
        motionManager.deviceMotionUpdateInterval = dataUpdateInterval
        
        // Start device motion updates
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Process motion data (will be incorporated into the next physiological state update)
            self.processMotionData(motion)
        }
    }
    
    private func fetchLatestHeartRateSample() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-10), end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self, let samples = samples, let sample = samples.first as? HKQuantitySample else { return }
            
            // Process heart rate sample
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            print("Latest heart rate: \(heartRate) BPM")
            
            // Heart rate will be incorporated into the next physiological state update
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHRVSample() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self, let samples = samples, let sample = samples.first as? HKQuantitySample else { return }
            
            // Process HRV sample
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            print("Latest HRV (SDNN): \(hrv) ms")
            
            // HRV will be incorporated into the next physiological state update
        }
        
        healthStore.execute(query)
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        // Process motion data for tremor detection and freeze responses
        // This is a placeholder for actual tremor and freeze detection algorithms
        
        // Calculate tremor magnitude from acceleration and rotation data
        let accelMagnitude = sqrt(
            pow(motion.userAcceleration.x, 2) +
            pow(motion.userAcceleration.y, 2) +
            pow(motion.userAcceleration.z, 2)
        )
        
        let rotationMagnitude = sqrt(
            pow(motion.rotationRate.x, 2) +
            pow(motion.rotationRate.y, 2) +
            pow(motion.rotationRate.z, 2)
        )
        
        // Simple tremor detection (high-frequency oscillations)
        let tremorIndex = Float(min(1.0, (accelMagnitude * 2 + rotationMagnitude) / 3.0))
        
        // Simple freeze detection (lack of movement)
        // In a real app, this would be more sophisticated with time-series analysis
        let freezeIndex = Float(max(0, 1.0 - (accelMagnitude * 5)))
        
        // Store these values for the next physiological state update
        print("Tremor index: \(tremorIndex), Freeze index: \(freezeIndex)")
    }
    
    private func processLatestBiometricData() -> PhysiologicalState {
        // In a real implementation, this would combine all the latest biometric data
        // from HealthKit, Watch sensors, and motion tracking to create a comprehensive
        // physiological state. For now, we'll create a simulated state.
        
        return simulatePhysiologicalState()
    }
    
    private func simulatePhysiologicalState() -> PhysiologicalState {
        // This is a placeholder implementation that simulates biometric data
        // In a real app, this would be replaced with actual sensor data
        
        let heartRate = 60.0 + Double.random(in: 0...40) // 60-100 bpm
        let hrv = 30.0 + Double.random(in: 0...40) // 30-70 ms
        
        let hrvMetrics = HRVMetrics(
            heartRate: heartRate,
            heartRateVariability: hrv,
            rmssd: hrv * 1.2,
            sdnn: hrv,
            pnn50: Double.random(in: 0...40),
            hrQuality: Float.random(in: 0.7...1.0)
        )
        
        let edaMetrics = EDAMetrics(
            skinConductanceLevel: Double.random(in: 1...10),
            skinConductanceResponses: Int.random(in: 0...5),
            peakAmplitude: Double.random(in: 0...2),
            edaQuality: Float.random(in: 0.6...1.0)
        )
        
        let motionMetrics = MotionMetrics(
            acceleration: CMAcceleration(
                x: Double.random(in: -0.1...0.1),
                y: Double.random(in: -0.1...0.1),
                z: Double.random(in: 0.9...1.1)
            ),
            rotationRate: CMRotationRate(
                x: Double.random(in: -0.1...0.1),
                y: Double.random(in: -0.1...0.1),
                z: Double.random(in: -0.1...0.1)
            ),
            tremor: Float.random(in: 0...0.3),
            freezeIndex: Float.random(in: 0...0.3),
            motionQuality: Float.random(in: 0.7...1.0)
        )
        
        let respirationMetrics = RespirationMetrics(
            respirationRate: 12.0 + Double.random(in: 0...8), // 12-20 breaths per minute
            irregularity: Double.random(in: 0...0.5),
            depth: Double.random(in: 0.5...1.0),
            respirationQuality: Float.random(in: 0.6...1.0)
        )
        
        // Calculate arousal level based on heart rate, skin conductance, and respiration
        // This is a simple placeholder calculation
        let arousalBase = (heartRate - 60) / 40 // 0.0-1.0 from HR
        let arousalEda = edaMetrics.skinConductanceLevel / 10 // 0.0-1.0 from EDA
        let arousalResp = (respirationMetrics.respirationRate - 12) / 8 // 0.0-1.0 from respiration
        
        let arousalLevel = Float((arousalBase + arousalEda + arousalResp) / 3.0)
        
        // Calculate overall quality index
        let qualityIndex = (hrvMetrics.hrQuality + edaMetrics.edaQuality +
                          motionMetrics.motionQuality + respirationMetrics.respirationQuality) / 4.0
        
        return PhysiologicalState(
            timestamp: Date(),
            hrvMetrics: hrvMetrics,
            edaMetrics: edaMetrics,
            motionMetrics: motionMetrics,
            respirationMetrics: respirationMetrics,
            arousalLevel: arousalLevel,
            qualityIndex: qualityIndex
        )
    }
}

// MARK: - WCSessionDelegate

extension AppleWatchBiometricService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        
        print("WCSession activated: \(activationState.rawValue)")
        
        // Check if Watch app is installed
        if session.isPaired && session.isWatchAppInstalled {
            print("Watch app is paired and installed")
        } else {
            print("Watch app is not available: paired=\(session.isPaired), installed=\(session.isWatchAppInstalled)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        
        // Reactivate session if needed
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle messages from the Watch app
        print("Received message from Watch: \(message)")
        
        if let messageType = message["type"] as? String {
            switch messageType {
            case "biometricData":
                // Process biometric data received from Watch
                handleBiometricDataMessage(message)
                
            case "connectionStatus":
                // Handle Watch connection status update
                if let isConnected = message["connected"] as? Bool {
                    print("Watch connection status updated: \(isConnected)")
                }
                
            case "sensorError":
                // Handle sensor error report from Watch
                if let errorMessage = message["message"] as? String {
                    print("Watch sensor error: \(errorMessage)")
                    updateStatus(.failed(BiometricAnalysisError.internalError(errorMessage)))
                }
                
            default:
                print("Unknown message type: \(messageType)")
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func handleBiometricDataMessage(_ message: [String: Any]) {
        // Extract and process biometric data from Watch message
        // In a real implementation, this would parse detailed sensor data
        
        if let heartRate = message["heartRate"] as? Double,
           let heartRateVariability = message["hrv"] as? Double {
            print("Received HR: \(heartRate), HRV: \(heartRateVariability)")
            
            // In a real implementation, you would update your internal data model
            // and potentially trigger a new physiological state calculation
        }
    }
    
    // MARK: - Send Messages to Watch
    
    func sendConfigurationToWatch() {
        guard isWatchConnected else { return }
        
        // Prepare configuration message
        let message: [String: Any] = [
            "type": "configuration",
            "samplingFrequency": options.samplingFrequency.rawValue,
            "includeHRV": options.includeHeartRateVariability,
            "includeEDA": options.includeElectrodermalActivity,
            "includeMotion": options.includeMotionAnalysis,
            "includeRespiration": options.includeRespirationAnalysis
        ]
        
        // Send message to Watch
        session?.sendMessage(message, replyHandler: { response in
            print("Watch configuration response: \(response)")
        }, errorHandler: { error in
            print("Failed to send configuration to Watch: \(error.localizedDescription)")
        })
    }
}
