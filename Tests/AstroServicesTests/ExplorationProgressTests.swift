import AstroGameCore
import Foundation
import XCTest

@testable import AstroServices

final class ExplorationProgressTests: XCTestCase {
    func testSchemaThreeMigrationPreservesEveryEarnedLedgerAndPendingLegacyStep() throws {
        var old = populatedProgress()
        old.schemaVersion = 3
        old.activeRun = AdventureRunCursor(
            kind: .video, contentID: "earth-film", destinationID: "earth", revision: 1,
            ageBand: .ages10To12, phase: .videoCheckpoint, stepID: "checkpoint-1")
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        object.removeValue(forKey: "explorationCompletions")
        object.removeValue(forKey: "explorationCursor")
        let migrated = try JSONDecoder().decode(
            GameProgress.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(migrated.schemaVersion, 4)
        XCTAssertEqual(migrated.destinations, old.destinations)
        XCTAssertEqual(migrated.missionCompletions, old.missionCompletions)
        XCTAssertEqual(migrated.videoCompletions, old.videoCompletions)
        XCTAssertEqual(migrated.concepts, old.concepts)
        XCTAssertEqual(migrated.activeRun, old.activeRun)
        XCTAssertEqual(migrated.totalScore, old.totalScore)
        XCTAssertEqual(migrated.leaderboard, old.leaderboard)
        XCTAssertTrue(migrated.explorationCompletions.isEmpty)
        XCTAssertNil(migrated.explorationCursor)
    }

    func testSchemaFourPostcardsAndCarriedItemRoundTripInBothPlatformStores() async throws {
        let expected = populatedProgress()
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let suite = "AstroExplorationProgress-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let stores: [any ProgressStoring] = [
            JSONProgressStore(fileURL: file), try PreferencesProgressStore(suiteName: suite),
        ]
        for store in stores {
            try await store.save(expected)
            let restored = try await store.load()
            XCTAssertEqual(restored, expected)
            XCTAssertEqual(restored?.explorationCursor?.carriedItemID, "mercury.sensor")
            XCTAssertEqual(restored?.explorationCompletions.count, 3)
            XCTAssertEqual(restored?.explorationCursor?.clipCheckpointIDs, ["segment-0"])
        }
    }

    func testFullyPopulatedSchemaFourRemainsBelowTelevisionSaveBound() async throws {
        let expected = populatedProgress()
        let encoder = JSONEncoder()
        XCTAssertLessThan(
            try encoder.encode(expected).count, PreferencesProgressStore.maximumEncodedBytes)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        XCTAssertLessThan(
            try encoder.encode(expected).count, PreferencesProgressStore.maximumEncodedBytes)
        let suite = "AstroExplorationProgress-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = try PreferencesProgressStore(suiteName: suite)
        try await store.save(expected)
        let restored = try await store.load()
        XCTAssertEqual(restored?.explorationCompletions, expected.explorationCompletions)
        XCTAssertEqual(restored?.concepts.count, 264)
    }

    @MainActor
    func testFailedCompletionSnapshotRetriesStampAndPostcardTogether() async throws {
        let previous = GameProgress(totalScore: 500)
        let earned = populatedProgress()
        let store = RejectFirstSnapshotStore(previous: previous)
        let queue = ProgressSaveQueue(store: store)
        queue.enqueue(earned)
        await queue.flush()
        XCTAssertNotNil(queue.errorMessage)
        let afterFailure = await store.load()
        XCTAssertEqual(afterFailure, previous)
        XCTAssertTrue(afterFailure?.explorationCompletions.isEmpty == true)
        XCTAssertTrue(afterFailure?.destinations.isEmpty == true)
        queue.retry()
        await queue.flush()
        let afterRetry = await store.load()
        XCTAssertEqual(afterRetry, earned)
        XCTAssertTrue(afterRetry?.destinations["mercury"]?.isQuizCompleted == true)
        XCTAssertNotNil(afterRetry?.explorationCompletions["mercury-playground"])
        XCTAssertNil(queue.errorMessage)
        let writeCount = await store.successfulWrites
        XCTAssertEqual(writeCount, 1)
    }

