//
//  ContentView.swift
//  FlowTimer
//
//  Main window content view composing the flip clock and control components.
//  Layout: Sound dropdown at top center, toolbar buttons top-right,
//  large flip clock in the middle, control buttons below.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    @State private var showHistory: Bool = false
    @State private var selectedSound: AmbientSound? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            if showHistory {
                HistoryView(showHistory: $showHistory)
                    .environmentObject(timerManager)
            } else {
                mainTimerView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadPreferences()
        }
        .onChange(of: timerManager.timerState) { _, newState in
            handleTimerStateChange(newState)
        }
    }

    // MARK: - Main Timer View

    private var mainTimerView: some View {
        VStack(spacing: 0) {
            // Top bar: sound dropdown centered, toolbar buttons on right
            topBar

            Spacer()

            // Flip clock display
            clockSection

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
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Control buttons
            ControlButtonsView(
                timerState: timerManager.timerState,
                onStart: handleStart,
                onPause: handlePause,
                onResume: handleResume,
                onStop: handleStop,
                onReset: { timerManager.reset() }
            )
            .padding(.bottom, 20)

            // Bottom status bar
            bottomStatusBar
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: timerManager.timerState)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Left spacer to balance the right toolbar buttons
            Color.clear
                .frame(width: 72, height: 32)

            Spacer()

            // Sound dropdown centered
            SoundPickerView(
                selectedSound: $selectedSound,
                onSoundSelected: handleSoundSelection
            )
            .frame(width: 240)

            Spacer()

            // Toolbar buttons on the right
            HStack(spacing: 8) {
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
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Clock Section

    private var clockSection: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                FlipClockView(
                    remainingTime: timerManager.remainingTime,
                    scale: 1.5,
                    showSeconds: true,
                    maxWidth: geometry.size.width - 40
                )
                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Bottom Status Bar

    private var bottomStatusBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(stateIndicatorColor)
                    .frame(width: 8, height: 8)
                Text(stateText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

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
        case .idle: return .gray
        case .running: return .green
        case .paused: return .yellow
        case .completed: return .blue
        }
    }

    private var stateText: String {
        switch timerManager.timerState {
        case .idle: return "Ready"
        case .running: return "In Flow"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }

    // MARK: - Actions

    private func handleStart() {
        timerManager.start()
        if let sound = selectedSound {
            audioManager.play(sound)
        }
    }

    private func handlePause() {
        timerManager.pause()
        audioManager.pauseAmbient()
    }

    private func handleResume() {
        timerManager.resume()
        if selectedSound != nil {
            audioManager.resumeAmbient()
        }
    }

    private func handleStop() {
        timerManager.stop()
        audioManager.stop()
    }

    private func handleTimerStateChange(_ newState: TimerState) {
        if newState == .completed {
            audioManager.stop()
            audioManager.playCompletionChime()
        }
    }

    private func handleSoundSelection(_ sound: AmbientSound?) {
        selectedSound = sound
        preferencesManager.setLastSound(sound)

        // If timer is running, update the playing sound immediately
        if timerManager.timerState == .running {
            if let sound = sound {
                audioManager.play(sound)
            } else {
                audioManager.stop()
            }
        }
    }

    private func loadPreferences() {
        timerManager.setDuration(preferencesManager.lastDuration)
        selectedSound = preferencesManager.lastAmbientSound
    }
}

// MARK: - Preview

#Preview("Standard") {
    ContentView()
        .environmentObject(TimerManager())
        .environmentObject(AudioManager())
        .environmentObject(PreferencesManager())
        .frame(width: 800, height: 600)
}
