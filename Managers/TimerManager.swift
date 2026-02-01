//
//  TimerManager.swift
//  FlowTimer
//
//  Central state manager for the flow timer, coordinating timer state,
//  countdown logic, and duration presets.
//

import Foundation
import Combine

/// Duration presets available for flow sessions (in seconds).
/// Corresponds to 30 minutes, 1 hour, 2 hours, 3 hours, and 4 hours.
enum DurationPreset: TimeInterval, CaseIterable, Identifiable {
    case thirtyMinutes = 1800    // 30 minutes
    case oneHour = 3600          // 1 hour
    case twoHours = 7200         // 2 hours
    case threeHours = 10800      // 3 hours
    case fourHours = 14400       // 4 hours
    
    var id: TimeInterval { rawValue }
    
    /// Human-readable display name for the preset
    var displayName: String {
        switch self {
        case .thirtyMinutes:
            return "30 min"
        case .oneHour:
            return "1 hour"
        case .twoHours:
            return "2 hours"
        case .threeHours:
            return "3 hours"
        case .fourHours:
            return "4 hours"
        }
    }
    
    /// Short display name for compact UI
    var shortName: String {
        switch self {
        case .thirtyMinutes:
            return "30m"
        case .oneHour:
            return "1h"
        case .twoHours:
            return "2h"
        case .threeHours:
            return "3h"
        case .fourHours:
            return "4h"
        }
    }
}

