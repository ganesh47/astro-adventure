import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class LessonCatalogTests: XCTestCase {
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
