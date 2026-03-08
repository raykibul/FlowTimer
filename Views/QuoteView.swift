//
//  QuoteView.swift
//  FlowTimer
//
//  Displays a motivational quote with smooth fade transitions.
//

import SwiftUI

struct QuoteView: View {
    
    let quote: MotivationalQuote
    let isVisible: Bool
    
    @State private var opacity: Double = 0
    @State private var previousQuoteId: UUID?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(quote.text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            if let author = quote.author {
                Text("— \(author)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(opacity)
        .onChange(of: quote.id) { _, newId in
            if previousQuoteId != newId {
                animateQuoteChange()
                previousQuoteId = newId
            }
        }
        .onChange(of: isVisible) { _, visible in
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = visible ? 1.0 : 0.0
            }
        }
        .onAppear {
            previousQuoteId = quote.id
            if isVisible {
                withAnimation(.easeInOut(duration: 0.6)) {
                    opacity = 1.0
                }
            }
        }
    }
    
    private func animateQuoteChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = 1.0
            }
        }
    }
}
