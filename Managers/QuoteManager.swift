//
//  QuoteManager.swift
//  FlowTimer
//
//  Manages motivational quote rotation during focus sessions.
//

import Foundation
import Combine

@MainActor
class QuoteManager: ObservableObject {
    
    @Published private(set) var currentQuote: MotivationalQuote
    @Published private(set) var isPaused: Bool = false
    
    private var quotes: [MotivationalQuote]
    private var quoteTimer: Timer?
    private var currentIndex: Int = 0
    private let rotationInterval: TimeInterval = 60
    
    init() {
        self.quotes = MotivationalQuote.curated.shuffled()
        self.currentQuote = quotes[0]
    }
    
    func startRotation() {
        stopRotation()
        isPaused = false
        quoteTimer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.rotateToNextQuote()
            }
        }
        
        if let timer = quoteTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    func pauseRotation() {
        isPaused = true
        quoteTimer?.invalidate()
        quoteTimer = nil
    }
    
    func resumeRotation() {
        guard isPaused else { return }
        isPaused = false
        startRotation()
    }
    
    func stopRotation() {
        isPaused = false
        quoteTimer?.invalidate()
        quoteTimer = nil
        reshuffleQuotes()
    }
    
    private func rotateToNextQuote() {
        currentIndex = (currentIndex + 1) % quotes.count
        currentQuote = quotes[currentIndex]
    }
    
    private func reshuffleQuotes() {
        quotes.shuffle()
        currentIndex = 0
        currentQuote = quotes[0]
    }
}
