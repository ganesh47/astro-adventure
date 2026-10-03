import AstroGameCore
import Foundation
import XCTest

@testable import AstroServices

final class SchemaFiveProgressTests: XCTestCase {
    private let progressKey = "SchemaFiveProgressTests.progress"

    func testJSONLoadAndSaveRejectUnreadableLogsWithoutChangingOriginalBytes() async throws {
        for payload in try unreadablePayloads() {
            let file = try temporaryProgressFile()
            defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
            try payload.bytes.write(to: file)
            let store = JSONProgressStore(fileURL: file)
            await assertLoadRejected(store, expected: payload.reason, context: payload.name)
            XCTAssertEqual(try Data(contentsOf: file), payload.bytes, payload.name)
            await assertSaveRejected(
                store, progress: populatedProgress(), expected: payload.reason,
                context: "after failed load: \(payload.name)")
            XCTAssertEqual(try Data(contentsOf: file), payload.bytes, payload.name)
            let storeWithoutLoad = JSONProgressStore(fileURL: file)
            await assertSaveRejected(
                storeWithoutLoad, progress: populatedProgress(), expected: payload.reason,
                context: "without prior load: \(payload.name)")
            XCTAssertEqual(try Data(contentsOf: file), payload.bytes, payload.name)
        }
    }

    func testPreferencesLoadAndSavePreserveUnreadableDataExactly() async throws {
        for payload in try unreadablePayloads() {
            let (suite, defaults) = try isolatedPreferences()
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(payload.bytes, forKey: progressKey)
            let store = try PreferencesProgressStore(suiteName: suite, key: progressKey)
            await assertLoadRejected(store, expected: payload.reason, context: payload.name)
            XCTAssertEqual(defaults.data(forKey: progressKey), payload.bytes, payload.name)
            await assertSaveRejected(
                store, progress: populatedProgress(), expected: payload.reason,
                context: "after failed load: \(payload.name)")
            XCTAssertEqual(defaults.data(forKey: progressKey), payload.bytes, payload.name)
            let storeWithoutLoad = try PreferencesProgressStore(suiteName: suite, key: progressKey)
            await assertSaveRejected(
                storeWithoutLoad, progress: populatedProgress(), expected: payload.reason,
                context: "without prior load: \(payload.name)")
            XCTAssertEqual(defaults.data(forKey: progressKey), payload.bytes, payload.name)
        }
    }

    func testNonDataPreferencesCannotBeOverwrittenOrBypassedByLegacyMigration() async throws {
        let (suite, defaults) = try isolatedPreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = try temporaryProgressFile()
        defer { try? FileManager.default.removeItem(at: legacy.deletingLastPathComponent()) }
        let validLegacyBytes = try JSONEncoder().encode(populatedProgress())
        try validLegacyBytes.write(to: legacy)
        let original = "An unreadable preferences value must stay intact"
        defaults.set(original, forKey: progressKey)
        let store = try PreferencesProgressStore(
            suiteName: suite, key: progressKey, legacyFileURL: legacy)
        await assertLoadRejected(store, expected: .nonData, context: "non-Data preferences")
        XCTAssertEqual(defaults.object(forKey: progressKey) as? String, original)
        XCTAssertNil(defaults.data(forKey: progressKey))
        await assertSaveRejected(
            store, progress: populatedProgress(), expected: .nonData,
            context: "save after non-Data load")
        XCTAssertEqual(defaults.object(forKey: progressKey) as? String, original)
        let storeWithoutLoad = try PreferencesProgressStore(
            suiteName: suite, key: progressKey, legacyFileURL: legacy)
        await assertSaveRejected(
            storeWithoutLoad, progress: populatedProgress(), expected: .nonData,
            context: "save without prior non-Data load")
        XCTAssertEqual(defaults.object(forKey: progressKey) as? String, original)
        XCTAssertEqual(try Data(contentsOf: legacy), validLegacyBytes)
    }

