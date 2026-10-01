import Foundation
import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class PlanetMissionCatalogTests: XCTestCase {
    func testAllEightPlanetsHaveThreeCompleteMissions() throws {
        let missions = try PlanetMissionCatalog.bundled()
        XCTAssertEqual(missions.count, 24)
        XCTAssertEqual(missions.flatMap(\.cards).count, 72)
        XCTAssertEqual(missions.map(\.deepDive).count, 24)
        XCTAssertEqual(missions.flatMap(\.questions).count * AgeBand.allCases.count, 216)
        for planetID in PlanetMissionCatalog.planetIDs {
            let planetMissions = missions.filter { $0.destinationID == planetID }
            XCTAssertEqual(planetMissions.count, 3, planetID)
            for mission in planetMissions {
                XCTAssertEqual(mission.cards.map(\.conceptID), mission.requiredConceptIDs)
                XCTAssertEqual(mission.questions.map(\.conceptID), mission.requiredConceptIDs)
                XCTAssertFalse(mission.requiredConceptIDs.contains(mission.deepDive.conceptID))
            }
        }
        XCTAssertEqual(
            try PlanetMissionCatalog.missions(destinationID: "mercury").first?.id,
            "mercury-crater-detective")
        XCTAssertTrue(try PlanetMissionCatalog.missions(destinationID: "pluto").isEmpty)
    }

    func testAgeBandsAndLaterReviewAreIndependentlyAuthored() throws {
        for mission in try PlanetMissionCatalog.bundled() {
            for card in mission.cards + [mission.deepDive] {
                XCTAssertEqual(Set(AgeBand.allCases.map { card.body[$0] }).count, 3, card.id)
                XCTAssertEqual(card.source.reviewStatus, "reviewed")
            }
            for question in mission.questions {
                XCTAssertEqual(
                    Set(AgeBand.allCases.map { question.content[$0].prompt }).count, 3,
                    question.id)
                for band in AgeBand.allCases {
                    let quiz = question.content[band]
                    let review = question.reviewContent[band]
                    XCTAssertNotEqual(quiz.prompt, review.prompt, question.id)
                    XCTAssertEqual(quiz.choices.count, band == .ages4To6 ? 2 : 3)
                    XCTAssertEqual(review.choices.count, quiz.choices.count)
                    XCTAssertTrue(quiz.choices.contains { $0.id == quiz.correctChoiceID })
                    XCTAssertTrue(review.choices.contains { $0.id == review.correctChoiceID })
                    XCTAssertFalse(quiz.correctFeedback.isEmpty)
                    XCTAssertFalse(review.hint.isEmpty)
                }
            }
        }
    }

    func testEveryMissionVariesCorrectAnswerPositions() throws {
        for mission in try PlanetMissionCatalog.bundled() {
            for band in AgeBand.allCases {
                for quizzes in [
                    mission.questions.map { $0.content[band] },
                    mission.questions.map { $0.reviewContent[band] },
                ] {
                    let positions = Set(
                        quizzes.compactMap { quiz in
                            quiz.choices.firstIndex { $0.id == quiz.correctChoiceID }
                        })
                    XCTAssertEqual(positions, Set(0..<(band == .ages4To6 ? 2 : 3)), mission.id)
                }
            }
        }
    }

    func testActivitiesHaveMultipleItemsAndQualitativeSettings() throws {
        let activities = try PlanetMissionCatalog.bundled().map(\.activity)
        XCTAssertEqual(Set(activities.map(\.family)), Set(ScienceActivityFamily.allCases))
        for activity in activities {
            XCTAssertEqual(activity.tasks.count, 2, activity.id)
            for task in activity.tasks {
                XCTAssertEqual(task.options.count, 2)
                XCTAssertTrue(task.options.contains { $0.id == task.correctOptionID })
                if activity.family == .experiment {
                    XCTAssertFalse(task.options.contains { $0.id.hasSuffix("option-0") })
                    for band in AgeBand.allCases {
                        XCTAssertNotEqual(
                            task.options[0].outcome[band], task.options[1].outcome[band])
                    }
                }
            }
        }
    }

    func testImageCreditsMatchTheReviewedAssetLedgerAndFilesExist() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let ledger = try String(
            contentsOf: root.appendingPathComponent("docs/IMAGE_CREDITS.md"),
            encoding: .utf8)
        for mission in try PlanetMissionCatalog.bundled() {
            for card in mission.cards + [mission.deepDive] {
                XCTAssertTrue(
                    ledger.contains(
                        "`\(card.imageName).jpg` | \(card.imageSourceID) | \(card.imageCredit) |"),
                    card.id)
                XCTAssertTrue(
                    FileManager.default.fileExists(
                        atPath: root.appendingPathComponent(
                            "Sources/AstroUI/Resources/DiscoveryImages/\(card.imageName).jpg"
                        ).path), card.imageName)
            }
        }
    }

    func testCatalogRejectsDuplicateIDsIncompleteCoverageAndMisalignedConcepts() throws {
        let missions = try PlanetMissionCatalog.bundled()
        XCTAssertThrowsError(try PlanetMissionCatalog.validate(missions + [missions[0]])) { error in
            XCTAssertEqual(error as? PlanetMissionCatalogError, .duplicateID(missions[0].id))
        }
        XCTAssertThrowsError(try PlanetMissionCatalog.validate(Array(missions.dropLast()))) {
            error in
            XCTAssertEqual(error as? PlanetMissionCatalogError, .incompletePlanetCoverage)
        }
        XCTAssertThrowsError(
            try mutatedCatalog { records in
                records[0]["requiredConceptIDs"] = ["wrong", "also-wrong", "third-wrong"]
            })
    }

    func testCatalogRejectsUnreviewedClaimsBadCreditsAndAmbiguousAnswers() throws {
        XCTAssertThrowsError(
            try mutatedCatalog { records in
                var cards = records[0]["cards"] as! [[String: Any]]
                var source = cards[0]["source"] as! [String: Any]
                source["reviewStatus"] = "source needed"
                cards[0]["source"] = source
                records[0]["cards"] = cards
            })
        XCTAssertThrowsError(
            try mutatedCatalog { records in
                var cards = records[0]["cards"] as! [[String: Any]]
                cards[0]["imageCredit"] = "unknown"
                records[0]["cards"] = cards
            })
        XCTAssertThrowsError(
            try mutatedCatalog { records in
                var questions = records[0]["questions"] as! [[String: Any]]
                var content = questions[0]["content"] as! [String: Any]
                var quiz = content["ages4To6"] as! [String: Any]
                var choices = quiz["choices"] as! [[String: Any]]
                choices[1]["text"] = choices[0]["text"]
                quiz["choices"] = choices
                content["ages4To6"] = quiz
                questions[0]["content"] = content
                records[0]["questions"] = questions
            })
    }

    func testLegacyCopySeparatesSpinAndLightTravelRoutes() {
        let venus = DiscoveryStoryCatalog.slides(destinationID: "venus", ageBand: .ages10To12)
        let motion = venus.first { $0.id == "venus-motion" }
        XCTAssertEqual(motion?.title, "Spins and orbits")
        XCTAssertTrue(motion?.body.contains("117 Earth days") == true)
        XCTAssertFalse(motion?.facts.contains { $0.label == "one day" } == true)
        let sun = DiscoveryStoryCatalog.slides(destinationID: "sun", ageBand: .ages10To12)
        XCTAssertTrue(
            sun.first { $0.id == "sun-light-time" }?.body.contains("Sun-to-Earth") == true)
        for planet in ["mercury", "mars", "neptune"] {
            let slides = DiscoveryStoryCatalog.slides(destinationID: planet, ageBand: .ages10To12)
            XCTAssertFalse(slides.contains { $0.body.contains("minimum one-way radio delay") })
        }
        XCTAssertTrue(
            venus.first { $0.id == "venus-color" }?.body.contains("assigned colors") == true)
    }

    private func mutatedCatalog(_ mutation: (inout [[String: Any]]) -> Void) throws
        -> [PlanetMission]
    {
        let data = try JSONEncoder().encode(PlanetMissionCatalog.bundled())
        var records = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        mutation(&records)
        return try PlanetMissionCatalog.decode(JSONSerialization.data(withJSONObject: records))
    }
}
