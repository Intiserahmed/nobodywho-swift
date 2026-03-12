import Foundation

/// Coordinates an embedder and a vector store to provide semantic search over documents.
public class SemanticMemory {
    private let embedder: any EmbedderAgent
    private let vectorStore: any VectorStore

    public init(embedder: any EmbedderAgent, vectorStore: any VectorStore) {
        self.embedder = embedder
        self.vectorStore = vectorStore
    }

    /// Embeds and stores a document.
    public func saveDocument(id: String, text: String, metadata: [String: String] = [:]) throws {
        let vector = try embedder.embed(text)
        var fullMetadata = metadata
        fullMetadata["text"] = text
        vectorStore.add(id: id, vector: vector, metadata: fullMetadata)
    }

    /// Embeds and stores multiple documents.
    public func saveDocuments(_ documents: [(id: String, text: String, metadata: [String: String])]) throws {
        for doc in documents {
            try saveDocument(id: doc.id, text: doc.text, metadata: doc.metadata)
        }
    }

    /// Returns the top-K documents most semantically similar to the query.
    public func search(query: String, topK: Int = 3) throws -> [ScoredDocument] {
        let queryVector = try embedder.embed(query)
        return vectorStore.search(query: queryVector, topK: topK)
    }

    public func removeDocument(id: String) {
        vectorStore.remove(id: id)
    }

    public func clear() {
        vectorStore.clear()
    }

    public var documentCount: Int {
        vectorStore.count
    }
}

/// Extends `SemanticMemory` with an optional cross-encoder reranker for two-stage retrieval.
public class HybridSemanticMemory {
    private let semanticMemory: SemanticMemory
    private let reranker: (any Reranker)?

    public init(
        embedder: any EmbedderAgent,
        vectorStore: any VectorStore,
        reranker: (any Reranker)? = nil
    ) {
        self.semanticMemory = SemanticMemory(embedder: embedder, vectorStore: vectorStore)
        self.reranker = reranker
    }

    public func saveDocument(id: String, text: String, metadata: [String: String] = [:]) throws {
        try semanticMemory.saveDocument(id: id, text: text, metadata: metadata)
    }

    /// Retrieves the top-K documents.
    ///
    /// When a reranker is present, fetches `rerankCandidates` via vector search first,
    /// then reranks with a cross-encoder and returns the top-K results.
    public func search(query: String, topK: Int = 3, rerankCandidates: Int = 10) throws -> [ScoredDocument] {
        guard let reranker else {
            return try semanticMemory.search(query: query, topK: topK)
        }

        let candidates = try semanticMemory.search(query: query, topK: rerankCandidates)
        let reranked = try reranker.rankAndSort(query: query, documents: candidates.map { $0.text })

        return Array(reranked.prefix(topK).map { ranked in
            let original = candidates.first { $0.text == ranked.content }
            return ScoredDocument(
                id: original?.id ?? UUID().uuidString,
                text: ranked.content,
                score: ranked.score,
                metadata: original?.metadata ?? [:]
            )
        })
    }

    public func clear() {
        semanticMemory.clear()
    }

    public var documentCount: Int {
        semanticMemory.documentCount
    }
}
