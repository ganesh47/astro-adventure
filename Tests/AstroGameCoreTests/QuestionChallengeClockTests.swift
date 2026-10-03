import AstroGameCore
import Foundation
import XCTest

final class QuestionChallengeClockTests: XCTestCase {
    func testPracticeIsCalmAndOptingInDoesNotChargePracticeTime() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", now: 10)
        clock.tick(now: 10_000)
        XCTAssertEqual(clock.mode, .practice)
        XCTAssertEqual(clock.remaining, 90)
        XCTAssertFalse(clock.challengeUsed)
        XCTAssertFalse(clock.isRunning)
        XCTAssertFalse(clock.isExpired)

        clock.setMode(.challenge, now: 10_010)
        XCTAssertTrue(clock.challengeUsed)
        XCTAssertTrue(clock.isRunning)
        clock.tick(now: 10_020)
        XCTAssertEqual(clock.remaining, 80)
        clock.continuePractice(now: 10_025)
        clock.tick(now: 20_000)
        XCTAssertEqual(clock.remaining, 75)
        XCTAssertTrue(clock.challengeUsed, "Leaving challenge does not erase its context")
        XCTAssertFalse(clock.isExpired)
    }

    func testElapsedTimeIsIndependentOfTickFrequencyAndExactExpiryIsStable() {
        var sparse = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        var frequent = sparse
        for second in 1...90 { frequent.tick(now: Double(second)) }
        sparse.tick(now: 90)
        XCTAssertEqual(sparse.remaining, frequent.remaining)
        XCTAssertEqual(sparse.remaining, 0)
        XCTAssertEqual(sparse.fractionRemaining, 0)
        XCTAssertTrue(sparse.isExpired)
        XCTAssertFalse(sparse.isRunning)

        let expiredSnapshot = sparse.snapshot
        sparse.tick(now: 90)
        sparse.tick(now: 900)
        XCTAssertEqual(sparse.snapshot, expiredSnapshot, "Expiry has no additional side effect")
    }

    func testEveryPauseReasonCanFreezeTimeAndNestedReasonsCannotResumeEachOther() {
        for reason in QuestionChallengePauseReason.allCases {
            var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
            clock.setPaused(reason, isPaused: true, now: 10)
            clock.tick(now: 100)
            XCTAssertEqual(clock.remaining, 80, "\(reason) charges only time before pausing")
            clock.setPaused(reason, isPaused: false, now: 110)
            clock.tick(now: 120)
            XCTAssertEqual(clock.remaining, 70)
        }

        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        clock.setPaused(.narration, isPaused: true, now: 5)
        clock.setPaused(.appInactive, isPaused: true, now: 10)
        clock.setPaused(.manual, isPaused: true, now: 15)
        clock.setPaused(.narration, isPaused: false, now: 40)
        clock.setPaused(.appInactive, isPaused: false, now: 60)
        clock.tick(now: 100)
        XCTAssertEqual(clock.remaining, 85)
        XCTAssertEqual(clock.pauseReasons, [.manual])
        XCTAssertFalse(clock.isRunning)
        clock.setPaused(.manual, isPaused: false, now: 100)
        clock.tick(now: 105)
        XCTAssertEqual(clock.remaining, 80)
    }

    func testPauseAndResumeAtSameInstantAreIdempotent() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        clock.setPaused(.help, isPaused: true, now: 10)
        clock.setPaused(.help, isPaused: true, now: 10)
        clock.setPaused(.help, isPaused: true, now: 100)
        XCTAssertEqual(clock.remaining, 80)
        XCTAssertEqual(clock.pauseReasons, [.help])
        clock.setPaused(.help, isPaused: false, now: 100)
        clock.setPaused(.help, isPaused: false, now: 100)
        clock.tick(now: 110)
        clock.tick(now: 110)
        XCTAssertEqual(clock.remaining, 70)
    }

    func testIncorrectFeedbackAndRetryCanKeepTheSameBudget() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        clock.setPaused(.feedback, isPaused: true, now: 20)
        clock.tick(now: 200)
        clock.invalidateInteractions(now: 200)
        clock.setPaused(.feedback, isPaused: false, now: 200)
        clock.tick(now: 210)
        XCTAssertEqual(clock.remaining, 60)
        XCTAssertEqual(clock.questionID, "sun-kind")
        XCTAssertTrue(clock.challengeUsed)
        XCTAssertEqual(clock.interactionEpoch, 1)
    }

    func testExpiryOffersRefillOrPracticeWithoutRemovingOtherPauses() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        clock.tick(now: 100)
        clock.setPaused(.story, isPaused: true, now: 100)
        clock.moreTime(now: 120)
        clock.moreTime(now: 120)
        XCTAssertEqual(clock.remaining, 90, "More Time refills instead of stacking budgets")
        XCTAssertEqual(clock.pauseReasons, [.story])
        XCTAssertFalse(clock.isRunning)
        XCTAssertFalse(clock.isExpired)
        clock.tick(now: 200)
        XCTAssertEqual(clock.remaining, 90)
        clock.setPaused(.story, isPaused: false, now: 200)
        clock.tick(now: 290)
        XCTAssertTrue(clock.isExpired)
        clock.continuePractice(now: 290)
        clock.tick(now: 1000)
        XCTAssertEqual(clock.remaining, 0)
        XCTAssertFalse(clock.isExpired)
        XCTAssertFalse(clock.isRunning)
        XCTAssertTrue(clock.challengeUsed)
    }

    func testBackwardsAndNonfiniteSamplesCannotConsumeRefundOrChangeMode() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 100)
        clock.tick(now: 110)
        let beforeInvalidEvents = clock
        for invalid in [109, -1, Double.nan, Double.infinity, -Double.infinity] {
            clock.tick(now: invalid)
            clock.setPaused(.manual, isPaused: true, now: invalid)
            clock.setMode(.practice, now: invalid)
            clock.moreTime(now: invalid)
            clock.invalidateInteractions(now: invalid)
        }
        XCTAssertEqual(clock, beforeInvalidEvents)
        clock.tick(now: 120)
        XCTAssertEqual(clock.remaining, 70)
    }

    func testInvalidInitialAnchorWaitsForAValidSample() {
        var clock = QuestionChallengeClock(
            questionID: "sun-kind", mode: .challenge, now: .nan)
        XCTAssertFalse(clock.isRunning)
        clock.tick(now: 10_000)
        XCTAssertTrue(clock.isRunning)
        XCTAssertEqual(clock.remaining, 90)
        clock.tick(now: 10_010)
        XCTAssertEqual(clock.remaining, 80)
    }

    func testStaleQuestionAndRetryCallbacksCannotMutateTheClock() {
        var clock = QuestionChallengeClock(questionID: "sun-kind", mode: .challenge, now: 0)
        let oldInteraction = clock.interaction
        clock.setPaused(.feedback, isPaused: true, now: 10)
        clock.invalidateInteractions(now: 20)
        clock.setPaused(.narration, isPaused: true, now: 20)
        let beforeStaleEvents = clock
        clock.tick(now: 50, expectedInteraction: oldInteraction)
        clock.setPaused(.narration, isPaused: false, now: 50, expectedInteraction: oldInteraction)
        clock.setMode(.practice, now: 50, expectedInteraction: oldInteraction)
        clock.moreTime(now: 50, expectedInteraction: oldInteraction)
        clock.continuePractice(now: 50, expectedInteraction: oldInteraction)
        XCTAssertEqual(clock, beforeStaleEvents)

        let currentInteraction = clock.interaction
        clock.setPaused(
            .narration, isPaused: false, now: 50, expectedInteraction: currentInteraction)
        clock.setPaused(
            .feedback, isPaused: false, now: 50, expectedInteraction: currentInteraction)
        clock.tick(now: 60, expectedInteraction: currentInteraction)
        XCTAssertEqual(clock.remaining, 70)

        var nextQuestion = QuestionChallengeClock(
            questionID: "sun-light", mode: .challenge, now: 60,
            interactionEpoch: currentInteraction.epoch)
        let beforePreviousQuestionEvent = nextQuestion
        nextQuestion.tick(now: 70, expectedInteraction: currentInteraction)
        nextQuestion.setPaused(
            .help, isPaused: true, now: 70, expectedInteraction: currentInteraction)
        XCTAssertEqual(nextQuestion, beforePreviousQuestionEvent)
    }

    func testRestoreHasFreshAnchorAndExplicitResumeWithoutChargingAwayTime() throws {
        var original = QuestionChallengeClock(
            questionID: "sun-kind", mode: .challenge, now: 100,
            interactionEpoch: 9)
        original.setPaused(.appInactive, isPaused: true, now: 120)
        let bytes = try JSONEncoder().encode(original.snapshot)
        let snapshot = try JSONDecoder().decode(QuestionChallengeSnapshot.self, from: bytes)
        var restored = QuestionChallengeClock(
            restoring: snapshot, now: 100_000, interactionEpoch: 10)
        XCTAssertEqual(restored.remaining, 70)
        XCTAssertEqual(restored.pauseReasons, [.awaitingResume])
        XCTAssertFalse(restored.isRunning)
        restored.tick(now: 200_000)
        XCTAssertEqual(restored.remaining, 70)
        restored.setPaused(.manual, isPaused: true, now: 200_000)
        restored.setPaused(.awaitingResume, isPaused: false, now: 200_010)
        restored.tick(now: 200_020)
        XCTAssertEqual(restored.remaining, 70)
        restored.setPaused(.manual, isPaused: false, now: 200_020)
        restored.tick(now: 200_025)
        XCTAssertEqual(restored.remaining, 65)
        restored.tick(now: 200_030, expectedInteraction: original.interaction)
        XCTAssertEqual(restored.remaining, 65)
    }

    func testSnapshotsContainOnlyBoundedPresentationContext() throws {
        let snapshot = QuestionChallengeSnapshot(
            mode: .challenge, questionID: "sun-kind", remaining: 900, challengeUsed: false)
        XCTAssertEqual(snapshot.remaining, 300)
        XCTAssertTrue(snapshot.challengeUsed)
        let bytes = try JSONEncoder().encode(snapshot)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["mode", "questionID", "remaining", "challengeUsed"])
        XCTAssertEqual(
            try JSONDecoder().decode(QuestionChallengeSnapshot.self, from: bytes), snapshot)

        let decoded = try JSONDecoder().decode(
            QuestionChallengeSnapshot.self,
            from: Data(
                """
                {"mode":"challenge","questionID":"sun-kind","remaining":-50}
                """.utf8))
        XCTAssertEqual(decoded.remaining, 0)
        XCTAssertTrue(decoded.challengeUsed)
        XCTAssertEqual(
            QuestionChallengeSnapshot(questionID: "sun-kind", remaining: .nan).remaining, 90)

        var restored = QuestionChallengeClock(restoring: snapshot, now: 0)
        restored.moreTime(now: 0)
        XCTAssertEqual(restored.remaining, 300, "More Time cannot shorten a restored budget")
    }

    func testAllowanceIsFiniteAndBoundedAndPracticeDoesNotRefillByAccident() {
        for invalidAllowance in [0, -1, Double.nan, Double.infinity] {
            let clock = QuestionChallengeClock(
                questionID: "sun-kind", allowance: invalidAllowance, now: 0)
            XCTAssertEqual(clock.allowance, 90)
            XCTAssertEqual(clock.remaining, 90)
        }
        var short = QuestionChallengeClock(
            questionID: "sun-kind", mode: .challenge, allowance: 0.1, now: 0)
        XCTAssertEqual(short.allowance, 1)
        short.tick(now: 1)
        XCTAssertTrue(short.isExpired)
        short.continuePractice(now: 1)
        short.moreTime(now: 2)
        XCTAssertEqual(short.remaining, 0)
        let bounded = QuestionChallengeClock(
            questionID: "sun-kind", allowance: 1000, now: 0)
        XCTAssertEqual(bounded.allowance, 300)
        XCTAssertEqual(bounded.fractionRemaining, 1)
    }
}
