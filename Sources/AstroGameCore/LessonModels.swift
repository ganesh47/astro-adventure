import Foundation

public struct QuizChoice: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public struct QuizContent: Codable, Equatable, Sendable {
    public let prompt: String
    public let choices: [QuizChoice]
    public let correctChoiceID: String
    public let correctFeedback: String
    public let retryFeedback: String
    public let hint: String

    public init(
        prompt: String,
        choices: [QuizChoice],
        correctChoiceID: String,
        correctFeedback: String,
        retryFeedback: String,
        hint: String
    ) {
        self.prompt = prompt
        self.choices = choices
        self.correctChoiceID = correctChoiceID
        self.correctFeedback = correctFeedback
        self.retryFeedback = retryFeedback
        self.hint = hint
    }
}

public struct AgeBandLessonContent: Codable, Equatable, Sendable {
    public let discoveryText: String
    public let readAloudText: String?
    public let quiz: QuizContent

    public init(discoveryText: String, readAloudText: String? = nil, quiz: QuizContent) {
        self.discoveryText = discoveryText
        self.readAloudText = readAloudText
        self.quiz = quiz
    }
}

public struct AgeBandContentSet: Codable, Equatable, Sendable {
    public let ages4To6: AgeBandLessonContent
    public let ages7To9: AgeBandLessonContent
    public let ages10To12: AgeBandLessonContent

    public init(
        ages4To6: AgeBandLessonContent,
        ages7To9: AgeBandLessonContent,
        ages10To12: AgeBandLessonContent
    ) {
        self.ages4To6 = ages4To6
        self.ages7To9 = ages7To9
        self.ages10To12 = ages10To12
    }

    public subscript(ageBand: AgeBand) -> AgeBandLessonContent {
        switch ageBand {
        case .ages4To6:
            ages4To6
        case .ages7To9:
            ages7To9
        case .ages10To12:
            ages10To12
        }
    }
}

public struct LearningSource: Codable, Equatable, Sendable {
    public let title: String
    public let url: URL
    public let reviewStatus: String

    public init(title: String, url: URL, reviewStatus: String) {
        self.title = title
        self.url = url
        self.reviewStatus = reviewStatus
    }
}

public struct DestinationLesson: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let kind: String
    public let source: LearningSource
    public let content: AgeBandContentSet

    public init(
        id: String,
        displayName: String,
        kind: String,
        source: LearningSource,
        content: AgeBandContentSet
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.source = source
        self.content = content
    }
}
