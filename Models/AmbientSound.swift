//
//  AmbientSound.swift
//  FlowTimer
//
//  Represents the available ambient sound options for focus sessions.
//

import Foundation

/// Represents the available ambient sound options for focus sessions.
///
/// Each case has a raw value corresponding to the audio file name (without extension).
enum AmbientSound: String, CaseIterable, Identifiable, Equatable {
    /// Gentle brook/stream water sounds
    case brook = "brook"
    
    /// Ocean waves sounds
    case ocean = "ocean"
    
    /// White noise for focus
    case whiteNoise = "white_noise"
    
    /// Rain sounds
    case rain = "rain"
    
    /// Forest ambience with birds and nature
    case forest = "forest"
    
    /// Coffee shop background chatter and ambience
    case coffeeShop = "coffee_shop"
    
    /// Crackling fireplace sounds
    case fireplace = "fireplace"
    
    /// Unique identifier for SwiftUI lists
    var id: String { rawValue }
    
    /// Human-readable display name for the sound
    var displayName: String {
        switch self {
        case .brook:
            return "Brook"
        case .ocean:
            return "Ocean Waves"
        case .whiteNoise:
            return "White Noise"
        case .rain:
            return "Rain"
        case .forest:
            return "Forest"
        case .coffeeShop:
            return "Coffee Shop"
        case .fireplace:
            return "Fireplace"
        }
    }
    
    /// SF Symbol icon name for the sound
    var iconName: String {
        switch self {
        case .brook:
            return "drop.fill"
        case .ocean:
            return "water.waves"
        case .whiteNoise:
            return "waveform"
        case .rain:
            return "cloud.rain.fill"
        case .forest:
            return "leaf.fill"
        case .coffeeShop:
            return "cup.and.saucer.fill"
        case .fireplace:
            return "flame.fill"
        }
    }
    
    /// The file name for the audio resource (with extension)
    var fileName: String {
        "\(rawValue).mp3"
    }
}
