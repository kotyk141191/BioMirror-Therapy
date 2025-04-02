//
//  AppleWatchBiometricService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import Foundation
import Combine
import CoreMotion
import WatchConnectivity

//enum SamplingFrequency: Int {
//    case low = 1   // 1 Hz
//    case medium = 5 // 5 Hz
//    case high = 10  // 10+ Hz
//}

class AppleWatchBiometricService: NSObject, BiometricAnalysisService, WCSessionDelegate {
    // MARK: - Properties
    
    private var wcSession: WCSession?
    private let physiologicalStateSubject = PassthroughSubject<PhysiologicalState, Never>()
    private let statusSubject = PassthroughSubject<BiometricAnalysisStatus, Never>()
    
    private var _currentPhysiologicalState: PhysiologicalState?
    private var _status: BiometricAnalysisStatus = .notStarted
    private var _isRunning = false
    
    private var options = BiometricAnalysisOptions.default
    private var dataUpdateTimer: Timer?
    
    // Fallback on-device motion monitoring if watch is not available
    private let motionManager = CMMotionManager()
    
    // MARK: - BiometricAnalysisService Protocol Properties
    
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
    
    // MARK: - BiometricAnalysisService Protocol Methods
    
    func startMonitoring() throws {
        guard \!_isRunning else { return }
        
        updateStatus(.initializing)
        
        // Check if Watch is connected
        if let session = wcSession, session.isPaired && session.isReachable {
            // Send start command to Watch
            sendCommandToWatch(command: "start")
            _isRunning = true
            updateStatus(.running)
        } else {
            // No Watch available, use on-device fallback if possible
            startLocalMotionMonitoring()
            _isRunning = true
            updateStatus(.running)
        }
    }
    
    func stopMonitoring() {
        guard _isRunning else { return }
        
        if let session = wcSession, session.isPaired && session.isReachable {
            // Send stop command to Watch
            sendCommandToWatch(command: "stop")
        }
        
        // Stop local monitoring
        stopLocalMotionMonitoring()
        
        // Stop data simulation
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = nil
        
        _isRunning = false
        updateStatus(.notStarted)
    }
    
    func pauseMonitoring() {
        guard _isRunning else { return }
        
        if let session = wcSession, session.isPaired && session.isReachable {
            // Send pause command to Watch
            sendCommandToWatch(command: "pause")
        }
        
        // Pause local monitoring
        motionManager.stopDeviceMotionUpdates()
        
        updateStatus(.paused)
    }
    
    func resumeMonitoring() {
        guard status == .paused else { return }
        
        if let session = wcSession, session.isPaired && session.isReachable {
            // Send resume command to Watch
            sendCommandToWatch(command: "resume")
        } else {
            // Resume local monitoring
            startLocalMotionUpdates()
        }
        
        updateStatus(.running)
    }
    
    func configure(with options: BiometricAnalysisOptions) {
        self.options = options
        
        if let session = wcSession, session.isPaired && session.isReachable {
            // Send configuration to Watch
            let configData: [String: Any] = [
                "samplingFrequency": options.samplingFrequency.rawValue,
                "includeHRV": options.includeHeartRateVariability,
                "includeEDA": options.includeElectrodermalActivity,
                "includeMotion": options.includeMotionAnalysis,
                "includeRespiration": options.includeRespirationAnalysis
            ]
            
            session.sendMessage(configData, replyHandler: nil, errorHandler: { error in
                print("Error sending configuration to Watch: \(error.localizedDescription)")
            })
        }
    }
    
