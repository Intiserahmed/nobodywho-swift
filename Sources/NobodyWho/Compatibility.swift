// Compatibility layer: maps the old NobodyWho API surface to the new generated types.
//
// The generated UniFFI bindings use Rust-prefixed type names (RustChat, RustModel, etc.)
// and async-ified token streaming. This file provides backward-compatible aliases and
// wrappers so existing call sites compile without changes to their logic, only minor
// `await` additions for the streaming loop.

import Foundation

// MARK: - Type aliases

public typealias Model = RustModel
public typealias Chat = RustChat
public typealias TokenStream = RustTokenStream
public typealias ImageEmbedding = RustImageEmbedding

// MARK: - ChatConfig

public struct ChatConfig {
    public var contextSize: UInt32
    public var systemPrompt: String
    public var allowThinking: Bool

    public init(contextSize: UInt32, systemPrompt: String, allowThinking: Bool = false) {
        self.contextSize = contextSize
        self.systemPrompt = systemPrompt
        self.allowThinking = allowThinking
    }
}

// MARK: - Prompt

/// Collects multimodal prompt parts and passes them to RustChat.askWithPrompt(parts:).
public final class Prompt {
    public var parts: [PromptPart] = []
    public init() {}
    public func pushImage(path: String) { parts.append(.image(path: path)) }
    public func pushText(text: String)  { parts.append(.text(content: text)) }
}

// MARK: - RustChat convenience inits + wrappers

public extension RustChat {
    /// Convenience init matching the old `Chat(model:config:)` signature.
    convenience init(model: RustModel, config: ChatConfig) {
        self.init(
            model: model,
            systemPrompt: config.systemPrompt.isEmpty ? nil : config.systemPrompt,
            contextSize: config.contextSize,
            templateVariables: nil,
            tools: nil,
            sampler: nil
        )
    }

    /// Old-style multimodal ask using a `Prompt` object.
    func askWithPrompt(prompt: Prompt) -> RustTokenStream {
        askWithPrompt(parts: prompt.parts)
    }
}

// MARK: - loadModel convenience wrapper

/// Convenience wrapper matching the old synchronous-style call signature.
/// The underlying implementation is async; callers already wrap this in `Task.detached`.
public func loadModel(
    path: String,
    useGpu: Bool,
    mmprojPath: String?
) async throws -> RustModel {
    try await loadModel(
        modelPath: path,
        useGpu: useGpu,
        projectionModelPath: mmprojPath,
        onDownloadProgress: nil
    )
}