    func testUnreadableLegacyFilesStayUntouchedWithoutCreatingPreferences() async throws {
        for payload in try unreadablePayloads() {
            let (suite, defaults) = try isolatedPreferences()
            defer { defaults.removePersistentDomain(forName: suite) }
            let legacy = try temporaryProgressFile()
            defer { try? FileManager.default.removeItem(at: legacy.deletingLastPathComponent()) }
            try payload.bytes.write(to: legacy)
            let store = try PreferencesProgressStore(
                suiteName: suite, key: progressKey, legacyFileURL: legacy)
            await assertLoadRejected(
                store, expected: payload.reason, context: "legacy \(payload.name)")
            XCTAssertEqual(try Data(contentsOf: legacy), payload.bytes)
            XCTAssertNil(defaults.object(forKey: progressKey))
            await assertSaveRejected(
                store, progress: populatedProgress(), expected: payload.reason,
                context: "legacy save after load: \(payload.name)")
            XCTAssertEqual(try Data(contentsOf: legacy), payload.bytes)
            XCTAssertNil(defaults.object(forKey: progressKey))
            let storeWithoutLoad = try PreferencesProgressStore(
                suiteName: suite, key: progressKey, legacyFileURL: legacy)
            await assertSaveRejected(
                storeWithoutLoad, progress: populatedProgress(), expected: payload.reason,
                context: "legacy save without load: \(payload.name)")
            XCTAssertEqual(try Data(contentsOf: legacy), payload.bytes)
            XCTAssertNil(defaults.object(forKey: progressKey))
        }
    }

    func testInvalidSuppliedSchemaOrBonusCannotReplaceReadableStoredRewards() async throws {
        let file = try temporaryProgressFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let (suite, defaults) = try isolatedPreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = populatedProgress()
        let originalBytes = try JSONEncoder().encode(original)
        try originalBytes.write(to: file)
        defaults.set(originalBytes, forKey: progressKey)
        let json = JSONProgressStore(fileURL: file)
        let preferences = try PreferencesProgressStore(suiteName: suite, key: progressKey)

        for version in [0, 6, 999] {
            var unsupported = original
            unsupported.schemaVersion = version
            await assertSaveRejected(
                json, progress: unsupported, expected: .version(version),
                context: "supplied JSON version \(version)")
            await assertSaveRejected(
                preferences, progress: unsupported, expected: .version(version),
                context: "supplied preferences version \(version)")
            XCTAssertEqual(try Data(contentsOf: file), originalBytes)
            XCTAssertEqual(defaults.data(forKey: progressKey), originalBytes)
        }
        var invalidBonus = original
        invalidBonus.bonusQuizRun?.questionIndex = 99
        await assertSaveRejected(
            json, progress: invalidBonus, expected: .bonus,
            context: "supplied JSON invalid cursor")
        await assertSaveRejected(
            preferences, progress: invalidBonus, expected: .bonus,
            context: "supplied preferences invalid cursor")
        XCTAssertEqual(try Data(contentsOf: file), originalBytes)
        XCTAssertEqual(defaults.data(forKey: progressKey), originalBytes)
        let jsonRestored = try await json.load()
        let preferencesRestored = try await preferences.load()
        XCTAssertEqual(jsonRestored, original)
        XCTAssertEqual(preferencesRestored, original)
    }

    func testFullyPopulatedSchemaFiveRoundTripsBothStoresBelowPreferencesLimit() async throws {
        let expected = populatedProgress()
        let bytes = try JSONEncoder().encode(expected)
        XCTAssertTrue(try XCTUnwrap(expected.bonusQuizRun).isValid)
        XCTAssertEqual(expected.schemaVersion, 5)
        XCTAssertEqual(expected.bonusQuizRun?.questions.count, 16)
        XCTAssertEqual(expected.questionEvidence.count, 64)
        XCTAssertLessThan(bytes.count, PreferencesProgressStore.maximumEncodedBytes)
        let file = try temporaryProgressFile()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let (suite, defaults) = try isolatedPreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let json = JSONProgressStore(fileURL: file)
        let preferences = try PreferencesProgressStore(suiteName: suite, key: progressKey)
        try await json.save(expected)
        try await preferences.save(expected)
        let jsonRestored = try await json.load()
        let preferencesRestored = try await preferences.load()
        XCTAssertEqual(jsonRestored, expected)
        XCTAssertEqual(preferencesRestored, expected)
        let jsonBytes = try Data(contentsOf: file)
        let preferencesBytes = try XCTUnwrap(defaults.data(forKey: progressKey))
        XCTAssertEqual(try JSONDecoder().decode(GameProgress.self, from: jsonBytes), expected)
        XCTAssertEqual(
            try JSONDecoder().decode(GameProgress.self, from: preferencesBytes), expected)
        XCTAssertLessThan(preferencesBytes.count, PreferencesProgressStore.maximumEncodedBytes)
    }

