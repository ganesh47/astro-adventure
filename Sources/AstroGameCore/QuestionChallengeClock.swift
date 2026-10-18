import Foundation

public enum QuestionChallengeMode: String, Codable, CaseIterable, Sendable {
    case practice
    case challenge
}

public enum QuestionChallengePauseReason: String, Codable, CaseIterable, Hashable, Sendable {
    case appInactive
    case manual
    case narration
    case help
    case story
    case feedback
    case awaitingResume
}

/// A bounded budget, without a deadline or an instant from another process.
public struct QuestionChallengeSnapshot: Codable, Equatable, Sendable {
    public let mode: QuestionChallengeMode
    public let questionID: String
    public let remaining: Double
    public let challengeUsed: Bool

    public init(
        mode: QuestionChallengeMode = .practice,
        questionID: String,
        remaining: Double = QuestionChallengeClock.defaultAllowance,
        challengeUsed: Bool = false
    ) {
        self.mode = mode
        self.questionID = questionID
        self.remaining = normalizedQuestionRemaining(remaining)
        self.challengeUsed = challengeUsed || mode == .challenge
    }

    private enum CodingKeys: String, CodingKey {
        case mode, questionID, remaining, challengeUsed
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            mode: try values.decode(QuestionChallengeMode.self, forKey: .mode),
            questionID: try values.decode(String.self, forKey: .questionID),
            remaining: try values.decode(Double.self, forKey: .remaining),
            challengeUsed: try values.decodeIfPresent(Bool.self, forKey: .challengeUsed) ?? false
        )
    }
}

/// Stamp delayed UI, narration and timer callbacks with the interaction that created them.
public struct QuestionChallengeInteraction: Equatable, Sendable {
    public let questionID: String
    public let epoch: UInt64

    public init(questionID: String, epoch: UInt64) {
        self.questionID = questionID
        self.epoch = epoch
    }
}

/// Optional play time is presentation only; this value never submits or scores an answer.
/// Supply monotonic seconds on the owning actor. Countdown callbacks merely sample elapsed time.
public struct QuestionChallengeClock: Equatable, Sendable {
    public static let defaultAllowance: Double = 90
    public static let maximumAllowance: Double = 300

    public let questionID: String
    public let allowance: Double
    public private(set) var mode: QuestionChallengeMode
    public private(set) var remaining: Double
    public private(set) var challengeUsed: Bool
    public private(set) var pauseReasons: Set<QuestionChallengePauseReason>
    public private(set) var interactionEpoch: UInt64
    private var lastInstant: Double?

    public init(
        questionID: String,
        mode: QuestionChallengeMode = .practice,
        allowance: Double = QuestionChallengeClock.defaultAllowance,
        now: Double,
        interactionEpoch: UInt64 = 0,
        pauseReasons: Set<QuestionChallengePauseReason> = []
    ) {
        self.questionID = questionID
        self.allowance = normalizedQuestionAllowance(allowance)
        self.mode = mode
        self.remaining = self.allowance
        self.challengeUsed = mode == .challenge
        self.pauseReasons = pauseReasons
        self.interactionEpoch = interactionEpoch
        self.lastInstant = now.isFinite && now >= 0 ? now : nil
    }

    /// Restoring never charges time away or starts a countdown before an explicit resume.
    /// Supply a fresh interaction epoch when replacing a clock within the same live session.
    public init(
        restoring snapshot: QuestionChallengeSnapshot,
        now: Double,
        allowance: Double = QuestionChallengeClock.defaultAllowance,
        interactionEpoch: UInt64 = 0
    ) {
        self.init(
            questionID: snapshot.questionID,
            mode: snapshot.mode,
            allowance: allowance,
            now: now,
            interactionEpoch: interactionEpoch,
            pauseReasons: [.awaitingResume]
        )
        remaining = snapshot.remaining
        challengeUsed = snapshot.challengeUsed
    }

    public var interaction: QuestionChallengeInteraction {
        QuestionChallengeInteraction(questionID: questionID, epoch: interactionEpoch)
    }

    public var snapshot: QuestionChallengeSnapshot {
        QuestionChallengeSnapshot(
            mode: mode, questionID: questionID, remaining: remaining,
            challengeUsed: challengeUsed
        )
    }

    public var isExpired: Bool { mode == .challenge && remaining == 0 }

    public var isRunning: Bool {
        mode == .challenge && remaining > 0 && pauseReasons.isEmpty && lastInstant != nil
    }

    public var fractionRemaining: Double { min(1, remaining / allowance) }

    public mutating func tick(
        now: Double, expectedInteraction: QuestionChallengeInteraction? = nil
    ) {
        guard accepts(expectedInteraction) else { return }
        settle(now: now)
    }

    public mutating func setMode(
        _ mode: QuestionChallengeMode,
        now: Double,
        expectedInteraction: QuestionChallengeInteraction? = nil
    ) {
        guard accepts(expectedInteraction), settle(now: now) else { return }
        self.mode = mode
        if mode == .challenge { challengeUsed = true }
    }

    public mutating func setPaused(
        _ reason: QuestionChallengePauseReason,
        isPaused: Bool,
        now: Double,
        expectedInteraction: QuestionChallengeInteraction? = nil
    ) {
        guard accepts(expectedInteraction), settle(now: now) else { return }
        if isPaused {
            pauseReasons.insert(reason)
        } else {
            pauseReasons.remove(reason)
        }
    }

    /// Refill this question's allowance. Other pause reasons remain in effect.
    public mutating func moreTime(
        now: Double, expectedInteraction: QuestionChallengeInteraction? = nil
    ) {
        guard accepts(expectedInteraction), mode == .challenge, settle(now: now) else { return }
        remaining = max(remaining, allowance)
    }

    public mutating func continuePractice(
        now: Double, expectedInteraction: QuestionChallengeInteraction? = nil
    ) {
        setMode(.practice, now: now, expectedInteraction: expectedInteraction)
    }

    /// Retry or a rebuilt interaction invalidates old callbacks without resetting its budget.
    public mutating func invalidateInteractions(now: Double) {
        guard settle(now: now) else { return }
        interactionEpoch &+= 1
    }

    private func accepts(_ expected: QuestionChallengeInteraction?) -> Bool {
        expected == nil || expected == interaction
    }

    @discardableResult
    private mutating func settle(now: Double) -> Bool {
        guard now.isFinite, now >= 0 else { return false }
        if let lastInstant {
            guard now >= lastInstant else { return false }
            if isRunning {
                remaining = max(0, remaining - (now - lastInstant))
            }
        }
        lastInstant = now
        return true
    }
}

private func normalizedQuestionAllowance(_ value: Double) -> Double {
    guard value.isFinite, value > 0 else { return QuestionChallengeClock.defaultAllowance }
    return min(max(1, value), QuestionChallengeClock.maximumAllowance)
}

private func normalizedQuestionRemaining(_ value: Double) -> Double {
    guard value.isFinite else { return QuestionChallengeClock.defaultAllowance }
    return min(max(0, value), QuestionChallengeClock.maximumAllowance)
}
