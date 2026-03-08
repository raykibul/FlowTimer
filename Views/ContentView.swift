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
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var quoteManager: QuoteManager

    @State private var showHistory: Bool = false
    @State private var selectedSound: AmbientSound? = nil
    @State private var workName: String = ""
    @State private var treeAnimationState: TreeAnimationState = .hidden
    @State private var shouldShowTreeAndQuote: Bool = false
    @State private var isWithering: Bool = false

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

            // Tree animation (only when timer is active)
            if shouldShowTreeAndQuote {
                TreeGrowthView(
                    progress: timerManager.progress,
                    animationState: treeAnimationState,
                    onComplete: {}
                )
                .transition(.opacity.combined(with: .scale))
                .padding(.bottom, 16)
            }

            // Motivational quote (only when timer is active)
            if shouldShowTreeAndQuote && !isWithering {
                QuoteView(
                    quote: quoteManager.currentQuote,
                    isVisible: shouldShowTreeAndQuote
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.bottom, 24)
            }

            // Flip clock display
            clockSection

            Spacer()

            // Work name input (only when idle)
            if timerManager.timerState == .idle {
                workNameField
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
        .animation(.easeInOut(duration: 0.4), value: shouldShowTreeAndQuote)
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

    // MARK: - Work Name Field

    private var workNameField: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("What are you working on?", text: $workName)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if !workName.isEmpty {
                Button {
                    workName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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
        appDelegate.setWorkName(workName)
        timerManager.start()
        if let sound = selectedSound {
            audioManager.play(sound)
        }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            shouldShowTreeAndQuote = true
            treeAnimationState = .growing
        }
        quoteManager.startRotation()
    }

    private func handlePause() {
        timerManager.pause()
        audioManager.pauseAmbient()
        treeAnimationState = .paused
        quoteManager.pauseRotation()
    }

    private func handleResume() {
        timerManager.resume()
        if selectedSound != nil {
            audioManager.resumeAmbient()
        }
        treeAnimationState = .growing
        quoteManager.resumeRotation()
    }

    private func handleStop() {
        isWithering = true
        treeAnimationState = .withering
        quoteManager.stopRotation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            timerManager.stop()
            audioManager.stop()
            withAnimation(.easeInOut(duration: 0.3)) {
                shouldShowTreeAndQuote = false
                isWithering = false
                treeAnimationState = .hidden
            }
        }
    }

    private func handleTimerStateChange(_ newState: TimerState) {
        if newState == .completed {
            treeAnimationState = .completed
            audioManager.stop()
            audioManager.playCompletionChime()
            quoteManager.stopRotation()
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
    let appDelegate = AppDelegate()
    let quoteManager = QuoteManager()
    
    return ContentView()
        .environmentObject(appDelegate)
        .environmentObject(appDelegate.timerManager)
        .environmentObject(appDelegate.audioManager)
        .environmentObject(appDelegate.preferencesManager)
        .environmentObject(quoteManager)
        .frame(width: 800, height: 600)
}
