//
//  DeviceCapabilityVerifier.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import ARKit
import CoreMotion

enum DeviceCapabilityError: Error {
    case lidarNotAvailable
    case arKitNotSupported
    case watchNotConnected
    case insufficientPermissions
}

class DeviceCapabilityVerifier {
    static func hasRequiredCapabilities() -> Bool {
        // Check for LiDAR Scanner
        let hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        
        // Check for ARKit face tracking capability
        let hasFaceTracking = ARFaceTrackingConfiguration.isSupported
        
        // For now, only check essential capabilities
        // Watch connectivity will be checked separately when needed
        return hasLiDAR && hasFaceTracking
    }
    
    static func verify() {
        // Log device capabilities for debugging
        let capabilities = [
            "LiDAR Available": ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            "Face Tracking Supported": ARFaceTrackingConfiguration.isSupported,
            "Device Model": UIDevice.current.model,
            "System Version": UIDevice.current.systemVersion
        ]
        
        print("Device Capabilities: \(capabilities)")
    }
}
