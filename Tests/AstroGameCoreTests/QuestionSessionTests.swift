import AstroGameCore
import Foundation
import XCTest

final class QuestionSessionTests: XCTestCase {
    private let answerDate = Date(timeIntervalSince1970: 1000)

    func testOldSchemasKeepEarnedEvidenceWithoutInventingABonusRun() throws {
        for version in 1...4 {
            let bytes = Data(
                """
                {
                  "schemaVersion": \(version),
                  "totalScore": 700,
                  "destinations": {
                    "sun": {
                      "isScanned": true, "isQuizCompleted": true,
                      "correctAnswers": 7, "attempts": 9,
                      "masteryScore": 65, "reviewBox": 3, "bestRoundStars": 3
                    }
                  }
                }
                """.utf8)
            let decoded = try JSONDecoder().decode(GameProgress.self, from: bytes)
            XCTAssertEqual(decoded.schemaVersion, GameProgress.currentSchemaVersion)
            XCTAssertNil(decoded.bonusQuizRun)
            XCTAssertNil(decoded.questionPresentation)
            XCTAssertTrue(decoded.questionEvidence.isEmpty)
            XCTAssertEqual(decoded.totalScore, 700)
            XCTAssertEqual(decoded.destinations["sun"]?.correctAnswers, 7)
            XCTAssertEqual(decoded.destinations["sun"]?.attempts, 9)
            XCTAssertEqual(decoded.destinations["sun"]?.masteryScore, 65)
            XCTAssertEqual(decoded.destinations["sun"]?.reviewBox, 3)
            XCTAssertEqual(decoded.destinations["sun"]?.bestRoundStars, 3)
            let session = makeSession(progress: decoded)
            XCTAssertFalse(session.hasSavedAdventure)
            XCTAssertEqual(session.phase, .missionPrompt)
        }
    }

