//
//  FlipClockView.swift
//  FlowTimer
//
//  Full flip clock display showing HH:MM:SS with animated digit transitions.
//  Composes FlipDigitView components with colon separators.
//

import SwiftUI

/// A full flip clock display showing hours, minutes, and seconds.
///
/// The clock displays time in HH:MM:SS format with animated flip transitions
/// when digits change. Uses TimerManager's extractDigits() method to break
/// down the time into individual digits.
///
/// ## Features
/// - Six flip digits (2 hours, 2 minutes, 2 seconds)
/// - Animated colon separators
/// - Dark theme aesthetic for focus work
/// - Scalable sizing for different display contexts
/// - Easy to read from a distance
struct FlipClockView: View {
    /// The remaining time in seconds to display
    let remainingTime: TimeInterval
    
    /// Scale factor for the entire clock (1.0 = default size)
    var scale: CGFloat = 1.0
    
    /// Whether to show seconds (can be hidden for compact display)
    var showSeconds: Bool = true
    
    /// Whether to animate the colons (pulsing effect)
    var animateColons: Bool = true
    
    /// Optional maximum width constraint — when set, the clock auto-scales to fit
    var maxWidth: CGFloat? = nil
    
    // MARK: - Sizing Constants
    
    /// Base digit height before scaling
    private let baseDigitHeight: CGFloat = 120
    
    /// Base digit width before scaling
    private let baseDigitWidth: CGFloat = 80
    
    /// Base font size before scaling
    private let baseFontSize: CGFloat = 100
    
    /// Spacing between digit pairs
    private let pairSpacing: CGFloat = 16
    
    /// Spacing between digits in a pair
    private let digitSpacing: CGFloat = 6
    
    // MARK: - Computed Sizing
    
    /// Effective scale that respects the maxWidth constraint
    private var effectiveScale: CGFloat {
        guard let maxWidth = maxWidth else { return scale }
        // Calculate the natural width at the requested scale
        let digitPairs = showSeconds ? 3 : 2
        let colonCount = showSeconds ? 2 : 1
        let naturalWidth = (baseDigitWidth * 2 + digitSpacing) * CGFloat(digitPairs) * scale
            + pairSpacing * CGFloat(digitPairs - 1) * scale
            + CGFloat(colonCount) * 24 * 0.4 * scale  // colon dot width approx
            + 40 * scale  // horizontal padding
        if naturalWidth > maxWidth {
            return scale * (maxWidth / naturalWidth)
        }
        return scale
    }
    
    private var digitHeight: CGFloat { baseDigitHeight * effectiveScale }
    private var digitWidth: CGFloat { baseDigitWidth * effectiveScale }
    private var fontSize: CGFloat { baseFontSize * effectiveScale }
    private var colonSize: CGFloat { 24 * effectiveScale }
    
    // MARK: - Extracted Digits
    
    /// Extract individual digits from the time
    private var digits: (Int, Int, Int, Int, Int, Int) {
        TimerManager.extractDigits(remainingTime)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: pairSpacing * effectiveScale) {
            // Hours
            digitPair(tens: digits.0, ones: digits.1)
            
            // Colon separator
            ColonSeparatorView(size: colonSize, animate: animateColons)
            
            // Minutes
            digitPair(tens: digits.2, ones: digits.3)
            
            // Seconds (optional)
            if showSeconds {
                // Colon separator
                ColonSeparatorView(size: colonSize, animate: animateColons)
                
                // Seconds
                digitPair(tens: digits.4, ones: digits.5)
            }
        }
        .padding(.horizontal, 20 * effectiveScale)
        .padding(.vertical, 16 * effectiveScale)
        .background(clockBackground)
    }
    
    // MARK: - Subviews
    
    /// Creates a pair of flip digits (e.g., hours tens and ones)
    @ViewBuilder
    private func digitPair(tens: Int, ones: Int) -> some View {
        HStack(spacing: digitSpacing * effectiveScale) {
            FlipDigitView(
                digit: tens,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                fontSize: fontSize
            )
            
            FlipDigitView(
                digit: ones,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                fontSize: fontSize
            )
        }
    }
    
    /// Background for the entire clock
    private var clockBackground: some View {
        RoundedRectangle(cornerRadius: 16 * effectiveScale)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.10),
                        Color(red: 0.05, green: 0.05, blue: 0.07)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
    }
}

