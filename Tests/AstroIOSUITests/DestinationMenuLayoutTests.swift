import XCTest

@MainActor
final class DestinationMenuLayoutTests: XCTestCase {
    private let app = XCUIApplication()

    func testPortraitMenuWrapsAtLargestAccessibilitySize() {
        XCUIDevice.shared.orientation = .portrait
        checkMenuAcrossTextSizes(orientation: "Portrait")
    }

    func testLandscapeMenuWrapsAtLargestAccessibilitySize() {
        XCUIDevice.shared.orientation = .landscapeLeft
        checkMenuAcrossTextSizes(orientation: "Landscape")
    }

    private func checkMenuAcrossTextSizes(orientation: String) {
        continueAfterFailure = false
        var normalCardHeight = 0.0
        for (name, category) in [
            ("Default", "UICTContentSizeCategoryL"),
            ("Accessibility XXXL", "UICTContentSizeCategoryAccessibilityXXXL"),
        ] {
            app.launchArguments = [
                "--ui-testing", "--reset-ui-testing-progress",
                "-UIPreferredContentSizeCategoryName", category,
            ]
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
            reach("adventure.begin").press(forDuration: 0.15)
            let row = app.scrollViews["destination.selector"]
            XCTAssertTrue(row.waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["destination.sun"].label.contains("Stamped"))
            XCTAssertTrue(app.buttons["destination.mercury"].label.contains("Living playground"))
            XCTAssertTrue(app.buttons["destination.venus"].label.contains("0/3 missions"))
            capture("\(orientation) \(name) world cards")
            for id in ["sun", "mercury", "venus"] {
                assertVerticallyContained(app.buttons["destination.\(id)"], in: row)
            }
            let height = app.buttons["destination.mercury"].frame.height
            if normalCardHeight == 0 {
                normalCardHeight = height
            } else {
                XCTAssertGreaterThan(
                    height, normalCardHeight * 1.4,
                    "Accessibility text must grow the card instead of shrinking the text")
            }
            // Scrolling the containing menu keeps actions below tall text reachable.
            let review = reach("review.start")
            XCTAssertTrue(review.isHittable)
            capture("\(orientation) \(name) reachable memory action")
            reach("destination.section.technologyLab").press(forDuration: 0.15)
            let technology = app.buttons["destination.space-technology-lab"]
            XCTAssertTrue(technology.waitForExistence(timeout: 10))
            XCTAssertTrue(technology.label.contains("Space Technology Lab"))
            assertVerticallyContained(technology, in: row)
            reach(technology.identifier)
            capture("\(orientation) \(name) wrapped Technology Lab card")
            app.terminate()
        }
    }

    private func assertVerticallyContained(
        _ card: XCUIElement, in viewport: XCUIElement,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(
            card.frame.minY, viewport.frame.minY - 0.5,
            "\(card.identifier) top is clipped", file: file, line: line)
        XCTAssertLessThanOrEqual(
            card.frame.maxY, viewport.frame.maxY + 0.5,
            "\(card.identifier) bottom is clipped", file: file, line: line)
    }

    @discardableResult
    private func reach(
        _ identifier: String, file: StaticString = #filePath, line: UInt = #line
    ) -> XCUIElement {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        let menu = app.scrollViews["adventure.menu"]
        for _ in 0..<12 {
            if button.isHittable { return button }
            if button.frame.midY < menu.frame.midY {
                menu.swipeDown()
            } else {
                menu.swipeUp()
            }
        }
        capture("Unreachable \(identifier)")
        XCTFail("Menu action \(identifier) is unreachable", file: file, line: line)
        return button
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