    func testSupportedLegacyVersionsMigrateWithoutChangingLegacyBytes() async throws {
        for version in 1...4 {
            let (suite, defaults) = try isolatedPreferences()
            defer { defaults.removePersistentDomain(forName: suite) }
            let file = try temporaryProgressFile()
            defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
            let bytes = Data(
                """
                {"schemaVersion":\(version),"totalScore":900,
                 "destinations":{"sun":{"isScanned":true,"isQuizCompleted":true,
                 "correctAnswers":9,"attempts":11,"masteryScore":60,"bestRoundStars":3}}}
                """.utf8)
            try bytes.write(to: file)
            let store = try PreferencesProgressStore(
                suiteName: suite, key: progressKey, legacyFileURL: file)
            let loaded = try await store.load()
            let restored = try XCTUnwrap(loaded)
            XCTAssertEqual(restored.schemaVersion, 5)
            XCTAssertEqual(restored.totalScore, 900)
            XCTAssertEqual(restored.destinations["sun"]?.attempts, 11)
            XCTAssertEqual(restored.destinations["sun"]?.bestRoundStars, 3)
            XCTAssertNil(restored.bonusQuizRun)
            XCTAssertNil(restored.questionPresentation)
            XCTAssertTrue(restored.questionEvidence.isEmpty)
            XCTAssertEqual(try Data(contentsOf: file), bytes)
            let migratedBytes = try XCTUnwrap(defaults.data(forKey: progressKey))
            XCTAssertEqual(
                try JSONDecoder().decode(GameProgress.self, from: migratedBytes), restored)
        }
        let missingVersion = try JSONDecoder().decode(
            GameProgress.self, from: Data("{\"totalScore\":900}".utf8))
        XCTAssertEqual(missingVersion.schemaVersion, 5)
        XCTAssertEqual(missingVersion.totalScore, 900)
        XCTAssertNil(missingVersion.bonusQuizRun)
    }

    @MainActor
    func testFailedOutboxWriteRetriesNewestBonusAndRewardAsOneSnapshot() async throws {
        var initial = populatedProgress()
        initial.bonusQuizRun?.phase = .quiz
        initial.bonusQuizRun?.attempts = 0
        let store = try SchemaFiveRejectFirstStore(initial: initial)
        let queue = ProgressSaveQueue(store: store)
        var firstAttempt = initial
        firstAttempt.bonusQuizRun?.phase = .quizFeedback
        firstAttempt.bonusQuizRun?.attempts = 1
        var secondAttempt = firstAttempt
        secondAttempt.bonusQuizRun?.attempts = 2
        let latest = terminalProgress(from: secondAttempt, attempts: 3)

        queue.enqueue(firstAttempt)
        await store.waitForFirstSave()
        queue.enqueue(secondAttempt)
        queue.enqueue(latest)
        await store.releaseFirstSave()
        await queue.flush()
        XCTAssertNotNil(queue.errorMessage)
        let afterFailure = try await store.load()
        XCTAssertEqual(afterFailure, initial)
        let attemptsAfterFailure = await store.attemptedSnapshots
        XCTAssertEqual(attemptsAfterFailure, [firstAttempt])
        let commitsAfterFailure = await store.committedSnapshots
        XCTAssertTrue(commitsAfterFailure.isEmpty)

        queue.retry()
        await queue.flush()
        XCTAssertNil(queue.errorMessage)
        let attemptsAfterRetry = await store.attemptedSnapshots
        XCTAssertEqual(
            attemptsAfterRetry, [firstAttempt, latest], "Intermediate cursor is coalesced")
        let committed = await store.committedSnapshots
        XCTAssertEqual(committed, [latest])
        let loaded = try await store.load()
        let stored = try XCTUnwrap(loaded)
        XCTAssertEqual(stored, latest)
        XCTAssertEqual(stored.bonusQuizRun?.attempts, 3)
        XCTAssertEqual(stored.bonusQuizRun?.hasFinishedRound, true)
        XCTAssertEqual(stored.bonusQuizRun?.correctAnswers, 16)
        XCTAssertEqual(stored.totalScore, initial.totalScore + 1600)
        XCTAssertEqual(stored.leaderboard.first?.score, 1600)
        XCTAssertEqual(stored.questionEvidence.last?.attempts, 3)
    }

