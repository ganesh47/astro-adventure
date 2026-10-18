import AstroContent
import AstroGameCore
import Foundation
import XCTest

/// Real catalog questions loaded through the existing durable-progress test seam.
/// No copied question text, fabricated artwork or correctness-based picture selection.
struct ReviewedScientificQuestionFixture {
    let name: String
    let quiz: QuizContent
    let identifierPrefix: String
    let progressJSON: String

    static func reviewedQuestions() throws -> [Self] {
        let missions = try PlanetMissionCatalog.bundled()
        let videos = try VideoLessonCatalog.bundled()
        var fixtures: [Self] = []
        for (id, questionIndex, band) in [
            ("saturn-ring-builder", 1, AgeBand.ages4To6),
            ("saturn-ring-builder", 1, AgeBand.ages7To9),
            ("earth-season-tracker", 0, AgeBand.ages4To6),
            ("earth-season-tracker", 0, AgeBand.ages7To9),
            ("earth-season-tracker", 2, AgeBand.ages7To9),
            ("saturn-two-moon-mysteries", 0, AgeBand.ages7To9),
            ("uranus-sideways-seasons", 1, AgeBand.ages7To9),
            ("neptune-tritons-backward-orbit", 1, AgeBand.ages7To9),
            ("mars-ancient-water-detective", 1, AgeBand.ages7To9),
        ] {
            let mission = try XCTUnwrap(missions.first { $0.id == id }, id)
            XCTAssertTrue(mission.questions.indices.contains(questionIndex))
            let question = mission.questions[questionIndex]
            var cursor = AdventureRunCursor(
                kind: .planetMission, contentID: mission.id,
                destinationID: mission.destinationID, revision: mission.revision,
                ageBand: band, phase: .missionQuestion, stepID: question.id)
            cursor.questionIndex = questionIndex
            cursor.cardIndex = min(questionIndex, mission.cards.count - 1)
            fixtures.append(
                try fixture(
                    name: "\(id) Q\(questionIndex + 1) \(band.rawValue)",
                    quiz: question.content[band], prefix: "quiz",
                    progress: GameProgress(selectedAgeBand: band, activeRun: cursor)))
        }

        let mars = try XCTUnwrap(videos.first { $0.id == "mars-video" })
        let checkpoint = try XCTUnwrap(mars.checkpoints.first)
        let band = AgeBand.ages7To9
        var videoCursor = AdventureRunCursor(
            kind: .video, contentID: mars.id, destinationID: mars.destinationID,
            revision: mars.revision, ageBand: band, phase: .videoCheckpoint,
            stepID: checkpoint.id)
        videoCursor.videoSeconds = checkpoint.time
        fixtures.append(
            try fixture(
                name: "Mars red liquid ocean ages7To9", quiz: checkpoint.question.content[band],
                prefix: "video",
                progress: GameProgress(selectedAgeBand: band, activeRun: videoCursor)))

        let dsn = try XCTUnwrap(
            QuizRoundCatalog.quizzes(destinationID: "space-technology-lab", ageBand: band)
                .first { $0.choices.contains { $0.text == "To stay in touch as Earth rotates" } })
        let bonus = BonusQuizRunCursor(
            destinationID: "space-technology-lab", ageBand: band, questions: [dsn])
        XCTAssertTrue(bonus.isValid)
        fixtures.append(
            try fixture(
                name: "DSN axial rotation ages7To9", quiz: dsn, prefix: "quiz",
                progress: GameProgress(selectedAgeBand: band, bonusQuizRun: bonus)))
        return fixtures
    }

    private static func fixture(
        name: String, quiz: QuizContent, prefix: String, progress: GameProgress
    ) throws -> Self {
        XCTAssertTrue(quiz.choices.allSatisfy { $0.picture != nil }, name)
        let bytes = try JSONEncoder().encode(progress)
        return Self(
            name: name, quiz: quiz, identifierPrefix: prefix,
            progressJSON: try XCTUnwrap(String(data: bytes, encoding: .utf8)))
    }
}
