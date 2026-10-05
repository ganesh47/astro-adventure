import Foundation

/// A bounded snapshot of the bonus discovery round. Story and World visits suspend
/// this cursor; only an explicit new round replaces it. Earned rewards live elsewhere.
public struct BonusQuizRunCursor: Codable, Equatable, Sendable {
    public let id: String
    public let destinationID: String
    public let ageBand: AgeBand
    public let questions: [QuizContent]
    public var phase: MissionPhase
    public var questionIndex: Int
    public var roundScore: Int
    public var correctAnswers: Int
    public var hasFinishedRound: Bool
    public var attempts: Int
    public var isShowingHint: Bool
    public var assistedQuestionIndices: Set<Int>
    public var feedbackWasCorrect: Bool
    public var feedbackText: String

    public init(destinationID: String, ageBand: AgeBand, questions: [QuizContent]) {
        id = UUID().uuidString
        self.destinationID = destinationID
        self.ageBand = ageBand
        self.questions = questions
        phase = .quiz
        questionIndex = 0
        roundScore = 0
        correctAnswers = 0
        hasFinishedRound = false
        attempts = 0
        isShowingHint = false
        assistedQuestionIndices = []
        feedbackWasCorrect = false
        feedbackText = ""
    }

    public var isValid: Bool {
        guard !id.isEmpty, id.count <= 64, !destinationID.isEmpty,
            (1...16).contains(questions.count), questions.indices.contains(questionIndex),
            [.quiz, .quizFeedback, .quizRoundComplete].contains(phase),
            (0...questions.count).contains(correctAnswers),
            correctAnswers == questionIndex + (phase != .quiz && feedbackWasCorrect ? 1 : 0),
            roundScore == correctAnswers * 100, (0...10000).contains(attempts),
            feedbackText.count <= 4096,
            assistedQuestionIndices.allSatisfy(questions.indices.contains)
        else { return false }
        if phase != .quiz && attempts == 0 { return false }
        if isShowingHint && !assistedQuestionIndices.contains(questionIndex) { return false }
        if phase == .quizFeedback && !feedbackWasCorrect
            && !assistedQuestionIndices.contains(questionIndex)
        {
            return false
        }
        if hasFinishedRound {
            guard questionIndex == questions.count - 1, correctAnswers == questions.count,
                feedbackWasCorrect, phase != .quiz
            else { return false }
        } else if phase == .quizRoundComplete
            || (phase == .quizFeedback && feedbackWasCorrect
                && questionIndex == questions.count - 1)
        {
            return false
        }
        return questions.allSatisfy { question in
            let count = question.choices.count
            return (2...3).contains(count) && !question.prompt.isEmpty
                && question.prompt.count <= 4096
                && Set(question.choices.map(\.id)).count == count
                && question.choices.allSatisfy { !$0.id.isEmpty && !$0.text.isEmpty }
                && question.choices.contains { $0.id == question.correctChoiceID }
        }
    }
}
