import Foundation

public struct DestinationProgress: Codable, Equatable, Sendable {
    public var isScanned: Bool
    public var isQuizCompleted: Bool
    public var correctAnswers: Int
    public var attempts: Int
    public var masteryScore: Int
    public var reviewBox: Int
    public var nextReviewAt: Date?

    public init(
        isScanned: Bool = false,
        isQuizCompleted: Bool = false,
        correctAnswers: Int = 0,
        attempts: Int = 0,
        masteryScore: Int = 0,
        reviewBox: Int = 0,
        nextReviewAt: Date? = nil
    ) {
        self.isScanned = isScanned
        self.isQuizCompleted = isQuizCompleted
        self.correctAnswers = correctAnswers
        self.attempts = attempts
        self.masteryScore = masteryScore
        self.reviewBox = reviewBox
        self.nextReviewAt = nextReviewAt
    }
}

public struct GameProgress: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var missionID: String
    public var selectedAgeBand: AgeBand
    public var destinations: [String: DestinationProgress]

    public init(
        schemaVersion: Int = currentSchemaVersion,
        missionID: String = "signal-sweep",
        selectedAgeBand: AgeBand = .ages7To9,
        destinations: [String: DestinationProgress] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.missionID = missionID
        self.selectedAgeBand = selectedAgeBand
        self.destinations = destinations
    }
}
