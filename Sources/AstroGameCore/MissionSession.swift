import Foundation
import Observation

public enum MissionPhase: String, Codable, Sendable {
    case missionPrompt
    case navigation
    case discoveryCard
    case quiz
    case quizFeedback
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

    public var ageBand: AgeBand {
        get { progress.selectedAgeBand }
        set {
            progress.selectedAgeBand = newValue
            focusedQuizChoiceIndex = 0
            isShowingHint = false
        }
    }

    public var focusedLesson: DestinationLesson? {
        guard lessons.indices.contains(focusedDestinationIndex) else { return nil }
        return lessons[focusedDestinationIndex]
    }

    public var focusedContent: AgeBandLessonContent? {
        focusedLesson?.content[ageBand]
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
        progress: GameProgress? = nil
    ) {
        self.missionID = missionID
        self.lessons = lessons
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

        for lesson in lessons where self.progress.destinations[lesson.id] == nil {
            self.progress.destinations[lesson.id] = DestinationProgress()
        }
    }

    public func focusNext() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz {
            moveQuizFocus(by: 1)
            return
        }
        focusedDestinationIndex = (focusedDestinationIndex + 1) % lessons.count
        resetTransientState()
    }

    public func focusPrevious() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz {
            moveQuizFocus(by: -1)
            return
        }
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
            focusedQuizChoiceIndex = 0
            phase = .quiz
        case .quiz:
            submitAnswer(at: focusedQuizChoiceIndex, now: now)
        case .quizFeedback:
            if wasLastAnswerCorrect {
                phase = isMissionComplete ? .missionComplete : .navigation
            } else {
                phase = .quiz
            }
        case .missionComplete:
            phase = .navigation
        }
    }

    public func back() {
        isShowingHint = false
        switch phase {
        case .quiz:
            phase = .discoveryCard
        case .discoveryCard, .quizFeedback:
            phase = .navigation
        default:
            break
        }
    }

    public func requestHint() {
        isShowingHint = true
    }

    public func moveQuizFocus(by direction: Int) {
        guard phase == .quiz, let choices = focusedContent?.quiz.choices, !choices.isEmpty
        else {
            return
        }

        focusedQuizChoiceIndex =
            (focusedQuizChoiceIndex + direction + choices.count) % choices.count
    }

    public func submitAnswer(at choiceIndex: Int, now: Date = Date()) {
        guard
            let lesson = focusedLesson,
            let quiz = focusedContent?.quiz,
            quiz.choices.indices.contains(choiceIndex)
        else {
            return
        }

        var destinationProgress = progress.destinations[lesson.id] ?? DestinationProgress()
        destinationProgress.attempts += 1

        let isCorrect = quiz.choices[choiceIndex].id == quiz.correctChoiceID
        wasLastAnswerCorrect = isCorrect
        lastFeedback = isCorrect ? quiz.correctFeedback : quiz.retryFeedback
        phase = .quizFeedback

        destinationProgress.isQuizCompleted =
            destinationProgress.isQuizCompleted || isCorrect
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
}
