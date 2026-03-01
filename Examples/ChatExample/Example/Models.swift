//
//  Models.swift
//  Example
//
//  Supporting models for the chat interface
//

import Foundation

/// Represents a single chat message
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    let thinking: String?  // Optional thinking/reasoning process

    init(text: String, isUser: Bool, timestamp: Date = Date(), thinking: String? = nil) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.thinking = thinking
    }
}

/// Demo prompts to showcase SDK capabilities
struct DemoPrompt {
    let icon: String  // SF Symbol name
    let title: String
    let prompt: String
    let category: String
}

extension DemoPrompt {
    static let examples = [
        DemoPrompt(
            icon: "function",
            title: "Math",
            prompt: "Solve this equation step by step: 2x + 5 = 15",
            category: "Mathematics"
        ),
        DemoPrompt(
            icon: "chevron.left.forwardslash.chevron.right",
            title: "Code",
            prompt: "Write a Swift function to check if a string is a palindrome",
            category: "Programming"
        ),
        DemoPrompt(
            icon: "pencil.and.outline",
            title: "Creative",
            prompt: "Write a short haiku about artificial intelligence",
            category: "Creative Writing"
        ),
        DemoPrompt(
            icon: "lightbulb",
            title: "Explain",
            prompt: "Explain why the sky appears blue in simple terms",
            category: "Science"
        ),
        DemoPrompt(
            icon: "doc.text",
            title: "Summarize",
            prompt: "Summarize the benefits of exercise in 3 bullet points",
            category: "Health"
        )
    ]
}
