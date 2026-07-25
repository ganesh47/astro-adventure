import AstroGameCore
import Foundation

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
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(progress)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
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
