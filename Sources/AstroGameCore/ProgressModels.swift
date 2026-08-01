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

public struct GameProgress: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var missionID: String
    public var selectedAgeBand: AgeBand
    public var destinations: [String: DestinationProgress]
    public var totalScore: Int
    public var bestStreak: Int
    public var leaderboard: [LeaderboardEntry]

    public init(
        schemaVersion: Int = currentSchemaVersion,
        missionID: String = "signal-sweep",
        selectedAgeBand: AgeBand = .ages7To9,
        destinations: [String: DestinationProgress] = [:],
        totalScore: Int = 0,
        bestStreak: Int = 0,
        leaderboard: [LeaderboardEntry] = []
    ) {
        self.schemaVersion = schemaVersion
        self.missionID = missionID
        self.selectedAgeBand = selectedAgeBand
        self.destinations = destinations
        self.totalScore = totalScore
        self.bestStreak = bestStreak
        self.leaderboard = leaderboard
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, missionID, selectedAgeBand, destinations
        case totalScore, bestStreak, leaderboard
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
    }
}
