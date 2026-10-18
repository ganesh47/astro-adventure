import AstroGameCore
import Foundation
import Observation

public protocol ProgressStoring: Sendable {
    func load() async throws -> GameProgress?
    func save(_ progress: GameProgress) async throws
}

public actor JSONProgressStore: ProgressStoring {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func applicationSupport(
        fileManager: FileManager = .default,
        fileName: String = "astro-adventure-progress.json"
    ) throws -> JSONProgressStore {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = directory.appendingPathComponent(
            "AstroAdventure",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true
        )
        return JSONProgressStore(fileURL: appDirectory.appendingPathComponent(fileName))
    }

    public func load() async throws -> GameProgress? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(GameProgress.self, from: data)
    }

    public func save(_ progress: GameProgress) async throws {
        try validateSupportedSchema(progress)
        // Validate even when a caller skipped load, or another process changed the file.
        // Failed decoding must never turn a future/corrupt log into a fresh empty log.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try JSONDecoder().decode(GameProgress.self, from: Data(contentsOf: fileURL))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(progress)
        #if os(iOS) || os(tvOS)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        #else
            try data.write(to: fileURL, options: .atomic)
        #endif
    }
}

public actor InMemoryProgressStore: ProgressStoring {
    private var progress: GameProgress?

    public init(progress: GameProgress? = nil) {
        self.progress = progress
    }

    public func load() async throws -> GameProgress? {
        progress
    }

    public func save(_ progress: GameProgress) async throws {
        self.progress = progress
    }
}

/// A small preferences-backed log for tvOS, where Application Support files are purgeable.
/// Preferences are local to this device; this does not provide cloud backup or uninstall recovery.
public actor PreferencesProgressStore: ProgressStoring {
    public static let maximumLeaderboardEntries = 20
    public static let maximumEncodedBytes = 256 * 1024
    private let defaults: UserDefaults
    private let key: String
    private let legacyFileURL: URL?

    public init(
        suiteName: String? = nil,
        key: String = "astro-adventure-progress-v2",
        legacyFileURL: URL? = nil
    ) throws {
        guard let defaults = suiteName.map(UserDefaults.init(suiteName:)) ?? .standard else {
            throw ProgressStorageError.unavailable
        }
        self.defaults = defaults
        self.key = key
        self.legacyFileURL = legacyFileURL
    }

    public static func television() throws -> PreferencesProgressStore {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first
        let legacyURL = directory?
            .appendingPathComponent("AstroAdventure", isDirectory: true)
            .appendingPathComponent("astro-adventure-progress.json")
        return try PreferencesProgressStore(legacyFileURL: legacyURL)
    }

    public func load() async throws -> GameProgress? {
        if let data = defaults.data(forKey: key) {
            return bounded(try JSONDecoder().decode(GameProgress.self, from: data))
        }
        if defaults.object(forKey: key) != nil { throw ProgressStorageError.invalidPayload }
        guard let legacyFileURL,
            FileManager.default.fileExists(atPath: legacyFileURL.path)
        else { return nil }
        let migrated = try JSONDecoder().decode(
            GameProgress.self, from: Data(contentsOf: legacyFileURL)
        )
        try await save(migrated)
        // Keep the original file as a fallback; preferences take precedence on subsequent loads.
        return bounded(migrated)
    }

    public func save(_ progress: GameProgress) async throws {
        try validateSupportedSchema(progress)
        if let existing = defaults.object(forKey: key) {
            guard let data = existing as? Data else { throw ProgressStorageError.invalidPayload }
            _ = try JSONDecoder().decode(GameProgress.self, from: data)
        } else if let legacyFileURL, FileManager.default.fileExists(atPath: legacyFileURL.path) {
            _ = try JSONDecoder().decode(GameProgress.self, from: Data(contentsOf: legacyFileURL))
        }
        let data = try JSONEncoder().encode(bounded(progress))
        guard data.count <= Self.maximumEncodedBytes else {
            throw ProgressStorageError.logTooLarge
        }
        defaults.set(data, forKey: key)
        // UserDefaults owns asynchronous disk persistence. Do not claim a forced disk flush.
        guard defaults.data(forKey: key) == data else {
            throw ProgressStorageError.unavailable
        }
    }

    private func bounded(_ progress: GameProgress) -> GameProgress {
        var result = progress
        result.leaderboard = Array(
            progress.leaderboard.sorted {
                $0.achievedAt > $1.achievedAt
            }.prefix(Self.maximumLeaderboardEntries)
        )
        return result
    }
}

public enum ProgressStorageError: LocalizedError {
    case unavailable
    case logTooLarge
    case invalidPayload

    public var errorDescription: String? {
        switch self {
        case .unavailable: "The space log storage is unavailable."
        case .logTooLarge: "The space log is too large to store on this device."
        case .invalidPayload: "The space log could not be read. Its original data is still safe."
        }
    }
}

private func validateSupportedSchema(_ progress: GameProgress) throws {
    guard (1...GameProgress.currentSchemaVersion).contains(progress.schemaVersion) else {
        throw GameProgressDecodingError.unsupportedSchemaVersion(progress.schemaVersion)
    }
    if let cursor = progress.bonusQuizRun, !cursor.isValid {
        throw GameProgressDecodingError.invalidBonusRound
    }
}

/// Accept snapshots synchronously on the main actor, then write them in order.
/// While a write is suspended, coalesce changes to the newest snapshot.
@MainActor
@Observable
public final class ProgressSaveQueue {
    public private(set) var errorMessage: String?
    private let store: any ProgressStoring
    private var pending: GameProgress?
    private var worker: Task<Void, Never>?

    public init(store: any ProgressStoring) {
        self.store = store
    }

    public func enqueue(_ progress: GameProgress) {
        pending = progress
        startWorker()
    }

    public func retry() {
        startWorker()
    }

    public func flush() async {
        startWorker()
        await worker?.value
    }

    private func startWorker() {
        guard worker == nil, pending != nil else { return }
        worker = Task {
            while let snapshot = pending {
                pending = nil
                do {
                    try await store.save(snapshot)
                    errorMessage = nil
                } catch {
                    // A newer snapshot always wins, including after a failed older write.
                    if pending == nil { pending = snapshot }
                    errorMessage = error.localizedDescription
                    break
                }
            }
            worker = nil
        }
    }
}