    @MainActor
    func testFailedOutboxSnapshotIsRetainedForRetryWithoutAnotherEnqueue() async throws {
        let initial = populatedProgress()
        let expected = terminalProgress(from: initial, attempts: 4)
        let store = try SchemaFiveRejectFirstStore(initial: initial)
        let queue = ProgressSaveQueue(store: store)
        queue.enqueue(expected)
        await store.waitForFirstSave()
        await store.releaseFirstSave()
        await queue.flush()
        XCTAssertNotNil(queue.errorMessage)
        let unchanged = try await store.load()
        XCTAssertEqual(unchanged, initial)
        queue.retry()
        await queue.flush()
        queue.retry()
        await queue.flush()
        XCTAssertNil(queue.errorMessage)
        let attempts = await store.attemptedSnapshots
        let commits = await store.committedSnapshots
        XCTAssertEqual(attempts, [expected, expected])
        XCTAssertEqual(commits, [expected], "A successful retry must not duplicate the snapshot")
        let restored = try await store.load()
        XCTAssertEqual(restored, expected)
    }

    private func populatedProgress() -> GameProgress {
        let completedAt = Date(timeIntervalSince1970: 1000)
        let questions = (0..<16).map { index in
            QuizContent(
                prompt: "Clue \(index + 1): Which object makes its own light?",
                choices: [
                    QuizChoice(
                        id: "star", text: "A star",
                        picture: QuizPicture(scene: .star, label: "A star making light")),
                    QuizChoice(
                        id: "rock", text: "A rocky planet",
                        picture: QuizPicture(scene: .rockyWorld, label: "A rocky planet")),
                    QuizChoice(
                        id: "moon", text: "A moon",
                        picture: QuizPicture(scene: .moon, label: "A moon orbiting a world")),
                ],
                correctChoiceID: "star", correctFeedback: "Stars make their own light.",
                retryFeedback: "Planets and moons reflect light. Look for the object making light.",
                hint: "A star shines with light it makes.")
        }
        var bonus = BonusQuizRunCursor(
            destinationID: "sun", ageBand: .ages7To9, questions: questions)
        bonus.phase = .quizFeedback
        bonus.questionIndex = 15
        bonus.correctAnswers = 15
        bonus.roundScore = 1500
        bonus.attempts = 3
        bonus.isShowingHint = true
        bonus.assistedQuestionIndices = [0, 7, 15]
        bonus.feedbackWasCorrect = false
        bonus.feedbackText = questions[15].retryFeedback
        let questionID = "bonus:\(bonus.id):15"
        let presentation = QuestionPresentationSnapshot(
            challenge: QuestionChallengeSnapshot(
                mode: .challenge, questionID: questionID, remaining: 45, challengeUsed: true),
            selectedChoiceID: "rock")
        let evidence = (0..<64).map { index in
            QuestionAnswerEvidence(
                questionID: "previous-round:question-\(index)", attempts: 1 + index % 3,
                usedHelp: index.isMultiple(of: 2), usedChallenge: index.isMultiple(of: 3))
        }
        let leaderboard = (0..<20).reversed().map { index in
            LeaderboardEntry(
                explorerName: "Space Explorer", destinationName: "Sun", score: 100,
                correctAnswers: 1, totalQuestions: 1, bestStreak: 0,
                achievedAt: completedAt.addingTimeInterval(Double(index)))
        }
        var postcard = ExplorationCursor(
            adventureID: "mercury-playground", revision: 1, ageBand: .ages7To9,
            selectedTargetID: "sunlit-crater")
        postcard.phase = .celebrating
        postcard.observations = ["shadow-change", "surface-impact"]
        postcard.completedGoalIDs = ["notice-shadow", "make-crater"]
        postcard.placements = ["sensor": "sunlit-crater"]
        postcard.modelSettings = ["impact-size": 2]
        postcard.clipSeconds = 20
        postcard.clipCheckpointIDs = ["segment-0"]
        return GameProgress(
            selectedAgeBand: .ages7To9,
            destinations: [
                "sun": DestinationProgress(
                    isScanned: true, isQuizCompleted: true, correctAnswers: 20, attempts: 30,
                    masteryScore: 80, reviewBox: 3,
                    nextReviewAt: completedAt.addingTimeInterval(4 * 86_400),
                    bestRoundScore: 700, bestRoundStars: 3),
                "mercury": DestinationProgress(isScanned: true, isQuizCompleted: true),
            ],
            totalScore: 3200, leaderboard: leaderboard,
            missionCompletions: [
                "mercury-observe": MissionCompletion(completedAt: completedAt, ageBand: .ages7To9)
            ],
            videoCompletions: [
                "mercury-video": MissionCompletion(completedAt: completedAt, ageBand: .ages7To9)
            ],
            concepts: [
                "ages7To9:mercury-shadow": ConceptProgress(
                    conceptID: "mercury-shadow", ageBand: .ages7To9, reviewBox: 2,
                    lastPracticedAt: completedAt,
                    nextReviewAt: completedAt.addingTimeInterval(2 * 86_400))
            ],
            bonusQuizRun: bonus, questionPresentation: presentation, questionEvidence: evidence,
            explorationCompletions: [
                "mercury-playground": ExplorationCompletion(
                    completedAt: completedAt, ageBand: .ages7To9, postcard: postcard)
            ])
    }

