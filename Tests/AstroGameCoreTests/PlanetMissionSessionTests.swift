import Foundation
import XCTest

@testable import AstroGameCore

final class PlanetMissionSessionTests: XCTestCase {
    private let firstDay = Date(timeIntervalSince1970: 0)

    func testPlanetNavigationUsesMissionChooserAndInterleavesThreeClues() {
        let session = makeSession()
        session.confirm()
        session.confirm()
        XCTAssertEqual(session.phase, .missionSelection)
        XCTAssertEqual(session.availableMissions.map(\.id), ["mercury-observe"])
        session.selectPlanetMission(id: "mercury-observe")
        XCTAssertEqual(session.phase, .missionBriefing)
        session.confirm()
        XCTAssertEqual(session.phase, .missionClue)
        for index in 0..<2 {
            XCTAssertEqual(session.activeCardIndex, index)
            session.confirm()
            XCTAssertEqual(session.phase, .missionQuestion)
            XCTAssertEqual(session.activeQuestionIndex, index)
            answerCorrectly(session)
            XCTAssertEqual(session.phase, .missionStepFeedback)
            session.confirm()
            XCTAssertEqual(session.phase, .missionClue)
        }
        XCTAssertEqual(session.activeCardIndex, 2)
        session.confirm()
        XCTAssertEqual(session.phase, .missionActivity)
        session.submitActivityAnswer(at: 0)
        session.confirm()
        XCTAssertEqual(session.phase, .missionActivity)
        XCTAssertEqual(session.currentActivityTaskIndex, 1)
        session.submitActivityAnswer(at: 0)
        session.confirm()
        XCTAssertEqual(session.phase, .missionQuestion)
        answerCorrectly(session)
        XCTAssertEqual(session.progress.completedMissionIDs, ["mercury-observe"])
        XCTAssertEqual(session.progress.totalScore, 300)
        XCTAssertEqual(session.progress.destinations["mercury"]?.bestRoundStars, 3)
        XCTAssertEqual(session.phase, .missionStepFeedback, "Rewards are durable before Continue")
        session.confirm()
        XCTAssertEqual(session.phase, .planetMissionComplete)
        XCTAssertTrue(session.isPlanetExpeditionComplete)
        session.confirm()
        XCTAssertEqual(session.phase, .missionSelection)
        XCTAssertFalse(session.hasSavedAdventure)
    }

    func testHintsRetriesAndReplayCannotDuplicateTheMissionReward() {
        let session = startedSession()
        session.confirm()
        session.requestHint()
        session.submitAnswer(at: 1, now: firstDay)
        XCTAssertFalse(session.wasLastAnswerCorrect)
        session.confirm()
        answerCorrectly(session)
        session.submitAnswer(at: 0, now: firstDay)
        finishMission(session)
        let originalScore = session.progress.totalScore
        XCTAssertEqual(originalScore, 300)
        XCTAssertEqual(session.progress.missionCompletions.count, 1)
        session.confirm()
        session.selectPlanetMission(id: "mercury-observe")
        finishMission(session)
        XCTAssertEqual(session.progress.totalScore, originalScore)
        XCTAssertEqual(session.progress.missionCompletions.count, 1)
        XCTAssertEqual(session.progress.concepts.count, 3)
        XCTAssertTrue(session.progress.concepts.values.allSatisfy { $0.reviewBox == 1 })
    }

    func testActivitySelectionPreviewsWithoutSubmittingAndInvalidActionsAreSafe() {
        let session = startedSession(family: .experiment)
        for _ in 0..<2 {
            session.confirm()
            answerCorrectly(session)
            session.confirm()
        }
        session.confirm()
        XCTAssertEqual(session.phase, .missionActivity)
        let before = session.progress
        session.submitActivityAnswer(at: -1)
        session.submitActivityAnswer(at: 8)
        XCTAssertEqual(session.progress, before)
        session.selectActivityOption(at: 1)
        XCTAssertEqual(session.phase, .missionActivity)
        XCTAssertEqual(session.selectedActivityOutcome, "Observation for setting 1")
        XCTAssertEqual(session.questionAttemptCount, 0)
        session.confirm()
        XCTAssertFalse(session.wasLastAnswerCorrect)
        session.confirm()
        session.requestHint()
        XCTAssertTrue(session.isShowingHint)
        session.submitActivityAnswer(at: 0)
        session.submitActivityAnswer(at: 0)
        XCTAssertEqual(session.progress.activeRun?.completedActivityTaskIDs.count, 1)
    }

