import AstroGameCore
import Foundation
import XCTest

@testable import AstroServices

final class ProgressStoreTests: XCTestCase {
    func testJSONStoreRoundTripsVersionedProgress() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let expected = GameProgress(
            selectedAgeBand: .ages4To6,
            destinations: [
                "mercury": DestinationProgress(
                    isScanned: true,
                    masteryScore: 25,
                    reviewBox: 1
                )
            ]
        )
        let store = JSONProgressStore(fileURL: fileURL)

        try await store.save(expected)
        let restored = try await store.load()

        XCTAssertEqual(restored, expected)
        XCTAssertEqual(restored?.schemaVersion, GameProgress.currentSchemaVersion)
    }

    func testVersionOneProgressMigratesWithoutLosingDestinationData() async throws {
        let legacyJSON = """
            {
              "schemaVersion": 1,
              "missionID": "signal-sweep",
              "selectedAgeBand": "ages7To9",
              "destinations": {
                "mars": {
                  "isScanned": true,
                  "isQuizCompleted": true,
                  "correctAnswers": 1,
                  "attempts": 1,
                  "masteryScore": 25,
                  "reviewBox": 1
                }
              }
            }
            """
        let decoded = try JSONDecoder().decode(GameProgress.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(decoded.schemaVersion, GameProgress.currentSchemaVersion)
        XCTAssertTrue(decoded.destinations["mars"]?.isQuizCompleted == true)
        XCTAssertEqual(decoded.totalScore, 0)
        XCTAssertTrue(decoded.leaderboard.isEmpty)
        XCTAssertTrue(decoded.completedMissionIDs.isEmpty)
        XCTAssertTrue(decoded.concepts.isEmpty)
        XCTAssertNil(decoded.activeRun)
    }

    func testVersionTwoKeepsEarnedStampsWithoutInventingNewMissionBadges() throws {
        let data = Data(
            """
            {"schemaVersion":2,"selectedAgeBand":"ages10To12","totalScore":700,
             "destinations":{"mercury":{"isScanned":true,"isQuizCompleted":true,
             "bestRoundStars":3,"bestRoundScore":700}}}
            """.utf8
        )
        let restored = try JSONDecoder().decode(GameProgress.self, from: data)
        XCTAssertEqual(restored.schemaVersion, 3)
        XCTAssertEqual(restored.totalScore, 700)
        XCTAssertEqual(restored.destinations["mercury"]?.bestRoundStars, 3)
        XCTAssertTrue(restored.destinations["mercury"]?.isQuizCompleted == true)
        XCTAssertTrue(restored.completedMissionIDs.isEmpty)
        XCTAssertTrue(restored.videoCompletions.isEmpty)
        XCTAssertNil(restored.activeRun)
    }

    func testSchemaThreeRoundTripsMissionRewardConceptsAndPendingCheckpoint() async throws {
        let suite = "AstroProgressTests-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let completedAt = Date(timeIntervalSince1970: 100)
        var cursor = AdventureRunCursor(
            kind: .video, contentID: "mercury-video", destinationID: "mercury", revision: 1,
            ageBand: .ages7To9, phase: .videoCheckpoint, stepID: "checkpoint-1"
        )
        cursor.questionIndex = 1
        cursor.completedCheckpointIDs = ["checkpoint-0"]
        cursor.videoSeconds = 20
        cursor.assistedConceptIDs = ["mercury-shadow"]
        let expected = GameProgress(
            totalScore: 300,
            missionCompletions: [
                "mercury-observe": MissionCompletion(completedAt: completedAt, ageBand: .ages7To9)
            ],
            concepts: [
                "ages7To9:mercury-shadow": ConceptProgress(
                    conceptID: "mercury-shadow", ageBand: .ages7To9, reviewBox: 1,
                    lastPracticedAt: completedAt,
                    nextReviewAt: completedAt.addingTimeInterval(86_400)
                )
            ], activeRun: cursor
        )
        let store = try PreferencesProgressStore(suiteName: suite)
        try await store.save(expected)
        let restored = try await store.load()
        XCTAssertEqual(restored, expected)
        XCTAssertEqual(restored?.completedMissionIDs, ["mercury-observe"])
        XCTAssertEqual(restored?.activeRun?.phase, .videoCheckpoint)
    }

    func testPreferencesMigratesLegacyLogAndUsesPreferencesAfterwards() async throws {
        let suite = "AstroProgressTests-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let expected = GameProgress(totalScore: 250, bestStreak: 3)
        try JSONEncoder().encode(expected).write(to: file)
        let store = try PreferencesProgressStore(suiteName: suite, legacyFileURL: file)
        let migrated = try await store.load()
        XCTAssertEqual(migrated, expected)
        try Data("broken legacy file".utf8).write(to: file)
        let restored = try await store.load()
        XCTAssertEqual(restored, expected)
    }

    func testPreferencesCapsLeaderboardWithoutLosingRewards() async throws {
        let suite = "AstroProgressTests-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let entries = (0..<50).map { score in
            LeaderboardEntry(
                explorerName: "Explorer", destinationName: "Mars", score: 50 - score,
                correctAnswers: 1, totalQuestions: 1, bestStreak: 1,
                achievedAt: Date(timeIntervalSince1970: Double(score))
            )
        }
        let store = try PreferencesProgressStore(suiteName: suite)
        try await store.save(GameProgress(totalScore: 5000, leaderboard: entries))
        let restored = try await store.load()
        XCTAssertEqual(restored?.totalScore, 5000)
        XCTAssertEqual(restored?.leaderboard.count, 20)
        XCTAssertEqual(restored?.leaderboard.first?.score, 1)
        XCTAssertEqual(restored?.leaderboard.last?.score, 20)
        // A legacy or externally restored preferences value is bounded on read as well.
        UserDefaults(suiteName: suite)?.set(
            try JSONEncoder().encode(GameProgress(totalScore: 5000, leaderboard: entries)),
            forKey: "astro-adventure-progress-v2"
        )
        let legacyRestored = try await store.load()
        XCTAssertEqual(legacyRestored?.leaderboard.count, 20)
        XCTAssertEqual(legacyRestored?.leaderboard.first?.score, 1)

    }

    func testCorruptPreferencesReportsFailureAndPreservesBytes() async throws {
        let suite = "AstroProgressTests-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let bytes = Data("broken space log".utf8)
        UserDefaults(suiteName: suite)?.set(bytes, forKey: "astro-adventure-progress-v2")
        let store = try PreferencesProgressStore(suiteName: suite)
        do {
            _ = try await store.load()
            XCTFail("Corrupt progress should be reported")
        } catch {
            XCTAssertEqual(
                UserDefaults(suiteName: suite)?.data(forKey: "astro-adventure-progress-v2"), bytes
            )
        }
    }

    func testOversizedLogKeepsPreviouslyStoredRewards() async throws {
        let suite = "AstroProgressTests-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = try PreferencesProgressStore(suiteName: suite)
        let original = GameProgress(totalScore: 200)
        try await store.save(original)
        let oversized = GameProgress(missionID: String(repeating: "x", count: 300_000))
        do {
            try await store.save(oversized)
            XCTFail("Oversized progress should be reported")
        } catch {
            let restored = try await store.load()
            XCTAssertEqual(restored, original)
        }
    }

    @MainActor
    func testSaveQueueCoalescesToLatestSnapshot() async throws {
        let store = ControlledProgressStore()
        let queue = ProgressSaveQueue(store: store)
        queue.enqueue(GameProgress(totalScore: 100))
        await store.waitForFirstSave()
        queue.enqueue(GameProgress(totalScore: 200))
        queue.enqueue(GameProgress(totalScore: 300))
        await store.releaseFirstSave()
        await queue.flush()
        let scores = await store.scores
        XCTAssertEqual(scores, [100, 300])
        XCTAssertNil(queue.errorMessage)
    }

    @MainActor
    func testSaveFailureCanRetryLatestRewards() async {
        let store = ControlledProgressStore(failFirst: true)
        let queue = ProgressSaveQueue(store: store)
        queue.enqueue(GameProgress(totalScore: 100))
        await store.releaseFirstSave()
        await queue.flush()
        XCTAssertNotNil(queue.errorMessage)
        queue.enqueue(GameProgress(totalScore: 200))
        await queue.flush()
        let scores = await store.scores
        XCTAssertEqual(scores, [200])
        XCTAssertNil(queue.errorMessage)
    }

}

private actor ControlledProgressStore: ProgressStoring {
    private var firstSaveStarted = false
    private var firstSaveReleased = false
    private let failFirst: Bool
    var scores: [Int] = []

    init(failFirst: Bool = false) { self.failFirst = failFirst }

    func load() async throws -> GameProgress? { nil }

    func save(_ progress: GameProgress) async throws {
        if !firstSaveStarted {
            firstSaveStarted = true
            while !firstSaveReleased { await Task.yield() }
            if failFirst { throw ProgressStorageError.unavailable }
        }
        scores.append(progress.totalScore)
    }

    func waitForFirstSave() async {
        while !firstSaveStarted { await Task.yield() }
    }

    func releaseFirstSave() { firstSaveReleased = true }
}