    private func terminalProgress(from progress: GameProgress, attempts: Int) -> GameProgress {
        var result = progress
        result.bonusQuizRun?.phase = .quizFeedback
        result.bonusQuizRun?.attempts = attempts
        result.bonusQuizRun?.correctAnswers = 16
        result.bonusQuizRun?.roundScore = 1600
        result.bonusQuizRun?.hasFinishedRound = true
        result.bonusQuizRun?.feedbackWasCorrect = true
        result.bonusQuizRun?.feedbackText = "Stars make their own light."
        result.totalScore += 1600
        result.destinations["sun"]?.attempts = 32
        result.destinations["sun"]?.correctAnswers = 21
        result.destinations["sun"]?.bestRoundScore = 1600
        result.leaderboard.insert(
            LeaderboardEntry(
                explorerName: "Space Explorer", destinationName: "Sun", score: 1600,
                correctAnswers: 16, totalQuestions: 16, bestStreak: 0,
                achievedAt: Date(timeIntervalSince1970: 2000)), at: 0)
        result.leaderboard = Array(result.leaderboard.prefix(20))
        if let presentation = result.questionPresentation {
            result.questionPresentation = QuestionPresentationSnapshot(
                challenge: presentation.challenge, selectedChoiceID: "star")
            result.questionEvidence.append(
                QuestionAnswerEvidence(
                    questionID: presentation.challenge.questionID, attempts: attempts,
                    usedHelp: true, usedChallenge: true))
            result.questionEvidence = Array(result.questionEvidence.suffix(64))
        }
        return result
    }

