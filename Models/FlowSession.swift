//
//  FlowSession.swift
//  FlowTimer
//
//  Data model for persisting flow session history.
//

import Foundation
import SwiftData

/// Represents a completed or cancelled flow session for history tracking.
///
/// This model is persisted using SwiftData to maintain session history
/// across app launches.
@Model
final class FlowSession {
    /// Unique identifier for the session
    var id: UUID
    
    /// When the session was started
    var startDate: Date
    
    /// The originally selected duration in seconds
    var duration: TimeInterval
    
    /// The actual time spent in the session in seconds
    /// (may be less than duration if cancelled early)
    var actualDuration: TimeInterval
    
    /// Whether the session completed naturally (true) or was cancelled (false)
    var completed: Bool
    
    /// The ambient sound used during the session, if any
    /// Stored as the raw value of AmbientSound enum
    var soundUsed: String?
    
    /// Creates a new flow session record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - startDate: When the session started
    ///   - duration: The originally selected duration in seconds
    ///   - actualDuration: The actual time spent in seconds
    ///   - completed: Whether the session completed naturally
    ///   - soundUsed: The ambient sound used, if any
    init(
        id: UUID = UUID(),
        startDate: Date,
        duration: TimeInterval,
        actualDuration: TimeInterval,
        completed: Bool,
        soundUsed: String? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.duration = duration
        self.actualDuration = actualDuration
        self.completed = completed
        self.soundUsed = soundUsed
    }
    
    /// Convenience initializer that accepts an AmbientSound enum value.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - startDate: When the session started
    ///   - duration: The originally selected duration in seconds
    ///   - actualDuration: The actual time spent in seconds
    ///   - completed: Whether the session completed naturally
    ///   - sound: The ambient sound used, if any
    convenience init(
        id: UUID = UUID(),
        startDate: Date,
        duration: TimeInterval,
        actualDuration: TimeInterval,
        completed: Bool,
        sound: AmbientSound?
    ) {
        self.init(
            id: id,
            startDate: startDate,
            duration: duration,
            actualDuration: actualDuration,
            completed: completed,
            soundUsed: sound?.rawValue
        )
    }
    
    /// Returns the AmbientSound enum value if one was used.
    var ambientSound: AmbientSound? {
        guard let soundUsed else { return nil }
        return AmbientSound(rawValue: soundUsed)
    }
    
    /// Returns the end date of the session based on start date and actual duration.
    var endDate: Date {
        startDate.addingTimeInterval(actualDuration)
    }
    
    /// Returns the completion percentage (actualDuration / duration).
    var completionPercentage: Double {
        guard duration > 0 else { return 0 }
        return min(actualDuration / duration, 1.0)
    }
    
    /// Formatted duration string (e.g., "1h 30m")
    var formattedDuration: String {
        let hours = Int(actualDuration) / 3600
        let minutes = (Int(actualDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
