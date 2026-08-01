import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class LessonCatalogTests: XCTestCase {
    func testEveryDestinationAndAgeBandHasAFiveCardDiscoveryDeck() throws {
        let lessons = try LessonCatalog.bundled()

        for lesson in lessons {
            for ageBand in AgeBand.allCases {
                let slides = DiscoveryStoryCatalog.slides(
                    destinationID: lesson.id,
                    ageBand: ageBand
                )

                XCTAssertEqual(slides.count, 5, "\(lesson.id) \(ageBand)")
                XCTAssertTrue(slides.allSatisfy { !$0.imageName.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.narration.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.credit.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.sourceID.isEmpty })
            }
        }
    }

    func testEveryFlashcardDeckHasFactsAndFiveQuizQuestions() throws {
        for lesson in try LessonCatalog.bundled() {
            for ageBand in AgeBand.allCases {
                let slides = DiscoveryStoryCatalog.slides(
                    destinationID: lesson.id,
                    ageBand: ageBand
                )
                XCTAssertTrue(slides.allSatisfy { !$0.facts.isEmpty })

                let quizzes = QuizRoundCatalog.quizzes(
                    destinationID: lesson.id,
                    ageBand: ageBand
                )
                XCTAssertEqual(quizzes.count, 5)
                XCTAssertTrue(
                    quizzes.allSatisfy { quiz in
                        quiz.choices.contains { $0.id == quiz.correctChoiceID }
                    })
                let expectedChoices = ageBand == .ages4To6 ? 2 : 3
                XCTAssertTrue(quizzes.allSatisfy { $0.choices.count == expectedChoices })
            }
        }
    }

    func testBundledCatalogContainsTheParityDestinations() throws {
        let lessons = try LessonCatalog.bundled()

        XCTAssertEqual(lessons.map(\.id), ["mercury", "mars", "europa"])
    }

    func testEveryAgeBandHasTheExpectedChoiceCount() throws {
        let lessons = try LessonCatalog.bundled()

        for lesson in lessons {
            XCTAssertEqual(lesson.content[.ages4To6].quiz.choices.count, 2)
            XCTAssertEqual(lesson.content[.ages7To9].quiz.choices.count, 3)
            XCTAssertEqual(lesson.content[.ages10To12].quiz.choices.count, 3)
        }
    }

    func testDuplicateLessonIDsAreRejected() throws {
        let lessons = try LessonCatalog.bundled()

        XCTAssertThrowsError(try LessonCatalog.validate([lessons[0], lessons[0]])) { error in
            XCTAssertEqual(error as? LessonCatalogError, .duplicateLessonID("mercury"))
        }
    }
}
