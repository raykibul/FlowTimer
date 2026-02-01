//
//  ControlButtonsView.swift
//  FlowTimer
//
//  Control buttons for timer operations: Start, Pause, Resume, and Stop.
//  Button visibility and state changes based on current timer state.
//

import SwiftUI

/// Control buttons for timer operations based on current timer state.
///
/// The view displays different buttons depending on the timer state:
/// - **Idle**: Shows "Start" button
/// - **Running**: Shows "Pause" and "Stop" buttons
/// - **Paused**: Shows "Resume" and "Stop" buttons
/// - **Completed**: Shows "Reset" button
///
/// ## Features
/// - Dynamic button display based on timer state
/// - Dark theme styling to match FlipClockView
/// - Prominent primary action button
/// - Secondary action button for stop/cancel
///
/// ## Usage
/// ```swift
/// @StateObject var timerManager = TimerManager()
///
/// ControlButtonsView(
///     timerState: timerManager.timerState,
///     onStart: { timerManager.start() },
///     onPause: { timerManager.pause() },
///     onResume: { timerManager.resume() },
///     onStop: { timerManager.stop() },
///     onReset: { timerManager.reset() }
/// )
/// ```
struct ControlButtonsView: View {
    /// Current timer state
    let timerState: TimerState
    
    /// Callback when Start button is tapped
    var onStart: () -> Void = {}
    
    /// Callback when Pause button is tapped
    var onPause: () -> Void = {}
    
    /// Callback when Resume button is tapped
    var onResume: () -> Void = {}
    
    /// Callback when Stop button is tapped
    var onStop: () -> Void = {}
    
    /// Callback when Reset button is tapped
    var onReset: () -> Void = {}
    
    // MARK: - Styling Constants
    
    /// Primary button corner radius
    private let primaryCornerRadius: CGFloat = 14
    
    /// Secondary button corner radius
    private let secondaryCornerRadius: CGFloat = 10
    
    /// Primary button horizontal padding
    private let primaryHorizontalPadding: CGFloat = 40
    
    /// Primary button vertical padding
    private let primaryVerticalPadding: CGFloat = 14
    
    /// Secondary button horizontal padding
    private let secondaryHorizontalPadding: CGFloat = 24
    
    /// Secondary button vertical padding
    private let secondaryVerticalPadding: CGFloat = 10
    
    /// Spacing between buttons
    private let buttonSpacing: CGFloat = 16
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: buttonSpacing) {
            switch timerState {
            case .idle:
                startButton
                
            case .running:
                pauseButton
                stopButton
                
            case .paused:
                resumeButton
                stopButton
                
            case .completed:
                resetButton
            }
        }
        .animation(.easeInOut(duration: 0.2), value: timerState)
    }
    
    // MARK: - Button Views
    
    /// Start button (shown in idle state)
    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Start Flow")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, primaryHorizontalPadding)
            .padding(.vertical, primaryVerticalPadding)
            .background(primaryButtonBackground)
        }
        .buttonStyle(.plain)
    }
    
    /// Pause button (shown in running state)
    private var pauseButton: some View {
        Button(action: onPause) {
            HStack(spacing: 8) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Pause")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, primaryHorizontalPadding)
            .padding(.vertical, primaryVerticalPadding)
            .background(primaryButtonBackground)
        }
        .buttonStyle(.plain)
    }
    
    /// Resume button (shown in paused state)
    private var resumeButton: some View {
        Button(action: onResume) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Resume")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, primaryHorizontalPadding)
            .padding(.vertical, primaryVerticalPadding)
            .background(primaryButtonBackground)
        }
        .buttonStyle(.plain)
    }
    
    /// Stop button (shown in running and paused states)
    private var stopButton: some View {
        Button(action: onStop) {
            HStack(spacing: 6) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Stop")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, secondaryHorizontalPadding)
            .padding(.vertical, secondaryVerticalPadding)
            .background(secondaryButtonBackground)
        }
        .buttonStyle(.plain)
    }
    
    /// Reset button (shown in completed state)
    private var resetButton: some View {
        Button(action: onReset) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text("Start New Session")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, primaryHorizontalPadding)
            .padding(.vertical, primaryVerticalPadding)
            .background(primaryButtonBackground)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Button Backgrounds
    
    /// Background for primary action buttons
    private var primaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: primaryCornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(white: 0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.white.opacity(0.3), radius: 8, y: 4)
    }
    
    /// Background for secondary action buttons (stop)
    private var secondaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: secondaryCornerRadius)
            .fill(Color(white: 0.2))
            .overlay(
                RoundedRectangle(cornerRadius: secondaryCornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Convenience Initializer

extension ControlButtonsView {
    /// Creates control buttons bound to a TimerManager
    init(timerManager: TimerManager) {
        self.timerState = timerManager.timerState
        self.onStart = { timerManager.start() }
        self.onPause = { timerManager.pause() }
        self.onResume = { timerManager.resume() }
        self.onStop = { timerManager.stop() }
        self.onReset = { timerManager.reset() }
    }
}

// MARK: - Preview

#Preview("Idle State") {
    ControlButtonsView(timerState: .idle)
        .padding()
        .background(Color.black)
}

#Preview("Running State") {
    ControlButtonsView(timerState: .running)
        .padding()
        .background(Color.black)
}

#Preview("Paused State") {
    ControlButtonsView(timerState: .paused)
        .padding()
        .background(Color.black)
}

#Preview("Completed State") {
    ControlButtonsView(timerState: .completed)
        .padding()
        .background(Color.black)
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var timerState: TimerState = .idle
        
        var body: some View {
            VStack(spacing: 30) {
                Text("State: \(timerState.rawValue)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ControlButtonsView(
                    timerState: timerState,
                    onStart: { timerState = .running },
                    onPause: { timerState = .paused },
                    onResume: { timerState = .running },
                    onStop: { timerState = .idle },
                    onReset: { timerState = .idle }
                )
                
                // Manual state controls for testing
                HStack(spacing: 10) {
                    ForEach(TimerState.allCases, id: \.self) { state in
                        Button(state.rawValue.capitalized) {
                            timerState = state
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractivePreview()
}
