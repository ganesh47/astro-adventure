import XCTest

@testable import AstroGameCore

final class LearningEngineTests: XCTestCase {
    func testCorrectAnswerAdvancesReviewBox() {
        XCTAssertEqual(LearningEngine.nextReviewBox(current: 0, answeredCorrectly: true), 1)
        XCTAssertEqual(LearningEngine.nextReviewBox(current: 5, answeredCorrectly: true), 5)
    }

    func testIncorrectAnswerResetsReviewBox() {
        XCTAssertEqual(LearningEngine.nextReviewBox(current: 4, answeredCorrectly: false), 1)
    }

    func testReviewDelays() {
        XCTAssertEqual(LearningEngine.reviewDelayDays(for: 3), 4)
        XCTAssertEqual(LearningEngine.reviewDelayDays(for: 99), 16)
    }

    func testMasteryRewardsRetryWithoutPenalty() {
        XCTAssertEqual(LearningEngine.masteryDelta(answeredCorrectly: true, attempts: 1), 25)
        XCTAssertEqual(LearningEngine.masteryDelta(answeredCorrectly: true, attempts: 2), 15)
        XCTAssertEqual(LearningEngine.masteryDelta(answeredCorrectly: false, attempts: 1), 0)
    }
}
