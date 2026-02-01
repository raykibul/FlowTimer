//
//  MenuBarController.swift
//  FlowTimer
//
//  Manages the menu bar status item and context menu for the Flow Timer app.
//

import AppKit
import SwiftUI
import Combine

/// Controller for the menu bar status item.
///
/// Manages:
/// - NSStatusItem display with remaining time
/// - Context menu with timer controls
/// - Click action to open/focus main window
///
/// **Validates: Requirements 6.1, 6.2, 6.3, 6.4**
@MainActor
class MenuBarController: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// The status item in the menu bar
    private var statusItem: NSStatusItem?
    
    /// Reference to the timer manager
    private weak var timerManager: TimerManager?
    
    /// Reference to the audio manager
    private weak var audioManager: AudioManager?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer for updating the menu bar title
    private var updateTimer: Timer?
    
    /// The context menu
    private var menu: NSMenu?
    
    // MARK: - Menu Item References
    
    private var pauseResumeItem: NSMenuItem?
    private var stopItem: NSMenuItem?
    private var muteItem: NSMenuItem?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    /// Sets up the menu bar with the given managers.
    ///
    /// - Parameters:
    ///   - timerManager: The timer manager to observe
    ///   - audioManager: The audio manager for mute control
    func setup(timerManager: TimerManager, audioManager: AudioManager) {
        self.timerManager = timerManager
        self.audioManager = audioManager
        
        setupStatusItem()
        setupMenu()
        setupObservers()
        startUpdateTimer()
    }
    
    // MARK: - Status Item Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set initial title with icon
            updateMenuBarTitle()
            
            // Set up click action
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    // MARK: - Menu Setup
    
    private func setupMenu() {
        menu = NSMenu()
        menu?.autoenablesItems = false
        
        // Timer status header
        let statusItem = NSMenuItem(title: "Flow Timer", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu?.addItem(statusItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Pause/Resume item
        pauseResumeItem = NSMenuItem(
            title: "Pause",
            action: #selector(pauseResumeClicked),
            keyEquivalent: "p"
        )
        pauseResumeItem?.target = self
        menu?.addItem(pauseResumeItem!)
        
        // Stop item
        stopItem = NSMenuItem(
            title: "Stop Session",
            action: #selector(stopClicked),
            keyEquivalent: "s"
        )
        stopItem?.target = self
        menu?.addItem(stopItem!)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Mute item
        muteItem = NSMenuItem(
            title: "Mute Sound",
            action: #selector(muteClicked),
            keyEquivalent: "m"
        )
        muteItem?.target = self
        menu?.addItem(muteItem!)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Open window item
        let openItem = NSMenuItem(
            title: "Open Flow Timer",
            action: #selector(openWindowClicked),
            keyEquivalent: "o"
        )
        openItem.target = self
        menu?.addItem(openItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(
            title: "Quit Flow Timer",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu?.addItem(quitItem)
        
        // Update menu state
        updateMenuState()
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Observe timer state changes
        timerManager?.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
                self?.updateMenuState()
            }
            .store(in: &cancellables)
        
        // Observe remaining time changes
        timerManager?.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &cancellables)
        
        // Observe mute state changes
        audioManager?.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update Timer
    
    private func startUpdateTimer() {
        // Update every second for smooth countdown display
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarTitle()
            }
        }
        
        // Add to common run loop mode
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // MARK: - Menu Bar Title Update
    
    /// Updates the menu bar title with the current timer state.
    ///
    /// **Validates: Requirements 6.1, 6.2**
    func updateMenuBarTitle() {
        guard let button = statusItem?.button else { return }
        
        guard let timerManager = timerManager else {
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Flow Timer")
            return
        }
        
        switch timerManager.timerState {
        case .idle:
            // Show just the icon when idle
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Flow Timer")
            
        case .running:
            // Show remaining time with play indicator
            let timeString = formatTimeForMenuBar(timerManager.remainingTime)
            button.title = " \(timeString)"
            button.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Running")
            
        case .paused:
            // Show remaining time with pause indicator
            let timeString = formatTimeForMenuBar(timerManager.remainingTime)
            button.title = " \(timeString)"
            button.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "Paused")
            
        case .completed:
            // Show completion indicator
            button.title = " Done!"
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Completed")
        }
    }
    
    /// Formats time for menu bar display.
    ///
    /// Uses MM:SS for times under 1 hour, HH:MM:SS otherwise.
    ///
    /// **Validates: Requirements 6.2**
    private func formatTimeForMenuBar(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Menu State Update
    
    private func updateMenuState() {
        guard let timerManager = timerManager else { return }
        
        // Update pause/resume item
        switch timerManager.timerState {
        case .running:
            pauseResumeItem?.title = "Pause"
            pauseResumeItem?.isEnabled = true
        case .paused:
            pauseResumeItem?.title = "Resume"
            pauseResumeItem?.isEnabled = true
        default:
            pauseResumeItem?.title = "Pause"
            pauseResumeItem?.isEnabled = false
        }
        
        // Update stop item
        stopItem?.isEnabled = timerManager.timerState.isActive
        
        // Update mute item
        if let audioManager = audioManager {
            muteItem?.title = audioManager.isMuted ? "Unmute Sound" : "Mute Sound"
            muteItem?.isEnabled = audioManager.isPlaying || audioManager.isMuted
        }
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click: show menu
            showMenu()
        } else {
            // Left click: open/focus window
            openMainWindow()
        }
    }
    
    private func showMenu() {
        guard let menu = menu, let button = statusItem?.button else { return }
        
        // Update menu state before showing
        updateMenuState()
        
        // Show the menu
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func pauseResumeClicked() {
        guard let timerManager = timerManager else { return }
        
        if timerManager.timerState == .running {
            timerManager.pause()
        } else if timerManager.timerState == .paused {
            timerManager.resume()
        }
    }
    
    @objc private func stopClicked() {
        timerManager?.stop()
        audioManager?.stop()
    }
    
    @objc private func muteClicked() {
        audioManager?.toggleMute()
    }
    
    @objc private func openWindowClicked() {
        openMainWindow()
    }
    
    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    /// Opens and focuses the main window.
    ///
    /// **Validates: Requirements 6.3**
    func openMainWindow() {
        // Find the main window
        if let window = NSApplication.shared.windows.first(where: { $0.title.isEmpty || $0.title == "Flow Timer" }) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        updateTimer?.invalidate()
        updateTimer = nil
        cancellables.removeAll()
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
}
