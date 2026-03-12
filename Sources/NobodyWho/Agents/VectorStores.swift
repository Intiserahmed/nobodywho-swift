import Foundation

/// An in-memory vector store. Fast but non-persistent — data is lost when the process exits.
public class InMemoryVectorStore: VectorStore {
    private var documents: [(id: String, vector: [Float], text: String, metadata: [String: String])] = []

    public init() {}

    public func add(id: String, vector: [Float], metadata: [String: String]) {
        let text = metadata["text"] ?? ""
        documents.append((id, vector, text, metadata))
    }

    public func search(query: [Float], topK: Int) -> [ScoredDocument] {
        let scored = documents.map { doc in
            ScoredDocument(
                id: doc.id,
                text: doc.text,
                score: cosineSimilarity(query, doc.vector),
                metadata: doc.metadata
            )
        }
        return Array(scored.sorted { $0.score > $1.score }.prefix(topK))
    }

    public func remove(id: String) {
        documents.removeAll { $0.id == id }
    }

    public func clear() {
        documents.removeAll()
    }

    public var count: Int {
        documents.count
    }
}

// MARK: - Helpers

func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count else { return 0.0 }

    let dotProduct = zip(a, b).map(*).reduce(0, +)
    let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

    guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }

    return dotProduct / (magnitudeA * magnitudeB)
}