/// Central manager for the flow timer state and countdown logic.
///
/// This class is the single source of truth for timer state and coordinates
/// with other managers (AudioManager, FocusManager, SessionStore) to provide
/// a complete flow session experience.
///
/// ## State Machine
/// The timer follows a strict state machine with valid transitions:
/// - `idle` → `running` (start)
/// - `running` → `paused` (pause)
/// - `running` → `idle` (stop/cancel)
/// - `running` → `completed` (time reaches 0)
/// - `paused` → `running` (resume)
/// - `paused` → `idle` (stop/cancel)
/// - `completed` → `idle` (reset)
@MainActor
class TimerManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current state of the timer
    @Published private(set) var timerState: TimerState = .idle
    
    /// Selected duration for the timer session (in seconds)
    @Published var selectedDuration: TimeInterval = 3600 // Default: 1 hour
    
    /// Remaining time in the current session (in seconds)
    @Published private(set) var remainingTime: TimeInterval = 0
    
    /// The time when the current session started
    @Published private(set) var sessionStartDate: Date?
    
    // MARK: - Duration Presets
    
    /// Available duration presets as TimeInterval values
    nonisolated static let durationPresets: [TimeInterval] = [1800, 3600, 7200, 10800, 14400]
    
    /// Available duration presets as enum values
    nonisolated static let presets: [DurationPreset] = DurationPreset.allCases
    
    // MARK: - Private Properties
    
    /// The timer used for countdown
    private var timer: Timer?
    
    /// Time when the timer was paused (for accurate resume)
    private var pausedTime: Date?
    
    /// Elapsed time before pause (for accurate tracking)
    private var elapsedBeforePause: TimeInterval = 0
    
    // MARK: - Initialization
    
    init() {
        // Initialize with default duration
        remainingTime = selectedDuration
    }
    
    /// Initialize with a specific duration
    /// - Parameter duration: Initial duration in seconds
    init(duration: TimeInterval) {
        self.selectedDuration = duration
        self.remainingTime = duration
    }
    
    // MARK: - Timer Control Methods
    
    /// Starts the timer from idle state.
    ///
    /// Transitions: `idle` → `running`
    ///
    /// - Precondition: Timer must be in `idle` state
    func start() {
        guard timerState.canStart else {
            return
        }
        
        // Set up initial state
        remainingTime = selectedDuration
        sessionStartDate = Date()
        elapsedBeforePause = 0
        
        // Transition to running state
        timerState = .running
        
        // Start the countdown timer
        startCountdownTimer()
    }
    
    /// Pauses the running timer.
    ///
    /// Transitions: `running` → `paused`
    ///
    /// - Precondition: Timer must be in `running` state
    func pause() {
        guard timerState.canPause else {
            return
        }
        
        // Stop the timer
        stopCountdownTimer()
        
        // Record pause time for accurate resume
        pausedTime = Date()
        
        // Calculate elapsed time so far
        if let startDate = sessionStartDate {
            elapsedBeforePause = Date().timeIntervalSince(startDate) - elapsedBeforePause
        }
        
        // Transition to paused state
        timerState = .paused
    }
    
    /// Resumes the timer from paused state.
    ///
    /// Transitions: `paused` → `running`
    ///
    /// - Precondition: Timer must be in `paused` state
    func resume() {
        guard timerState.canResume else {
            return
        }
        
        // Clear pause time
        pausedTime = nil
        
        // Transition to running state
        timerState = .running
        
        // Restart the countdown timer
        startCountdownTimer()
    }
    
    /// Stops the timer and returns to idle state.
    ///
    /// Transitions: `running` → `idle`, `paused` → `idle`
    ///
    /// - Precondition: Timer must be in `running` or `paused` state
    func stop() {
        guard timerState.canStop else {
            return
        }
        
        // Stop the timer
        stopCountdownTimer()
        
        // Reset state
        resetInternalState()
        
        // Transition to idle state
        timerState = .idle
    }
    
    /// Resets the timer from completed state to idle.
    ///
    /// Transitions: `completed` → `idle`
    ///
    /// - Precondition: Timer must be in `completed` state
    func reset() {
        guard timerState.canReset else {
            return
        }
        
        // Reset state
        resetInternalState()
        
        // Transition to idle state
        timerState = .idle
    }
    
    /// Sets the selected duration and updates remaining time if idle.
    ///
    /// - Parameter duration: The new duration in seconds
    func setDuration(_ duration: TimeInterval) {
        selectedDuration = duration
        
        // Only update remaining time if we're idle
        if timerState == .idle {
            remainingTime = duration
        }
    }
    
    /// Sets the duration from a preset.
    ///
    /// - Parameter preset: The duration preset to use
    func setDuration(_ preset: DurationPreset) {
        setDuration(preset.rawValue)
    }
    
    // MARK: - Computed Properties
    
    /// Returns the elapsed time in the current session.
    var elapsedTime: TimeInterval {
        return selectedDuration - remainingTime
    }
    
    /// Returns the progress as a value between 0 and 1.
    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return 1.0 - (remainingTime / selectedDuration)
    }
    
    /// Returns the remaining time formatted as HH:MM:SS.
    var formattedRemainingTime: String {
        return TimerManager.formatTime(remainingTime)
    }
    
    /// Returns the selected duration formatted as HH:MM:SS.
    var formattedSelectedDuration: String {
        return TimerManager.formatTime(selectedDuration)
    }
    
    // MARK: - Time Formatting
    
    /// Formats a time interval as HH:MM:SS.
    ///
    /// - Parameter time: Time interval in seconds
    /// - Returns: Formatted string in HH:MM:SS format
    nonisolated static func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Extracts individual digits from a time interval for flip clock display.
    ///
    /// - Parameter time: Time interval in seconds
    /// - Returns: Tuple containing (hoursTens, hoursOnes, minutesTens, minutesOnes, secondsTens, secondsOnes)
    nonisolated static func extractDigits(_ time: TimeInterval) -> (Int, Int, Int, Int, Int, Int) {
        let totalSeconds = max(0, Int(time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return (
            hours / 10,      // hours tens
            hours % 10,      // hours ones
            minutes / 10,    // minutes tens
            minutes % 10,    // minutes ones
            seconds / 10,    // seconds tens
            seconds % 10     // seconds ones
        )
    }
    
    // MARK: - Private Methods
    
    /// Starts the countdown timer with 1-second intervals.
    private func startCountdownTimer() {
        // Invalidate any existing timer
        timer?.invalidate()
        
        // Create a new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        // Add to common run loop mode for better responsiveness
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Stops the countdown timer.
    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Called every second to update the remaining time.
    private func tick() {
        guard timerState == .running else { return }
        
        if remainingTime > 0 {
            remainingTime -= 1
            
            // Check if timer completed
            if remainingTime <= 0 {
                remainingTime = 0
                complete()
            }
        }
    }
    
    /// Handles timer completion.
    private func complete() {
        // Stop the timer
        stopCountdownTimer()
        
        // Transition to completed state
        timerState = .completed
    }
    
    /// Resets internal state variables.
    private func resetInternalState() {
        remainingTime = selectedDuration
        sessionStartDate = nil
        pausedTime = nil
        elapsedBeforePause = 0
    }
    
    // MARK: - State Validation (for testing)
    
    /// Validates that a state transition is allowed.
    ///
    /// - Parameters:
    ///   - from: The current state
    ///   - to: The target state
    /// - Returns: True if the transition is valid
    nonisolated static func isValidTransition(from: TimerState, to: TimerState) -> Bool {
        switch (from, to) {
        case (.idle, .running):
            return true
        case (.running, .paused):
            return true
        case (.running, .idle):
            return true
        case (.running, .completed):
            return true
        case (.paused, .running):
            return true
        case (.paused, .idle):
            return true
        case (.completed, .idle):
            return true
        default:
            return false
        }
    }
    
    /// Returns all valid transitions from a given state.
    ///
    /// - Parameter state: The current state
    /// - Returns: Array of valid target states
    nonisolated static func validTransitions(from state: TimerState) -> [TimerState] {
        switch state {
        case .idle:
            return [.running]
        case .running:
            return [.paused, .idle, .completed]
        case .paused:
            return [.running, .idle]
        case .completed:
            return [.idle]
        }
    }
}
