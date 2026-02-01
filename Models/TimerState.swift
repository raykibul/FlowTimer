//
//  TimerState.swift
//  FlowTimer
//
//  Represents the current state of the flow timer.
//

import Foundation

/// Represents the possible states of the flow timer.
///
/// The timer follows a state machine with valid transitions:
/// - `idle` → `running` (start)
/// - `running` → `paused` (pause)
/// - `running` → `idle` (stop/cancel)
/// - `running` → `completed` (time reaches 0)
/// - `paused` → `running` (resume)
/// - `paused` → `idle` (stop/cancel)
/// - `completed` → `idle` (reset)
enum TimerState: String, Equatable, CaseIterable {
    /// Timer is not running and ready to start
    case idle
    
    /// Timer is actively counting down
    case running
    
    /// Timer is temporarily paused
    case paused
    
    /// Timer has finished counting down
    case completed
    
    /// Returns whether the timer can be started from this state
    var canStart: Bool {
        self == .idle
    }
    
    /// Returns whether the timer can be paused from this state
    var canPause: Bool {
        self == .running
    }
    
    /// Returns whether the timer can be resumed from this state
    var canResume: Bool {
        self == .paused
    }
    
    /// Returns whether the timer can be stopped from this state
    var canStop: Bool {
        self == .running || self == .paused
    }
    
    /// Returns whether the timer can be reset from this state
    var canReset: Bool {
        self == .completed
    }
    
    /// Returns whether the timer is currently active (running or paused)
    var isActive: Bool {
        self == .running || self == .paused
    }
}
