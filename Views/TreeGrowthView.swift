//
//  TreeGrowthView.swift
//  FlowTimer
//
//  Displays an animated tree that grows with timer progress.
//

import SwiftUI

enum TreeAnimationState {
    case hidden
    case growing
    case paused
    case completed
    case withering
}

struct TreeGrowthView: View {
    
    let progress: Double
    let animationState: TreeAnimationState
    let onComplete: (() -> Void)?
    
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var swayAngle: Double = 0
    @State private var sparklePositions: [CGPoint] = []
    @State private var sparkleOpacity: Double = 0
    
    private let treeHeight: CGFloat = 140
    
    var body: some View {
        ZStack {
            glowOverlay
            treeContainer
            sparklesOverlay
        }
        .frame(height: treeHeight)
        .opacity(opacity)
        .scaleEffect(scale)
        .onChange(of: animationState) { _, newState in
            handleStateChange(newState)
        }
        .onChange(of: progress) { _, newProgress in
            handleProgressChange(newProgress)
        }
        .onAppear {
            generateSparkles()
            startSwayAnimation()
        }
    }

    private var treeContainer: some View {
        let growth = max(0.35, min(1.0, progress))
        
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5)
                .fill(trunkGradient)
                .frame(width: 12, height: 50 * growth)
                .offset(y: 14)

            VStack(spacing: -10) {
                Circle()
                    .fill(treeGradient)
                    .frame(width: 20 + 24 * growth, height: 20 + 24 * growth)

                Circle()
                    .fill(treeGradient)
                    .frame(width: 30 + 36 * growth, height: 30 + 36 * growth)

                Circle()
                    .fill(treeGradient)
                    .frame(width: 36 + 44 * growth, height: 36 + 44 * growth)
            }
            .offset(y: -2)
            .scaleEffect(growth, anchor: .bottom)
        }
            .frame(width: 120, height: treeHeight)
            .rotationEffect(.degrees(swayAngle), anchor: .bottom)
            .opacity(animationState == .paused ? 0.6 : 1.0)
    }
    
    private var treeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.65, blue: 0.35),
                Color(red: 0.18, green: 0.55, blue: 0.28),
                Color(red: 0.12, green: 0.45, blue: 0.22)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var trunkGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.30, blue: 0.15),
                Color(red: 0.35, green: 0.22, blue: 0.10)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var glowOverlay: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.green.opacity(0.4 * glowOpacity),
                        Color.green.opacity(0.2 * glowOpacity),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 70
                )
            )
            .frame(width: 140, height: 100)
            .offset(y: -10)
    }
    
    private var sparklesOverlay: some View {
        ForEach(sparklePositions.indices, id: \.self) { index in
            Circle()
                .fill(Color.white.opacity(sparkleOpacity * 0.8))
                .frame(width: 3, height: 3)
                .offset(x: sparklePositions[index].x, y: sparklePositions[index].y)
        }
    }
    
    private func generateSparkles() {
        sparklePositions = (0..<8).map { _ in
            CGPoint(
                x: CGFloat.random(in: -40...40),
                y: CGFloat.random(in: -52...(-18))
            )
        }
    }
    
    private func startSwayAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            swayAngle = 2.5
        }
    }
    
    private func handleStateChange(_ state: TreeAnimationState) {
        switch state {
        case .hidden:
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = 0
                scale = 0.8
                glowOpacity = 0
                sparkleOpacity = 0
            }
        case .growing:
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
                scale = 1.0
                glowOpacity = 0
            }
            sparkleOpacity = 0.3
        case .paused:
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0.7
                scale = 0.98
                sparkleOpacity = 0
            }
        case .completed:
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
                scale = 1.08
                glowOpacity = 1.0
                sparkleOpacity = 1.0
            }
            onComplete?()
            pulseGlow()
            animateSparkles()
        case .withering:
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 0
                scale = 0.5
                glowOpacity = 0
                sparkleOpacity = 0
            }
        }
    }
    
    private func handleProgressChange(_ newProgress: Double) {
        if animationState == .growing && newProgress >= 0.9 {
            withAnimation(.easeInOut(duration: 0.5)) {
                glowOpacity = 0.3
                sparkleOpacity = 0.5
            }
        }
    }
    
    private func pulseGlow() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }
    
    private func animateSparkles() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            sparkleOpacity = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            generateSparkles()
        }
    }
}
