//
//  FlipDigitView.swift
//  FlowTimer
//
//  A single digit display with 3D flip animation when the digit changes.
//  Creates the classic split-flap/flip clock effect.
//

import SwiftUI

/// A view that displays a single digit with a 3D flip animation when the value changes.
///
/// The flip effect is achieved by:
/// 1. Showing the current digit's top half (static)
/// 2. Showing the previous digit's bottom half (static, behind)
/// 3. Animating a flipping panel from top to bottom
///
/// ## Animation Sequence
/// When digit changes from N to N+1:
/// 1. Top half shows new digit (N+1)
/// 2. Flipping panel rotates from 0° to 180° around X-axis
/// 3. First half of flip shows old digit (N) top half
/// 4. Second half of flip shows new digit (N+1) bottom half
/// 5. Static bottom half shows new digit (N+1)
struct FlipDigitView: View {
    /// The current digit to display (0-9)
    let digit: Int
    
    /// The height of the full digit
    var digitHeight: CGFloat = 120
    
    /// The width of the digit
    var digitWidth: CGFloat = 80
    
    /// Font size for the digit
    var fontSize: CGFloat = 100
    
    /// Animation duration for the flip effect
    var animationDuration: Double = 0.4
    
    // MARK: - State
    
    /// The previous digit (for animation)
    @State private var previousDigit: Int = 0
    
    /// Animation progress (0 to 1)
    @State private var flipProgress: Double = 0
    
    /// Whether we're currently animating
    @State private var isAnimating: Bool = false
    
    // MARK: - Computed Properties
    
    /// The height of each half
    private var halfHeight: CGFloat {
        digitHeight / 2
    }
    
    /// Gap between top and bottom halves
    private var gapHeight: CGFloat {
        2
    }
    
    /// The rotation angle for the flipping panel
    private var flipAngle: Double {
        flipProgress * 180
    }
    
    /// Whether the flip has passed the midpoint (showing back side)
    private var isPastMidpoint: Bool {
        flipProgress > 0.5
    }
    
    // MARK: - Colors
    
    /// Shadow color for depth effect
    private var shadowColor: Color {
        Color.black.opacity(0.4)
    }
    
    /// Divider line color
    private var dividerColor: Color {
        Color.black.opacity(0.8)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Layer 1: Static bottom half (shows current digit)
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: halfHeight + gapHeight)
                
                DigitHalfView(
                    digit: digit,
                    half: .bottom,
                    digitHeight: digitHeight,
                    digitWidth: digitWidth,
                    fontSize: fontSize
                )
            }
            
            // Layer 2: Static top half (shows current digit)
            VStack(spacing: 0) {
                DigitHalfView(
                    digit: digit,
                    half: .top,
                    digitHeight: digitHeight,
                    digitWidth: digitWidth,
                    fontSize: fontSize
                )
                
                Spacer()
                    .frame(height: halfHeight + gapHeight)
            }
            
            // Layer 3: Flipping panel (animated)
            if isAnimating {
                flippingPanel
            }
            
            // Layer 4: Center divider line
            Rectangle()
                .fill(dividerColor)
                .frame(width: digitWidth, height: gapHeight)
        }
        .frame(width: digitWidth, height: digitHeight + gapHeight)
        .onChange(of: digit) { oldValue, newValue in
            startFlipAnimation(from: oldValue, to: newValue)
        }
        .onAppear {
            previousDigit = digit
        }
    }
    
    // MARK: - Flipping Panel
    
    /// The panel that flips during animation
    @ViewBuilder
    private var flippingPanel: some View {
        // The flipping panel shows different content based on progress
        // First half (0-90°): Shows old digit's top half, flipping down
        // Second half (90-180°): Shows new digit's bottom half, continuing flip
        
        if !isPastMidpoint {
            // First half of flip - showing old digit's top half
            DigitHalfView(
                digit: previousDigit,
                half: .top,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                fontSize: fontSize
            )
            .rotation3DEffect(
                .degrees(flipAngle),
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.5
            )
            .offset(y: -halfHeight / 2 - gapHeight / 2)
            .shadow(color: shadowColor, radius: 4, y: 2)
        } else {
            // Second half of flip - showing new digit's bottom half
            DigitHalfView(
                digit: digit,
                half: .bottom,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                fontSize: fontSize
            )
            .rotation3DEffect(
                .degrees(flipAngle - 180),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.5
            )
            .offset(y: halfHeight / 2 + gapHeight / 2)
            .shadow(color: shadowColor, radius: 4, y: -2)
        }
    }
    
    // MARK: - Animation
    
    /// Starts the flip animation from one digit to another
    private func startFlipAnimation(from oldDigit: Int, to newDigit: Int) {
        // Store the previous digit for animation
        previousDigit = oldDigit
        
        // Reset and start animation
        flipProgress = 0
        isAnimating = true
        
        // Animate the flip
        withAnimation(.easeInOut(duration: animationDuration)) {
            flipProgress = 1.0
        }
        
        // End animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isAnimating = false
            flipProgress = 0
        }
    }
}

// MARK: - Preview

#Preview("Single Digit") {
    FlipDigitView(digit: 5)
        .padding()
        .background(Color.black)
}

#Preview("Digit Pair") {
    HStack(spacing: 8) {
        FlipDigitView(digit: 2)
        FlipDigitView(digit: 5)
    }
    .padding()
    .background(Color.black)
}

#Preview("Interactive Flip") {
    struct InteractivePreview: View {
        @State private var digit = 0
        
        var body: some View {
            VStack(spacing: 20) {
                FlipDigitView(digit: digit)
                
                Button("Increment") {
                    digit = (digit + 1) % 10
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractivePreview()
}