    private func unreadablePayloads() throws -> [UnreadablePayload] {
        var invalidBonus = populatedProgress()
        invalidBonus.bonusQuizRun?.questionIndex = 99
        return [
            UnreadablePayload(
                name: "future schema 6",
                bytes: Data(
                    """
                    { "schemaVersion": 6, "totalScore": 777, "futureOnly": {"keep": true} }
                    """.utf8), reason: .version(6)),
            UnreadablePayload(
                name: "future schema 999",
                bytes: Data(
                    """
                    { "schemaVersion": 999, "totalScore": 888, "futureOnly": [1, 2, 3] }
                    """.utf8), reason: .version(999)),
            UnreadablePayload(
                name: "invalid JSON", bytes: Data("{ not a space log".utf8), reason: .decoding),
            UnreadablePayload(
                name: "null version", bytes: Data("{\"schemaVersion\":null}".utf8),
                reason: .decoding),
            UnreadablePayload(
                name: "string version", bytes: Data("{\"schemaVersion\":\"future\"}".utf8),
                reason: .decoding),
            UnreadablePayload(
                name: "malformed bonus fields",
                bytes: Data(
                    "{\"schemaVersion\":5,\"bonusQuizRun\":{\"id\":\"incomplete\"}}".utf8),
                reason: .decoding),
            UnreadablePayload(
                name: "invalid bonus semantics", bytes: try JSONEncoder().encode(invalidBonus),
                reason: .bonus),
        ]
    }

    private func temporaryProgressFile() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "AstroSchemaFive-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("progress.json")
    }

    private func isolatedPreferences() throws -> (String, UserDefaults) {
        let suite = "AstroSchemaFiveTests-\(UUID().uuidString)"
        return (suite, try XCTUnwrap(UserDefaults(suiteName: suite)))
    }

    private func assertLoadRejected(
        _ store: any ProgressStoring, expected: Rejection, context: String,
        file: StaticString = #filePath, line: UInt = #line
    ) async {
        do {
            _ = try await store.load()
            XCTFail("Load should reject \(context)", file: file, line: line)
        } catch {
            assertError(error, matches: expected, file: file, line: line)
        }
    }

    private func assertSaveRejected(
        _ store: any ProgressStoring, progress: GameProgress,
        expected: Rejection, context: String,
        file: StaticString = #filePath, line: UInt = #line
    ) async {
        do {
            try await store.save(progress)
            XCTFail("Save should reject \(context)", file: file, line: line)
        } catch {
            assertError(error, matches: expected, file: file, line: line)
        }
    }

    private func assertError(
        _ error: any Error, matches expected: Rejection, file: StaticString, line: UInt
    ) {
        switch expected {
        case .version(let version):
            XCTAssertEqual(
                error as? GameProgressDecodingError, .unsupportedSchemaVersion(version),
                file: file, line: line)
        case .bonus:
            XCTAssertEqual(
                error as? GameProgressDecodingError, .invalidBonusRound, file: file, line: line)
        case .decoding:
            XCTAssertTrue(error is DecodingError, file: file, line: line)
        case .nonData:
            guard let storageError = error as? ProgressStorageError else {
                XCTFail("Expected a storage payload error", file: file, line: line)
                return
            }
            if case .invalidPayload = storageError { return }
            XCTFail("Expected invalidPayload", file: file, line: line)
        }
    }

    private struct UnreadablePayload {
        let name: String
        let bytes: Data
        let reason: Rejection
    }

    private enum Rejection {
        case version(Int)
        case bonus
        case decoding
        case nonData
    }
}

/// The first write is held and rejected; subsequent writes commit a complete encoded snapshot.
private actor SchemaFiveRejectFirstStore: ProgressStoring {
    private var storedBytes: Data
    private var firstSaveStarted = false
    private var firstSaveReleased = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?
    private(set) var attemptedSnapshots: [GameProgress] = []
    private(set) var committedSnapshots: [GameProgress] = []

    init(initial: GameProgress) throws {
        storedBytes = try JSONEncoder().encode(initial)
    }

    func load() async throws -> GameProgress? {
        try JSONDecoder().decode(GameProgress.self, from: storedBytes)
    }

    func save(_ progress: GameProgress) async throws {
        attemptedSnapshots.append(progress)
        if !firstSaveStarted {
            firstSaveStarted = true
            startWaiter?.resume()
            startWaiter = nil
            if !firstSaveReleased {
                await withCheckedContinuation { releaseWaiter = $0 }
            }
            throw ProgressStorageError.unavailable
        }
        let bytes = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(GameProgress.self, from: bytes)
        storedBytes = bytes
        committedSnapshots.append(decoded)
    }

    func waitForFirstSave() async {
        if firstSaveStarted { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func releaseFirstSave() {
        firstSaveReleased = true
        releaseWaiter?.resume()
        releaseWaiter = nil
    }
}
