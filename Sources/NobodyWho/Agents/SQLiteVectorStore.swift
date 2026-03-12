import Foundation
import SQLite3

/// A persistent vector store backed by SQLite.
public class SQLiteVectorStore: VectorStore {
    private var db: OpaquePointer?
    private let dbPath: String
    private let lock = NSLock()

    public init(databasePath: String) throws {
        self.dbPath = databasePath

        guard sqlite3_open(databasePath, &db) == SQLITE_OK else {
            throw VectorStoreError.databaseError("Failed to open database at \(databasePath)")
        }

        let createTable = """
        CREATE TABLE IF NOT EXISTS vectors (
            id TEXT PRIMARY KEY,
            vector BLOB NOT NULL,
            text TEXT,
            metadata TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS idx_created_at ON vectors(created_at);
        """
        try execute(sql: createTable)
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - VectorStore

    public func add(id: String, vector: [Float], metadata: [String: String]) {
        let text = metadata["text"] ?? ""
        let metadataJSON = try? JSONSerialization.data(withJSONObject: metadata)
        let metadataString = metadataJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let vectorData = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)
        let sql = "INSERT OR REPLACE INTO vectors (id, vector, text, metadata) VALUES (?, ?, ?, ?)"

        lock.lock()
        defer { lock.unlock() }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }

        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_bind_blob(stmt, 2, (vectorData as NSData).bytes, Int32(vectorData.count), nil)
        sqlite3_bind_text(stmt, 3, (text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (metadataString as NSString).utf8String, -1, nil)

        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    public func search(query: [Float], topK: Int) -> [ScoredDocument] {
        let sql = "SELECT id, vector, text, metadata FROM vectors"
        var results: [ScoredDocument] = []

        lock.lock()
        defer { lock.unlock() }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(stmt, 0))

            if let vectorBlob = sqlite3_column_blob(stmt, 1) {
                let vectorSize = Int(sqlite3_column_bytes(stmt, 1))
                let vectorData = Data(bytes: vectorBlob, count: vectorSize)
                let vector = vectorData.withUnsafeBytes { ptr in
                    Array(ptr.bindMemory(to: Float.self))
                }

                let text = String(cString: sqlite3_column_text(stmt, 2))
                let metadataString = String(cString: sqlite3_column_text(stmt, 3))
                let metadata = (try? JSONSerialization.jsonObject(with: Data(metadataString.utf8))) as? [String: String] ?? [:]

                results.append(ScoredDocument(
                    id: id,
                    text: text,
                    score: cosineSimilarity(query, vector),
                    metadata: metadata
                ))
            }
        }

        sqlite3_finalize(stmt)
        results.sort { $0.score > $1.score }
        return Array(results.prefix(topK))
    }

    public func remove(id: String) {
        let sql = "DELETE FROM vectors WHERE id = ?"

        lock.lock()
        defer { lock.unlock() }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        try? execute(sql: "DELETE FROM vectors")
    }

    public var count: Int {
        let sql = "SELECT COUNT(*) FROM vectors"

        lock.lock()
        defer { lock.unlock() }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }

        var count = 0
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }

        sqlite3_finalize(stmt)
        return count
    }

    // MARK: - Private

    private func execute(sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errMsg) == SQLITE_OK else {
            let error = String(cString: errMsg!)
            sqlite3_free(errMsg)
            throw VectorStoreError.databaseError(error)
        }
    }
}

// MARK: - Errors

public enum VectorStoreError: Error {
    case databaseError(String)
}
