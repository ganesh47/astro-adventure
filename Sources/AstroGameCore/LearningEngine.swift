import Foundation

public enum LearningEngine {
    public static func nextReviewBox(current: Int, answeredCorrectly: Bool) -> Int {
        answeredCorrectly ? min(max(current + 1, 1), 5) : 1
    }

    public static func reviewDelayDays(for reviewBox: Int) -> Int {
        let delays = [0, 1, 2, 4, 8, 16]
        return delays[min(max(reviewBox, 0), 5)]
    }

    public static func masteryDelta(answeredCorrectly: Bool, attempts: Int) -> Int {
        guard answeredCorrectly else { return 0 }
        return attempts <= 1 ? 25 : 15
    }
}
