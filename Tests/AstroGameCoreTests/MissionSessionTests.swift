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
        XCTAssertEqual(session.roundScore, 125)
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

    func testChangingAgeBandSelectsAgeSpecificContent() {
        let session = MissionSession(lessons: [Self.lesson])
        session.ageBand = .ages4To6
        XCTAssertEqual(session.focusedContent?.quiz.choices.count, 2)
        session.ageBand = .ages10To12
        XCTAssertEqual(session.focusedContent?.quiz.choices.count, 3)
    }

    func testThreeQuestionRoundTracksScoreStreakAndLeaderboard() {
        let quizzes = [Self.lesson.content.ages7To9.quiz, Self.lesson.content.ages7To9.quiz,
                       Self.lesson.content.ages7To9.quiz]
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
        XCTAssertEqual(session.roundBestStreak, 3)
        XCTAssertEqual(session.roundScore, 420)
        XCTAssertEqual(session.roundStars, 3)
        XCTAssertEqual(session.progress.leaderboard.first?.score, 420)
        XCTAssertEqual(session.progress.destinations["mercury"]?.bestRoundStars, 3)
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
