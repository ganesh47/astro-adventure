import XCTest

@MainActor
final class DiscoveryFlowTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launch()
    }

    func testRemoteDiscoveryRetryPauseAndPersistedPassport() {
        select("adventure.begin")
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 10))

        capture("Destination selection")
        remote.press(.playPause)
        XCTAssertTrue(app.buttons["adventure.pause.resume"].waitForExistence(timeout: 5))
        capture("Pause controls")
        select("adventure.pause.resume")
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 5))
        focus("destination.mercury")
        select("adventure.explore")

        // Every story card is advanced by the same focused Siri Remote action.
        for _ in 0..<30 {
            if app.buttons["quiz.answer.0"].exists { break }
            select("story.next")
        }
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 5))
        select("quiz.hint")
        XCTAssertTrue(app.buttons["quiz.hint"].label.contains("Revealed"))
        XCTAssertEqual(
            XCTWaiter.wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "hasFocus == true"),
                        object: app.buttons["quiz.answer.0"]
                    )
                ], timeout: 5
            ), .completed, "Revealing a hint returns focus to the answers"
        )
        capture("Quiz hint")

        // Mercury's first correct answer in the default Explorer mode is position 0.
        // Deliberately choose another clue, then recover without losing the discovery.
        select("quiz.answer.1")
        XCTAssertTrue(app.buttons["feedback.continue"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["feedback.continue"].label, "Try Again")
        select("feedback.continue")

        for _ in 0..<30 {
            if app.buttons["results.continue"].exists { break }
            var solved = false
            for answer in 0..<3 {
                let identifier = "quiz.answer.\(answer)"
                if !app.buttons[identifier].exists { continue }
                select(identifier)
                let feedback = app.buttons["feedback.continue"]
                XCTAssertTrue(feedback.waitForExistence(timeout: 5))
                solved = feedback.label == "Continue"
                select("feedback.continue")
                if solved { break }
            }
            XCTAssertTrue(solved, "A clue must be solvable using the displayed answers")
        }
        XCTAssertTrue(app.buttons["results.continue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A new stamp for your Discovery Passport"].exists)
        capture("Discovery celebration")

        // Back during the saved celebration must keep the earned destination stamp.
        remote.press(.menu)
        let mercury = app.buttons["destination.mercury"]
        XCTAssertTrue(mercury.waitForExistence(timeout: 5))
        XCTAssertTrue(mercury.label.contains("Stamped"))
        remote.press(.playPause)
        select("adventure.pause.worlds")
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["adventure.begin"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["adventure.begin"].label, "Continue Adventure")
        select("adventure.begin")
        XCTAssertTrue(mercury.waitForExistence(timeout: 5))
        XCTAssertTrue(mercury.label.contains("Stamped"), "Stamp must survive an app relaunch")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func select(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        focus(identifier, file: file, line: line)
        remote.press(.select)
    }

    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier]
        XCTAssertTrue(
            target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        var previousFrame: CGRect?
        var previousHorizontal = false
        for _ in 0..<20 {
            if target.hasFocus {
                return
            }
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
            if previousFrame == focused.frame {
                horizontal = !previousHorizontal
            }
            previousFrame = focused.frame
            previousHorizontal = horizontal
            if horizontal {
                remote.press(deltaX > 0 ? .right : .left)
            } else {
                remote.press(deltaY > 0 ? .down : .up)
            }
            _ = XCTWaiter.wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "hasFocus == true"), object: target)
                ], timeout: 0.3)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCTFail(
            "Remote could not focus \(identifier).\n\(app.debugDescription)", file: file, line: line
        )
    }
}
