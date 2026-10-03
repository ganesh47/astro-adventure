import UIKit
import XCTest

@MainActor
final class QuestionExperienceTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func testPictureSelectionRetryStoryAndRelaunchPreserveQuestion() {
        launch()
        openSunQuestion()
        capture("Sun authored rocky world moon and star proposals")
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        tap("quiz.answer.0")
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        XCTAssertFalse(
            app.buttons["feedback.continue"].exists, "Selection must wait for confirmation")
        tap("quiz.check")
        XCTAssertEqual(button("feedback.continue").label, "Try Again")
        capture("Explanatory retry keeps the discovery safe")
        tap("feedback.hint")
        XCTAssertTrue(app.buttons["quiz.hint.close"].waitForExistence(timeout: 5))
        tap("quiz.back")
        finishStory()
        XCTAssertTrue(app.buttons["quiz.hint.close"].exists)
        tap("quiz.hint.close")
        let correct = starAnswer()
        tap(correct.identifier)
        tap("quiz.check")
        XCTAssertEqual(button("feedback.continue").label, "Continue")
        tap("feedback.continue")
        let secondPrompt = app.staticTexts["quiz.question"].label
        XCTAssertTrue(app.staticTexts["quiz.progress"].label.contains("2"))
        tap("quiz.answer.0")
        app.terminate()
        launch(reset: false)
        tap("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["quiz.question"].label, secondPrompt)
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        capture("Restored second question with its selected proposal")
    }

    func testOptionalExpiryMoreTimeAndPracticeKeepSelectedAnswer() {
        launch(allowance: "1")
        openSunQuestion()
        turnSoundOff()
        let correct = starAnswer()
        tap(correct.identifier)
        tap("quiz.time.mode")
        XCTAssertTrue(app.buttons["quiz.time.more"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons[correct.identifier].value as? String, "Selected")
        XCTAssertFalse(app.buttons["feedback.continue"].exists)
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        capture("Optional expiry offers more time without losing an answer")
        tap("quiz.time.more")
        XCTAssertTrue(
            app.otherElements["quiz.time.remaining"].exists
                || app.staticTexts["quiz.time.remaining"].exists)
        XCTAssertTrue(app.buttons["quiz.time.more"].waitForExistence(timeout: 8))
        tap("quiz.time.practice")
        XCTAssertFalse(app.buttons["quiz.time.more"].exists)
        XCTAssertEqual(app.buttons[correct.identifier].value as? String, "Selected")
        tap("quiz.check")
        XCTAssertEqual(button("feedback.continue").label, "Continue")
    }

    func testBackgroundAndRestoredChallengeRequireExplicitResume() {
        launch(allowance: "30")
        openSunQuestion()
        turnSoundOff()
        tap("quiz.time.mode")
        tap("quiz.answer.0")
        XCUIDevice.shared.press(.home)
        app.activate()
        tap("adventure.pause.resume")
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        XCTAssertFalse(app.buttons["quiz.time.more"].exists)
        app.terminate()
        launch(reset: false, allowance: "30")
        tap("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.time.resume"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        capture("Saved challenge waits for explicit resume")
        tap("quiz.time.resume")
        tap("quiz.time.mode")
        XCTAssertTrue(app.buttons["quiz.check"].isEnabled)
    }

    func testQuestionAndFeedbackRemainReachableAtLargestTextSize() {
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            if UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .portrait
            }
            launch(category: category)
            openSunQuestion()
            for index in 0..<3 {
                let answer = button("quiz.answer.\(index)")
                reveal(answer)
                XCTAssertTrue(answer.isHittable)
                capture("\(category) readable Sun proposal \(index + 1)")
            }
            tap("quiz.answer.0")
            tap("quiz.check")
            capture("\(category) readable explanatory feedback")
            XCTAssertTrue(button("feedback.continue").isHittable)
            tap("feedback.hint")
            tap("quiz.hint.close")
            XCTAssertTrue(button("quiz.back").isHittable)
            app.terminate()
        }
    }

    func testFutureOrCorruptLogHasRecoveryWithoutReplacement() {
        for fixture in [#"{"schemaVersion":999}"#, "{corrupt"] {
            launch(fixture: fixture)
            XCTAssertTrue(app.buttons["progress.load.retry"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.buttons["Begin a new space log"].exists)
            XCTAssertFalse(app.buttons["adventure.begin"].exists)
            tap("progress.load.retry")
            XCTAssertTrue(app.buttons["progress.load.retry"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    private func launch(
        reset: Bool = true, allowance: String? = nil,
        category: String = "UICTContentSizeCategoryL", fixture: String? = nil
    ) {
        app.launchArguments = ["--ui-testing", "-UIPreferredContentSizeCategoryName", category]
        if reset { app.launchArguments.append("--reset-ui-testing-progress") }
        app.launchEnvironment = [:]
        if let allowance {
            app.launchEnvironment["ASTRO_UI_TEST_QUESTION_ALLOWANCE_SECONDS"] = allowance
        }
        if let fixture { app.launchEnvironment["ASTRO_UI_TEST_PROGRESS_JSON"] = fixture }
        app.launch()
    }

    private func openSunQuestion() {
        tap("adventure.begin")
        tap("destination.sun")
        if app.buttons["adventure.explore"].exists { tap("adventure.explore") }
        finishStory()
        XCTAssertTrue(app.staticTexts["quiz.question"].label.contains("Sun"))
    }

    private func finishStory() {
        for _ in 0..<12 {
            if app.buttons["quiz.answer.0"].exists { return }
            tap("story.next")
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
        let sound = button("quiz.narration")
        if sound.label == "Sound On" { sound.tap() }
        XCTAssertEqual(sound.label, "Sound Off")
    }

    @discardableResult private func button(_ identifier: String) -> XCUIElement {
        let element = app.buttons[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing \(identifier)")
        reveal(element)
        return element
    }

    private func tap(_ identifier: String) {
        let element = button(identifier)
        XCTAssertTrue(element.isHittable, "Unreachable \(identifier)")
        element.tap()
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<18 {
            let frame = app.frame.insetBy(dx: 18, dy: 24)
            if element.isHittable,
                frame.contains(CGPoint(x: element.frame.midX, y: element.frame.midY))
            {
                return
            }
            let scroll = app.scrollViews.matching(
                NSPredicate(
                    format: "identifier IN %@",
                    ["quiz.scroll", "feedback.scroll", "adventure.menu"])
            ).firstMatch
            let target = scroll.exists ? scroll : app
            if element.frame.midY < frame.midY { target.swipeDown() } else { target.swipeUp() }
        }
        capture("Unreachable \(element.identifier)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
