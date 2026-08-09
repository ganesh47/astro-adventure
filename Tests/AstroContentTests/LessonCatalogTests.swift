import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class LessonCatalogTests: XCTestCase {
    func testEveryDestinationAndAgeBandHasACompleteDiscoveryDeck() throws {
        let lessons = try LessonCatalog.bundled()

        for lesson in lessons {
            for ageBand in AgeBand.allCases {
                let slides = DiscoveryStoryCatalog.slides(
                    destinationID: lesson.id,
                    ageBand: ageBand
                )

                let expectedCount = lesson.id == "space-technology-lab" ? 10 : 7
                XCTAssertEqual(slides.count, expectedCount, "\(lesson.id) \(ageBand)")
                XCTAssertTrue(slides.allSatisfy { !$0.imageName.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.narration.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.credit.isEmpty })
                XCTAssertTrue(slides.allSatisfy { !$0.sourceID.isEmpty })
            }
        }
    }

    func testEveryFlashcardDeckHasFactsAndMatchingQuizQuestions() throws {
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
                XCTAssertEqual(quizzes.count, slides.count)
                XCTAssertTrue(
                    quizzes.allSatisfy { quiz in
                        quiz.choices.contains { $0.id == quiz.correctChoiceID }
                    })
                let expectedChoices = ageBand == .ages4To6 ? 2 : 3
                XCTAssertTrue(quizzes.allSatisfy { $0.choices.count == expectedChoices })
            }
        }
    }

    func testBundledCatalogContainsTheSolarSystemCollection() throws {
        let lessons = try LessonCatalog.bundled()

        XCTAssertEqual(
            lessons.map(\.id),
            [
                "sun", "mercury", "venus", "earth", "moon", "mars", "ceres", "jupiter",
                "europa", "saturn", "uranus", "neptune", "pluto", "space-technology-lab",
            ]
        )
    }

    func testTechnologyLabCoversCoreSpaceResearchTools() throws {
        let titles = DiscoveryStoryCatalog.slides(
            destinationID: "space-technology-lab",
            ageBand: .ages7To9
        ).map(\.title)

        XCTAssertTrue(titles.contains { $0.contains("Engines") })
        XCTAssertTrue(titles.contains { $0.contains("Launch vehicles") })
        XCTAssertTrue(titles.contains { $0.contains("Boosters") })
        XCTAssertTrue(titles.contains { $0.contains("ISS") })
        XCTAssertTrue(titles.contains { $0.contains("Satellites") })
        XCTAssertTrue(titles.contains { $0.contains("spacesuit") })
        XCTAssertTrue(titles.contains { $0.contains("Radio") })
        XCTAssertTrue(titles.contains { $0.contains("Deep Space Network") })
        XCTAssertTrue(titles.contains { $0.contains("Telescopes") })
        XCTAssertTrue(titles.contains { $0.contains("Robots") })
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
            XCTAssertEqual(error as? LessonCatalogError, .duplicateLessonID(lessons[0].id))
        }
    }
}
