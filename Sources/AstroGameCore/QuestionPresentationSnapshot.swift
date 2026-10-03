import Foundation

public struct QuestionPresentationSnapshot: Codable, Equatable, Sendable {
    public let challenge: QuestionChallengeSnapshot
    public let selectedChoiceID: String?

    public init(challenge: QuestionChallengeSnapshot, selectedChoiceID: String?) {
        self.challenge = challenge
        self.selectedChoiceID = selectedChoiceID
    }
}

/// Factual context, independent of points and spaced-review scheduling.
public struct QuestionAnswerEvidence: Codable, Equatable, Sendable {
    public let questionID: String
    public let attempts: Int
    public let usedHelp: Bool
    public let usedChallenge: Bool

    public init(questionID: String, attempts: Int, usedHelp: Bool, usedChallenge: Bool) {
        self.questionID = questionID
        self.attempts = attempts
        self.usedHelp = usedHelp
        self.usedChallenge = usedChallenge
    }
}