    func testStoryVisitKeepsCurrentQuestionAttemptsHintAndRoundPoints() throws {
        let session = startedSession()
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        let question = try XCTUnwrap(session.currentQuiz)
        let roundID = try XCTUnwrap(session.progress.bonusQuizRun?.id)
        session.requestHint()
        session.submitAnswer(at: 1, now: answerDate)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        session.back()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertEqual(session.progress.bonusQuizRun?.phase, .quiz)
        XCTAssertEqual(session.progress.bonusQuizRun?.assistedQuestionIndices, [1])
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.currentQuiz, question)
        XCTAssertEqual(session.quizQuestionIndex, 1)
        XCTAssertEqual(session.questionAttemptCount, 1)
        XCTAssertTrue(session.isShowingHint)
        XCTAssertEqual(session.roundScore, 100)
        XCTAssertEqual(session.roundCorrectAnswers, 1)
        XCTAssertEqual(session.progress.bonusQuizRun?.id, roundID)
        session.submitAnswer(at: 0, now: answerDate)
        XCTAssertEqual(session.progress.totalScore, 200)
        XCTAssertEqual(session.roundStars, 3)
        XCTAssertEqual(session.progress.destinations["sun"]?.attempts, 3)
        XCTAssertEqual(session.progress.bonusQuizRun?.assistedQuestionIndices, [1])
    }

    func testWorldsAndRelaunchRestoreWrongFeedbackBeforeRetryingSameQuestion() throws {
        let session = startedSession()
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        session.requestHint()
        session.submitAnswer(at: 1, now: answerDate)
        let question = try XCTUnwrap(session.currentQuiz)
        let retryExplanation = session.lastFeedback
        session.returnToWorlds()
        XCTAssertEqual(session.phase, .navigation)
        let restored = makeSession(
            progress: try roundTrip(session.progress), count: 1, marker: "replacement")
        XCTAssertEqual(restored.phase, .missionPrompt)
        XCTAssertTrue(restored.hasSavedAdventure)
        XCTAssertEqual(restored.savedAdventureTitle, "Sun picture questions")
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.phase, .quizFeedback)
        XCTAssertFalse(restored.wasLastAnswerCorrect)
        XCTAssertEqual(restored.lastFeedback, retryExplanation)
        XCTAssertEqual(restored.questionAttemptCount, 1)
        XCTAssertTrue(restored.isShowingHint)
        XCTAssertEqual(restored.currentQuiz, question)
        XCTAssertEqual(restored.quizQuestions.count, 2)
        XCTAssertEqual(restored.roundScore, 100)
        restored.confirm()
        XCTAssertEqual(restored.phase, .quiz)
        XCTAssertEqual(restored.quizQuestionIndex, 1)
        restored.submitAnswer(at: 0, now: answerDate)
        XCTAssertEqual(restored.progress.totalScore, 200)
        XCTAssertEqual(restored.progress.leaderboard.count, 1)
        XCTAssertEqual(restored.progress.bonusQuizRun?.assistedQuestionIndices, [1])
    }

    func testIncorrectFeedbackStoryReturnsToQuestionWithAttemptAndSelectionIntact() throws {
        let session = startedSession()
        let question = session.currentQuiz
        let interaction = session.questionInteraction
        session.selectQuizAnswer(at: 1, interaction: interaction)
        session.confirmSelectedQuizAnswer(interaction: interaction, now: answerDate)
        XCTAssertEqual(session.phase, .quizFeedback)
        let feedbackInteraction = session.questionInteraction
        session.revisitBonusStory()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertEqual(session.progress.bonusQuizRun?.phase, .quiz)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.currentQuiz, question)
        XCTAssertEqual(session.selectedQuizChoiceID, "rock")
        XCTAssertEqual(session.questionAttemptCount, 1)
        XCTAssertTrue(session.lastAnswerUsedHelp)
        XCTAssertTrue(try XCTUnwrap(session.progress.bonusQuizRun).isValid)
        XCTAssertFalse(session.continueQuestionFeedback(interaction: feedbackInteraction))
    }

    func testLeavingQuestionClearsOldNarrationPauseAndRejectsItsLateCallback() {
        let session = startedSession()
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction)
        session.setQuestionPaused(.narration, isPaused: true, interaction: interaction)
        session.selectQuizAnswer(at: 1, interaction: interaction)
        session.confirmSelectedQuizAnswer(interaction: interaction, now: answerDate)
        XCTAssertEqual(session.phase, .quizFeedback)
        XCTAssertFalse(session.questionClock.pauseReasons.contains(.narration))
        session.setQuestionPaused(.narration, isPaused: false, interaction: interaction)
        XCTAssertTrue(session.questionClock.pauseReasons.contains(.feedback))
        session.continueQuestionFeedback(interaction: session.questionInteraction)
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertTrue(session.questionClock.isRunning)
        session.setQuestionPaused(.narration, isPaused: true, interaction: interaction)
        XCTAssertTrue(session.questionClock.isRunning)
    }

    func testSuspendedStoryLocksAgeAndRelaunchUsesOriginalQuestionSet() throws {
        let session = startedSession(ageBand: .ages4To6)
        let lockedQuestions = session.quizQuestions
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        session.back()
        session.ageBand = .ages10To12
        XCTAssertEqual(session.ageBand, .ages4To6, "Story belongs to the locked round")
        session.returnToWorlds()
        session.ageBand = .ages10To12
        XCTAssertEqual(session.ageBand, .ages10To12)
        let restored = makeSession(
            progress: try roundTrip(session.progress), count: 3, marker: "new content")
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.ageBand, .ages4To6)
        XCTAssertEqual(restored.activeRoundAgeBand, .ages4To6)
        XCTAssertEqual(restored.quizQuestions, lockedQuestions)
        XCTAssertEqual(restored.currentQuiz, lockedQuestions[1])
        XCTAssertEqual(restored.quizQuestionIndex, 1)
        XCTAssertEqual(restored.roundScore, 100)
    }

    func testFinalRewardSurvivesFeedbackOrResultsRelaunchWithoutDuplicating() throws {
        for leaveFromResults in [false, true] {
            let session = startedSession()
            session.submitAnswer(at: 0, now: answerDate)
            session.confirm()
            session.submitAnswer(at: 0, now: answerDate)
            XCTAssertEqual(session.phase, .quizFeedback)
            XCTAssertEqual(session.progress.totalScore, 200, "Reward is saved before Continue")
            let reward = try XCTUnwrap(session.progress.leaderboard.first)
            XCTAssertEqual(session.progress.bonusQuizRun?.hasFinishedRound, true)
            if leaveFromResults { session.confirm() }
            session.back()
            let restored = makeSession(progress: try roundTrip(session.progress))
            restored.resumeSavedAdventure()
            XCTAssertEqual(restored.phase, leaveFromResults ? .quizRoundComplete : .quizFeedback)
            restored.submitAnswer(at: 0, now: answerDate)
            if !leaveFromResults { restored.confirm() }
            XCTAssertEqual(restored.phase, .quizRoundComplete)
            restored.submitAnswer(at: 0, now: answerDate)
            restored.confirm()
            XCTAssertEqual(restored.progress.totalScore, 200)
            XCTAssertEqual(restored.progress.leaderboard, [reward])
            XCTAssertEqual(restored.progress.destinations["sun"]?.correctAnswers, 2)
            XCTAssertEqual(restored.progress.destinations["sun"]?.attempts, 2)
            XCTAssertNil(restored.progress.bonusQuizRun)
        }
    }

    func testExplicitRestartReplacesPendingRoundWhileStoryResumeDoesNot() throws {
        let session = startedSession()
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        session.requestHint()
        let firstRunID = try XCTUnwrap(session.progress.bonusQuizRun?.id)
        session.back()
        session.confirm()
        XCTAssertEqual(session.progress.bonusQuizRun?.id, firstRunID)
        XCTAssertEqual(session.quizQuestionIndex, 1)
        XCTAssertEqual(session.roundScore, 100)
        session.restartBonusRound()
        XCTAssertNotEqual(session.progress.bonusQuizRun?.id, firstRunID)
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.quizQuestionIndex, 0)
        XCTAssertEqual(session.roundScore, 0)
        XCTAssertEqual(session.roundCorrectAnswers, 0)
        XCTAssertEqual(session.questionAttemptCount, 0)
        XCTAssertFalse(session.isShowingHint)
        XCTAssertEqual(session.progress.bonusQuizRun?.assistedQuestionIndices, [])
        XCTAssertEqual(session.progress.destinations["sun"]?.correctAnswers, 1)
        XCTAssertTrue(session.progress.destinations["sun"]?.isScanned == true)
        XCTAssertEqual(session.progress.totalScore, 0)
        XCTAssertEqual(session.progress.leaderboard.count, 0)
    }

    func testHelpIsLatchedAcrossRetryAndGetsTheSameCompletionReward() throws {
        let independent = startedSession(count: 1)
        independent.submitAnswer(at: 0, now: answerDate)
        let helped = startedSession(count: 1)
        helped.requestHint()
        let hintedProgress = helped.progress
        helped.requestHint()
        XCTAssertEqual(helped.progress, hintedProgress)
        helped.submitAnswer(at: 1, now: answerDate)
        helped.confirm()
        helped.returnToWorlds()
        let restored = makeSession(progress: try roundTrip(helped.progress), count: 1)
        restored.resumeSavedAdventure()
        XCTAssertTrue(restored.isShowingHint)
        XCTAssertEqual(restored.questionAttemptCount, 1)
        restored.submitAnswer(at: 0, now: answerDate)
        XCTAssertEqual(restored.progress.totalScore, independent.progress.totalScore)
        XCTAssertEqual(restored.roundStars, independent.roundStars)
        XCTAssertEqual(restored.progress.bonusQuizRun?.assistedQuestionIndices, [0])
        XCTAssertEqual(independent.progress.bonusQuizRun?.assistedQuestionIndices, [])
        XCTAssertEqual(restored.progress.destinations["sun"]?.attempts, 2)
        XCTAssertEqual(restored.progress.destinations["sun"]?.reviewBox, 1)
    }

    func testMalformedPendingCursorsCannotSkipAnswersOrDiscardEarnedRewards() {
        let questions = [Self.quiz("first"), Self.quiz("second")]
        var outOfBounds = BonusQuizRunCursor(
            destinationID: "sun", ageBand: .ages7To9, questions: questions)
        outOfBounds.questionIndex = 2
        var skippedFirstAnswer = BonusQuizRunCursor(
            destinationID: "sun", ageBand: .ages7To9, questions: questions)
        skippedFirstAnswer.questionIndex = 1
        var alreadyAnsweredButStillQuiz = skippedFirstAnswer
        alreadyAnsweredButStillQuiz.correctAnswers = 2
        alreadyAnsweredButStillQuiz.roundScore = 200
        alreadyAnsweredButStillQuiz.feedbackWasCorrect = true
        var invalidPhase = BonusQuizRunCursor(
            destinationID: "sun", ageBand: .ages7To9, questions: questions)
        invalidPhase.phase = .navigation
        var prematureCompletion = BonusQuizRunCursor(
            destinationID: "sun", ageBand: .ages7To9, questions: questions)
        prematureCompletion.phase = .quizFeedback
        prematureCompletion.correctAnswers = 1
        prematureCompletion.roundScore = 100
        prematureCompletion.feedbackWasCorrect = true
        prematureCompletion.hasFinishedRound = true

        for cursor in [
            outOfBounds, skippedFirstAnswer, alreadyAnsweredButStillQuiz,
            invalidPhase, prematureCompletion,
        ] {
            XCTAssertFalse(cursor.isValid)
            var earned = earnedProgress()
            earned.bonusQuizRun = cursor
            let session = makeSession(progress: earned)
            session.resumeSavedAdventure()
            earned.bonusQuizRun = nil
            XCTAssertEqual(session.progress, earned)
            XCTAssertEqual(session.phase, .navigation)
            XCTAssertFalse(session.hasSavedAdventure)
        }
    }

    func testRetiredDestinationDiscardsOnlyPendingCursor() {
        var earned = earnedProgress()
        earned.bonusQuizRun = BonusQuizRunCursor(
            destinationID: "retired-world", ageBand: .ages7To9,
            questions: [Self.quiz("old clue")])
        let session = makeSession(progress: earned)
        session.resumeSavedAdventure()
        earned.bonusQuizRun = nil
        XCTAssertEqual(session.progress, earned)
        XCTAssertEqual(session.focusedLesson?.id, "sun")
    }

    func testSelectionAndChangingMindDoNotAnswerUntilExplicitConfirmation() throws {
        let time = TestTime()
        let session = startedSession(count: 1, time: time)
        let interaction = session.questionInteraction
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        XCTAssertEqual(session.selectedQuizChoiceID, "star")
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.questionAttemptCount, 0)
        XCTAssertEqual(session.progress.destinations["sun"]?.attempts, 0)
        XCTAssertTrue(session.progress.questionEvidence.isEmpty)
        XCTAssertEqual(session.progress.totalScore, 0)
        session.selectQuizAnswer(at: 1, interaction: interaction, now: time.now)
        XCTAssertEqual(session.selectedQuizChoiceID, "rock")
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.phase, .quizFeedback)
        XCTAssertFalse(session.wasLastAnswerCorrect)
        XCTAssertEqual(session.questionAttemptCount, 1)
        let afterAnswer = session.progress
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress, afterAnswer)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertNotEqual(session.questionInteraction, interaction)
        let afterRetry = session.progress
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress, afterRetry)
        XCTAssertEqual(session.questionAttemptCount, 1)
        let retryInteraction = session.questionInteraction
        session.selectQuizAnswer(at: 0, interaction: retryInteraction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: retryInteraction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.progress.destinations["sun"]?.attempts, 2)
        let evidence = try XCTUnwrap(session.progress.questionEvidence.last)
        XCTAssertEqual(evidence.attempts, 2)
        XCTAssertTrue(evidence.usedHelp)
        XCTAssertFalse(evidence.usedChallenge)
    }

    func testPreviousQuestionInputIsRejectedEvenWhenChoiceIDsRepeat() {
        let time = TestTime()
        let session = startedSession(time: time)
        let firstInteraction = session.questionInteraction
        session.selectQuizAnswer(at: 0, interaction: firstInteraction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: firstInteraction, now: answerDate, monotonicNow: time.now)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.quizQuestionIndex, 1)
        XCTAssertNil(session.selectedQuizChoiceID)
        let beforeOldInput = session.progress
        session.selectQuizAnswer(at: 1, interaction: firstInteraction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: firstInteraction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress, beforeOldInput)
        XCTAssertNil(session.selectedQuizChoiceID)
        XCTAssertEqual(session.questionAttemptCount, 0)
        let secondInteraction = session.questionInteraction
        session.selectQuizAnswer(at: 0, interaction: secondInteraction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: secondInteraction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress.totalScore, 200)
        XCTAssertEqual(session.progress.questionEvidence.count, 2)
        XCTAssertTrue(
            session.progress.questionEvidence.allSatisfy {
                $0.attempts == 1 && !$0.usedHelp && !$0.usedChallenge
            })
    }

    func testExpiryDoesNotAnswerScoreAdvanceOrWriteEveryTick() throws {
        let time = TestTime()
        let session = startedSession(count: 1, time: time)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction, now: time.now)
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        let beforeSampling = session.progress
        time.now = 40
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 50)
        XCTAssertEqual(session.progress, beforeSampling)
        time.now = 90
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertTrue(session.questionClock.isExpired)
        XCTAssertEqual(session.progress, beforeSampling)
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.quizQuestionIndex, 0)
        XCTAssertEqual(session.selectedQuizChoiceID, "star")
        XCTAssertEqual(session.questionAttemptCount, 0)
        XCTAssertEqual(session.progress.totalScore, 0)
        XCTAssertTrue(session.progress.questionEvidence.isEmpty)
        session.giveQuestionMoreTime(interaction: interaction, now: time.now)
        XCTAssertEqual(session.questionClock.remaining, 90)
        XCTAssertFalse(session.questionClock.isExpired)
        time.now = 100
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 80)
        session.chooseQuestionMode(.practice, interaction: interaction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.progress.destinations["sun"]?.attempts, 1)
        let evidence = try XCTUnwrap(session.progress.questionEvidence.last)
        XCTAssertEqual(evidence.attempts, 1)
        XCTAssertFalse(evidence.usedHelp, "Time extension and Practice are not conceptual hints")
        XCTAssertTrue(evidence.usedChallenge)
        let calm = startedSession(count: 1)
        calm.submitAnswer(at: 0, now: answerDate)
        XCTAssertEqual(session.progress.destinations, calm.progress.destinations)
        XCTAssertEqual(session.progress.totalScore, calm.progress.totalScore)
        XCTAssertEqual(session.roundScore, calm.roundScore)
        XCTAssertEqual(session.roundStars, calm.roundStars)
    }

    func testNestedNarrationBackgroundAndManualPausesChargeOnlyActiveTime() {
        let time = TestTime()
        let session = startedSession(count: 1, time: time)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction, now: time.now)
        time.now = 5
        session.setQuestionPaused(.narration, isPaused: true, now: time.now)
        time.now = 10
        session.setQuestionPaused(.appInactive, isPaused: true, now: time.now)
        time.now = 20
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 85)
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        XCTAssertNil(session.selectedQuizChoiceID)
        time.now = 30
        session.setQuestionPaused(.narration, isPaused: false, now: time.now)
        XCTAssertFalse(session.questionClock.isRunning)
        time.now = 40
        session.setQuestionPaused(.appInactive, isPaused: false, now: time.now)
        session.setQuestionPaused(.manual, isPaused: true, now: time.now)
        time.now = 60
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 85)
        session.setQuestionPaused(.manual, isPaused: false, now: time.now)
        time.now = 65
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 80)
        XCTAssertEqual(session.questionAttemptCount, 0)
        XCTAssertEqual(session.progress.totalScore, 0)
        XCTAssertTrue(session.progress.questionEvidence.isEmpty)
    }

    func testBlockedOverlaysRejectSelectionAndConfirmation() {
        let blockedReasons: [QuestionChallengePauseReason] = [
            .manual, .appInactive, .awaitingResume, .story, .feedback,
        ]
        for reason in blockedReasons {
            let time = TestTime()
            let session = startedSession(count: 1, time: time)
            let interaction = session.questionInteraction
            session.setQuestionPaused(reason, isPaused: true, now: time.now)
            let paused = session.progress
            session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
            session.confirmSelectedQuizAnswer(
                interaction: interaction, now: answerDate, monotonicNow: time.now)
            XCTAssertEqual(session.progress, paused, "\(reason) must reject late answer input")
            XCTAssertNil(session.selectedQuizChoiceID)
            XCTAssertEqual(session.phase, .quiz)
            XCTAssertEqual(session.questionAttemptCount, 0)
        }
    }

    func testStoryChallengeKeepsBudgetSelectionAndHelpUntilExplicitResume() throws {
        let time = TestTime()
        let session = startedSession(time: time)
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        let question = session.currentQuiz
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction, now: time.now)
        session.selectQuizAnswer(at: 1, interaction: interaction, now: time.now)
        time.now = 20
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        session.requestHint()
        session.back()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertEqual(session.questionClock.remaining, 70)
        time.now = 1000
        session.sampleQuestionTime(now: time.now, interaction: session.questionInteraction)
        XCTAssertEqual(session.questionClock.remaining, 70)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.currentQuiz, question)
        XCTAssertEqual(session.selectedQuizChoiceID, "rock")
        XCTAssertEqual(session.questionClock.remaining, 70)
        XCTAssertTrue(session.isShowingHint)
        XCTAssertTrue(session.questionClock.pauseReasons.contains(.awaitingResume))
        session.dismissQuestionHint(now: time.now)
        XCTAssertFalse(session.isShowingHint)
        XCTAssertTrue(session.lastAnswerUsedHelp)
        let resumedInteraction = session.questionInteraction
        session.resumeQuestionChallenge(interaction: resumedInteraction, now: time.now)
        time.now = 1010
        session.sampleQuestionTime(now: time.now, interaction: resumedInteraction)
        XCTAssertEqual(session.questionClock.remaining, 60)
        session.selectQuizAnswer(at: 0, interaction: resumedInteraction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: resumedInteraction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(session.progress.totalScore, 200)
        let evidence = try XCTUnwrap(session.progress.questionEvidence.last)
        XCTAssertEqual(evidence.attempts, 1)
        XCTAssertTrue(evidence.usedHelp)
        XCTAssertTrue(evidence.usedChallenge)
    }

    func testChallengeRelaunchRestoresSelectionWithoutChargingTimeAway() throws {
        let time = TestTime()
        let session = startedSession(count: 1, time: time)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction, now: time.now)
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        time.now = 30
        session.setQuestionPaused(.appInactive, isPaused: true, now: time.now)
        session.returnToWorlds()
        time.now = 10_000
        let restored = makeSession(
            progress: try roundTrip(session.progress), count: 1, time: time)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.selectedQuizChoiceID, "star")
        XCTAssertEqual(restored.questionClock.remaining, 60)
        XCTAssertTrue(restored.questionClock.pauseReasons.contains(.awaitingResume))
        let restoredInteraction = restored.questionInteraction
        time.now = 20_000
        restored.sampleQuestionTime(now: time.now, interaction: restoredInteraction)
        XCTAssertEqual(restored.questionClock.remaining, 60)
        restored.resumeQuestionChallenge(interaction: restoredInteraction, now: time.now)
        time.now = 20_010
        restored.sampleQuestionTime(now: time.now, interaction: restoredInteraction)
        XCTAssertEqual(restored.questionClock.remaining, 50)
        restored.confirmSelectedQuizAnswer(
            interaction: restoredInteraction, now: answerDate, monotonicNow: time.now)
        XCTAssertEqual(restored.progress.totalScore, 100)
        let evidence = try XCTUnwrap(restored.progress.questionEvidence.last)
        XCTAssertEqual(evidence.attempts, 1)
        XCTAssertFalse(evidence.usedHelp)
        XCTAssertTrue(evidence.usedChallenge)
    }

    func testRelaunchedSecondQuestionSurvivesPrimaryMenuAndWorldsBeforeResume() throws {
        let time = TestTime()
        let session = startedSession(time: time)
        session.submitAnswer(at: 0, now: answerDate)
        session.confirm()
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction)
        session.selectQuizAnswer(at: 1, interaction: interaction)
        time.now = 25
        session.returnToWorlds()
        let saved = try roundTrip(session.progress)
        let presentation = try XCTUnwrap(saved.questionPresentation)
        XCTAssertEqual(presentation.challenge.remaining, 65)
        time.now = 10_000
        let restored = makeSession(progress: saved, count: 1, marker: "changed", time: time)
        restored.confirm()  // Primary Continue Adventure, before the explicit resume action.
        XCTAssertEqual(restored.phase, .navigation)
        XCTAssertEqual(restored.progress.questionPresentation, presentation)
        restored.returnToWorlds()
        XCTAssertEqual(restored.progress.questionPresentation, presentation)
        restored.resumeSavedAdventure()
        XCTAssertEqual(restored.quizQuestionIndex, 1)
        XCTAssertEqual(restored.currentQuiz, saved.bonusQuizRun?.questions[1])
        XCTAssertEqual(restored.selectedQuizChoiceID, "rock")
        XCTAssertEqual(restored.questionClock.mode, .challenge)
        XCTAssertEqual(restored.questionClock.remaining, 65)
        XCTAssertTrue(restored.questionClock.pauseReasons.contains(.awaitingResume))
    }

    func testMatchingWorldStoryMarksPendingQuestionAssistedWithoutChangingPriorEvidence() throws {
        let time = TestTime()
        let session = startedSession(time: time)
        session.submitAnswer(at: 0, now: answerDate)
        let firstEvidence = try XCTUnwrap(session.progress.questionEvidence.first)
        session.returnToWorlds()
        session.confirm()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertEqual(session.progress.bonusQuizRun?.assistedQuestionIndices, [])
        XCTAssertEqual(session.progress.questionEvidence.first, firstEvidence)
        session.confirm()
        XCTAssertEqual(session.phase, .quizFeedback)
        session.confirm()
        XCTAssertEqual(session.quizQuestionIndex, 1)
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction)
        session.selectQuizAnswer(at: 0, interaction: interaction)
        time.now = 25
        session.returnToWorlds()
        let saved = try roundTrip(session.progress)
        time.now = 10_000
        let restored = makeSession(progress: saved, count: 1, marker: "changed", time: time)
        restored.confirm()
        restored.confirm()
        XCTAssertEqual(restored.phase, .discoveryCard)
        XCTAssertEqual(restored.quizQuestionIndex, 1)
        XCTAssertEqual(restored.currentQuiz, saved.bonusQuizRun?.questions[1])
        XCTAssertEqual(restored.selectedQuizChoiceID, "star")
        XCTAssertEqual(restored.questionClock.remaining, 65)
        XCTAssertEqual(restored.progress.bonusQuizRun?.assistedQuestionIndices, [1])
        XCTAssertEqual(restored.progress.questionEvidence.first, firstEvidence)
        restored.confirm()
        let resumedInteraction = restored.questionInteraction
        restored.resumeQuestionChallenge(interaction: resumedInteraction)
        restored.confirmSelectedQuizAnswer(interaction: resumedInteraction, now: answerDate)
        XCTAssertEqual(restored.progress.totalScore, 200)
        XCTAssertTrue(try XCTUnwrap(restored.progress.questionEvidence.last).usedHelp)
        XCTAssertEqual(restored.progress.questionEvidence.first, firstEvidence)
    }

    func testHelpDismissalCannotTurnAssistedAnswerIntoIndependentEvidence() throws {
        let time = TestTime()
        let session = startedSession(count: 1, time: time)
        session.requestHint()
        let interaction = session.questionInteraction
        session.chooseQuestionMode(.challenge, interaction: interaction, now: time.now)
        time.now = 90
        session.sampleQuestionTime(now: time.now, interaction: interaction)
        XCTAssertEqual(session.questionClock.remaining, 90, "Reading help is free time")
        session.dismissQuestionHint(now: time.now)
        session.selectQuizAnswer(at: 0, interaction: interaction, now: time.now)
        session.confirmSelectedQuizAnswer(
            interaction: interaction, now: answerDate, monotonicNow: time.now)
        let evidence = try XCTUnwrap(session.progress.questionEvidence.last)
        XCTAssertEqual(evidence.attempts, 1)
        XCTAssertTrue(evidence.usedHelp)
        XCTAssertTrue(evidence.usedChallenge)
        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.roundStars, 3)
        XCTAssertEqual(session.progress.destinations["sun"]?.reviewBox, 1)
    }

    func testUnknownSavedChoiceCannotConfirmAnAnswer() throws {
        let session = startedSession(count: 1)
        var saved = session.progress
        saved.questionPresentation = QuestionPresentationSnapshot(
            challenge: session.questionClock.snapshot, selectedChoiceID: "missing choice")
        let restored = makeSession(progress: try roundTrip(saved), count: 1)
        restored.resumeSavedAdventure()
        XCTAssertNil(restored.selectedQuizChoiceID)
        let beforeConfirm = restored.progress
        restored.confirmSelectedQuizAnswer(
            interaction: restored.questionInteraction, now: answerDate, monotonicNow: 0)
        XCTAssertEqual(restored.progress, beforeConfirm)
        XCTAssertEqual(restored.questionAttemptCount, 0)
        XCTAssertEqual(restored.phase, .quiz)
    }

    func testEvidenceDecodeKeepsOnlyRecentFactualContexts() throws {
        let entries: [[String: Any]] = (0..<70).map { index in
            [
                "questionID": "question-\(index)", "attempts": index + 1,
                "usedHelp": index.isMultiple(of: 2), "usedChallenge": index.isMultiple(of: 3),
            ]
        }
        let bytes = try JSONSerialization.data(withJSONObject: ["questionEvidence": entries])
        let decoded = try JSONDecoder().decode(GameProgress.self, from: bytes)
        XCTAssertEqual(decoded.questionEvidence.count, 64)
        XCTAssertEqual(decoded.questionEvidence.first?.questionID, "question-6")
        XCTAssertEqual(decoded.questionEvidence.first?.attempts, 7)
        XCTAssertEqual(decoded.questionEvidence.first?.usedHelp, true)
        XCTAssertEqual(decoded.questionEvidence.first?.usedChallenge, true)
        XCTAssertEqual(decoded.questionEvidence.last?.questionID, "question-69")
        XCTAssertEqual(decoded.questionEvidence.last?.attempts, 70)
        XCTAssertEqual(decoded.questionEvidence.last?.usedHelp, false)
        XCTAssertEqual(decoded.questionEvidence.last?.usedChallenge, true)
    }

    private func startedSession(
        count: Int = 2, ageBand: AgeBand = .ages7To9, time: TestTime = TestTime()
    ) -> MissionSession {
        let session = makeSession(count: count, time: time)
        session.ageBand = ageBand
        session.confirm()
        session.confirm()
        session.confirm()
        return session
    }

    private func makeSession(
        progress: GameProgress? = nil, count: Int = 2, marker: String = "original",
        time: TestTime = TestTime()
    ) -> MissionSession {
        MissionSession(
            lessons: [Self.lesson], progress: progress,
            quizProvider: { _, band in
                (0..<count).map { Self.quiz("\(marker) \(band.rawValue) clue \($0)") }
            }, monotonicTime: { time.now })
    }

    private func roundTrip(_ progress: GameProgress) throws -> GameProgress {
        try JSONDecoder().decode(GameProgress.self, from: JSONEncoder().encode(progress))
    }

    private func earnedProgress() -> GameProgress {
        GameProgress(
            destinations: [
                "sun": DestinationProgress(
                    isScanned: true, isQuizCompleted: true, correctAnswers: 7, attempts: 9,
                    masteryScore: 65, reviewBox: 3, bestRoundScore: 700, bestRoundStars: 3)
            ],
            totalScore: 700,
            missionCompletions: [
                "old-mission": MissionCompletion(completedAt: answerDate, ageBand: .ages7To9)
            ])
    }

    private final class TestTime {
        var now: Double = 0
    }

    private static func quiz(_ prompt: String) -> QuizContent {
        QuizContent(
            prompt: prompt,
            choices: [
                QuizChoice(id: "star", text: "A star"),
                QuizChoice(id: "rock", text: "A rocky planet"),
            ],
            correctChoiceID: "star",
            correctFeedback: "A star makes its own light.",
            retryFeedback: "A rocky planet reflects light. Think about what makes light.",
            hint: "Stars make light.")
    }

    private static let lesson: DestinationLesson = {
        let content = AgeBandLessonContent(discoveryText: "The Sun is a star.", quiz: quiz("Sun"))
        return DestinationLesson(
            id: "sun", displayName: "Sun", kind: "star",
            source: LearningSource(
                title: "NASA Sun", url: URL(string: "https://science.nasa.gov/sun/")!,
                reviewStatus: "reviewed"),
            content: AgeBandContentSet(
                ages4To6: content, ages7To9: content, ages10To12: content))
    }()
}
