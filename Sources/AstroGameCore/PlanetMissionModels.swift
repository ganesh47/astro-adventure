import Foundation

/// Copy is authored separately for each Explorer Mode, rather than just removing a choice.
public struct AgeBandText: Codable, Equatable, Sendable {
    public let ages4To6: String
    public let ages7To9: String
    public let ages10To12: String

    public init(ages4To6: String, ages7To9: String, ages10To12: String) {
        self.ages4To6 = ages4To6
        self.ages7To9 = ages7To9
        self.ages10To12 = ages10To12
    }

    public subscript(_ ageBand: AgeBand) -> String {
        switch ageBand {
        case .ages4To6: ages4To6
        case .ages7To9: ages7To9
        case .ages10To12: ages10To12
        }
    }
}

public struct AgeBandQuizSet: Codable, Equatable, Sendable {
    public let ages4To6: QuizContent
    public let ages7To9: QuizContent
    public let ages10To12: QuizContent

    public init(ages4To6: QuizContent, ages7To9: QuizContent, ages10To12: QuizContent) {
        self.ages4To6 = ages4To6
        self.ages7To9 = ages7To9
        self.ages10To12 = ages10To12
    }

    public subscript(_ ageBand: AgeBand) -> QuizContent {
        switch ageBand {
        case .ages4To6: ages4To6
        case .ages7To9: ages7To9
        case .ages10To12: ages10To12
        }
    }
}

public struct MissionCard: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let conceptID: String
    public let title: String
    public let body: AgeBandText
    public let imageName: String
    public let imageCredit: String
    public let imageSourceID: String
    public let source: LearningSource

    public init(
        id: String, conceptID: String, title: String, body: AgeBandText,
        imageName: String, imageCredit: String, imageSourceID: String, source: LearningSource
    ) {
        self.id = id
        self.conceptID = conceptID
        self.title = title
        self.body = body
        self.imageName = imageName
        self.imageCredit = imageCredit
        self.imageSourceID = imageSourceID
        self.source = source
    }
}

public struct LearningQuestion: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let conceptID: String
    public let source: LearningSource
    public let content: AgeBandQuizSet
    public let reviewContent: AgeBandQuizSet

    public init(
        id: String, conceptID: String, source: LearningSource,
        content: AgeBandQuizSet, reviewContent: AgeBandQuizSet
    ) {
        self.id = id
        self.conceptID = conceptID
        self.source = source
        self.content = content
        self.reviewContent = reviewContent
    }
}

public enum ScienceActivityFamily: String, Codable, CaseIterable, Sendable {
    case evidence
    case classify
    case experiment
}

public struct ActivityOption: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: AgeBandText
    public let symbol: String
    public let outcome: AgeBandText

    public init(id: String, label: AgeBandText, symbol: String, outcome: AgeBandText) {
        self.id = id
        self.label = label
        self.symbol = symbol
        self.outcome = outcome
    }
}

/// Classification uses several item tasks; experiments expose each setting's outcome before checking it.
public struct ActivityTask: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let prompt: AgeBandText
    public let imageName: String
    public let options: [ActivityOption]
    public let correctOptionID: String
    public let hint: AgeBandText
    public let explanation: AgeBandText

    public init(
        id: String, prompt: AgeBandText, imageName: String, options: [ActivityOption],
        correctOptionID: String, hint: AgeBandText, explanation: AgeBandText
    ) {
        self.id = id
        self.prompt = prompt
        self.imageName = imageName
        self.options = options
        self.correctOptionID = correctOptionID
        self.hint = hint
        self.explanation = explanation
    }
}

public struct ScienceActivity: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let family: ScienceActivityFamily
    public let title: String
    public let conceptID: String
    public let tasks: [ActivityTask]

    public init(
        id: String, family: ScienceActivityFamily, title: String,
        conceptID: String, tasks: [ActivityTask]
    ) {
        self.id = id
        self.family = family
        self.title = title
        self.conceptID = conceptID
        self.tasks = tasks
    }
}

public struct PlanetMission: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let destinationID: String
    public let revision: Int
    public let title: String
    public let invitation: AgeBandText
    public let requiredConceptIDs: [String]
    public let cards: [MissionCard]
    public let questions: [LearningQuestion]
    public let activity: ScienceActivity
    public let deepDive: MissionCard

    public init(
        id: String, destinationID: String, revision: Int, title: String,
        invitation: AgeBandText, requiredConceptIDs: [String], cards: [MissionCard],
        questions: [LearningQuestion], activity: ScienceActivity, deepDive: MissionCard
    ) {
        self.id = id
        self.destinationID = destinationID
        self.revision = revision
        self.title = title
        self.invitation = invitation
        self.requiredConceptIDs = requiredConceptIDs
        self.cards = cards
        self.questions = questions
        self.activity = activity
        self.deepDive = deepDive
    }
}

public struct VideoSegment: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let startTime: Double
    public let endTime: Double
    public let narration: AgeBandText
    public let imageName: String

    public init(
        id: String, startTime: Double, endTime: Double, narration: AgeBandText, imageName: String
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.narration = narration
        self.imageName = imageName
    }
}

public struct VideoCheckpoint: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let time: Double
    public let replayStartTime: Double
    public let question: LearningQuestion

    public init(id: String, time: Double, replayStartTime: Double, question: LearningQuestion) {
        self.id = id
        self.time = time
        self.replayStartTime = replayStartTime
        self.question = question
    }
}

public struct VideoLesson: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let destinationID: String
    public let revision: Int
    public let title: String
    public let resourceName: String
    public let duration: Double
    public let credit: String
    public let source: LearningSource
    public let segments: [VideoSegment]
    public let checkpoints: [VideoCheckpoint]
    public let fallbackCards: [MissionCard]

    public init(
        id: String, destinationID: String, revision: Int, title: String,
        resourceName: String, duration: Double, credit: String, source: LearningSource,
        segments: [VideoSegment], checkpoints: [VideoCheckpoint], fallbackCards: [MissionCard]
    ) {
        self.id = id
        self.destinationID = destinationID
        self.revision = revision
        self.title = title
        self.resourceName = resourceName
        self.duration = duration
        self.credit = credit
        self.source = source
        self.segments = segments
        self.checkpoints = checkpoints
        self.fallbackCards = fallbackCards
    }
}
