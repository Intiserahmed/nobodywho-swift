import Foundation

/// A composable retrieval or retrieval-and-inference pipeline.
public protocol Chain {
    func execute(query: String) throws -> String
}

/// Retrieves relevant documents and returns them as a formatted string.
public class RetrievalChain: Chain {
    private let semanticMemory: SemanticMemory
    private let topK: Int

    public init(semanticMemory: SemanticMemory, topK: Int = 3) {
        self.semanticMemory = semanticMemory
        self.topK = topK
    }

    public func execute(query: String) throws -> String {
        let documents = try semanticMemory.search(query: query, topK: topK)
        return documents.map { "[\($0.score)] \($0.text)" }.joined(separator: "\n\n")
    }
}

/// Retrieves relevant documents and generates an answer with a language model.
public class RetrievalAndInferenceChain: Chain {
    private let semanticMemory: SemanticMemory
    private let languageModel: LanguageModel
    private let topK: Int
    private let promptTemplate: PromptTemplate

    public init(
        semanticMemory: SemanticMemory,
        languageModel: LanguageModel,
        topK: Int = 3,
        promptTemplate: PromptTemplate = .default
    ) {
        self.semanticMemory = semanticMemory
        self.languageModel = languageModel
        self.topK = topK
        self.promptTemplate = promptTemplate
    }

    public func execute(query: String) throws -> String {
        let documents = try semanticMemory.search(query: query, topK: topK)
        let prompt = promptTemplate.build(query: query, documents: documents)
        return try languageModel.generate(prompt: prompt)
    }

    /// Executes the chain and returns both the generated answer and the retrieved documents.
    public func executeWithContext(query: String) throws -> (answer: String, documents: [ScoredDocument]) {
        let documents = try semanticMemory.search(query: query, topK: topK)
        let prompt = promptTemplate.build(query: query, documents: documents)
        let answer = try languageModel.generate(prompt: prompt)
        return (answer, documents)
    }
}

/// Retrieves with two-stage hybrid search (embedding + reranking) and generates an answer.
public class HybridRetrievalAndInferenceChain: Chain {
    private let hybridMemory: HybridSemanticMemory
    private let languageModel: LanguageModel
    private let topK: Int
    private let rerankCandidates: Int
    private let promptTemplate: PromptTemplate

    public init(
        hybridMemory: HybridSemanticMemory,
        languageModel: LanguageModel,
        topK: Int = 3,
        rerankCandidates: Int = 10,
        promptTemplate: PromptTemplate = .default
    ) {
        self.hybridMemory = hybridMemory
        self.languageModel = languageModel
        self.topK = topK
        self.rerankCandidates = rerankCandidates
        self.promptTemplate = promptTemplate
    }

    public func execute(query: String) throws -> String {
        let documents = try hybridMemory.search(
            query: query,
            topK: topK,
            rerankCandidates: rerankCandidates
        )
        let prompt = promptTemplate.build(query: query, documents: documents)
        return try languageModel.generate(prompt: prompt)
    }
}

// MARK: - Prompt Templates

public struct PromptTemplate {
    public let template: (String, [ScoredDocument]) -> String

    public init(template: @escaping (String, [ScoredDocument]) -> String) {
        self.template = template
    }

    public func build(query: String, documents: [ScoredDocument]) -> String {
        template(query, documents)
    }

    /// Provides numbered context passages followed by the question.
    public static let `default` = PromptTemplate { query, documents in
        var prompt = "Use the following context to answer the question.\n\n"
        prompt += "Context:\n"
        for (index, doc) in documents.enumerated() {
            prompt += "[\(index + 1)] \(doc.text)\n\n"
        }
        prompt += "Question: \(query)\n"
        prompt += "Answer based on the context above:"
        return prompt
    }

    /// Minimal prompt for short, direct answers.
    public static let concise = PromptTemplate { query, documents in
        let context = documents.map { $0.text }.joined(separator: "\n")
        return "Context:\n\(context)\n\nQuestion: \(query)\nAnswer:"
    }

    /// Instructs the model to cite sources using [1], [2], etc.
    public static let withCitations = PromptTemplate { query, documents in
        var prompt = "Answer the question using the provided context. Cite sources using [1], [2], etc.\n\n"
        prompt += "Context:\n"
        for (index, doc) in documents.enumerated() {
            prompt += "[\(index + 1)] \(doc.text)\n\n"
        }
        prompt += "Question: \(query)\n"
        prompt += "Answer with citations:"
        return prompt
    }
}