    private func populatedProgress() -> GameProgress {
        let date = Date(timeIntervalSince1970: 100)
        var progress = GameProgress(totalScore: 7200, bestStreak: 7)
        for index in 0..<264 {
            let age = AgeBand.allCases[index % AgeBand.allCases.count]
            let id = "authored-concept-\(index)-bounded-science-observation"
            progress.concepts[ConceptProgress.key(conceptID: id, ageBand: age)] = ConceptProgress(
                conceptID: id, ageBand: age, reviewBox: 5, lastPracticedAt: date,
                nextReviewAt: date.addingTimeInterval(16 * 86_400))
        }
        for index in 0..<24 {
            progress.missionCompletions["legacy-mission-\(index)"] = MissionCompletion(
                completedAt: date, ageBand: .ages7To9)
        }
        for index in 0..<8 {
            progress.videoCompletions["native-video-\(index)"] = MissionCompletion(
                completedAt: date, ageBand: .ages7To9)
        }
        for planet in ["mercury", "mars", "saturn"] {
            var postcard = ExplorationCursor(
                adventureID: "\(planet)-playground", revision: 1, ageBand: .ages7To9,
                selectedTargetID: "\(planet)-last-target")
            postcard.phase = .celebrating
            postcard.completedGoalIDs = Set((0..<3).map { "\(planet)-goal-\($0)" })
            postcard.observations = Set((0..<16).map { "\(planet).observation.\($0)" })
            postcard.placements = Dictionary(
                uniqueKeysWithValues: (0..<8).map {
                    ("\(planet)-item-\($0)", "\(planet)-anchor-\($0)")
                })
            postcard.modelSettings = Dictionary(
                uniqueKeysWithValues: (0..<8).map {
                    ("\(planet)-model-\($0)", 1)
                })
            postcard.clipSeconds = 60
            postcard.clipCheckpointIDs = ["segment-0", "segment-1"]
            progress.explorationCompletions[postcard.adventureID] = ExplorationCompletion(
                completedAt: date, ageBand: .ages7To9, postcard: postcard)
            progress.destinations[planet] = DestinationProgress(
                isScanned: true, isQuizCompleted: true, bestRoundStars: 3)
        }
        progress.leaderboard = (0..<20).reversed().map { index in
            LeaderboardEntry(
                explorerName: "Explorer", destinationName: "Mercury", score: index,
                correctAnswers: 7, totalQuestions: 7, bestStreak: 7,
                achievedAt: date.addingTimeInterval(Double(index)))
        }
        var cursor = ExplorationCursor(
            adventureID: "mercury-playground", revision: 1, ageBand: .ages7To9,
            selectedTargetID: "mercury-sensor")
        cursor.phase = .playing
        cursor.carriedItemID = "mercury.sensor"
        cursor.observations = ["impact.small", "impact.large", "mercury.ejecta.traced"]
        cursor.completedGoalIDs = ["mercury-two-impacts", "mercury-trace-ejecta"]
        cursor.modelSettings = ["impact.small.count": 12, "impact.large.count": 12]
        cursor.clipSeconds = 25
        cursor.clipCheckpointIDs = ["segment-0"]
        progress.explorationCursor = cursor
        return progress
    }
}

private actor RejectFirstSnapshotStore: ProgressStoring {
    private var stored: GameProgress
    private var shouldReject = true
    var successfulWrites = 0

    init(previous: GameProgress) { stored = previous }
    func load() -> GameProgress? { stored }
    func save(_ progress: GameProgress) throws {
        if shouldReject {
            shouldReject = false
            throw ProgressStorageError.unavailable
        }
        stored = progress
        successfulWrites += 1
    }
}
