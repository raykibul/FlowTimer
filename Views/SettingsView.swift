//
//  SettingsView.swift
//  FlowTimer
//
//  App settings and preferences view.
//

import SwiftUI

/// Settings view for configuring app preferences.
///
/// **Validates: Requirements 9.4**
struct SettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var showResetConfirmation = false
    
    var body: some View {
        TabView {
            // General settings
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // Sound settings
            soundSettings
                .tabItem {
                    Label("Sound", systemImage: "speaker.wave.2")
                }
            
            // About
            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(width: 450, height: 300)
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        Form {
            Section("Default Duration") {
                Picker("Default session duration", selection: Binding(
                    get: { preferencesManager.lastDuration },
                    set: { preferencesManager.setLastDuration($0) }
                )) {
                    ForEach(DurationPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button("Reset All Preferences") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .alert("Reset Preferences?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                preferencesManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all preferences to their default values.")
        }
    }
    
    // MARK: - Sound Settings
    
    private var soundSettings: some View {
        Form {
            Section("Default Sound") {
                Picker("Default ambient sound", selection: Binding(
                    get: { preferencesManager.lastSound },
                    set: { preferencesManager.lastSound = $0 }
                )) {
                    Text("None").tag("")
                    ForEach(AmbientSound.allCases) { sound in
                        Text(sound.displayName).tag(sound.rawValue)
                    }
                }
            }
            
            Section("Default Volume") {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { preferencesManager.lastVolume },
                        set: { preferencesManager.lastVolume = $0 }
                    ), in: 0...1)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(preferencesManager.lastVolume * 100))%")
                        .frame(width: 45, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - About View
    
    private var aboutView: some View {
        VStack(spacing: 20) {
            // App icon placeholder
            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Flow Timer")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Version 1.0")
                .foregroundColor(.secondary)
            
            Text("A beautiful flip clock timer for deep focus sessions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Text("© 2024 Flow Timer")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(PreferencesManager())
        .environmentObject(AudioManager())
}
