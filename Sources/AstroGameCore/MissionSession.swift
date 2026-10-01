import Foundation
import Observation

public enum MissionPhase: String, Codable, Sendable {
    case missionPrompt
    case navigation
    case discoveryCard
    case quiz
    case quizFeedback
    case quizRoundComplete
    case missionComplete
}

@Observable
public final class MissionSession {
    public let missionID: String
    public let lessons: [DestinationLesson]

    public private(set) var phase: MissionPhase
    public private(set) var focusedDestinationIndex: Int
    public private(set) var focusedQuizChoiceIndex: Int
    public private(set) var isShowingHint: Bool
    public private(set) var wasLastAnswerCorrect: Bool
    public private(set) var lastFeedback: String
    public private(set) var progress: GameProgress
    public private(set) var quizQuestionIndex: Int
    public private(set) var roundScore: Int
    public private(set) var roundCorrectAnswers: Int
    public private(set) var currentStreak: Int
    public private(set) var roundBestStreak: Int
    public private(set) var questionAttemptCount: Int

    public private(set) var activeRoundAgeBand: AgeBand?
    private var activeRoundQuestions: [QuizContent] = []
    private var hasFinishedRound = false

    private let quizProvider: (String, AgeBand) -> [QuizContent]

    public var ageBand: AgeBand {
        get { progress.selectedAgeBand }
        set {
            guard !isRoundInProgress else { return }
            progress.selectedAgeBand = newValue
            focusedQuizChoiceIndex = 0
            isShowingHint = false
        }
    }

    public var isRoundInProgress: Bool {
        phase == .quiz || phase == .quizFeedback || phase == .quizRoundComplete
    }

    public var suggestedDestinationIndex: Int? {
        guard !lessons.isEmpty else { return nil }
        return (1...lessons.count).map {
            (focusedDestinationIndex + $0) % lessons.count
        }.first { progress.destinations[lessons[$0].id]?.isQuizCompleted != true }
    }

    public func exploreNextDestination() {
        guard phase == .navigation || phase == .quizRoundComplete else { return }
        if let next = suggestedDestinationIndex {
            focusedDestinationIndex = next
        }
        phase = isMissionComplete ? .missionComplete : .navigation
        resetTransientState()
    }

    public var focusedLesson: DestinationLesson? {
        guard lessons.indices.contains(focusedDestinationIndex) else { return nil }
        return lessons[focusedDestinationIndex]
    }

    public var focusedContent: AgeBandLessonContent? {
        focusedLesson?.content[ageBand]
    }

    public var quizQuestions: [QuizContent] {
        if isRoundInProgress { return activeRoundQuestions }
        guard let lesson = focusedLesson else { return [] }
        let provided = quizProvider(lesson.id, ageBand)
        return provided.isEmpty ? [lesson.content[ageBand].quiz] : provided
    }

    public var currentQuiz: QuizContent? {
        let questions = quizQuestions
        guard questions.indices.contains(quizQuestionIndex) else { return nil }
        return questions[quizQuestionIndex]
    }

    public var quizProgressText: String {
        "Question \(min(quizQuestionIndex + 1, quizQuestions.count)) of \(quizQuestions.count)"
    }

    public var roundStars: Int {
        // Every completed discovery earns the same celebration, with unlimited help.
        hasFinishedRound ? 3 : 0
    }

    public var completedDestinationCount: Int {
        lessons.count { progress.destinations[$0.id]?.isQuizCompleted == true }
    }

    public var isMissionComplete: Bool {
        !lessons.isEmpty && completedDestinationCount == lessons.count
    }

    public init(
        missionID: String = "signal-sweep",
        lessons: [DestinationLesson],
        progress: GameProgress? = nil,
        quizProvider: @escaping (String, AgeBand) -> [QuizContent] = { _, _ in [] }
    ) {
        self.missionID = missionID
        self.lessons = lessons
        self.quizProvider = quizProvider
        self.progress =
            progress
            ?? GameProgress(
                missionID: missionID,
                destinations: Dictionary(
                    uniqueKeysWithValues: lessons.map { ($0.id, DestinationProgress()) }
                )
            )
        self.phase = .missionPrompt
        self.focusedDestinationIndex = 0
        self.focusedQuizChoiceIndex = 0
        self.isShowingHint = false
        self.wasLastAnswerCorrect = false
        self.lastFeedback = ""
        self.quizQuestionIndex = 0
        self.roundScore = 0
        self.roundCorrectAnswers = 0
        self.currentStreak = 0
        self.roundBestStreak = 0
        self.questionAttemptCount = 0

        for lesson in lessons where self.progress.destinations[lesson.id] == nil {
            self.progress.destinations[lesson.id] = DestinationProgress()
        }
    }

    public func selectDestination(at index: Int) {
        guard phase == .navigation || phase == .missionPrompt,
            lessons.indices.contains(index)
        else { return }
        focusedDestinationIndex = index
        resetTransientState()
    }

