//
//  DigitHalfView.swift
//  FlowTimer
//
//  Displays the top or bottom half of a digit for the flip clock effect.
//  Used as a building block for FlipDigitView to create the split-flap animation.
//

import SwiftUI

/// Represents which half of the digit to display
enum DigitHalf {
    case top
    case bottom
}

/// A view that displays either the top or bottom half of a digit.
///
/// This view is used to create the flip clock effect by showing only half
/// of the digit at a time. The top half shows the upper portion of the digit,
/// while the bottom half shows the lower portion.
///
/// ## Design
/// - Uses a clipping mask to show only the relevant half
/// - Styled with dark theme aesthetic for focus work
/// - Rounded corners on the appropriate edges
/// - Subtle gradient for depth effect
struct DigitHalfView: View {
    /// The digit to display (0-9)
    let digit: Int
    
    /// Which half of the digit to show
    let half: DigitHalf
    
    /// The height of the full digit (half will be shown)
    var digitHeight: CGFloat = 120
    
    /// The width of the digit
    var digitWidth: CGFloat = 80
    
    /// Font size for the digit
    var fontSize: CGFloat = 100
    
    // MARK: - Colors
    
    /// Background color for the digit panel
    private var backgroundColor: Color {
        Color(red: 0.12, green: 0.12, blue: 0.14)
    }
    
    /// Gradient overlay for depth effect
    private var gradientOverlay: LinearGradient {
        switch half {
        case .top:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .bottom:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.15),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    /// Text color for the digit
    private var textColor: Color {
        Color.white.opacity(0.95)
    }
    
    // MARK: - Computed Properties
    
    /// The height of this half view
    private var halfHeight: CGFloat {
        digitHeight / 2
    }
    
    /// Corner radius for the panel
    private var cornerRadius: CGFloat {
        8
    }
    
    /// Rounded corners based on which half is displayed
    private var roundedCorners: UIRectCorner {
        switch half {
        case .top:
            return [.topLeft, .topRight]
        case .bottom:
            return [.bottomLeft, .bottomRight]
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background panel
            RoundedCornersShape(corners: roundedCorners, radius: cornerRadius)
                .fill(backgroundColor)
            
            // Gradient overlay for depth
            RoundedCornersShape(corners: roundedCorners, radius: cornerRadius)
                .fill(gradientOverlay)
            
            // Digit text - positioned to show correct half
            Text("\(digit)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .monospacedDigit()
                .offset(y: half == .top ? halfHeight / 2 : -halfHeight / 2)
        }
        .frame(width: digitWidth, height: halfHeight)
        .clipped()
    }
}

/// A shape that allows specifying which corners to round.
struct RoundedCornersShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        // Start from top-left
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        
        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                radius: topRight,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
        
        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                radius: bottomRight,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        
        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                radius: bottomLeft,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }
        
        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                radius: topLeft,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        
        path.closeSubpath()
        return path
    }
}

/// UIRectCorner equivalent for macOS
struct UIRectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

// MARK: - Preview

#Preview("Top Half - Digit 5") {
    DigitHalfView(digit: 5, half: .top)
        .padding()
        .background(Color.black)
}

#Preview("Bottom Half - Digit 5") {
    DigitHalfView(digit: 5, half: .bottom)
        .padding()
        .background(Color.black)
}

#Preview("Full Digit Stack") {
    VStack(spacing: 2) {
        DigitHalfView(digit: 3, half: .top)
        DigitHalfView(digit: 3, half: .bottom)
    }
    .padding()
    .background(Color.black)
}
