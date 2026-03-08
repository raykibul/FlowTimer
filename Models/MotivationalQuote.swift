//
//  MotivationalQuote.swift
//  FlowTimer
//
//  Model representing a motivational quote for focus sessions.
//

import Foundation

struct MotivationalQuote: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let author: String?
    
    init(text: String, author: String? = nil) {
        self.text = text
        self.author = author
    }
}

extension MotivationalQuote {
    static let curated: [MotivationalQuote] = [
        MotivationalQuote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        MotivationalQuote(text: "Focus on being productive instead of busy.", author: "Tim Ferriss"),
        MotivationalQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        MotivationalQuote(text: "Small steps lead to big achievements."),
        MotivationalQuote(text: "Stay patient and trust your journey."),
        MotivationalQuote(text: "Progress, not perfection."),
        MotivationalQuote(text: "Your focus determines your reality.", author: "George Lucas"),
        MotivationalQuote(text: "One task at a time. You've got this."),
        MotivationalQuote(text: "Deep work creates deep value."),
        MotivationalQuote(text: "Every minute of focus is an investment in your future."),
        MotivationalQuote(text: "Distraction is the enemy of creation."),
        MotivationalQuote(text: "Be stronger than your excuses."),
        MotivationalQuote(text: "The present moment is filled with joy and happiness. If you are attentive, you will see it.", author: "Thich Nhat Hanh"),
        MotivationalQuote(text: "Concentrate all your thoughts upon the work in hand. The sun's rays do not burn until brought to a focus.", author: "Alexander Graham Bell"),
        MotivationalQuote(text: "You don't have to be great to start, but you have to start to be great.", author: "Zig Ziglar"),
        MotivationalQuote(text: "The successful warrior is the average man, with laser-like focus.", author: "Bruce Lee"),
        MotivationalQuote(text: "Where focus goes, energy flows.", author: "Tony Robbins"),
        MotivationalQuote(text: "A year from now you may wish you had started today.", author: "Karen Lamb"),
        MotivationalQuote(text: "The key is not to prioritize your schedule, but to schedule your priorities.", author: "Stephen Covey"),
        MotivationalQuote(text: "Lack of direction, not lack of time, is the problem.", author: "Zig Ziglar"),
        MotivationalQuote(text: "Focus is a matter of deciding what things you're not going to do.", author: "John Carmack"),
        MotivationalQuote(text: "Keep going. Everything you need will come to you at the perfect time."),
        MotivationalQuote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
        MotivationalQuote(text: "Your future is created by what you do today, not tomorrow."),
        MotivationalQuote(text: "Done is better than perfect."),
    ]
}
