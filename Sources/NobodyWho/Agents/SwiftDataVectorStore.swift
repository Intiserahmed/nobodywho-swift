import Foundation
import SwiftData

// MARK: - SwiftData Model

@available(iOS 17.0, macOS 14.0, *)
@Model
final class VectorDocument {
    @Attribute(.unique) var id: String
    var vectorData: Data
    var text: String
    var metadataJSON: String
    var createdAt: Date

    init(id: String, vector: [Float], text: String, metadata: [String: String]) {
        self.id = id
        self.vectorData = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)
        self.text = text
        self.metadataJSON = (try? JSONSerialization.data(withJSONObject: metadata))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        self.createdAt = Date()
    }

    var vector: [Float] {
        vectorData.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self))
        }
    }

    var metadata: [String: String] {
        guard let data = metadataJSON.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return dict
    }
}

// MARK: - SwiftData Vector Store

/// A persistent vector store backed by SwiftData. Requires iOS 17+ or macOS 14+.
@available(iOS 17.0, macOS 14.0, *)
public class SwiftDataVectorStore: VectorStore {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init() throws {
        let schema = Schema([VectorDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(modelContainer)
    }

    // MARK: - VectorStore

    public func add(id: String, vector: [Float], metadata: [String: String]) {
        let text = metadata["text"] ?? ""
        let descriptor = FetchDescriptor<VectorDocument>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        }

        modelContext.insert(VectorDocument(id: id, vector: vector, text: text, metadata: metadata))
        try? modelContext.save()
    }

    public func search(query: [Float], topK: Int) -> [ScoredDocument] {
        guard let documents = try? modelContext.fetch(FetchDescriptor<VectorDocument>()) else {
            return []
        }

        var results = documents.map { doc in
            ScoredDocument(
                id: doc.id,
                text: doc.text,
                score: cosineSimilarity(query, doc.vector),
                metadata: doc.metadata
            )
        }

        results.sort { $0.score > $1.score }
        return Array(results.prefix(topK))
    }

    public func remove(id: String) {
        let descriptor = FetchDescriptor<VectorDocument>(
            predicate: #Predicate { $0.id == id }
        )
        guard let doc = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(doc)
        try? modelContext.save()
    }

    public func clear() {
        guard let documents = try? modelContext.fetch(FetchDescriptor<VectorDocument>()) else { return }
        for doc in documents { modelContext.delete(doc) }
        try? modelContext.save()
    }

    public var count: Int {
        (try? modelContext.fetchCount(FetchDescriptor<VectorDocument>())) ?? 0
    }

    // MARK: - Extended Search

    /// Searches with optional metadata filters applied in-memory after fetching.
    public func searchFiltered(
        query: [Float],
        topK: Int,
        textContains: String? = nil,
        createdAfter: Date? = nil
    ) -> [ScoredDocument] {
        guard var documents = try? modelContext.fetch(FetchDescriptor<VectorDocument>()) else {
            return []
        }

        if let textContains {
            documents = documents.filter { $0.text.contains(textContains) }
        }
        if let createdAfter {
            documents = documents.filter { $0.createdAt > createdAfter }
        }

        var results = documents.map { doc in
            ScoredDocument(
                id: doc.id,
                text: doc.text,
                score: cosineSimilarity(query, doc.vector),
                metadata: doc.metadata
            )
        }

        results.sort { $0.score > $1.score }
        return Array(results.prefix(topK))
    }
}
