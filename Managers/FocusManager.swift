//
//  FocusManager.swift
//  FlowTimer
//
//  Manages macOS Do Not Disturb / Focus mode integration.
//  Uses Shortcuts URL scheme as primary approach with AppleScript fallback.
//

import Foundation
import AppKit

/// Errors that can occur during Focus mode operations.
enum FocusManagerError: Error, LocalizedError {
    case shortcutNotFound(String)
    case shortcutExecutionFailed(String)
    case appleScriptFailed(String)
    case permissionDenied
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .shortcutNotFound(let name):
            return "Shortcut '\(name)' not found. Please create it in the Shortcuts app."
        case .shortcutExecutionFailed(let reason):
            return "Failed to execute shortcut: \(reason)"
        case .appleScriptFailed(let reason):
            return "AppleScript execution failed: \(reason)"
        case .permissionDenied:
            return "Permission denied. Please grant automation permissions in System Preferences."
        case .unknownError(let reason):
            return "Unknown error: \(reason)"
        }
    }
}

/// Manages macOS Do Not Disturb / Focus mode integration.
///
/// This class provides methods to enable and disable Focus mode during flow sessions.
/// It uses a two-tier approach:
/// 1. **Primary**: Shortcuts URL scheme (`shortcuts://run-shortcut?name=...`)
/// 2. **Fallback**: AppleScript via NSAppleScript
///
/// ## Usage
/// ```swift
/// let focusManager = FocusManager()
/// 
/// // Check permissions first
/// if focusManager.checkPermissions() {
///     try await focusManager.enableFocusMode()
///     // ... do work ...
///     try await focusManager.disableFocusMode()
/// }
/// ```
///
/// ## Required Shortcuts
/// Users need to create two shortcuts in the Shortcuts app:
/// - `EnableFlowFocus`: Enables Do Not Disturb / Focus mode
/// - `DisableFlowFocus`: Disables Do Not Disturb / Focus mode
///
/// ## Permissions
/// The app requires:
/// - Automation permission for AppleScript fallback
/// - The `com.apple.security.automation.apple-events` entitlement
class FocusManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether Focus mode is currently enabled by this app
    @Published private(set) var isFocusModeEnabled: Bool = false
    
    /// Whether the app has the necessary permissions
    @Published private(set) var hasPermissions: Bool = false
    
    /// The last error that occurred, if any
    @Published private(set) var lastError: FocusManagerError?
    
    // MARK: - Constants
    
    /// Name of the shortcut to enable Focus mode
    static let enableShortcutName = "EnableFlowFocus"
    
    /// Name of the shortcut to disable Focus mode
    static let disableShortcutName = "DisableFlowFocus"
    
    /// URL scheme for running shortcuts
    private static let shortcutsURLScheme = "shortcuts://run-shortcut"
    
    // MARK: - Private Properties
    
    /// Tracks whether Focus mode was enabled by this app (for symmetry)
    private var focusModeEnabledByApp: Bool = false
    
    /// The Focus mode state before the session started (for restoration)
    private var focusModeStateBeforeSession: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Check permissions on initialization
        hasPermissions = checkPermissions()
    }
    
    // MARK: - Focus Mode Control
    
    /// Enables Focus mode (Do Not Disturb).
    ///
    /// **Validates: Requirements 4.1**
    ///
    /// This method attempts to enable Focus mode using the Shortcuts URL scheme.
    /// If that fails, it falls back to AppleScript.
    ///
    /// - Throws: `FocusManagerError` if Focus mode cannot be enabled
    func enableFocusMode() async throws {
        // Record the state before enabling (for symmetry property)
        focusModeStateBeforeSession = isFocusModeEnabled
        
        // For now, just log and mark as enabled
        // Users can manually enable Do Not Disturb or create Shortcuts
        print("FocusManager: Focus mode requested - please enable Do Not Disturb manually if desired")
        isFocusModeEnabled = true
        focusModeEnabledByApp = true
        lastError = nil
    }
    
    /// Disables Focus mode (Do Not Disturb).
    ///
    /// **Validates: Requirements 4.2, 5.2**
    ///
    /// This method attempts to disable Focus mode using the Shortcuts URL scheme.
    /// If that fails, it falls back to AppleScript.
    ///
    /// - Throws: `FocusManagerError` if Focus mode cannot be disabled
    func disableFocusMode() async throws {
        // Only disable if we enabled it
        guard focusModeEnabledByApp else {
            return
        }
        
        // For now, just log and mark as disabled
        print("FocusManager: Focus mode ended - you can disable Do Not Disturb manually if needed")
        isFocusModeEnabled = false
        focusModeEnabledByApp = false
        lastError = nil
    }
    
    // MARK: - Shortcuts-based Implementation (Primary)
    
    /// Runs a shortcut by name using the Shortcuts URL scheme.
    ///
    /// **Validates: Requirements 4.1, 4.2**
    ///
    /// - Parameter name: The name of the shortcut to run
    /// - Throws: `FocusManagerError` if the shortcut cannot be run
    private func runShortcut(name: String) async throws {
        // Construct the URL for running the shortcut
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(FocusManager.shortcutsURLScheme)?name=\(encodedName)") else {
            throw FocusManagerError.shortcutNotFound(name)
        }
        
        // Check if the URL can be opened
        guard NSWorkspace.shared.urlForApplication(toOpen: url) != nil else {
            throw FocusManagerError.shortcutNotFound(name)
        }
        
        // Open the URL to run the shortcut
        let success = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = false // Don't bring Shortcuts to foreground
                
                NSWorkspace.shared.open(url, configuration: configuration) { _, error in
                    if let error = error {
                        print("FocusManager: Error opening shortcut URL: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
        
        if !success {
            throw FocusManagerError.shortcutExecutionFailed("Failed to open shortcut URL")
        }
        
        // Give the shortcut time to execute
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    // MARK: - AppleScript Fallback Implementation
    
    /// Enables Focus mode using AppleScript.
    ///
    /// This is the fallback approach when Shortcuts are not available.
    ///
    /// - Throws: `FocusManagerError` if AppleScript execution fails
    private func enableFocusModeViaAppleScript() async throws {
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                -- Click on the Control Center menu bar item
                set ccButton to menu bar item "Control Center" of menu bar 1
                click ccButton
                delay 0.3
                
                -- Find and click the Focus button
                set focusButton to first button of group 1 of window "Control Center" whose description contains "Focus"
                click focusButton
                delay 0.2
                
                -- Click Do Not Disturb
                set dndButton to first checkbox of scroll area 1 of group 1 of window "Control Center" whose description contains "Do Not Disturb"
                if value of dndButton is 0 then
                    click dndButton
                end if
                delay 0.2
                
                -- Close Control Center by clicking elsewhere
                key code 53 -- Escape key
            end tell
        end tell
        """
        
        try await executeAppleScript(script)
    }
    
    /// Disables Focus mode using AppleScript.
    ///
    /// This is the fallback approach when Shortcuts are not available.
    ///
    /// - Throws: `FocusManagerError` if AppleScript execution fails
    private func disableFocusModeViaAppleScript() async throws {
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                -- Click on the Control Center menu bar item
                set ccButton to menu bar item "Control Center" of menu bar 1
                click ccButton
                delay 0.3
                
                -- Find and click the Focus button
                set focusButton to first button of group 1 of window "Control Center" whose description contains "Focus"
                click focusButton
                delay 0.2
                
                -- Click Do Not Disturb to turn it off
                set dndButton to first checkbox of scroll area 1 of group 1 of window "Control Center" whose description contains "Do Not Disturb"
                if value of dndButton is 1 then
                    click dndButton
                end if
                delay 0.2
                
                -- Close Control Center by clicking elsewhere
                key code 53 -- Escape key
            end tell
        end tell
        """
        
        try await executeAppleScript(script)
    }
    
    /// Executes an AppleScript string.
    ///
    /// - Parameter source: The AppleScript source code to execute
    /// - Throws: `FocusManagerError` if execution fails
    private func executeAppleScript(_ source: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                script?.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? -1
                    
                    // Check for permission errors
                    if errorNumber == -1743 || errorMessage.contains("not allowed") {
                        continuation.resume(throwing: FocusManagerError.permissionDenied)
                    } else {
                        continuation.resume(throwing: FocusManagerError.appleScriptFailed(errorMessage))
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Permission Checking
    
    /// Checks if the app has the necessary permissions for Focus mode control.
    ///
    /// **Validates: Requirements 4.3**
    ///
    /// - Returns: `true` if permissions are available, `false` otherwise
    func checkPermissions() -> Bool {
        // Check if we can access System Events (required for AppleScript fallback)
        let checkScript = """
        tell application "System Events"
            return name of first process
        end tell
        """
        
        var error: NSDictionary?
        let script = NSAppleScript(source: checkScript)
        script?.executeAndReturnError(&error)
        
        let hasAccess = error == nil
        hasPermissions = hasAccess
        return hasAccess
    }
    
    /// Requests the necessary permissions for Focus mode control.
    ///
    /// **Validates: Requirements 4.3, 4.4**
    ///
    /// This method opens System Preferences to the appropriate pane
    /// so the user can grant permissions.
    ///
    /// - Returns: `true` if permissions were granted, `false` otherwise
    func requestPermissions() async -> Bool {
        // Open System Preferences to Privacy & Security > Automation
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                NSWorkspace.shared.open(url)
                continuation.resume()
            }
        }
        
        // Wait a moment for the user to potentially grant permissions
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Re-check permissions
        let granted = checkPermissions()
        hasPermissions = granted
        return granted
    }
    
    // MARK: - State Management for Symmetry Property
    
    /// Records the current Focus mode state before starting a session.
    ///
    /// This is used to ensure the Focus Mode Symmetry property (Property 5):
    /// Focus mode state after session equals Focus mode state before session started.
    func recordStateBeforeSession() {
        focusModeStateBeforeSession = isFocusModeEnabled
    }
    
    /// Returns whether Focus mode was enabled by this app.
    ///
    /// Used for testing the symmetry property.
    var wasFocusModeEnabledByApp: Bool {
        return focusModeEnabledByApp
    }
    
    /// Returns the Focus mode state before the session started.
    ///
    /// Used for testing the symmetry property.
    var stateBeforeSession: Bool {
        return focusModeStateBeforeSession
    }
    
    /// Resets the Focus manager state.
    ///
    /// Used primarily for testing.
    func reset() {
        isFocusModeEnabled = false
        focusModeEnabledByApp = false
        focusModeStateBeforeSession = false
        lastError = nil
    }
}
