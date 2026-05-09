import Foundation

// MARK: - Agent Protocols

/// Converts text into embedding vectors.
public protocol EmbedderAgent {
    func embed(_ text: String) async throws -> [Float]
    func embedBatch(_ texts: [String]) async throws -> [[Float]]
}

/// Stores and retrieves vectors by cosine similarity.
public protocol VectorStore {
    func add(id: String, vector: [Float], metadata: [String: String])
    func search(query: [Float], topK: Int) -> [ScoredDocument]
    func remove(id: String)
    func clear()
    var count: Int { get }
}

/// Reranks documents by relevance to a query using a cross-encoder.
public protocol Reranker {
    func rank(query: String, documents: [String]) async throws -> [Float]
    func rankAndSort(query: String, documents: [String]) async throws -> [RankedDocument]
}

/// Generates text from a prompt.
public protocol LanguageModel {
    func generate(prompt: String) async throws -> String
    func generateStream(prompt: String, onToken: (String) -> Void) async throws
}

// MARK: - Data Types

/// A document with its relevance score, returned from a cross-encoder ranking.
public struct RankedDocument: Codable, Equatable {
    public let content: String
    public let score: Float

    public init(content: String, score: Float) {
        self.content = content
        self.score = score
    }
}

/// A document returned from a vector search, with its relevance score.
public struct ScoredDocument: Equatable {
    public let id: String
    public let text: String
    public let score: Float
    public let metadata: [String: String]

    public init(id: String, text: String, score: Float, metadata: [String: String] = [:]) {
        self.id = id
        self.text = text
        self.score = score
        self.metadata = metadata
    }
}

extension RankedDocument {
    public func toScoredDocument(id: String = UUID().uuidString) -> ScoredDocument {
        ScoredDocument(id: id, text: content, score: score)
    }
}
