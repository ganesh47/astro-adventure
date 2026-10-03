import Foundation
import XCTest

@testable import AstroGameCore

final class MissionSessionTests: XCTestCase {
    func testMissionMovesFromPromptThroughCorrectQuiz() {
        let session = MissionSession(lessons: [Self.lesson])

        XCTAssertEqual(session.phase, .missionPrompt)
        session.confirm()
        XCTAssertEqual(session.phase, .navigation)
        session.confirm()
        XCTAssertEqual(session.phase, .discoveryCard)
        XCTAssertTrue(session.progress.destinations["mercury"]?.isScanned == true)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)

        session.submitAnswer(at: 0, now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(session.phase, .quizFeedback)
        XCTAssertTrue(session.wasLastAnswerCorrect)
        XCTAssertTrue(session.isMissionComplete)
        session.confirm()
        XCTAssertEqual(session.phase, .quizRoundComplete)
        XCTAssertEqual(session.roundScore, 100)
        XCTAssertEqual(session.progress.leaderboard.count, 1)
        session.confirm()
        XCTAssertEqual(session.phase, .missionComplete)
    }

    func testRetryDoesNotEraseScanProgress() {
        let session = MissionSession(lessons: [Self.lesson])
        session.confirm()
        session.confirm()
        session.confirm()
        session.submitAnswer(at: 1)

        XCTAssertFalse(session.wasLastAnswerCorrect)
        XCTAssertTrue(session.progress.destinations["mercury"]?.isScanned == true)
        XCTAssertFalse(session.progress.destinations["mercury"]?.isQuizCompleted == true)
        session.confirm()
        XCTAssertEqual(session.phase, .quiz)
    }

    func testBackFromWorldSelectionReturnsToWelcomeScreen() {
        let session = MissionSession(lessons: [Self.lesson])

        session.confirm()
        XCTAssertEqual(session.phase, .navigation)

        session.back()
        XCTAssertEqual(session.phase, .missionPrompt)
    }

    func testChangingAgeBandSelectsAgeSpecificContent() {
        let session = MissionSession(lessons: [Self.lesson])
        session.ageBand = .ages4To6
        XCTAssertEqual(session.focusedContent?.quiz.choices.count, 2)
        session.ageBand = .ages10To12
        XCTAssertEqual(session.focusedContent?.quiz.choices.count, 3)
    }

    func testThreeQuestionRoundGivesEqualDiscoveryPoints() {
        let quizzes = [
            Self.lesson.content.ages7To9.quiz, Self.lesson.content.ages7To9.quiz,
            Self.lesson.content.ages7To9.quiz,
        ]
        let session = MissionSession(
            lessons: [Self.lesson],
            quizProvider: { _, _ in quizzes }
        )
        session.confirm()
        session.confirm()
        session.confirm()

        for question in 0..<3 {
            XCTAssertEqual(session.quizQuestionIndex, question)
            session.submitAnswer(at: 0, now: Date(timeIntervalSince1970: 10))
            session.confirm(now: Date(timeIntervalSince1970: 10))
        }

        XCTAssertEqual(session.phase, .quizRoundComplete)
        XCTAssertEqual(session.roundCorrectAnswers, 3)
        XCTAssertEqual(session.roundBestStreak, 0)
        XCTAssertEqual(session.roundScore, 300)
        XCTAssertEqual(session.roundStars, 3)
        XCTAssertEqual(session.progress.leaderboard.first?.score, 300)
        XCTAssertEqual(session.progress.destinations["mercury"]?.bestRoundStars, 3)
    }

