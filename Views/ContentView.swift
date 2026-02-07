//
//  ContentView.swift
//  FlowTimer
//
//  Main window content view composing the flip clock and control components.
//  Wires up TimerManager to all UI components for a complete flow timer experience.
//

import SwiftUI

/// Main content view for the Flow Timer app.
///
/// This view composes all the UI components:
/// - FlipClockView for time display
/// - DurationPickerView for selecting session length
/// - ControlButtonsView for timer control
/// - SoundPickerView for ambient sound selection
/// - VolumeSliderView for volume control
///
/// **Validates: Requirements 7.1, 7.2, 7.3**
struct ContentView: View {
    /// The shared timer manager instance
    @EnvironmentObject var timerManager: TimerManager
    
    /// The shared audio manager instance
    @EnvironmentObject var audioManager: AudioManager
    
    /// The shared preferences manager instance
    @EnvironmentObject var preferencesManager: PreferencesManager
    
    /// Whether compact mode is enabled
    @State private var isCompactMode: Bool = false
    
    /// Whether to show the history view
    @State private var showHistory: Bool = false
    
    /// Currently selected ambient sound
    @State private var selectedSound: AmbientSound? = nil
    
    /// Whether sound controls section is expanded
    @State private var isSoundControlsExpanded: Bool = false
    
    // MARK: - Layout Constants
    
    private let standardSpacing: CGFloat = 24
    private let compactSpacing: CGFloat = 16
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Dark background
            backgroundGradient
                .ignoresSafeArea()
            