    public func focusNext() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz {
            moveQuizFocus(by: 1)
            return
        }
        guard phase == .navigation || phase == .missionPrompt else { return }
        focusedDestinationIndex = (focusedDestinationIndex + 1) % lessons.count
        resetTransientState()
    }

    public func focusPrevious() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz {
            moveQuizFocus(by: -1)
            return
        }
        guard phase == .navigation || phase == .missionPrompt else { return }
        focusedDestinationIndex =
            (focusedDestinationIndex - 1 + lessons.count) % lessons.count
        resetTransientState()
    }

    public func confirm(now: Date = Date()) {
        guard let lesson = focusedLesson else { return }
        isShowingHint = false

        switch phase {
        case .missionPrompt:
            phase = .navigation
        case .navigation:
            markScanned(destinationID: lesson.id)
            phase = .discoveryCard
        case .discoveryCard:
            beginQuizRound()
            phase = .quiz
        case .quiz:
            submitAnswer(at: focusedQuizChoiceIndex, now: now)
        case .quizFeedback:
            if wasLastAnswerCorrect {
                if quizQuestionIndex + 1 < quizQuestions.count {
                    quizQuestionIndex += 1
                    focusedQuizChoiceIndex = 0
                    questionAttemptCount = 0
                    phase = .quiz
                } else {
                    phase = .quizRoundComplete
                }
            } else {
                phase = .quiz
            }
        case .quizRoundComplete:
            exploreNextDestination()
        case .missionComplete:
            phase = .navigation
        }
    }

    public func back() {
        isShowingHint = false
        switch phase {
        case .navigation:
            phase = .missionPrompt
        case .quiz:
            phase = .discoveryCard
        case .discoveryCard, .quizFeedback, .quizRoundComplete, .missionComplete:
            phase = .navigation
        default:
            break
        }
    }

    public func returnToWorlds() {
        phase = .navigation
        resetTransientState()
    }

    public func requestHint() {
        guard phase == .quiz else { return }
        isShowingHint = true
    }

    public func moveQuizFocus(by direction: Int) {
        guard phase == .quiz, let choices = currentQuiz?.choices, !choices.isEmpty
        else {
            return
        }

        focusedQuizChoiceIndex =
            (focusedQuizChoiceIndex + direction + choices.count) % choices.count
    }

    public func submitAnswer(at choiceIndex: Int, now: Date = Date()) {
        guard
            phase == .quiz,
            let lesson = focusedLesson,
            let quiz = currentQuiz,
            quiz.choices.indices.contains(choiceIndex)
        else {
            return
        }

        var destinationProgress = progress.destinations[lesson.id] ?? DestinationProgress()
        destinationProgress.attempts += 1
        questionAttemptCount += 1

        let isCorrect = quiz.choices[choiceIndex].id == quiz.correctChoiceID
        wasLastAnswerCorrect = isCorrect
        lastFeedback = isCorrect ? quiz.correctFeedback : quiz.retryFeedback
        phase = .quizFeedback

        if isCorrect {
            roundCorrectAnswers += 1
            roundScore += 100
        }

        destinationProgress.isQuizCompleted =
            destinationProgress.isQuizCompleted
            || (isCorrect && quizQuestionIndex == quizQuestions.count - 1)
        destinationProgress.correctAnswers += isCorrect ? 1 : 0
        destinationProgress.masteryScore = min(
            max(
                destinationProgress.masteryScore
                    + LearningEngine.masteryDelta(
                        answeredCorrectly: isCorrect,
                        attempts: destinationProgress.attempts
                    ),
                0
            ),
            100
        )
        destinationProgress.reviewBox = LearningEngine.nextReviewBox(
            current: destinationProgress.reviewBox,
            answeredCorrectly: isCorrect
        )
        let delay = LearningEngine.reviewDelayDays(for: destinationProgress.reviewBox)
        destinationProgress.nextReviewAt = now.addingTimeInterval(
            TimeInterval(delay * 24 * 60 * 60)
        )
        progress.destinations[lesson.id] = destinationProgress
        if isCorrect && quizQuestionIndex == activeRoundQuestions.count - 1 {
            finishQuizRound(now: now)
        }
    }

    private func markScanned(destinationID: String) {
        var destinationProgress =
            progress.destinations[destinationID] ?? DestinationProgress()
        destinationProgress.isScanned = true
        progress.destinations[destinationID] = destinationProgress
    }

    private func resetTransientState() {
        focusedQuizChoiceIndex = 0
        isShowingHint = false
    }

    private func beginQuizRound() {
        activeRoundAgeBand = ageBand
        activeRoundQuestions = quizQuestions
        hasFinishedRound = false
        quizQuestionIndex = 0
        focusedQuizChoiceIndex = 0
        roundScore = 0
        roundCorrectAnswers = 0
        currentStreak = 0
        roundBestStreak = 0
        questionAttemptCount = 0
        isShowingHint = false
    }

    private func finishQuizRound(now: Date) {
        guard !hasFinishedRound, let lesson = focusedLesson else { return }
        hasFinishedRound = true
        var destinationProgress = progress.destinations[lesson.id] ?? DestinationProgress()
        destinationProgress.bestRoundScore = max(destinationProgress.bestRoundScore, roundScore)
        destinationProgress.bestRoundStars = max(destinationProgress.bestRoundStars, roundStars)
        progress.destinations[lesson.id] = destinationProgress
        progress.totalScore += roundScore
        progress.bestStreak = max(progress.bestStreak, roundBestStreak)
        progress.leaderboard.append(
            LeaderboardEntry(
                explorerName: (activeRoundAgeBand ?? ageBand).modeName,
                destinationName: lesson.displayName,
                score: roundScore,
                correctAnswers: roundCorrectAnswers,
                totalQuestions: quizQuestions.count,
                bestStreak: roundBestStreak,
                achievedAt: now
            )
        )
        progress.leaderboard = Array(
            progress.leaderboard.sorted { $0.achievedAt > $1.achievedAt }.prefix(20)
        )
    }
}
