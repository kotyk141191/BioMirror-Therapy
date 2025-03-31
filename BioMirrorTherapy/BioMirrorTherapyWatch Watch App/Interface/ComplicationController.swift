//
//  ComplicationController.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the current session status
        let isSessionActive = WatchSessionManager.shared.isSessionActive
        
        // Get complication template
        let template = getComplicationTemplate(for: complication.family, isSessionActive: isSessionActive)
        
        if let template = template {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = getComplicationTemplate(for: complication.family, isSessionActive: false)
        handler(template)
    }
    
    // MARK: - Private Methods
    
    private func getComplicationTemplate(for family: CLKComplicationFamily, isSessionActive: Bool) -> CLKComplicationTemplate? {
        let heartRate = WatchBiometricMonitor.shared.latestHeartRate ?? 0
        
        switch family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BioMirror")
            template.line2TextProvider = CLKSimpleTextProvider(
                text: isSessionActive ? String(format: "%.0f", heartRate) : "Inactive",
                shortText: isSessionActive ? String(format: "%.0f", heartRate) : "Off"
            )
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BM")
            template.line2TextProvider = CLKSimpleTextProvider(
                text: isSessionActive ? String(format: "%.0f", heartRate) : "--"
            )
            return template
            
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(
                text: isSessionActive ? "BM: \(String(format: "%.0f", heartRate))" : "BM: Off",
                shortText: isSessionActive ? "\(String(format: "%.0f", heartRate))" : "Off"
            )
            return template
            
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(
                text: isSessionActive ? "BM: \(String(format: "%.0f", heartRate))" : "BM: Off",
                shortText: isSessionActive ? "\(String(format: "%.0f", heartRate))" : "Off"
            )
            return template
            
        default:
            return nil
        }
    }
}
