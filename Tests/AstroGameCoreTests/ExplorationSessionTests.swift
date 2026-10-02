import Foundation
import XCTest

@testable import AstroGameCore

@MainActor
final class ExplorationSessionTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 100)

    func testGoalsRequireEnvironmentalActionsAndCommitExactlyOnePostcard() {
        let session = makeSession()
        XCTAssertEqual(session.cursor.phase, .arriving)
        session.send(.activateTarget)
        XCTAssertTrue(session.cursor.observations.isEmpty)
        session.send(.begin)
        XCTAssertFalse(session.availableTargets.contains { $0.id == "shelter" })
        session.send(.selectTarget("shelter"))
        XCTAssertEqual(session.selectedTarget?.id, "small")
        session.send(.activateTarget, now: day)
        XCTAssertTrue(session.cursor.completedGoalIDs.isEmpty)
        activate("large", in: session)
        XCTAssertEqual(session.cursor.completedGoalIDs, ["compare"])
        XCTAssertEqual(session.currentGoal?.id, "shelter-goal")
        activate("shelter", in: session)
        XCTAssertFalse(session.cursor.observations.contains("protected"), "Placing needs the kit")
        activate("kit", in: session)
        activate("shelter", in: session)
        XCTAssertEqual(session.cursor.completedGoalIDs.count, 2)
        activate("model", in: session)
        XCTAssertEqual(session.cursor.phase, .celebrating)
        let completion = session.progress.explorationCompletions["mercury-playground"]
        XCTAssertEqual(completion?.ageBand, .ages7To9)
        XCTAssertEqual(completion?.postcard, session.cursor)
        XCTAssertEqual(session.progress.explorationCursor, session.cursor)
        XCTAssertTrue(session.progress.destinations["mercury"]?.isQuizCompleted == true)
        XCTAssertEqual(session.progress.totalScore, 700, "Legacy totals are preserved")
        let earned = session.progress
        session.send(.activateTarget)
        XCTAssertEqual(session.progress, earned)
        session.send(.keepPlaying)
        session.send(.activateTarget, now: day.addingTimeInterval(86_400))
        XCTAssertEqual(session.progress.explorationCompletions.count, 1)
        XCTAssertEqual(session.progress.explorationCompletions["mercury-playground"], completion)
    }

    func testKitCanMoveWithoutErasingAnEarlierObservation() {
        let session = makeSession()
        session.send(.begin)
        activate("small", in: session)
        activate("large", in: session)
        activate("kit", in: session)
        activate("sunlit", in: session)
        XCTAssertEqual(session.cursor.placements["sensor"], "sunlit")
        activate("kit", in: session)
        XCTAssertNil(session.cursor.placements["sensor"])
        XCTAssertTrue(session.cursor.observations.contains("sunlit"))
        activate("other-kit", in: session)
        XCTAssertEqual(
            session.cursor.carriedItemID, "sensor", "An occupied hand cannot take another kit")
        activate("shelter", in: session)
        XCTAssertNil(session.cursor.carriedItemID)
        XCTAssertEqual(session.cursor.placements["sensor"], "shelter")
        XCTAssertTrue(session.cursor.observations.isSuperset(of: ["sunlit", "protected"]))
    }

    func testHelpAndEveryOverlaySuspendActionsWithoutReducingRewards() {
        let session = makeSession()
        session.send(.begin)
        for command: ExplorationCommand in [.requestHelp, .openJournal, .openClip, .pause] {
            session.send(command)
            XCTAssertTrue(session.isPaused)
            let cursor = session.cursor
            session.send(.activateTarget)
            session.send(.selectTarget("large"))
            session.send(.moveTarget(.right))
            session.send(.adjustModel("light", by: 1))
            session.send(.resetToy)
            session.send(.cancelManipulation)
            XCTAssertEqual(session.cursor, cursor)
            session.send(.closeOverlay)
            XCTAssertFalse(session.isPaused)
        }
        finish(session)
        XCTAssertEqual(session.progress.explorationCompletions.count, 1)
        XCTAssertTrue(session.progress.destinations["mercury"]?.isQuizCompleted == true)
    }

    func testDirectionsChooseNearestTargetDeterministicallyWithoutDiscovery() {
        let session = makeSession()
        session.send(.begin)
        let initial = session.cursor.observations
        session.send(.moveTarget(.right))
        XCTAssertEqual(session.selectedTarget?.id, "large")
        session.send(.moveTarget(.down))
        XCTAssertEqual(session.selectedTarget?.id, "kit")
        session.send(.moveTarget(.up))
        XCTAssertEqual(session.selectedTarget?.id, "small", "Equidistant choices break ties by ID")
        XCTAssertEqual(session.cursor.observations, initial)
        XCTAssertTrue(session.cursor.completedGoalIDs.isEmpty)
    }

    func testAdjustmentsRecordOnlyReachedSettingAndGuardUnknownOrLockedModels() {
        let session = makeSession()
        session.send(.begin)
        session.send(.adjustModel("light", by: 1))
        XCTAssertNil(
            session.cursor.modelSettings["light"], "Model is locked until the kit is sheltered")
        activate("small", in: session)
        activate("large", in: session)
        activate("kit", in: session)
        activate("shelter", in: session)
        session.send(.adjustModel("light", by: -1))
        XCTAssertEqual(session.cursor.modelSettings["light"], 1)
        XCTAssertTrue(session.cursor.observations.contains("edge"))
        XCTAssertFalse(session.cursor.observations.contains("face"))
        session.send(.keepPlaying)
        session.send(.adjustModel("light", by: Int.max))
        XCTAssertEqual(session.cursor.modelSettings["light"], 0)
        let cursor = session.cursor
        session.send(.adjustModel("unknown", by: 1))
        session.send(.adjustModel("light", by: 0))
        XCTAssertEqual(session.cursor, cursor)
    }

    func testResetPreservesDiscoveriesAndCompletionButClearsToyArrangement() {
        let session = makeSession()
        session.send(.begin)
        finish(session)
        session.send(.keepPlaying)
        let observations = session.cursor.observations
        let goals = session.cursor.completedGoalIDs
        let completion = session.progress.explorationCompletions
        session.send(.resetToy)
        XCTAssertEqual(session.cursor.observations, observations)
        XCTAssertEqual(session.cursor.completedGoalIDs, goals)
        XCTAssertTrue(session.cursor.modelSettings.isEmpty)
        XCTAssertTrue(session.cursor.placements.isEmpty)
        XCTAssertEqual(session.progress.explorationCompletions, completion)
        XCTAssertEqual(session.cursor.phase, .playing)
        activate("small", in: session)
        XCTAssertEqual(session.cursor.phase, .playing, "Free play does not repeatedly celebrate")
    }

    func testImpactCountsRemainBoundedDuringLongFreePlay() {
        let session = makeSession()
        session.send(.begin)
        for _ in 0..<1000 { session.send(.activateTarget) }
        XCTAssertEqual(session.cursor.modelSettings["impact.small.count"], 12)
        XCTAssertEqual(session.cursor.observations, ["impact.small"])
        XCTAssertTrue(session.progress.explorationCompletions.isEmpty)
    }

    func testSavedCarriedKitRestoresCapturedModeAndRequiresExplicitResume() throws {
        let session = makeSession()
        session.send(.begin)
        activate("small", in: session)
        activate("large", in: session)
        activate("kit", in: session)
        var saved = try JSONDecoder().decode(
            GameProgress.self, from: JSONEncoder().encode(session.progress))
        saved.selectedAgeBand = .ages4To6
        let restored = ExplorationSession(adventure: adventure(), progress: saved)
        XCTAssertEqual(restored.ageBand, .ages7To9)
        XCTAssertEqual(restored.cursor.carriedItemID, "sensor")
        XCTAssertEqual(restored.overlay, .pause)
        XCTAssertEqual(restored.feedback, "You are carrying the kit. Choose where to place it.")
        let before = restored.progress
        restored.send(.activateTarget)
        XCTAssertEqual(restored.progress, before)
        restored.send(.resume)
        activate("shelter", in: restored)
        XCTAssertEqual(restored.cursor.placements["sensor"], "shelter")
        activate("model", in: restored)
        XCTAssertEqual(restored.cursor.phase, .celebrating)
        XCTAssertEqual(restored.progress.explorationCompletions.count, 1)
    }

    func testRestoredFeedbackUsesTheCurrentGoalAndCapturedModeWithoutChangingTheSave() {
        let session = makeSession()
        session.send(.begin)
        activate("small", in: session)
        activate("large", in: session)
        var saved = session.progress
        saved.selectedAgeBand = .ages4To6
        let restored = ExplorationSession(adventure: adventure(), progress: saved)
        XCTAssertEqual(restored.currentGoal?.id, "shelter-goal")
        XCTAssertEqual(
            restored.feedback,
            restored.currentGoal?.invitation.text(for: .ages7To9))
        XCTAssertNotEqual(restored.feedback, restored.adventure.welcome.text(for: .ages7To9))
        XCTAssertEqual(restored.progress, saved, "Restored guidance does not reset the cursor")
        XCTAssertTrue(restored.isPaused)
        restored.send(.resume)
        XCTAssertEqual(restored.progress, saved)
    }

    func testRestoredFreePlayFeedbackKeepsTheEarnedPostcardAndCompletion() {
        let session = makeSession()
        session.send(.begin)
        finish(session)
        session.send(.keepPlaying)
        let saved = session.progress
        let restored = ExplorationSession(adventure: adventure(), progress: saved)
        XCTAssertEqual(
            restored.feedback, "Your discovery is saved. Keep playing and see what changes!")
        XCTAssertEqual(restored.progress, saved)
        XCTAssertNil(restored.currentGoal)
        XCTAssertTrue(restored.isPaused)
    }

    func testTerminalRestoreKeepsEarnedPostcardAndFreePlayCanResume() throws {
        let session = makeSession()
        session.send(.begin)
        finish(session)
        let restored = ExplorationSession(adventure: adventure(), progress: session.progress)
        XCTAssertEqual(restored.cursor.phase, .celebrating)
        XCTAssertTrue(restored.isPaused)
        restored.send(.resume)
        restored.send(.keepPlaying)
        activate("model", in: restored)
        XCTAssertEqual(
            restored.progress.explorationCompletions, session.progress.explorationCompletions)
    }

    func testRetiredRevisionAndMalformedCursorRestartWithoutRemovingEarnedProgress() {
        let session = makeSession()
        session.send(.begin)
        finish(session)
        let original = session.progress
        var mutations: [ExplorationCursor] = []
        func altered(_ mutate: (inout ExplorationCursor) -> Void) {
            var cursor = session.cursor
            mutate(&cursor)
            mutations.append(cursor)
        }
        altered { $0.revision = 99 }
        altered { $0.adventureID = "removed" }
        altered { $0.selectedTargetID = "unknown" }
        altered { $0.avatarAnchorID = "unknown" }
        altered { $0.observations.insert("unknown") }
        altered { $0.completedGoalIDs.insert("unknown") }
        altered { $0.modelSettings["light"] = 2 }
        altered { $0.modelSettings["impact.small.count"] = 13 }
        altered { $0.carriedItemID = "unknown" }
        altered { $0.placements["sensor"] = "small" }
        altered { $0.clipSeconds = .infinity }
        altered { $0.clipCheckpointIDs = ["untrusted"] }
        altered { $0.completedGoalIDs.remove("compare") }
        for invalid in mutations {
            var saved = original
            saved.explorationCursor = invalid
            let restored = ExplorationSession(adventure: adventure(), progress: saved)
            XCTAssertEqual(restored.cursor.phase, .arriving)
            XCTAssertTrue(restored.cursor.observations.isEmpty)
            XCTAssertEqual(
                restored.progress.explorationCompletions, original.explorationCompletions)
            XCTAssertEqual(restored.progress.destinations, original.destinations)
            XCTAssertEqual(restored.progress.totalScore, original.totalScore)
        }
    }

    func testLegacyRunForEnteredPlanetRestartsArrivalButOtherDestinationRunSurvives() {
        var saved = GameProgress(totalScore: 1000)
        saved.activeRun = AdventureRunCursor(
            kind: .planetMission, contentID: "legacy-mercury", destinationID: "mercury",
            revision: 1, ageBand: .ages10To12, phase: .missionStepFeedback)
        saved.destinations["mercury"] = DestinationProgress(isScanned: true, isQuizCompleted: true)
        let migrated = ExplorationSession(adventure: adventure(), progress: saved)
        XCTAssertNil(migrated.progress.activeRun)
        XCTAssertEqual(migrated.cursor.phase, .arriving)
        XCTAssertTrue(migrated.progress.explorationCompletions.isEmpty)
        XCTAssertTrue(migrated.progress.destinations["mercury"]?.isQuizCompleted == true)
        saved.activeRun?.destinationID = "earth"
        let independent = ExplorationSession(adventure: adventure(), progress: saved)
        XCTAssertEqual(independent.progress.activeRun, saved.activeRun)
    }

    func testClipTimingRejectsStaleCallbacksAndUntrustedCheckpoints() {
        let session = makeSession()
        session.send(.begin)
        session.updateClipSeconds(20)
        XCTAssertEqual(session.cursor.clipSeconds, 0)
        session.send(.openClip)
        session.updateClipProgress(seconds: 20, checkpointIDs: ["segment-0"])
        session.updateClipProgress(seconds: 40, checkpointIDs: ["unknown"])
        XCTAssertEqual(session.cursor.clipSeconds, 20)
        session.updateClipSeconds(.nan)
        XCTAssertEqual(session.cursor.clipSeconds, 20)
        session.updateClipProgress(seconds: 200, checkpointIDs: ["segment-1"])
        XCTAssertEqual(session.cursor.clipSeconds, 60)
        session.updateClipProgress(seconds: -1, checkpointIDs: [])
        XCTAssertEqual(session.cursor.clipSeconds, 0)
        XCTAssertEqual(session.cursor.clipCheckpointIDs, ["segment-0", "segment-1"])
        session.send(.closeOverlay)
        session.updateClipSeconds(50)
        XCTAssertEqual(session.cursor.clipSeconds, 0)
        XCTAssertTrue(session.progress.explorationCompletions.isEmpty)
        XCTAssertNil(session.progress.destinations["mercury"])
    }

    func testExplorationSnapshotFlowsThroughExistingMissionPersistenceOwner() {
        let session = makeSession()
        session.send(.begin)
        finish(session)
        let legacy = MissionSession(lessons: [], progress: GameProgress())
        legacy.applyExplorationProgress(session.progress)
        XCTAssertEqual(legacy.progress, session.progress)
        XCTAssertEqual(legacy.phase, .missionPrompt)
    }

    private func activate(_ id: String, in session: ExplorationSession) {
        session.send(.selectTarget(id))
        session.send(.activateTarget, now: day)
    }

    private func finish(_ session: ExplorationSession) {
        activate("small", in: session)
        activate("large", in: session)
        activate("kit", in: session)
        activate("shelter", in: session)
        activate("model", in: session)
    }

    private func makeSession() -> ExplorationSession {
        ExplorationSession(adventure: adventure(), progress: GameProgress(totalScore: 700))
    }

    private func adventure() -> ExplorationAdventure {
        let response = ExplorationText("Look what changed!")
        func target(
            _ id: String, _ x: Double, _ y: Double, _ interaction: ExplorationInteraction,
            requires observations: Set<String> = []
        ) -> ExplorationTarget {
            ExplorationTarget(
                id: id, name: id, symbol: "sparkles", verb: "Try",
                position: ExplorationPoint(x, y), interaction: interaction,
                requiredObservations: observations, response: response)
        }
        func goal(_ id: String, _ observations: Set<String>, _ targetID: String) -> ExplorationGoal
        {
            ExplorationGoal(
                id: id, title: id, invitation: ExplorationText("Try the world"),
                hint: ExplorationText("Look for the glowing target"),
                requiredObservations: observations, suggestedTargetID: targetID,
                conceptID: id, explanation: ExplorationText("You discovered a pattern!"),
                sourceURL: "https://science.nasa.gov/mercury/")
        }
        return ExplorationAdventure(
            id: "mercury-playground", destinationID: "mercury", title: "Mercury",
            welcome: ExplorationText("Welcome"),
            goals: [
                goal("compare", ["impact.small", "impact.large"], "small"),
                goal("shelter-goal", ["protected"], "shelter"),
                goal("view", ["edge"], "model"),
            ],
            targets: [
                target("small", 0.2, 0.2, .impact(size: 0)),
                target("large", 0.4, 0.2, .impact(size: 1)),
                target("kit", 0.3, 0.4, .pickUp("sensor")),
                target("other-kit", 0.8, 0.8, .pickUp("other")),
                target("sunlit", 0.2, 0.8, .place(item: "sensor", observation: "sunlit")),
                target(
                    "shelter", 0.6, 0.4, .place(item: "sensor", observation: "protected"),
                    requires: ["impact.small", "impact.large"]),
                target(
                    "model", 0.8, 0.4, .adjust(model: "light", observations: ["face", "edge"]),
                    requires: ["protected"]),
            ], postcardTitle: "Mercury memories", videoLessonID: "mercury-video")
    }
}