            if showHistory {
                // History view
                HistoryView(showHistory: $showHistory)
                    .environmentObject(timerManager)
            } else {
                // Main timer view
                mainTimerView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadPreferences()
        }
    }
    
    // MARK: - Main Timer View
    
    private var mainTimerView: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar
            
            Spacer()
            
            // Main content
            if isCompactMode {
                compactLayout
            } else {
                standardLayout
            }
            
            Spacer()
            
            // Bottom status bar
            bottomStatusBar
        }
        .padding()
    }
    
    // MARK: - Standard Layout
    
    private var standardLayout: some View {
        GeometryReader { geometry in
            VStack(spacing: standardSpacing) {
                Spacer()
                
                // Flip clock display - scales to fit available width
                FlipClockView(
                    remainingTime: timerManager.remainingTime,
                    scale: 1.5,
                    showSeconds: true,
                    maxWidth: geometry.size.width - 40
                )
                .animation(.easeInOut(duration: 0.3), value: timerManager.remainingTime)
                
                Spacer()
                
                // Duration picker (only when idle)
                if timerManager.timerState == .idle {
                    DurationPickerView(
                        selectedDuration: Binding(
                            get: { timerManager.selectedDuration },
                            set: { timerManager.setDuration($0) }
                        ),
                        isDisabled: timerManager.timerState.isActive,
                        onDurationSelected: { preset in
                            preferencesManager.setLastDuration(preset.rawValue)
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Control buttons
                ControlButtonsView(
                    timerState: timerManager.timerState,
                    onStart: handleStart,
                    onPause: { timerManager.pause() },
                    onResume: { timerManager.resume() },
                    onStop: handleStop,
                    onReset: { timerManager.reset() }
                )
                
                // Collapsible sound controls
                if timerManager.timerState == .idle || timerManager.timerState.isActive {
                    collapsibleSoundControls
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.3), value: timerManager.timerState)
        }
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        GeometryReader { geometry in
            VStack(spacing: compactSpacing) {
                // Smaller flip clock - scales to fit
                FlipClockView(
                    remainingTime: timerManager.remainingTime,
                    scale: 1.0,
                    showSeconds: true,
                    maxWidth: geometry.size.width - 40
                )
                
                // Compact controls row
                HStack(spacing: 20) {
                    // Duration picker (compact)
                    if timerManager.timerState == .idle {
                        compactDurationPicker
                    }
                    
                    // Control buttons
                    ControlButtonsView(
                        timerState: timerManager.timerState,
                        onStart: handleStart,
                        onPause: { timerManager.pause() },
                        onResume: { timerManager.resume() },
                        onStop: handleStop,
                        onReset: { timerManager.reset() }
                    )
                }
                
                // Compact sound controls
                HStack(spacing: 16) {
                    CompactSoundPickerView(
                        selectedSound: $selectedSound,
                        onSoundSelected: handleSoundSelection
                    )
                    
                    CompactVolumeView(
                        volume: Binding(
                            get: { audioManager.volume },
                            set: { audioManager.setVolume($0) }
                        ),
                        isMuted: Binding(
                            get: { audioManager.isMuted },
                            set: { _ in audioManager.toggleMute() }
                        ),
                        onVolumeChanged: { volume in
                            preferencesManager.setLastVolume(volume)
                        },
                        onMuteToggled: { audioManager.toggleMute() }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Collapsible Sound Controls
    
    private var collapsibleSoundControls: some View {
        VStack(spacing: 12) {
            // Header with toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSoundControlsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Ambient Sound")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    // Show selected sound name when collapsed
                    if !isSoundControlsExpanded, let sound = selectedSound {
                        Text("• \(sound.displayName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSoundControlsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isSoundControlsExpanded {
                VStack(spacing: 16) {
                    // Sound picker
                    SoundPickerView(
                        selectedSound: $selectedSound,
                        onSoundSelected: handleSoundSelection,
                        isDisabled: false
                    )
                    
                    // Volume slider
                    VolumeSliderView(
                        volume: Binding(
                            get: { audioManager.volume },
                            set: { audioManager.setVolume($0) }
                        ),
                        isMuted: Binding(
                            get: { audioManager.isMuted },
                            set: { _ in audioManager.toggleMute() }
                        ),
                        onVolumeChanged: { volume in
                            preferencesManager.setLastVolume(volume)
                        },
                        onMuteToggled: { audioManager.toggleMute() }
                    )
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 40)
        .animation(.easeInOut(duration: 0.25), value: isSoundControlsExpanded)
    }
    
    // MARK: - Sound Controls Section (Legacy)
    
    private var soundControlsSection: some View {
        VStack(spacing: 20) {
            // Sound picker
            SoundPickerView(
                selectedSound: $selectedSound,
                onSoundSelected: handleSoundSelection,
                isDisabled: false
            )
            
            // Volume slider
            VolumeSliderView(
                volume: Binding(
                    get: { audioManager.volume },
                    set: { audioManager.setVolume($0) }
                ),
                isMuted: Binding(
                    get: { audioManager.isMuted },
                    set: { _ in audioManager.toggleMute() }
                ),
                onVolumeChanged: { volume in
                    preferencesManager.setLastVolume(volume)
                },
                onMuteToggled: { audioManager.toggleMute() }
            )
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            // App title
            Text("Flow Timer")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            // Compact mode toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCompactMode.toggle()
                }
            } label: {
                Image(systemName: isCompactMode ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .help(isCompactMode ? "Expand window" : "Compact mode")
            
            // History button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showHistory = true
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .help("View session history")
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Bottom Status Bar
    
    private var bottomStatusBar: some View {
        HStack {
            // Timer state indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(stateIndicatorColor)
                    .frame(width: 8, height: 8)
                
                Text(stateText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Sound indicator
            if let sound = selectedSound, audioManager.isPlaying {
                HStack(spacing: 4) {
                    Image(systemName: sound.iconName)
                        .font(.caption)
                    Text(sound.displayName)
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Compact Duration Picker
    
    private var compactDurationPicker: some View {
        Menu {
            ForEach(DurationPreset.allCases) { preset in
                Button(preset.displayName) {
                    timerManager.setDuration(preset)
                    preferencesManager.setLastDuration(preset.rawValue)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentPresetName)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.15))
            )
        }
        .menuStyle(.borderlessButton)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color(red: 0.02, green: 0.02, blue: 0.04)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Computed Properties
    
    private var stateIndicatorColor: Color {
        switch timerManager.timerState {
        case .idle:
            return .gray
        case .running:
            return .green
        case .paused:
            return .yellow
        case .completed:
            return .blue
        }
    }
    
    private var stateText: String {
        switch timerManager.timerState {
        case .idle:
            return "Ready"
        case .running:
            return "In Flow"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        }
    }
    
    private var currentPresetName: String {
        if let preset = DurationPreset.allCases.first(where: { $0.rawValue == timerManager.selectedDuration }) {
            return preset.displayName
        }
        return TimerManager.formatTime(timerManager.selectedDuration)
    }
    
    // MARK: - Actions
    
    private func handleStart() {
        timerManager.start()
        
        // Start playing sound if selected
        if let sound = selectedSound {
            audioManager.play(sound)
        }
    }
    
    private func handleStop() {
        timerManager.stop()
        audioManager.stop()
    }
    
    private func handleSoundSelection(_ sound: AmbientSound?) {
        selectedSound = sound
        preferencesManager.setLastSound(sound)
        
        // If timer is running, update the playing sound
        if timerManager.timerState.isActive {
            if let sound = sound {
                audioManager.play(sound)
            } else {
                audioManager.stop()
            }
        }
    }
    
    private func loadPreferences() {
        // Load last used duration
        timerManager.setDuration(preferencesManager.lastDuration)
        
        // Load last used sound
        selectedSound = preferencesManager.lastAmbientSound
        
        // Load last used volume
        audioManager.setVolume(Float(preferencesManager.lastVolume))
    }
}

// MARK: - Preview

#Preview("Standard Mode") {
    ContentView()
        .environmentObject(TimerManager())
        .environmentObject(AudioManager())
        .environmentObject(PreferencesManager())
        .frame(width: 800, height: 600)
}

#Preview("Running State") {
    let timerManager = TimerManager()
    // Simulate running state
    return ContentView()
        .environmentObject(timerManager)
        .environmentObject(AudioManager())
        .environmentObject(PreferencesManager())
        .frame(width: 800, height: 600)
}
