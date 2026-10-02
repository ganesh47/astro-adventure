import Foundation

public struct DestinationProgress: Codable, Equatable, Sendable {
    public var isScanned: Bool
    public var isQuizCompleted: Bool
    public var correctAnswers: Int
    public var attempts: Int
    public var masteryScore: Int
    public var reviewBox: Int
    public var nextReviewAt: Date?
    public var bestRoundScore: Int
    public var bestRoundStars: Int

    public init(
        isScanned: Bool = false,
        isQuizCompleted: Bool = false,
        correctAnswers: Int = 0,
        attempts: Int = 0,
        masteryScore: Int = 0,
        reviewBox: Int = 0,
        nextReviewAt: Date? = nil,
        bestRoundScore: Int = 0,
        bestRoundStars: Int = 0
    ) {
        self.isScanned = isScanned
        self.isQuizCompleted = isQuizCompleted
        self.correctAnswers = correctAnswers
        self.attempts = attempts
        self.masteryScore = masteryScore
        self.reviewBox = reviewBox
        self.nextReviewAt = nextReviewAt
        self.bestRoundScore = bestRoundScore
        self.bestRoundStars = bestRoundStars
    }

    private enum CodingKeys: String, CodingKey {
        case isScanned, isQuizCompleted, correctAnswers, attempts, masteryScore
        case reviewBox, nextReviewAt, bestRoundScore, bestRoundStars
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isScanned = try values.decodeIfPresent(Bool.self, forKey: .isScanned) ?? false
        isQuizCompleted = try values.decodeIfPresent(Bool.self, forKey: .isQuizCompleted) ?? false
        correctAnswers = try values.decodeIfPresent(Int.self, forKey: .correctAnswers) ?? 0
        attempts = try values.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        masteryScore = try values.decodeIfPresent(Int.self, forKey: .masteryScore) ?? 0
        reviewBox = try values.decodeIfPresent(Int.self, forKey: .reviewBox) ?? 0
        nextReviewAt = try values.decodeIfPresent(Date.self, forKey: .nextReviewAt)
        bestRoundScore = try values.decodeIfPresent(Int.self, forKey: .bestRoundScore) ?? 0
        bestRoundStars = try values.decodeIfPresent(Int.self, forKey: .bestRoundStars) ?? 0
    }
}

public struct LeaderboardEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let explorerName: String
    public let destinationName: String
    public let score: Int
    public let correctAnswers: Int
    public let totalQuestions: Int
    public let bestStreak: Int
    public let achievedAt: Date

    public init(
        id: UUID = UUID(),
        explorerName: String,
        destinationName: String,
        score: Int,
        correctAnswers: Int,
        totalQuestions: Int,
        bestStreak: Int,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.explorerName = explorerName
        self.destinationName = destinationName
        self.score = score
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.bestStreak = bestStreak
        self.achievedAt = achievedAt
    }
}

public struct MissionCompletion: Codable, Equatable, Sendable {
    public let completedAt: Date
    public let ageBand: AgeBand

    public init(completedAt: Date, ageBand: AgeBand) {
        self.completedAt = completedAt
        self.ageBand = ageBand
    }
}

public struct ConceptProgress: Codable, Equatable, Sendable {
    public let conceptID: String
    public let ageBand: AgeBand
    public var reviewBox: Int
    public var lastPracticedAt: Date
    public var nextReviewAt: Date

    public init(
        conceptID: String, ageBand: AgeBand, reviewBox: Int,
        lastPracticedAt: Date, nextReviewAt: Date
    ) {
        self.conceptID = conceptID
        self.ageBand = ageBand
        self.reviewBox = reviewBox
        self.lastPracticedAt = lastPracticedAt
        self.nextReviewAt = nextReviewAt
    }

    public static func key(conceptID: String, ageBand: AgeBand) -> String {
        "\(ageBand.rawValue):\(conceptID)"
    }
}

public enum AdventureRunKind: String, Codable, Sendable {
    case planetMission
    case video
    case review
}