    func testModeIsLockedAcrossBriefingCardsActivitiesAndPausedResume() throws {
        let session = startedSession()
        session.ageBand = .ages4To6
        XCTAssertEqual(session.ageBand, .ages7To9)
        session.returnToWorlds()
        session.ageBand = .ages4To6
        XCTAssertEqual(session.ageBand, .ages4To6)
        XCTAssertEqual(session.activeMissionAgeBand, .ages4To6)
        let resumed = try restoredSession(session)
        XCTAssertEqual(resumed.phase, .missionPrompt)
        resumed.resumeSavedAdventure()
        XCTAssertEqual(resumed.phase, .missionClue)
        XCTAssertEqual(resumed.ageBand, .ages7To9)
        resumed.ageBand = .ages10To12
        XCTAssertEqual(resumed.ageBand, .ages7To9)
    }

    func testResumeRestoresWrongFeedbackHintAndAttempts() throws {
        let session = startedSession()
        session.confirm()
        session.requestHint()
        session.submitAnswer(at: 1, now: firstDay)
        session.returnToWorlds()
        let resumed = try restoredSession(session)
        resumed.resumeSavedAdventure()
        XCTAssertEqual(resumed.phase, .missionStepFeedback)
        XCTAssertFalse(resumed.wasLastAnswerCorrect)
        XCTAssertEqual(resumed.questionAttemptCount, 1)
        resumed.confirm()
        XCTAssertEqual(resumed.phase, .missionQuestion)
        XCTAssertTrue(resumed.isShowingHint)
        answerCorrectly(resumed)
        finishMission(resumed)
        XCTAssertEqual(resumed.progress.totalScore, 300)
    }

    func testResumeRestoresActivityTaskAndPreview() throws {
        let session = startedSession()
        for _ in 0..<2 {
            session.confirm()
            answerCorrectly(session)
            session.confirm()
        }
        session.confirm()
        session.submitActivityAnswer(at: 0)
        session.confirm()
        session.selectActivityOption(at: 1)
        session.returnToWorlds()
        let resumed = try restoredSession(session)
        resumed.resumeSavedAdventure()
        XCTAssertEqual(resumed.phase, .missionActivity)
        XCTAssertEqual(resumed.currentActivityTaskIndex, 1)
        XCTAssertEqual(resumed.selectedActivityOptionIndex, 1)
        XCTAssertEqual(resumed.progress.activeRun?.completedActivityTaskIDs, ["task-0"])
    }

