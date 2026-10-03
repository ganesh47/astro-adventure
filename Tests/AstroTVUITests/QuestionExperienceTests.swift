import XCTest

@MainActor
final class QuestionExperienceTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testRemotePictureSelectionRetryStoryAndSavedQuestion() {
        launch()
        openSunQuestion()
        capture("Television Sun rocky world moon and star proposals")
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        select("quiz.answer.0")
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        XCTAssertFalse(app.buttons["feedback.continue"].exists)
        select("quiz.check")
        XCTAssertEqual(app.buttons["feedback.continue"].label, "Try Again")
        capture("Television explanatory retry")
        select("feedback.story")
        finishStory()
        select(starAnswer().identifier)
        select("quiz.check")
        XCTAssertEqual(app.buttons["feedback.continue"].label, "Continue")
        select("feedback.continue")
        let prompt = app.staticTexts["quiz.question"].label
        select("quiz.answer.0")
        app.terminate()
        launch(reset: false)
        select("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["quiz.question"].label, prompt)
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        capture("Television restored selected second question")
    }

    func testRemoteExpiryKeepsAnswerAndOffersCalmPractice() {
        launch(allowance: "1")
        openSunQuestion()
        turnSoundOff()
        let answer = starAnswer()
        select(answer.identifier)
        select("quiz.time.mode")
        XCTAssertTrue(app.buttons["quiz.time.more"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons[answer.identifier].value as? String, "Selected")
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        XCTAssertFalse(app.buttons["feedback.continue"].exists)
        capture("Television optional expiry focused recovery")
        select("quiz.time.more")
        XCTAssertTrue(app.buttons["quiz.time.more"].waitForExistence(timeout: 8))
        select("quiz.time.practice")
        XCTAssertEqual(app.buttons[answer.identifier].value as? String, "Selected")
        select("quiz.check")
        XCTAssertEqual(app.buttons["feedback.continue"].label, "Continue")
    }

    func testEveryQuestionControlAndFeedbackReachableAtLargeText() {
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            launch(category: category)
            openSunQuestion()
            if app.buttons["quiz.narration"].label == "Sound Off" { select("quiz.narration") }
            for index in 0..<3 {
                focus("quiz.answer.\(index)")
                capture("\(category) television focused proposal \(index + 1)")
            }
            for identifier in [
                "quiz.hint", "quiz.narration", "quiz.time.mode", "quiz.back", "quiz.read",
            ] {
                focus(identifier)
                XCTAssertTrue(app.buttons[identifier].hasFocus)
            }
            select("quiz.hint")
            capture("\(category) television hint")
            select("quiz.hint.close")
            select("quiz.answer.0")
            select("quiz.check")
            capture("\(category) television feedback")
            for identifier in [
                "feedback.continue", "feedback.hint", "feedback.story", "feedback.read",
            ] {
                focus(identifier)
                XCTAssertTrue(app.buttons[identifier].hasFocus)
            }
            app.terminate()
        }
    }

    private func launch(
        reset: Bool = true, allowance: String? = nil, category: String = "UICTContentSizeCategoryL"
    ) {
        app.launchArguments = ["--ui-testing", "-UIPreferredContentSizeCategoryName", category]
        if reset { app.launchArguments.append("--reset-ui-testing-progress") }
        app.launchEnvironment = [:]
        if let allowance {
            app.launchEnvironment["ASTRO_UI_TEST_QUESTION_ALLOWANCE_SECONDS"] = allowance
        }
        app.launch()
    }

    private func openSunQuestion() {
        select("adventure.begin")
        select("destination.sun")
        finishStory()
        XCTAssertTrue(app.staticTexts["quiz.question"].label.contains("Sun"))
    }

    private func finishStory() {
        for _ in 0..<12 {
            if app.buttons["quiz.answer.0"].exists { return }
            select("story.next")
        }
        XCTFail("The story must reach its question")
    }

    private func starAnswer() -> XCUIElement {
        let answer = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND label CONTAINS[c] %@", "quiz.answer.", "star")
        ).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        return answer
    }

    private func turnSoundOff() {
        let sound = app.buttons["quiz.narration"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        if sound.label == "Sound On" { select(sound.identifier) }
        XCTAssertEqual(sound.label, "Sound Off")
    }

    private func select(_ identifier: String) {
        focus(identifier)
        remote.press(.select)
    }

    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier]
        XCTAssertTrue(
            target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        var previousFrame: CGRect?
        var previousHorizontal = false
        for _ in 0..<32 {
            if target.hasFocus { return }
            let focused = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            guard focused.exists else {
                remote.press(.down)
                continue
            }
            let deltaX = target.frame.midX - focused.frame.midX
            let deltaY = target.frame.midY - focused.frame.midY
            var horizontal =
                target.frame.minX > focused.frame.maxX || target.frame.maxX < focused.frame.minX
                || abs(deltaY) <= 40
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
        capture("Unreachable remote control \(identifier)")
        XCTFail("Remote could not focus \(identifier)", file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
