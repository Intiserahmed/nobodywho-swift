//
//  ContentView.swift
//  Example
//
//  Main view - NobodyWho SDK integration and chat logic
//

import SwiftUI
import NobodyWho

struct ContentView: View {
    // MARK: - State
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var chat: Chat?
    @State private var model: Model?

    // Model Status
    @State private var modelLoaded: Bool = false
    @State private var modelName: String = "Loading..."
    @State private var useGPU: Bool = true
    @State private var errorMessage: String?

    // Settings
    @State private var showSettings: Bool = false
    @State private var systemPrompt: String = "You are a helpful AI assistant."
    @State private var contextSize: UInt32 = 2048

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with model status
                ModelStatusBar(
                    modelLoaded: modelLoaded,
                    modelName: modelName,
                    useGPU: useGPU,
                    onInfoTap: { showSettings = true }
                )

                Divider()

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                Divider()

                // Quick demo prompts (only show when empty)
                if messages.isEmpty {
                    QuickPromptsView(onSelect: handleDemoPrompt)
                    Divider()
                }

                // Input field
                ChatInputField(
                    text: $inputText,
                    isLoading: isLoading,
                    onSend: sendMessage,
                    onClear: clearChat
                )
            }
            .navigationTitle("NobodyWho Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    systemPrompt: $systemPrompt,
                    contextSize: $contextSize,
                    useGPU: $useGPU,
                    onApply: reinitializeChat
                )
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await initializeSDK()
            }
        }
    }

    // MARK: - SDK Integration

    /// Initialize NobodyWho SDK - Load model and create chat
    func initializeSDK() async {
        do {
            // Step 1: Initialize logging
            initLogging()

            // Step 2: Find model file
            guard let modelPath = Bundle.main.path(
                forResource: "Qwen_Qwen3-0.6B-Q4_K_M",
                ofType: "gguf"
            ) else {
                await MainActor.run {
                    errorMessage = """
                    Model file not found in bundle.

                    Please add 'Qwen_Qwen3-0.6B-Q4_K_M.gguf' to the project \
                    and ensure it's included in Copy Bundle Resources.
                    """
                    modelName = "Model Missing"
                }
                return
            }

            // Step 3: Load model with GPU
            let loadedModel = try loadModel(path: modelPath, useGpu: useGPU)

            await MainActor.run {
                model = loadedModel
                modelName = "Qwen-0.6B"
                modelLoaded = true

                // Step 4: Initialize chat
                initializeChat()

                // Add welcome message
                messages.append(ChatMessage(
                    text: "Hello! I'm powered by NobodyWho SDK. Ask me anything or try the quick prompts below!",
                    isUser: false
                ))
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load model: \(error.localizedDescription)"
                modelName = "Error"
            }
        }
    }

    /// Initialize chat session with configuration
    func initializeChat() {
        guard let model = model else { return }

        do {
            let config = ChatConfig(
                contextSize: contextSize,
                systemPrompt: systemPrompt
            )
            chat = try Chat(model: model, config: config)
        } catch {
            errorMessage = "Failed to create chat: \(error.localizedDescription)"
        }
    }

    /// Send user message and get AI response
    func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty, let chat = chat else { return }

        // Add user message
        messages.append(ChatMessage(text: userMessage, isUser: true))
        inputText = ""
        isLoading = true

        Task {
            do {
                // Get response from SDK
                let response = try chat.askBlocking(prompt: userMessage)

                // Parse thinking and answer from response
                let (thinking, answer) = parseThinkingFromResponse(response)

                await MainActor.run {
                    messages.append(ChatMessage(
                        text: answer,
                        isUser: false,
                        thinking: thinking
                    ))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Handle demo prompt selection
    func handleDemoPrompt(_ prompt: String) {
        inputText = prompt
        sendMessage()
    }

    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        messages.append(ChatMessage(
            text: "Chat cleared. How can I help you?",
            isUser: false
        ))
    }

    /// Reinitialize chat with new settings
    func reinitializeChat() {
        initializeChat()
        messages.removeAll()
        messages.append(ChatMessage(
            text: "Settings updated! Chat reinitialized with new configuration.",
            isUser: false
        ))
    }

    /// Scroll to bottom of chat
    func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    /// Parse thinking content from model response
    /// Returns (thinking, answer) tuple
    func parseThinkingFromResponse(_ response: String) -> (thinking: String?, answer: String) {
        var thinkingContent: String? = nil
        var answerContent = response

        // Try to extract thinking tags
        let patterns = [
            "<think>(.*?)</think>",
            "<thinking>(.*?)</thinking>",
            "\\[THINKING\\](.*?)\\[/THINKING\\]",
            "\\[THINK\\](.*?)\\[/THINK\\]"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) {
                let nsRange = NSRange(response.startIndex..., in: response)

                if let match = regex.firstMatch(in: response, range: nsRange),
                   match.numberOfRanges > 1 {
                    // Extract thinking content
                    if let thinkingRange = Range(match.range(at: 1), in: response) {
                        thinkingContent = String(response[thinkingRange])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    // Remove thinking tags from answer
                    answerContent = regex.stringByReplacingMatches(
                        in: response,
                        range: nsRange,
                        withTemplate: ""
                    ).trimmingCharacters(in: .whitespacesAndNewlines)

                    break
                }
            }
        }

        return (thinkingContent, answerContent)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
