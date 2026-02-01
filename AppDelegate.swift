//
//  AppDelegate.swift
//  FlowTimer
//
//  Handles app lifecycle, menu bar integration, and manager coordination.
//

import AppKit
import SwiftUI
import Combine
import UserNotifications

/// App delegate handling lifecycle events and manager coordination.
///
/// Responsibilities:
/// - Menu bar setup and management
/// - Background running when window closed
/// - Coordinating TimerManager with AudioManager and FocusManager
/// - Automatic session saving
/// - Completion notifications
///
/// **Validates: Requirements 5.1, 5.2, 6.1-6.4, 7.4, 8.1**
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    // MARK: - Shared Managers
    
    /// The shared timer manager instance
    @Published var timerManager = TimerManager()
    
    /// The shared audio manager instance
    @Published var audioManager = AudioManager()
    
    /// The shared focus manager instance
    @Published var focusManager = FocusManager()
    
    /// The shared session store instance
    var sessionStore: SessionStore?
    
    /// The shared preferences manager instance
    @Published var preferencesManager = PreferencesManager()
    
    // MARK: - Menu Bar
    
    /// The menu bar controller
    private var menuBarController: MenuBarController?
    
    // MARK: - Private Properties
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Tracks the session start time for saving
    private var currentSessionStartDate: Date?
    
    /// Tracks the sound used in the current session
    private var currentSessionSound: AmbientSound?
    
    // MARK: - App Lifecycle
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await setupApp()
        }
    }
    
    private func setupApp() async {
        // Initialize session store
        do {
            sessionStore = try SessionStore()
        } catch {
            print("Failed to initialize SessionStore: \(error)")
        }
        
        // Set up menu bar
        setupMenuBar()
        
        // Set up manager coordination
        setupManagerCoordination()
        
        // Load preferences
        loadPreferences()
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    nonisolated func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            await cleanupApp()
        }
    }
    
    private func cleanupApp() async {
        // Save any active session as cancelled
        if timerManager.timerState.isActive {
            saveSession(completed: false)
        }
        
        // Disable focus mode if enabled
        if focusManager.isFocusModeEnabled {
            try? await focusManager.disableFocusMode()
        }
        
        // Stop audio
        audioManager.cleanup()
        
        // Clean up menu bar
        menuBarController?.cleanup()
    }
    
    /// Keeps the app running in the background when the window is closed.
    ///
    /// **Validates: Requirements 7.4**
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar when window is closed
        return false
    }
    
    /// Handles app activation (e.g., clicking dock icon).
    nonisolated func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // No visible windows, open the main window
            Task { @MainActor in
                menuBarController?.openMainWindow()
            }
        }
        return true
    }
    
    // MARK: - Menu Bar Setup
    
    /// Sets up the menu bar status item and controller.
    ///
    /// **Validates: Requirements 6.1**
    private func setupMenuBar() {
        menuBarController = MenuBarController()
        menuBarController?.setup(timerManager: timerManager, audioManager: audioManager)
    }
    
    // MARK: - Manager Coordination
    
    /// Sets up coordination between managers.
    ///
    /// **Validates: Requirements 4.1, 4.2, 5.1, 5.2, 8.1**
    private func setupManagerCoordination() {
        // Observe timer state changes
        timerManager.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                Task { @MainActor in
                    self?.handleTimerStateChange(newState)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handles timer state changes for coordination.
    private func handleTimerStateChange(_ newState: TimerState) {
        switch newState {
        case .running:
            // Timer just started
            if currentSessionStartDate == nil {
                handleSessionStart()
            }
            
        case .paused:
            // Timer paused - no special action needed
            break
            
        case .completed:
            // Timer completed naturally
            handleSessionComplete()
            
        case .idle:
            // Timer stopped or reset
            if currentSessionStartDate != nil {
                // Session was cancelled (stopped before completion)
                handleSessionCancelled()
            }
        }
    }
    
    // MARK: - Session Lifecycle
    
    /// Handles the start of a new session.
    ///
    /// **Validates: Requirements 4.1**
    private func handleSessionStart() {
        currentSessionStartDate = Date()
        currentSessionSound = audioManager.currentSound
        
        // Enable Focus mode
        Task {
            do {
                try await focusManager.enableFocusMode()
            } catch {
                print("Failed to enable Focus mode: \(error)")
            }
        }
    }
    
    /// Handles session completion.
    ///
    /// **Validates: Requirements 5.1, 5.2, 8.1**
    private func handleSessionComplete() {
        // Play completion chime
        playCompletionChime()
        
        // Disable Focus mode
        disableFocusMode()
        
        // Stop ambient sound
        audioManager.stop()
        
        // Save session
        saveSession(completed: true)
        
        // Show completion notification
        showCompletionNotification()
    }
    
    /// Handles session cancellation (stopped before completion).
    private func handleSessionCancelled() {
        // Disable Focus mode
        disableFocusMode()
        
        // Save session as cancelled
        saveSession(completed: false)
    }
    
    // MARK: - Focus Mode
    
    /// Disables Focus mode.
    ///
    /// **Validates: Requirements 4.2, 5.2**
    private func disableFocusMode() {
        Task {
            do {
                try await focusManager.disableFocusMode()
            } catch {
                print("Failed to disable Focus mode: \(error)")
            }
        }
    }
    
    // MARK: - Notifications
    
    /// Requests notification permissions.
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    /// Plays the completion chime sound.
    ///
    /// **Validates: Requirements 5.1, 5.4**
    private func playCompletionChime() {
        audioManager.playCompletionChime()
    }
    
    /// Shows a system notification for session completion.
    ///
    /// **Validates: Requirements 5.3**
    private func showCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Flow Session Complete"
        content.body = "Great work! You completed a \(formatDuration(timerManager.selectedDuration)) focus session."
        content.sound = nil // We play our own chime
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    // MARK: - Session Saving
    
    /// Saves the current session to the store.
    ///
    /// **Validates: Requirements 8.1**
    private func saveSession(completed: Bool) {
        guard let startDate = currentSessionStartDate else { return }
        
        let actualDuration = timerManager.selectedDuration - timerManager.remainingTime
        
        let session = FlowSession(
            startDate: startDate,
            duration: timerManager.selectedDuration,
            actualDuration: actualDuration,
            completed: completed,
            sound: currentSessionSound
        )
        
        sessionStore?.saveSession(session)
        
        // Clear session tracking
        currentSessionStartDate = nil
        currentSessionSound = nil
    }
    
    // MARK: - Preferences
    
    /// Loads user preferences.
    private func loadPreferences() {
        // Load last used duration
        timerManager.setDuration(preferencesManager.lastDuration)
        
        // Load last used volume
        audioManager.setVolume(Float(preferencesManager.lastVolume))
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours) hour \(minutes) minute"
            }
            return "\(hours) hour"
        } else {
            return "\(minutes) minute"
        }
    }
}
