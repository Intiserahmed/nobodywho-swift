import Foundation

/// `EmbedderAgent` backed by a llama.cpp embedding model.
public class LlamaCppEmbedder: EmbedderAgent {
    private let encoder: RustEncoder

    public init(modelPath: String, useGPU: Bool = true, contextSize: UInt32 = 512) async throws {
        let model = try await loadModel(modelPath: modelPath, useGpu: useGPU, projectionModelPath: nil, onDownloadProgress: nil)
        self.encoder = RustEncoder(model: model, contextSize: contextSize)
    }

    public func embed(_ text: String) async throws -> [Float] {
        try await encoder.encode(text: text)
    }

    public func embedBatch(_ texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        for text in texts { results.append(try await encoder.encode(text: text)) }
        return results
    }
}

/// `Reranker` backed by a llama.cpp cross-encoder model.
public class LlamaCppReranker: Reranker {
    private let crossEncoder: RustCrossEncoder

    public init(modelPath: String, useGPU: Bool = true, contextSize: UInt32 = 4096) async throws {
        let model = try await loadModel(modelPath: modelPath, useGpu: useGPU, projectionModelPath: nil, onDownloadProgress: nil)
        self.crossEncoder = RustCrossEncoder(model: model, contextSize: contextSize)
    }

    public func rank(query: String, documents: [String]) async throws -> [Float] {
        try await crossEncoder.rank(query: query, documents: documents)
    }

    public func rankAndSort(query: String, documents: [String]) async throws -> [RankedDocument] {
        let json = try await crossEncoder.rankAndSortJson(query: query, documents: documents)
        let data = Data(json.utf8)
        return (try? JSONDecoder().decode([RankedDocument].self, from: data)) ?? []
    }
}

/// `LanguageModel` backed by a llama.cpp chat model.
public class LlamaCppLanguageModel: LanguageModel {
    private let chat: Chat

    public init(modelPath: String, useGPU: Bool = true, config: ChatConfig) async throws {
        let model = try await loadModel(path: modelPath, useGpu: useGPU, mmprojPath: nil)
        self.chat = Chat(model: model, config: config)
    }

    public func generate(prompt: String) async throws -> String {
        let stream = chat.ask(message: prompt)
        var out = ""
        while let token = await stream.nextToken() { out += token }
        _ = try await stream.completed()
        return out
    }

    public func generateStream(prompt: String, onToken: (String) -> Void) async throws {
        let stream = chat.ask(message: prompt)
        while let token = await stream.nextToken() { onToken(token) }
        _ = try await stream.completed()
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
