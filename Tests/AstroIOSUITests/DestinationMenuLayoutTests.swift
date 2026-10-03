import UIKit
import XCTest

@MainActor
final class DestinationMenuLayoutTests: XCTestCase {
    private let app = XCUIApplication()

    func testTabletPortraitMenuWrapsAtLargestAccessibilitySize() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Portrait menu layout is supported on iPad; iPhone is landscape-only")
        }
        XCUIDevice.shared.orientation = .portrait
        checkMenuAcrossTextSizes(orientation: "iPad portrait", expectsPortrait: true)
    }

    func testLandscapeMenuWrapsAtLargestAccessibilitySize() {
        XCUIDevice.shared.orientation = .landscapeLeft
        checkMenuAcrossTextSizes(orientation: "Landscape", expectsPortrait: false)
    }

    private func checkMenuAcrossTextSizes(orientation: String, expectsPortrait: Bool) {
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
            if expectsPortrait {
                XCTAssertGreaterThan(
                    app.frame.height, app.frame.width, "Actual app must be portrait")
            } else {
                XCTAssertGreaterThan(
                    app.frame.width, app.frame.height, "Actual app must be landscape")
            }
            reach("adventure.begin").press(forDuration: 0.15)
            let row = app.scrollViews["destination.selector"]
            XCTAssertTrue(row.waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["destination.sun"].label.contains("Stamped"))
            XCTAssertTrue(app.buttons["destination.mercury"].label.contains("Living playground"))
            XCTAssertTrue(app.buttons["destination.venus"].label.contains("0/3 missions"))
            revealCard("destination.mercury", in: row)
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

    private func revealCard(_ identifier: String, in row: XCUIElement) {
        let card = app.buttons[identifier]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        revealVertically(card)
        for _ in 0..<8 {
            let visible = row.frame.intersection(app.frame)
            if card.frame.minX >= visible.minX && card.frame.maxX <= visible.maxX {
                XCTAssertTrue(card.isHittable)
                return
            }
            let delta = card.frame.midX - visible.midX
            let distance = min(abs(delta), visible.width * 0.45)
            let start = row.coordinate(
                withNormalizedOffset: CGVector(dx: delta > 0 ? 0.75 : 0.25, dy: 0.5))
            let end = start.withOffset(CGVector(dx: delta > 0 ? -distance : distance, dy: 0))
            start.press(
                forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.25)
        }
        capture("Card cannot be fully revealed")
        XCTFail("\(identifier) cannot be scrolled into the visible horizontal viewport")
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
        revealVertically(button, file: file, line: line)
        XCTAssertTrue(button.isHittable, file: file, line: line)
        return button
    }

    private func revealVertically(
        _ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line
    ) {
        let menu = app.scrollViews["adventure.menu"]
        for _ in 0..<12 {
            var visible = menu.frame.intersection(app.frame)
            let pause = app.buttons["adventure.pause"]
            if pause.exists, pause.frame.minY > visible.minY {
                visible.size.height = min(visible.maxY, pause.frame.minY) - visible.minY
            }
            let fitsVertically =
                element.frame.minY >= visible.minY
                && element.frame.maxY <= visible.maxY
            if fitsVertically { return }
            let delta = element.frame.midY - visible.midY
            let distance = min(abs(delta), visible.height * 0.45)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
                CGVector(
                    dx: visible.minX + visible.width * 0.08,
                    dy: visible.minY + visible.height * (delta > 0 ? 0.75 : 0.25)))
            let end = start.withOffset(CGVector(dx: 0, dy: delta > 0 ? -distance : distance))
            start.press(
                forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.25)
            if element.frame.height > visible.height {
                // A taller element can be read by scrolling; its center must be on screen.
                if visible.contains(CGPoint(x: visible.midX, y: element.frame.midY)) { return }
            }
        }
        capture("Unreachable \(element.identifier)")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Menu element \(element.identifier) is unreachable", file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