/// Animated colon separator between digit pairs.
///
/// The colon pulses subtly to indicate the clock is running,
/// similar to traditional digital clocks.
struct ColonSeparatorView: View {
    /// Size of each dot in the colon
    let size: CGFloat
    
    /// Whether to animate the colon (pulsing)
    var animate: Bool = true
    
    /// Animation state for pulsing effect
    @State private var isPulsing: Bool = false
    
    /// Dot color
    private var dotColor: Color {
        Color.white.opacity(isPulsing ? 0.9 : 0.5)
    }
    
    /// Spacing between dots
    private var dotSpacing: CGFloat {
        size * 1.5
    }
    
    /// Dot diameter
    private var dotDiameter: CGFloat {
        size * 0.4
    }
    
    var body: some View {
        VStack(spacing: dotSpacing) {
            Circle()
                .fill(dotColor)
                .frame(width: dotDiameter, height: dotDiameter)
            
            Circle()
                .fill(dotColor)
                .frame(width: dotDiameter, height: dotDiameter)
        }
        .onAppear {
            if animate {
                startPulsingAnimation()
            }
        }
        .onChange(of: animate) { _, newValue in
            if newValue {
                startPulsingAnimation()
            } else {
                isPulsing = false
            }
        }
    }
    
    /// Starts the pulsing animation
    private func startPulsingAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

// MARK: - Convenience Initializer

extension FlipClockView {
    /// Creates a flip clock view from a TimerManager
    init(timerManager: TimerManager, scale: CGFloat = 1.0, showSeconds: Bool = true) {
        self.remainingTime = timerManager.remainingTime
        self.scale = scale
        self.showSeconds = showSeconds
        self.animateColons = timerManager.timerState == .running
    }
}

// MARK: - Size Presets

extension FlipClockView {
    /// Preset sizes for different contexts
    enum SizePreset {
        case compact    // For menu bar or small displays
        case standard   // Default size
        case large      // For main window prominent display
        
        var scale: CGFloat {
            switch self {
            case .compact:
                return 0.5
            case .standard:
                return 1.0
            case .large:
                return 1.3
            }
        }
    }
    
    /// Creates a flip clock with a preset size
    init(remainingTime: TimeInterval, preset: SizePreset, showSeconds: Bool = true) {
        self.remainingTime = remainingTime
        self.scale = preset.scale
        self.showSeconds = showSeconds
        self.animateColons = true
    }
}

// MARK: - Preview

#Preview("Standard Size") {
    FlipClockView(remainingTime: 3661) // 1:01:01
        .padding()
        .background(Color.black)
}

#Preview("Large Size") {
    FlipClockView(remainingTime: 7325, preset: .large) // 2:02:05
        .padding()
        .background(Color.black)
}

#Preview("Compact Size") {
    FlipClockView(remainingTime: 1800, preset: .compact) // 0:30:00
        .padding()
        .background(Color.black)
}

#Preview("Without Seconds") {
    FlipClockView(remainingTime: 3600, scale: 1.0, showSeconds: false)
        .padding()
        .background(Color.black)
}

#Preview("All Zeros") {
    FlipClockView(remainingTime: 0)
        .padding()
        .background(Color.black)
}

#Preview("Max Time (4 hours)") {
    FlipClockView(remainingTime: 14400) // 4:00:00
        .padding()
        .background(Color.black)
}

#Preview("Interactive Timer") {
    struct InteractivePreview: View {
        @State private var time: TimeInterval = 3661
        
        var body: some View {
            VStack(spacing: 30) {
                FlipClockView(remainingTime: time)
                
                HStack(spacing: 20) {
                    Button("-1 sec") {
                        if time > 0 { time -= 1 }
                    }
                    
                    Button("-1 min") {
                        if time >= 60 { time -= 60 }
                    }
                    
                    Button("+1 min") {
                        time += 60
                    }
                    
                    Button("Reset") {
                        time = 3661
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractivePreview()
}
