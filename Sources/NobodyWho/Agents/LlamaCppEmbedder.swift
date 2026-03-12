import Foundation

/// `EmbedderAgent` backed by a llama.cpp embedding model.
public class LlamaCppEmbedder: EmbedderAgent {
    private let embedder: Embedder

    public init(modelPath: String, useGPU: Bool = true, contextSize: UInt32 = 512) throws {
        self.embedder = try loadEmbedder(path: modelPath, useGpu: useGPU, contextSize: contextSize)
    }

    public func embed(_ text: String) throws -> [Float] {
        try embedder.embed(text: text)
    }

    public func embedBatch(_ texts: [String]) throws -> [[Float]] {
        try embedder.embedBatch(texts: texts)
    }
}

/// `Reranker` backed by a llama.cpp cross-encoder model.
public class LlamaCppReranker: Reranker {
    private let crossEncoder: CrossEncoder

    public init(modelPath: String, useGPU: Bool = true, contextSize: UInt32 = 4096) throws {
        self.crossEncoder = try loadCrossEncoder(
            path: modelPath,
            useGpu: useGPU,
            contextSize: contextSize
        )
    }

    public func rank(query: String, documents: [String]) throws -> [Float] {
        try crossEncoder.rank(query: query, documents: documents)
    }

    public func rankAndSort(query: String, documents: [String]) throws -> [RankedDocument] {
        try crossEncoder.rankAndSort(query: query, documents: documents)
    }
}

/// `LanguageModel` backed by a llama.cpp chat model.
public class LlamaCppLanguageModel: LanguageModel {
    private let chat: Chat

    public init(modelPath: String, useGPU: Bool = true, config: ChatConfig) throws {
        let model = try loadModel(path: modelPath, useGpu: useGPU)
        self.chat = try Chat(model: model, config: config)
    }

    public func generate(prompt: String) throws -> String {
        try chat.askBlocking(prompt: prompt)
    }

    public func generateStream(prompt: String, onToken: (String) -> Void) throws {
        let response = try generate(prompt: prompt)
        onToken(response)
    }
}

// MARK: - Errors

public enum AgentError: Error, LocalizedError {
    case notImplemented(String)
    case invalidConfiguration(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}
