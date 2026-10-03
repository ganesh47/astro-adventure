import XCTest

@MainActor
final class DestinationMenuLayoutTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launchEnvironment["ASTRO_UI_TEST_PROGRESS_JSON"] = #"""
            {
              "destinations": {"sun": {"isQuizCompleted": true}},
              "concepts": {
                "ages7To9:mercury-crater-detective-impacts": {
                  "conceptID": "mercury-crater-detective-impacts",
                  "ageBand": "ages7To9", "reviewBox": 1,
                  "lastPracticedAt": 0, "nextReviewAt": 0
                }
              }
            }
            """#
        app.launch()
    }

    func testStampedWorldAndPlaygroundCardsFitTheFocusedViewport() {
        focus("adventure.begin")
        remote.press(.select)
        XCTAssertTrue(app.buttons["review.start"].waitForExistence(timeout: 10))
        let row = app.scrollViews["destination.selector"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["destination.sun"].label.contains("Stamped"))
        XCTAssertTrue(app.buttons["destination.mercury"].label.contains("Living playground"))
        XCTAssertTrue(app.buttons["destination.venus"].label.contains("0/3 missions"))
        capture("World menu with stamps and memory action")

        var bounds: [(String, CGRect, CGRect)] = []
        for (id, title) in [
            ("sun", "Sun"), ("mercury", "Mercury"), ("venus", "Venus"),
            ("mars", "Mars"), ("saturn", "Saturn"),
        ] {
            let identifier = "destination.\(id)"
            focus(identifier)
            capture("Focused \(id) card")
            bounds.append((identifier, app.buttons[identifier].frame, row.frame))
            remote.press(.down)
            let explore = app.buttons["adventure.explore"]
            XCTAssertEqual(
                XCTWaiter.wait(
                    for: [
                        XCTNSPredicateExpectation(
                            predicate: NSPredicate(format: "hasFocus == true"), object: explore)
                    ], timeout: 3), .completed,
                "Down from \(id) must reach Explore without detouring through another world")
            XCTAssertTrue(explore.label.contains("Explore \(title)"))
        }
        focus("destination.section.technologyLab")
        remote.press(.select)
        let technology = app.buttons["destination.space-technology-lab"]
        XCTAssertTrue(technology.waitForExistence(timeout: 10))
        XCTAssertTrue(technology.label.contains("Space Technology Lab"))
        focus(technology.identifier)
        capture("Focused Technology Lab card with wrapped title")
        bounds.append((technology.identifier, technology.frame, row.frame))
        for (identifier, card, viewport) in bounds {
            XCTAssertGreaterThanOrEqual(
                card.minY, viewport.minY - 0.5, "\(identifier) top is clipped")
            XCTAssertLessThanOrEqual(
                card.maxY, viewport.maxY + 0.5, "\(identifier) bottom is clipped")
            XCTAssertGreaterThanOrEqual(
                card.minX, viewport.minX - 0.5, "\(identifier) focused leading edge is clipped")
            XCTAssertLessThanOrEqual(
                card.maxX, viewport.maxX + 0.5, "\(identifier) focused trailing edge is clipped")
        }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier]
        XCTAssertTrue(
            target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        var previousFrame: CGRect?
        var previousHorizontal = false
        for _ in 0..<20 {
            if target.hasFocus { return }
            let focused = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            guard focused.exists else {
                remote.press(.down)
                continue
            }
            let deltaX = target.frame.midX - focused.frame.midX
            let deltaY = target.frame.midY - focused.frame.midY
            var horizontal =
                target.frame.minX > focused.frame.maxX
                || target.frame.maxX < focused.frame.minX || abs(deltaY) <= 40
            if previousFrame == focused.frame { horizontal = !previousHorizontal }
            previousFrame = focused.frame
            previousHorizontal = horizontal
            remote.press(horizontal ? (deltaX > 0 ? .right : .left) : (deltaY > 0 ? .down : .up))
            _ = XCTWaiter.wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "hasFocus == true"), object: target)
                ], timeout: 0.3)
        }
        capture("Remote focus failure")
        XCTFail(
            "Remote could not focus \(identifier).\n\(app.debugDescription)", file: file, line: line
        )
    }
}
