//
//  FlowTimerApp.swift
//  FlowTimer
//
//  A native macOS flow timer application with flip clock display,
//  ambient sounds, and Do Not Disturb integration.
//

import SwiftUI

@main
struct FlowTimerApp: App {
    /// The app delegate handles lifecycle and manager coordination
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.timerManager)
                .environmentObject(appDelegate.audioManager)
                .environmentObject(appDelegate.preferencesManager)
                .environmentObject(appDelegate.sessionStore ?? createFallbackSessionStore())
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        .commands {
            // Custom menu commands
            CommandGroup(replacing: .newItem) {
                // Remove "New Window" command
            }
            
            CommandMenu("Timer") {
                Button("Start Flow") {
                    if appDelegate.timerManager.timerState == .idle {
                        appDelegate.timerManager.start()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(appDelegate.timerManager.timerState != .idle)
                
                Button("Pause") {
                    appDelegate.timerManager.pause()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .disabled(appDelegate.timerManager.timerState != .running)
                
                Button("Resume") {
                    appDelegate.timerManager.resume()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(appDelegate.timerManager.timerState != .paused)
                
                Button("Stop") {
                    appDelegate.timerManager.stop()
                    appDelegate.audioManager.stop()
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!appDelegate.timerManager.timerState.isActive)
                
                Divider()
                
                // Duration presets
                Menu("Set Duration") {
                    ForEach(DurationPreset.allCases) { preset in
                        Button(preset.displayName) {
                            appDelegate.timerManager.setDuration(preset)
                            appDelegate.preferencesManager.setLastDuration(preset.rawValue)
                        }
                    }
                }
                .disabled(appDelegate.timerManager.timerState.isActive)
            }
            
            CommandMenu("Sound") {
                Button(appDelegate.audioManager.isMuted ? "Unmute" : "Mute") {
                    appDelegate.audioManager.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [.command])
                
                Divider()
                
                // Sound selection
                ForEach(AmbientSound.allCases) { sound in
                    Button(sound.displayName) {
                        appDelegate.audioManager.play(sound)
                        appDelegate.preferencesManager.setLastSound(sound)
                    }
                }
                
                Divider()
                
                Button("Stop Sound") {
                    appDelegate.audioManager.stop()
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appDelegate.preferencesManager)
                .environmentObject(appDelegate.audioManager)
        }
    }
    
    /// Creates a fallback in-memory session store if the main one fails.
    private func createFallbackSessionStore() -> SessionStore {
        do {
            return try SessionStore.inMemory()
        } catch {
            fatalError("Failed to create fallback SessionStore: \(error)")
        }
    }
}