    func testFinalAnswerRelaunchAndBackKeepExactlyOneReward() throws {
        let session = startedSession()
        for _ in 0..<30 {
            if session.phase == .missionQuestion && session.activeQuestionIndex == 2 { break }
            advanceCorrectly(session)
        }
        XCTAssertEqual(session.phase, .missionQuestion)
        XCTAssertEqual(session.activeQuestionIndex, 2)
        answerCorrectly(session)
        XCTAssertEqual(session.progress.totalScore, 300)
        let restored = try restoredSession(session)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .missionStepFeedback)
        restored.submitAnswer(at: 0, now: firstDay)
        restored.back()
        restored.resumeSavedAdventure()
        restored.confirm()
        restored.confirm()
        XCTAssertEqual(restored.phase, .missionSelection)
        XCTAssertEqual(restored.progress.totalScore, 300)
        XCTAssertEqual(restored.completedPlanetMissionCount, 1)
    }

    func testChangedRevisionRestartsOnlyTheCursorAndPreservesRewards() {
        let session = startedSession()
        finishMission(session)
        let restored = makeSession(progress: session.progress, revision: 2)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .missionBriefing)
        XCTAssertEqual(restored.activeCardIndex, 0)
        XCTAssertEqual(restored.progress.totalScore, 300)
        XCTAssertEqual(restored.completedPlanetMissionCount, 1)
        XCTAssertEqual(restored.progress.activeRun?.revision, 2)
        XCTAssertTrue(restored.progress.activeRun?.completedQuestionIDs.isEmpty == true)
    }

    func testMismatchedSavedMissionStepRestartsOnlyItsCursor() {
        let session = startedSession()
        var saved = session.progress
        saved.activeRun?.stepID = "card-1"
        saved.missionCompletions["old-mission"] = MissionCompletion(
            completedAt: firstDay, ageBand: .ages7To9
        )
        let restored = makeSession(progress: saved)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .missionBriefing)
        XCTAssertEqual(restored.progress.activeRun?.stepID, "mercury-observe")
        XCTAssertNotNil(restored.progress.missionCompletions["old-mission"])
    }

    func testStartingABonusDiscoveryReplacesPendingCursorAndKeepsEarnedDiscoveries() {
        let bonus = DestinationLesson(
            id: "moon", displayName: "Moon", kind: "moon", source: Self.lesson.source,
            content: Self.lesson.content
        )
        let session = MissionSession(
            lessons: [Self.lesson, bonus],
            planetMissions: [Self.mission(revision: 1, family: .classify)]
        )
        session.selectPlanetMission(id: "mercury-observe")
        finishMission(session)
        session.returnToWorlds()
        session.selectPlanetMission(id: "mercury-observe")
        session.confirm()
        session.returnToWorlds()
        XCTAssertTrue(session.hasSavedAdventure)
        session.selectDestination(at: 1)
        XCTAssertTrue(session.hasSavedAdventure, "Browsing worlds keeps the pending adventure")
        session.confirm()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertFalse(session.hasSavedAdventure)
        XCTAssertNil(session.progress.activeRun)
        XCTAssertEqual(session.completedPlanetMissionCount, 1)
        XCTAssertEqual(session.progress.totalScore, 300)
        XCTAssertTrue(session.progress.destinations["mercury"]?.isQuizCompleted == true)
        XCTAssertTrue(session.progress.destinations["moon"]?.isScanned == true)
    }

    func testMissingSavedVideoStepRestartsPausedWithoutDroppingRewards() {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        session.videoSeek(to: 3)
        var saved = session.progress
        saved.activeRun?.stepID = "retired-checkpoint"
        saved.missionCompletions["old-mission"] = MissionCompletion(
            completedAt: firstDay, ageBand: .ages7To9
        )
        let restored = makeSession(progress: saved)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .videoPlayback)
        XCTAssertEqual(restored.videoPlaybackSeconds, 0)
        XCTAssertFalse(restored.isVideoPlaying)
        XCTAssertEqual(restored.progress.activeRun?.stepID, "checkpoint-0")
        XCTAssertNotNil(restored.progress.missionCompletions["old-mission"])
    }

    func testDeepDiveDoesNotChangeTheMissionCursor() {
        let session = makeSession()
        session.selectPlanetMission(id: "mercury-observe")
        let cursor = session.progress.activeRun
        session.showDeepDive()
        XCTAssertEqual(session.phase, .deepDive)
        XCTAssertEqual(session.deepDiveCard?.id, "deep-dive")
        XCTAssertEqual(session.progress.activeRun, cursor)
        session.back()
        XCTAssertEqual(session.phase, .missionBriefing)
        XCTAssertEqual(session.progress.activeRun, cursor)
    }

    func testVideoPausesAtCheckpointAndIgnoresLateTicks() {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        XCTAssertFalse(session.isVideoPlaying)
        session.videoSeekCompleted()
        session.playVideo()
        session.playbackTimeChanged(seconds: 12)
        XCTAssertEqual(session.phase, .videoCheckpoint)
        XCTAssertEqual(session.videoPlaybackSeconds, 10)
        XCTAssertFalse(session.isVideoPlaying)
        let snapshot = session.progress
        session.playbackTimeChanged(seconds: 19)
        session.videoDidEnd()
        XCTAssertEqual(session.progress, snapshot)
        session.submitAnswer(at: 1, now: firstDay)
        session.replayVideoClue()
        XCTAssertEqual(session.phase, .videoPlayback)
        XCTAssertEqual(session.videoSeekTarget, 0)
        session.videoSeekCompleted()
        session.playbackTimeChanged(seconds: 10)
        XCTAssertEqual(session.activeVideoCheckpoint?.id, "checkpoint-0")
        XCTAssertEqual(session.questionAttemptCount, 1)
    }

    func testMissionQuestionSelectionAndBudgetSurviveWorldsAndStartMenuRelaunch() throws {
        var instant = 0.0
        let session = makeSession(monotonicTime: { instant })
        session.selectPlanetMission(id: "mercury-observe")
        session.confirm()
        session.confirm()
        XCTAssertEqual(session.phase, .missionQuestion)
        let question = try XCTUnwrap(session.currentQuiz)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction)
        session.selectQuizAnswer(at: 0, interaction: interaction)
        instant = 20
        session.returnToWorlds()
        session.back()
        XCTAssertEqual(session.phase, .missionPrompt)
        let bytes = try JSONEncoder().encode(session.progress)
        let saved = try JSONDecoder().decode(GameProgress.self, from: bytes)
        let presentation = try XCTUnwrap(saved.questionPresentation)
        XCTAssertEqual(presentation.challenge.remaining, 70)
        instant = 10_000
        let restored = makeSession(progress: saved, monotonicTime: { instant })
        restored.confirm()
        restored.back()
        XCTAssertEqual(restored.phase, .missionPrompt)
        XCTAssertEqual(restored.progress.questionPresentation, presentation)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .missionQuestion)
        XCTAssertEqual(restored.currentQuiz, question)
        XCTAssertEqual(restored.selectedQuizChoiceID, "yes")
        XCTAssertEqual(restored.questionClock.remaining, 70)
        XCTAssertEqual(restored.questionClock.mode, .challenge)
        XCTAssertTrue(restored.questionClock.pauseReasons.contains(.awaitingResume))
        XCTAssertEqual(restored.questionAttemptCount, 0)
        XCTAssertTrue(restored.progress.questionEvidence.isEmpty)
        let resumed = restored.questionInteraction
        restored.resumeQuestionChallenge(interaction: resumed)
        instant = 10_010
        restored.confirmSelectedQuizAnswer(interaction: resumed, now: firstDay)
        XCTAssertEqual(restored.phase, .missionStepFeedback)
        XCTAssertEqual(restored.questionAttemptCount, 1)
        XCTAssertEqual(restored.questionClock.remaining, 60)
        XCTAssertEqual(restored.progress.questionEvidence.count, 1)
    }

    func testVideoReplayKeepsPreselectionAndElapsedBudgetThroughRelaunchDuringReplay() throws {
        var instant = 0.0
        let session = makeSession(monotonicTime: { instant })
        session.startVideoLesson(id: "mercury-video")
        session.videoSeek(to: 10)
        let question = try XCTUnwrap(session.currentQuiz)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction)
        session.selectQuizAnswer(at: 0, interaction: interaction)
        instant = 20
        session.replayVideoClue()
        XCTAssertEqual(session.phase, .videoPlayback)
        XCTAssertEqual(session.selectedQuizChoiceID, "yes")
        XCTAssertEqual(session.questionClock.remaining, 70)
        XCTAssertNotEqual(session.questionInteraction, interaction)
        instant = 100
        session.videoSeek(to: 10)
        XCTAssertEqual(session.phase, .videoCheckpoint)
        XCTAssertEqual(session.currentQuiz, question)
        XCTAssertEqual(session.selectedQuizChoiceID, "yes")
        XCTAssertEqual(session.questionClock.remaining, 70)
        let afterReplay = session.progress
        session.confirmSelectedQuizAnswer(interaction: interaction, now: firstDay)
        XCTAssertEqual(session.progress, afterReplay)
        instant = 110
        session.replayVideoClue()
        XCTAssertEqual(session.questionClock.remaining, 60)
        let bytes = try JSONEncoder().encode(session.progress)
        let saved = try JSONDecoder().decode(GameProgress.self, from: bytes)
        let presentation = try XCTUnwrap(saved.questionPresentation)
        instant = 10_000
        let restored = makeSession(progress: saved, monotonicTime: { instant })
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .videoPlayback)
        XCTAssertFalse(restored.isVideoPlaying)
        XCTAssertEqual(restored.videoPlaybackSeconds, 0)
        XCTAssertEqual(restored.progress.questionPresentation, presentation)
        instant = 20_000
        restored.videoSeek(to: 10)
        XCTAssertEqual(restored.phase, .videoCheckpoint)
        XCTAssertEqual(restored.currentQuiz, question)
        XCTAssertEqual(restored.selectedQuizChoiceID, "yes")
        XCTAssertEqual(restored.questionClock.mode, .challenge)
        XCTAssertEqual(restored.questionClock.remaining, 60)
        XCTAssertTrue(restored.questionClock.pauseReasons.contains(.awaitingResume))
        XCTAssertEqual(restored.questionAttemptCount, 0)
        XCTAssertTrue(restored.progress.questionEvidence.isEmpty)
        let resumed = restored.questionInteraction
        restored.resumeQuestionChallenge(interaction: resumed)
        restored.confirmSelectedQuizAnswer(interaction: resumed, now: firstDay)
        XCTAssertEqual(restored.phase, .videoFeedback)
        XCTAssertEqual(restored.questionAttemptCount, 1)
        XCTAssertTrue(try XCTUnwrap(restored.progress.questionEvidence.last).usedHelp)
        XCTAssertTrue(try XCTUnwrap(restored.progress.questionEvidence.last).usedChallenge)
    }

    func testVideoReplayRejectsOldQuestionInputAndCancelledNarrationCallbacks() {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        session.videoSeek(to: 10)
        XCTAssertEqual(session.phase, .videoCheckpoint)
        let originalInteraction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: originalInteraction)
        session.setQuestionPaused(.narration, isPaused: true, interaction: originalInteraction)
        session.replayVideoClue()
        XCTAssertEqual(session.phase, .videoPlayback)
        XCTAssertNotEqual(session.questionInteraction, originalInteraction)
        XCTAssertFalse(session.questionClock.pauseReasons.contains(.narration))
        session.videoSeek(to: 10)
        XCTAssertEqual(session.phase, .videoCheckpoint)
        XCTAssertNotEqual(session.questionInteraction, originalInteraction)
        let returnedProgress = session.progress
        session.selectQuizAnswer(at: 0, interaction: originalInteraction)
        session.confirmSelectedQuizAnswer(interaction: originalInteraction, now: firstDay)
        session.setQuestionPaused(.narration, isPaused: true, interaction: originalInteraction)
        XCTAssertEqual(session.progress, returnedProgress)
        XCTAssertNil(session.selectedQuizChoiceID)
        XCTAssertEqual(session.questionAttemptCount, 0)
        XCTAssertTrue(session.questionClock.isRunning)
        let currentInteraction = session.questionInteraction
        session.selectQuizAnswer(at: 0, interaction: currentInteraction)
        session.confirmSelectedQuizAnswer(interaction: currentInteraction, now: firstDay)
        XCTAssertEqual(session.phase, .videoFeedback)
        XCTAssertEqual(session.questionAttemptCount, 1)
    }

    func testSeekCannotSkipQuestionsAndFinalSegmentCompletesVideoWithoutPlanetStamp() throws {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        session.videoSeek(to: 999)
        XCTAssertEqual(session.phase, .videoCheckpoint)
        XCTAssertEqual(session.activeVideoCheckpoint?.id, "checkpoint-0")
        answerCorrectly(session)
        session.confirm()
        XCTAssertEqual(session.phase, .videoPlayback)
        session.videoSeek(to: 999)
        XCTAssertEqual(session.activeVideoCheckpoint?.id, "checkpoint-1")
        answerCorrectly(session)
        XCTAssertTrue(session.progress.videoCompletions.isEmpty)
        XCTAssertTrue(session.progress.concepts.isEmpty)
        let restored = try restoredSession(session)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .videoFeedback)
        XCTAssertFalse(restored.isVideoPlaying)
        restored.submitAnswer(at: 0, now: firstDay)
        restored.confirm()
        XCTAssertEqual(restored.phase, .videoPlayback)
        XCTAssertFalse(restored.isVideoPlaying)
        XCTAssertEqual(restored.videoPlaybackSeconds, 20)
        restored.videoSeekCompleted()
        restored.playVideo()
        restored.playbackTimeChanged(seconds: 25)
        XCTAssertEqual(restored.phase, .videoPlayback)
        restored.videoDidEnd(now: firstDay)
        XCTAssertEqual(restored.phase, .videoComplete)
        XCTAssertEqual(restored.progress.totalScore, 200)
        XCTAssertEqual(restored.progress.videoCompletions.count, 1)
        XCTAssertEqual(restored.progress.concepts.count, 2)
        XCTAssertFalse(restored.progress.destinations["mercury"]?.isQuizCompleted == true)
    }

    func testVideoEndCannotBypassCheckpointAndResumeNeverAutoplays() throws {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        session.videoSeekCompleted()
        session.playVideo()
        session.playbackTimeChanged(seconds: 3.5)
        session.pauseVideo()
        session.playbackTimeChanged(seconds: 7)
        XCTAssertEqual(session.videoPlaybackSeconds, 3.5)
        let restored = try restoredSession(session)
        restored.resumeSavedAdventure()
        XCTAssertFalse(restored.isVideoPlaying)
        XCTAssertEqual(restored.videoSeekTarget, 3.5)
        restored.videoSeekCompleted()
        restored.playVideo()
        restored.videoDidEnd()
        XCTAssertEqual(restored.phase, .videoCheckpoint)
        XCTAssertEqual(restored.activeVideoCheckpoint?.id, "checkpoint-0")
    }

    func testFallbackUsesTheSameTwoQuestionsAndRewards() {
        let session = makeSession()
        session.startVideoLesson(id: "mercury-video")
        session.videoFailed()
        XCTAssertTrue(session.isVideoFallback)
        XCTAssertFalse(session.isVideoPlaying)
        for index in 0..<2 {
            XCTAssertEqual(session.videoFallbackCardIndex, index)
            session.continueVideoFallback()
            XCTAssertEqual(session.phase, .videoCheckpoint)
            if index == 0 {
                session.requestHint()
                session.submitAnswer(at: 1, now: firstDay)
                session.replayVideoClue()
                XCTAssertEqual(session.phase, .videoPlayback)
                XCTAssertTrue(session.isVideoFallback)
                session.continueVideoFallback()
            }
            answerCorrectly(session)
            session.confirm()
        }
        XCTAssertEqual(session.phase, .videoPlayback)
        XCTAssertEqual(session.videoFallbackCardIndex, 2)
        XCTAssertTrue(session.progress.videoCompletions.isEmpty)
        session.continueVideoFallback(now: firstDay)
        XCTAssertEqual(session.phase, .videoComplete)
        XCTAssertEqual(session.progress.totalScore, 200)
        XCTAssertFalse(session.progress.destinations["mercury"]?.isQuizCompleted == true)
    }

    func testReviewUsesTwoDueTransferQuestionsAndSchedulesOncePerEncounter() {
        let session = startedSession()
        finishMission(session)
        XCTAssertEqual(session.progress.concepts.count, 3)
        XCTAssertTrue(session.progress.concepts.values.allSatisfy { $0.reviewBox == 1 })
        session.returnToWorlds()
        XCTAssertEqual(session.dueReviewConceptCount(now: firstDay), 0)
        let tomorrow = firstDay.addingTimeInterval(24 * 60 * 60)
        session.startReview(now: tomorrow)
        XCTAssertEqual(session.phase, .reviewQuestion)
        XCTAssertEqual(session.activeReviewQuestions.count, 2)
        XCTAssertTrue(session.currentQuiz?.prompt.hasPrefix("Connect") == true)
        for _ in 0..<2 {
            let quiz = session.currentQuiz!
            let index = quiz.choices.firstIndex { $0.id == quiz.correctChoiceID }!
            session.submitAnswer(at: index, now: tomorrow)
            session.confirm()
        }
        XCTAssertEqual(session.phase, .reviewComplete)
        XCTAssertEqual(session.progress.totalScore, 300, "Review is not another mission reward")
        XCTAssertEqual(session.progress.concepts.values.filter { $0.reviewBox == 2 }.count, 2)
        XCTAssertEqual(session.progress.concepts.values.filter { $0.reviewBox == 1 }.count, 1)
    }

    func testReviewCursorRestoresAndModeEvidenceIsSeparate() throws {
        let session = startedSession()
        finishMission(session)
        session.returnToWorlds()
        session.ageBand = .ages4To6
        XCTAssertEqual(session.dueReviewConceptCount(now: firstDay.addingTimeInterval(100_000)), 0)
        session.ageBand = .ages7To9
        session.startReview(now: firstDay.addingTimeInterval(86_400))
        session.submitAnswer(at: 1, now: firstDay.addingTimeInterval(86_400))
        let restored = try restoredSession(session)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .reviewFeedback)
        XCTAssertEqual(
            restored.activeReviewQuestions.map(\.id), session.activeReviewQuestions.map(\.id))
        XCTAssertEqual(restored.currentQuiz?.prompt, session.currentQuiz?.prompt)
        restored.confirm()
        XCTAssertEqual(restored.phase, .reviewQuestion)
    }

    func testEarlyMissionReplayCannotAdvanceOrExtendAFutureReview() {
        let nextReview = firstDay.addingTimeInterval(16 * 86_400)
        let key = ConceptProgress.key(conceptID: "concept-0", ageBand: .ages7To9)
        let retention = ConceptProgress(
            conceptID: "concept-0", ageBand: .ages7To9, reviewBox: 5,
            lastPracticedAt: firstDay, nextReviewAt: nextReview
        )
        let session = makeSession(progress: GameProgress(concepts: [key: retention]))
        session.selectPlanetMission(id: "mercury-observe")
        finishMission(session, now: firstDay.addingTimeInterval(2 * 86_400))
        XCTAssertEqual(session.progress.concepts[key], retention)
        session.returnToWorlds()
        session.selectPlanetMission(id: "mercury-observe")
        finishMission(session, now: nextReview)
        XCTAssertEqual(session.progress.concepts[key]?.reviewBox, 5)
        XCTAssertEqual(session.progress.concepts[key]?.lastPracticedAt, nextReview)
        XCTAssertEqual(
            session.progress.concepts[key]?.nextReviewAt, nextReview.addingTimeInterval(16 * 86_400)
        )
        XCTAssertEqual(session.progress.totalScore, 300)
    }

    func testActivityHelpInfluencesTerminalConceptEncounterWithoutChangingReward() {
        let tomorrow = firstDay.addingTimeInterval(86_400)
        let key = ConceptProgress.key(conceptID: "concept-2", ageBand: .ages7To9)
        let session = makeSession(
            progress: GameProgress(concepts: [
                key: ConceptProgress(
                    conceptID: "concept-2", ageBand: .ages7To9, reviewBox: 3,
                    lastPracticedAt: firstDay, nextReviewAt: tomorrow
                )
            ]))
        session.selectPlanetMission(id: "mercury-observe")
        for _ in 0..<20 {
            if session.phase == .missionActivity { break }
            advanceCorrectly(session, now: tomorrow)
        }
        XCTAssertEqual(session.phase, .missionActivity)
        XCTAssertEqual(session.progress.concepts[key]?.reviewBox, 3)
        session.requestHint()
        finishMission(session, now: tomorrow)
        XCTAssertEqual(session.progress.concepts[key]?.reviewBox, 1)
        XCTAssertEqual(
            session.progress.concepts[key]?.nextReviewAt, tomorrow.addingTimeInterval(86_400))
        XCTAssertEqual(session.progress.totalScore, 300)
    }

    private func makeSession(
        progress: GameProgress? = nil, revision: Int = 1,
        family: ScienceActivityFamily = .classify,
        monotonicTime: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime }
    ) -> MissionSession {
        MissionSession(
            lessons: [Self.lesson], progress: progress,
            planetMissions: [Self.mission(revision: revision, family: family)],
            videoLessons: [Self.video], monotonicTime: monotonicTime
        )
    }

    private func startedSession(family: ScienceActivityFamily = .classify) -> MissionSession {
        let session = makeSession(family: family)
        session.selectPlanetMission(id: "mercury-observe")
        session.confirm()
        return session
    }

    private func restoredSession(_ session: MissionSession) throws -> MissionSession {
        let bytes = try JSONEncoder().encode(session.progress)
        return makeSession(progress: try JSONDecoder().decode(GameProgress.self, from: bytes))
    }

    private func answerCorrectly(_ session: MissionSession, now: Date? = nil) {
        let quiz = session.currentQuiz!
        session.submitAnswer(
            at: quiz.choices.firstIndex { $0.id == quiz.correctChoiceID }!, now: now ?? firstDay
        )
    }

    private func advanceCorrectly(_ session: MissionSession, now: Date? = nil) {
        switch session.phase {
        case .missionQuestion: answerCorrectly(session, now: now)
        case .missionActivity: session.submitActivityAnswer(at: 0)
        default: session.confirm(now: now ?? firstDay)
        }
    }

    private func finishMission(_ session: MissionSession, now: Date? = nil) {
        for _ in 0..<30 {
            if session.phase == .planetMissionComplete { return }
            advanceCorrectly(session, now: now)
        }
        XCTFail("Mission did not reach completion")
    }

    private static let source = LearningSource(
        title: "NASA Mercury", url: URL(string: "https://science.nasa.gov/mercury/")!,
        reviewStatus: "reviewed"
    )

    private static func text(_ value: String) -> AgeBandText {
        AgeBandText(ages4To6: value, ages7To9: value, ages10To12: value)
    }

    private static func quiz(_ prompt: String) -> QuizContent {
        QuizContent(
            prompt: prompt,
            choices: [.init(id: "yes", text: "Evidence"), .init(id: "no", text: "Other")],
            correctChoiceID: "yes", correctFeedback: "That evidence fits the clue.",
            retryFeedback: "Look for the evidence in the clue.", hint: "Choose the evidence."
        )
    }

    private static func question(_ index: Int) -> LearningQuestion {
        let normal = quiz("Clue \(index)")
        let review = quiz("Connect clue \(index) to another world")
        return LearningQuestion(
            id: "question-\(index)", conceptID: "concept-\(index)", source: source,
            content: .init(ages4To6: normal, ages7To9: normal, ages10To12: normal),
            reviewContent: .init(ages4To6: review, ages7To9: review, ages10To12: review)
        )
    }

    private static func card(_ index: Int) -> MissionCard {
        MissionCard(
            id: "card-\(index)", conceptID: "concept-\(index)", title: "A clue",
            body: text("Observe the clue."), imageName: "mercury-color", imageCredit: "NASA",
            imageSourceID: "PIA12842", source: source
        )
    }

    private static func mission(revision: Int, family: ScienceActivityFamily) -> PlanetMission {
        PlanetMission(
            id: "mercury-observe", destinationID: "mercury", revision: revision,
            title: "Mercury investigator", invitation: text("Explore three clues."),
            requiredConceptIDs: (0..<3).map { "concept-\($0)" },
            cards: (0..<3).map(card), questions: (0..<3).map(question),
            activity: ScienceActivity(
                id: "activity", family: family, title: "Explore a model", conceptID: "concept-2",
                tasks: (0..<2).map { index in
                    ActivityTask(
                        id: "task-\(index)", prompt: text("Choose the evidence."),
                        imageName: "mercury-color",
                        options: (0..<2).map { option in
                            ActivityOption(
                                id: "option-\(option)", label: text("Setting \(option)"),
                                symbol: "sun.max.fill",
                                outcome: text("Observation for setting \(option)")
                            )
                        }, correctOptionID: "option-0", hint: text("Notice the evidence."),
                        explanation: text("The observation matches the clue.")
                    )
                }
            ),
            deepDive: MissionCard(
                id: "deep-dive", conceptID: "extra", title: "More Mercury",
                body: text("An optional discovery."), imageName: "mercury-color",
                imageCredit: "NASA", imageSourceID: "PIA12842", source: source
            )
        )
    }

    private static let video = VideoLesson(
        id: "mercury-video", destinationID: "mercury", revision: 1, title: "Mercury story",
        resourceName: "mercury-video", duration: 30, credit: "NASA", source: source,
        segments: (0..<3).map { index in
            VideoSegment(
                id: "segment-\(index)", startTime: Double(index * 10),
                endTime: Double((index + 1) * 10),
                narration: text("Observe this clue."), imageName: "mercury-color"
            )
        },
        checkpoints: (0..<2).map { index in
            VideoCheckpoint(
                id: "checkpoint-\(index)", time: Double((index + 1) * 10),
                replayStartTime: Double(index * 10), question: question(index)
            )
        }, fallbackCards: (0..<3).map(card)
    )

    private static let lesson: DestinationLesson = {
        let content = AgeBandLessonContent(discoveryText: "A clue", quiz: quiz("Legacy clue"))
        return DestinationLesson(
            id: "mercury", displayName: "Mercury", kind: "planet", source: source,
            content: .init(ages4To6: content, ages7To9: content, ages10To12: content)
        )
    }()
}