/// One bounded resume record. Player objects and playback tick histories are never persisted.
public struct AdventureRunCursor: Codable, Equatable, Sendable {
    public var kind: AdventureRunKind
    public var contentID: String
    public var destinationID: String
    public var revision: Int
    public var ageBand: AgeBand
    public var phase: MissionPhase
    public var stepID: String
    public var cardIndex: Int = 0
    public var questionIndex: Int = 0
    public var activityTaskIndex: Int = 0
    public var selectedActivityOptionID: String?
    public var completedQuestionIDs: Set<String> = []
    public var completedActivityTaskIDs: Set<String> = []
    public var completedCheckpointIDs: Set<String> = []
    public var reviewQuestionIDs: [String] = []
    public var assistedConceptIDs: Set<String> = []
    public var videoSeconds: Double = 0
    public var isVideoFallback: Bool = false
    public var questionAttemptCount: Int = 0
    public var isShowingHint: Bool = false
    public var feedbackWasCorrect: Bool = false
    public var feedbackText: String = ""

    public init(
        kind: AdventureRunKind, contentID: String, destinationID: String,
        revision: Int, ageBand: AgeBand, phase: MissionPhase, stepID: String = ""
    ) {
        self.kind = kind
        self.contentID = contentID
        self.destinationID = destinationID
        self.revision = revision
        self.ageBand = ageBand
        self.phase = phase
        self.stepID = stepID
    }
}

public struct GameProgress: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 3

    public var schemaVersion: Int
    public var missionID: String
    public var selectedAgeBand: AgeBand
    public var destinations: [String: DestinationProgress]
    public var totalScore: Int
    public var bestStreak: Int
    public var leaderboard: [LeaderboardEntry]
    public var missionCompletions: [String: MissionCompletion]
    public var videoCompletions: [String: MissionCompletion]
    public var concepts: [String: ConceptProgress]
    public var activeRun: AdventureRunCursor?

    public var completedMissionIDs: Set<String> { Set(missionCompletions.keys) }

    public init(
        schemaVersion: Int = currentSchemaVersion,
        missionID: String = "signal-sweep",
        selectedAgeBand: AgeBand = .ages7To9,
        destinations: [String: DestinationProgress] = [:],
        totalScore: Int = 0,
        bestStreak: Int = 0,
        leaderboard: [LeaderboardEntry] = [],
        missionCompletions: [String: MissionCompletion] = [:],
        videoCompletions: [String: MissionCompletion] = [:],
        concepts: [String: ConceptProgress] = [:],
        activeRun: AdventureRunCursor? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.missionID = missionID
        self.selectedAgeBand = selectedAgeBand
        self.destinations = destinations
        self.totalScore = totalScore
        self.bestStreak = bestStreak
        self.leaderboard = leaderboard
        self.missionCompletions = missionCompletions
        self.videoCompletions = videoCompletions
        self.concepts = concepts
        self.activeRun = activeRun
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, missionID, selectedAgeBand, destinations
        case totalScore, bestStreak, leaderboard
        case missionCompletions, videoCompletions, concepts, activeRun
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = Self.currentSchemaVersion
        missionID = try values.decodeIfPresent(String.self, forKey: .missionID) ?? "signal-sweep"
        selectedAgeBand =
            try values.decodeIfPresent(AgeBand.self, forKey: .selectedAgeBand) ?? .ages7To9
        destinations =
            try values.decodeIfPresent([String: DestinationProgress].self, forKey: .destinations)
            ?? [:]
        totalScore = try values.decodeIfPresent(Int.self, forKey: .totalScore) ?? 0
        bestStreak = try values.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        leaderboard =
            try values.decodeIfPresent([LeaderboardEntry].self, forKey: .leaderboard) ?? []
        missionCompletions =
            try values.decodeIfPresent(
                [String: MissionCompletion].self, forKey: .missionCompletions)
            ?? [:]
        videoCompletions =
            try values.decodeIfPresent([String: MissionCompletion].self, forKey: .videoCompletions)
            ?? [:]
        concepts =
            try values.decodeIfPresent([String: ConceptProgress].self, forKey: .concepts) ?? [:]
        activeRun = try values.decodeIfPresent(AdventureRunCursor.self, forKey: .activeRun)
    }
}
