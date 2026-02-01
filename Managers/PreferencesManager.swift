//
//  PreferencesManager.swift
//  FlowTimer
//
//  Manages user preferences persistence using @AppStorage.
//

import Foundation
import SwiftUI

/// Manages user preferences for the Flow Timer app.
///
/// **Validates: Requirements 9.1, 9.2, 9.3, 9.4**
class PreferencesManager: ObservableObject {
    
    // MARK: - Default Values
    
    static let defaultDuration: TimeInterval = 3600
    static let defaultSound: String = ""
    static let defaultVolume: Double = 0.5
    
    // MARK: - Stored Properties
    
    /// Last used timer duration in seconds (Req 9.1)
    @AppStorage("lastDuration") var lastDuration: TimeInterval = PreferencesManager.defaultDuration
    
    /// Last used ambient sound identifier (Req 9.2)
    @AppStorage("lastSound") var lastSound: String = PreferencesManager.defaultSound
    
    /// Last used volume level (Req 9.2)
    @AppStorage("lastVolume") var lastVolume: Double = PreferencesManager.defaultVolume
    
    // MARK: - Computed Properties
    
    var lastAmbientSound: AmbientSound? {
        guard !lastSound.isEmpty else { return nil }
        return AmbientSound(rawValue: lastSound)
    }
    
    // MARK: - Methods
    
    /// Resets all preferences to defaults (Req 9.4)
    func resetToDefaults() {
        lastDuration = PreferencesManager.defaultDuration
        lastSound = PreferencesManager.defaultSound
        lastVolume = PreferencesManager.defaultVolume
    }
    
    func setLastSound(_ sound: AmbientSound?) {
        lastSound = sound?.rawValue ?? PreferencesManager.defaultSound
    }
    
    func setLastVolume(_ volume: Float) {
        lastVolume = Double(min(max(volume, 0.0), 1.0))
    }
    
    func setLastDuration(_ duration: TimeInterval) {
        guard duration > 0 else { return }
        lastDuration = duration
    }
}