    // MARK: - Watch Connectivity
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("Watch Connectivity not supported on this device")
        }
    }
    
    private func sendCommandToWatch(command: String) {
        guard let session = wcSession, session.activationState == .activated else { return }
        
        let commandData = ["command": command]
        
        session.sendMessage(commandData, replyHandler: nil, errorHandler: { error in
            print("Error sending command to Watch: \(error.localizedDescription)")
        })
    }
    
    // MARK: - Local Motion Monitoring
    
    private func startLocalMotionMonitoring() {
        // Start device motion updates if available
        if motionManager.isDeviceMotionAvailable {
            startLocalMotionUpdates()
        }
        
        // Start data simulation timer (for demo purposes)
        startDataSimulation()
    }
    
    private func startLocalMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / Double(getUpdateFrequency())
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                
                // Process motion data
                self.processLocalMotionData(motion)
            }
        }
    }
    
    private func stopLocalMotionMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func processLocalMotionData(_ motion: CMDeviceMotion) {
        // Extract motion data
        let acceleration = motion.userAcceleration
        let rotation = motion.rotationRate
        
        // Calculate motion metrics
        let accelerationMagnitude = sqrt(
            pow(Float(acceleration.x), 2) +
            pow(Float(acceleration.y), 2) +
            pow(Float(acceleration.z), 2)
        )
        
        let rotationMagnitude = sqrt(
            pow(Float(rotation.x), 2) +
            pow(Float(rotation.y), 2) +
            pow(Float(rotation.z), 2)
        )
        
        // Estimate tremor and freeze based on motion patterns
        let tremor = min(1.0, accelerationMagnitude * 5.0) // Simple tremor approximation
        let freezeIndex = max(0.0, 1.0 - (accelerationMagnitude * 10.0)) // Freeze = low movement
        
        // Create motion metrics
        let motionMetrics = MotionMetrics(
            acceleration: acceleration,
            rotationRate: rotation,
            tremor: tremor,
            freezeIndex: freezeIndex,
            motionQuality: 0.8 // Assuming good quality from direct device motion
        )
        
        // For demo purposes, generate simulated data for other metrics
        updateWithSimulatedData(motionMetrics: motionMetrics)
    }
    
    // MARK: - Data Simulation (for demo/development)
    
    private func startDataSimulation() {
        // Create a timer to simulate data if no real data is available
        let updateInterval = 1.0 / Double(getUpdateFrequency())
        
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            
            // Only use simulated data if we don't have real motion data
            if \!self.motionManager.isDeviceMotionActive {
                self.generateSimulatedData()
            }
        }
    }
    
    private func generateSimulatedData() {
        // Generate random physiological data for demo purposes
        let hrvMetrics = HRVMetrics(
            heartRate: Double.random(in: 65...85),
            heartRateVariability: Double.random(in: 30...70),
            rmssd: Double.random(in: 20...60),
            sdnn: Double.random(in: 30...80),
            pnn50: Double.random(in: 10...40),
            hrQuality: Float.random(in: 0.7...0.9)
        )
        
        let edaMetrics = EDAMetrics(
            skinConductanceLevel: Double.random(in: 2...8),
            skinConductanceResponses: Int.random(in: 0...5),
            peakAmplitude: Double.random(in: 0.2...2.0),
            edaQuality: Float.random(in: 0.6...0.9)
        )
        
        let motionMetrics = MotionMetrics(
            acceleration: CMAcceleration(x: Double.random(in: -0.5...0.5),
                                        y: Double.random(in: -0.5...0.5),
                                        z: Double.random(in: -0.5...0.5)),
            rotationRate: CMRotationRate(x: Double.random(in: -0.5...0.5),
                                        y: Double.random(in: -0.5...0.5),
                                        z: Double.random(in: -0.5...0.5)),
            tremor: Float.random(in: 0...0.3),
            freezeIndex: Float.random(in: 0.1...0.4),
            motionQuality: 0.7
        )
        
        let respirationMetrics = RespirationMetrics(
            respirationRate: Double.random(in: 12...18),
            irregularity: Double.random(in: 0.1...0.4),
            depth: Double.random(in: 0.7...1.0),
            respirationQuality: Float.random(in: 0.6...0.8)
        )
        
        // Generate physiological state
        let state = PhysiologicalState(
            timestamp: Date(),
            hrvMetrics: hrvMetrics,
            edaMetrics: edaMetrics,
            motionMetrics: motionMetrics,
            respirationMetrics: respirationMetrics,
            arousalLevel: Float.random(in: 0.3...0.7),
            qualityIndex: 0.7
        )
        
        // Update state
        _currentPhysiologicalState = state
        physiologicalStateSubject.send(state)
    }
    
    private func updateWithSimulatedData(motionMetrics: MotionMetrics) {
        // Generate random physiological data for metrics we don't have from device
        let hrvMetrics = HRVMetrics(
            heartRate: Double.random(in: 65...85),
            heartRateVariability: Double.random(in: 30...70),
            rmssd: Double.random(in: 20...60),
            sdnn: Double.random(in: 30...80),
            pnn50: Double.random(in: 10...40),
            hrQuality: Float.random(in: 0.7...0.9)
        )
        
        let edaMetrics = EDAMetrics(
            skinConductanceLevel: Double.random(in: 2...8),
            skinConductanceResponses: Int.random(in: 0...5),
            peakAmplitude: Double.random(in: 0.2...2.0),
            edaQuality: Float.random(in: 0.6...0.9)
        )
        
        let respirationMetrics = RespirationMetrics(
            respirationRate: Double.random(in: 12...18),
            irregularity: Double.random(in: 0.1...0.4),
            depth: Double.random(in: 0.7...1.0),
            respirationQuality: Float.random(in: 0.6...0.8)
        )
        
        // Estimate arousal from motion
        let motionBasedArousal = min(1.0, max(0.3,
                                             Float(sqrt(pow(motionMetrics.acceleration.x, 2) +
                                                      pow(motionMetrics.acceleration.y, 2) +
                                                      pow(motionMetrics.acceleration.z, 2)) * 2)
        )
        
        // Generate physiological state with real motion but simulated other metrics
        let state = PhysiologicalState(
            timestamp: Date(),
            hrvMetrics: hrvMetrics,
            edaMetrics: edaMetrics,
            motionMetrics: motionMetrics,
            respirationMetrics: respirationMetrics,
            arousalLevel: motionBasedArousal,
            qualityIndex: 0.8
        )
        
        // Update state
        _currentPhysiologicalState = state
        physiologicalStateSubject.send(state)
    }
    
    // MARK: - Utility Methods
    
    private func updateStatus(_ newStatus: BiometricAnalysisStatus) {
        _status = newStatus
        statusSubject.send(newStatus)
    }
    
    private func getUpdateFrequency() -> Double {
        switch options.samplingFrequency {
        case .low:
            return 1.0 // 1 Hz
        case .medium:
            return 5.0 // 5 Hz
        case .high:
            return 10.0 // 10 Hz
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        
        print("WCSession activated: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Process biometric data received from Watch
        if let dataType = message["type"] as? String, dataType == "biometric" {
            processBiometricDataFromWatch(message)
        }
    }
    
    private func processBiometricDataFromWatch(_ message: [String: Any]) {
        // Extract biometric data from the message
        guard let heartRate = message["heartRate"] as? Double,
              let hrv = message["hrv"] as? Double,
              let scl = message["scl"] as? Double,
              let respirationRate = message["respirationRate"] as? Double,
              let arousal = message["arousal"] as? Float,
              let quality = message["quality"] as? Float else {
            print("Incomplete biometric data received from Watch")
            return
        }
        
        // Create metrics from Watch data
        let hrvMetrics = HRVMetrics(
            heartRate: heartRate,
            heartRateVariability: hrv,
            rmssd: message["rmssd"] as? Double ?? 0.0,
            sdnn: message["sdnn"] as? Double ?? 0.0,
            pnn50: message["pnn50"] as? Double ?? 0.0,
            hrQuality: message["hrQuality"] as? Float ?? 0.7
        )
        
        let edaMetrics = EDAMetrics(
            skinConductanceLevel: scl,
            skinConductanceResponses: message["scrCount"] as? Int ?? 0,
            peakAmplitude: message["scrAmplitude"] as? Double ?? 0.0,
            edaQuality: message["edaQuality"] as? Float ?? 0.7
        )
        
        // Use on-device motion data or create from Watch data if available
        let motionMetrics: MotionMetrics
        if motionManager.isDeviceMotionActive, let deviceMotion = motionManager.deviceMotion {
            motionMetrics = MotionMetrics(
                acceleration: deviceMotion.userAcceleration,
                rotationRate: deviceMotion.rotationRate,
                tremor: message["tremor"] as? Float ?? 0.0,
                freezeIndex: message["freezeIndex"] as? Float ?? 0.0,
                motionQuality: message["motionQuality"] as? Float ?? 0.7
            )
        } else if let accX = message["accX"] as? Double,
                  let accY = message["accY"] as? Double,
                  let accZ = message["accZ"] as? Double,
                  let rotX = message["rotX"] as? Double,
                  let rotY = message["rotY"] as? Double,
                  let rotZ = message["rotZ"] as? Double {
            // Use motion data from Watch
            motionMetrics = MotionMetrics(
                acceleration: CMAcceleration(x: accX, y: accY, z: accZ),
                rotationRate: CMRotationRate(x: rotX, y: rotY, z: rotZ),
                tremor: message["tremor"] as? Float ?? 0.0,
                freezeIndex: message["freezeIndex"] as? Float ?? 0.0,
                motionQuality: message["motionQuality"] as? Float ?? 0.7
            )
        } else {
            // Use default values if no motion data available
            motionMetrics = MotionMetrics.empty
        }
        
        let respirationMetrics = RespirationMetrics(
            respirationRate: respirationRate,
            irregularity: message["respirationIrregularity"] as? Double ?? 0.0,
            depth: message["respirationDepth"] as? Double ?? 0.0,
            respirationQuality: message["respirationQuality"] as? Float ?? 0.7
        )
        
        // Create physiological state
        let state = PhysiologicalState(
            timestamp: Date(),
            hrvMetrics: hrvMetrics,
            edaMetrics: edaMetrics,
            motionMetrics: motionMetrics,
            respirationMetrics: respirationMetrics,
            arousalLevel: arousal,
            qualityIndex: quality
        )
        
        // Update state
        _currentPhysiologicalState = state
        physiologicalStateSubject.send(state)
    }
}