    func testFinalAnswerSavesRewardsBeforeContinueAndBackKeepsThem() {
        let session = Self.startedSession()
        let earnedAt = Date(timeIntervalSince1970: 10)
        session.submitAnswer(at: 0, now: earnedAt)

        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.progress.destinations["mercury"]?.bestRoundStars, 3)
        XCTAssertEqual(session.progress.leaderboard.first?.achievedAt, earnedAt)
        session.back()
        XCTAssertEqual(session.phase, .navigation)
        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.progress.leaderboard.count, 1)
    }

    func testDuplicateAnswerAndContinueDoNotDuplicateRewards() {
        let session = Self.startedSession()
        session.submitAnswer(at: 0)
        session.submitAnswer(at: 0)
        session.confirm()
        session.submitAnswer(at: 0)
        session.confirm()

        XCTAssertEqual(session.progress.totalScore, 100)
        XCTAssertEqual(session.progress.leaderboard.count, 1)
        XCTAssertEqual(session.progress.destinations["mercury"]?.attempts, 1)
        XCTAssertEqual(session.roundCorrectAnswers, 1)
    }

    func testHintsAndRetriesEarnSameRewardAsFirstTry() {
        let firstTry = Self.startedSession()
        firstTry.submitAnswer(at: 0)
        let helped = Self.startedSession()
        helped.requestHint()
        helped.submitAnswer(at: 1)
        helped.confirm()
        helped.requestHint()
        helped.submitAnswer(at: 0)

        XCTAssertEqual(helped.roundScore, firstTry.roundScore)
        XCTAssertEqual(helped.roundStars, firstTry.roundStars)
        XCTAssertEqual(helped.progress.totalScore, firstTry.progress.totalScore)
        XCTAssertEqual(helped.currentStreak, 0)
        XCTAssertEqual(helped.roundBestStreak, 0)
    }

    func testRoundLocksModeAndQuestionSetUntilReturningToWorlds() {
        let session = MissionSession(
            lessons: [Self.lesson],
            quizProvider: { _, band in
                Array(repeating: Self.lesson.content[band].quiz, count: band == .ages4To6 ? 1 : 2)
            }
        )
        session.ageBand = .ages4To6
        session.confirm()
        session.confirm()
        session.confirm()
        session.ageBand = .ages10To12
        XCTAssertEqual(session.ageBand, .ages4To6)
        XCTAssertEqual(session.activeRoundAgeBand, .ages4To6)
        XCTAssertEqual(session.quizQuestions.count, 1)
        session.submitAnswer(at: 0)
        session.ageBand = .ages10To12
        XCTAssertEqual(session.progress.leaderboard.first?.explorerName, AgeBand.ages4To6.modeName)
        XCTAssertEqual(session.quizQuestions.count, 1)
        session.returnToWorlds()
        session.ageBand = .ages10To12
        XCTAssertEqual(session.ageBand, .ages10To12)
        XCTAssertEqual(session.quizQuestions.count, 2)
    }

    func testInvalidActionsCannotChangeProgressOrDestination() {
        let session = MissionSession(lessons: [Self.lesson, Self.secondLesson])
        session.submitAnswer(at: 0)
        session.requestHint()
        XCTAssertFalse(session.isShowingHint)
        XCTAssertEqual(session.progress.destinations["mercury"]?.attempts, 0)
        session.confirm()
        session.confirm()
        session.confirm()
        session.submitAnswer(at: -1)
        session.submitAnswer(at: 100)
        XCTAssertEqual(session.phase, .quiz)
        XCTAssertEqual(session.progress.destinations["mercury"]?.attempts, 0)
        session.submitAnswer(at: 0)
        session.focusNext()
        session.focusPrevious()
        XCTAssertEqual(session.focusedLesson?.id, "mercury")
        XCTAssertEqual(session.progress.totalScore, 100)
    }

    func testWorldVisitSuspendsIncompleteRoundWithoutLosingAnswers() {
        let session = Self.startedSession(questionCount: 2)
        session.submitAnswer(at: 0)
        session.confirm()
        session.returnToWorlds()
        XCTAssertEqual(session.phase, .navigation)
        XCTAssertEqual(session.progress.destinations["mercury"]?.correctAnswers, 1)
        XCTAssertEqual(session.progress.totalScore, 0)
        XCTAssertFalse(session.isMissionComplete)
        session.confirm()
        session.confirm()
        XCTAssertEqual(session.quizQuestionIndex, 1)
        XCTAssertEqual(session.roundScore, 100)
        XCTAssertEqual(session.roundCorrectAnswers, 1)
        XCTAssertEqual(session.roundStars, 0)
    }

    func testRoundCompletionSuggestsNextUncompletedWorld() {
        let session = MissionSession(lessons: [Self.lesson, Self.secondLesson])
        session.confirm()
        session.confirm()
        session.confirm()
        session.submitAnswer(at: 0)
        session.confirm()
        XCTAssertEqual(session.suggestedDestinationIndex, 1)
        session.exploreNextDestination()
        XCTAssertEqual(session.phase, .navigation)
        XCTAssertEqual(session.focusedLesson?.id, "mars")
        session.confirm()
        session.confirm()
        session.submitAnswer(at: 0)
        session.confirm()
        session.confirm()
        XCTAssertEqual(session.phase, .missionComplete)
        XCTAssertNil(session.suggestedDestinationIndex)
        session.back()
        XCTAssertEqual(session.phase, .navigation)
        XCTAssertEqual(session.progress.totalScore, 200)
    }

    func testDestinationSelectionIgnoresStaleFocusDuringRound() {
        let session = MissionSession(lessons: [Self.lesson, Self.secondLesson])
        session.selectDestination(at: 1)
        XCTAssertEqual(session.focusedLesson?.id, "mars")
        session.selectDestination(at: -1)
        session.selectDestination(at: 2)
        XCTAssertEqual(session.focusedLesson?.id, "mars")
        session.confirm()
        session.confirm()
        session.selectDestination(at: 0)
        XCTAssertEqual(session.focusedLesson?.id, "mars")
        session.confirm()
        session.selectDestination(at: 0)
        session.submitAnswer(at: 0)
        session.selectDestination(at: 0)
        session.confirm()
        session.selectDestination(at: 0)
        XCTAssertEqual(session.focusedLesson?.id, "mars")
        XCTAssertEqual(session.progress.destinations["mars"]?.bestRoundScore, 100)
        XCTAssertEqual(session.progress.destinations["mercury"]?.bestRoundScore, 0)
        session.returnToWorlds()
        session.selectDestination(at: 0)
        XCTAssertEqual(session.focusedLesson?.id, "mercury")
    }

    func testEmptyMissionIsSafe() {
        let session = MissionSession(lessons: [])
        session.confirm()
        session.focusNext()
        session.focusPrevious()
        session.submitAnswer(at: 0)
        XCTAssertNil(session.currentQuiz)
        XCTAssertNil(session.suggestedDestinationIndex)
        XCTAssertFalse(session.isMissionComplete)
        XCTAssertEqual(session.progress.totalScore, 0)
    }

    private static func startedSession(questionCount: Int = 1) -> MissionSession {
        let session = MissionSession(
            lessons: [lesson],
            quizProvider: { _, band in
                Array(repeating: lesson.content[band].quiz, count: questionCount)
            }
        )
        session.confirm()
        session.confirm()
        session.confirm()
        return session
    }

    private static var secondLesson: DestinationLesson {
        DestinationLesson(
            id: "mars",
            displayName: "Mars",
            kind: lesson.kind,
            source: lesson.source,
            content: lesson.content
        )
    }

    private static let lesson: DestinationLesson = {
        let juniorQuiz = QuizContent(
            prompt: "Which one is Mercury?",
            choices: [
                QuizChoice(id: "sun", text: "The world near the Sun"),
                QuizChoice(id: "ice", text: "The icy moon"),
            ],
            correctChoiceID: "sun",
            correctFeedback: "You found it!",
            retryFeedback: "Try the Sun clue.",
            hint: "Look near the Sun."
        )
        let advancedQuiz = QuizContent(
            prompt: "Which clue identifies Mercury?",
            choices: [
                QuizChoice(id: "sun", text: "Closest to the Sun"),
                QuizChoice(id: "rust", text: "Rusty dust"),
                QuizChoice(id: "ice", text: "Icy moon"),
            ],
            correctChoiceID: "sun",
            correctFeedback: "Correct.",
            retryFeedback: "Try again.",
            hint: "Look at its orbit."
        )
        let source = LearningSource(
            title: "NASA Mercury",
            url: URL(string: "https://science.nasa.gov/mercury/")!,
            reviewStatus: "reviewed"
        )
        return DestinationLesson(
            id: "mercury",
            displayName: "Mercury",
            kind: "planet",
            source: source,
            content: AgeBandContentSet(
                ages4To6: AgeBandLessonContent(
                    discoveryText: "Mercury is close to the Sun.",
                    quiz: juniorQuiz
                ),
                ages7To9: AgeBandLessonContent(
                    discoveryText: "Mercury is the closest planet to the Sun.",
                    quiz: advancedQuiz
                ),
                ages10To12: AgeBandLessonContent(
                    discoveryText: "Mercury is the innermost planet.",
                    quiz: advancedQuiz
                )
            )
        )
    }()
}
