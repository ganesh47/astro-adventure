import AstroContent
import AstroGameCore
import UIKit
import XCTest

@MainActor
final class QuestionExperienceTests: XCTestCase {
    private let app = XCUIApplication()
    private var initialReduceMotion: Bool?

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    override func tearDown() async throws {
        app.terminate()
        // Also restore after XCTest aborts a failed method before its defer runs.
        restoreNativeReduceMotion()
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
        turnSoundOff()
        tap("quiz.time.mode")
        app.terminate()
        launch(reset: false)
        // Taking the primary menu route before resuming must preserve Q2's presentation.
        openSunQuestion()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["quiz.question"].label, secondPrompt)
        XCTAssertEqual(app.buttons["quiz.answer.0"].value as? String, "Selected")
        XCTAssertTrue(app.buttons["quiz.time.resume"].exists)
        capture("Restored second question with its selected proposal")
    }

    func testOptionalExpiryMoreTimeAndPracticeKeepSelectedAnswer() {
        launch(allowance: "5")
        openSunQuestion()
        turnSoundOff()
        let correct = starAnswer()
        tap(correct.identifier)
        tap("quiz.time.mode")
        XCTAssertEqual(app.buttons["quiz.time.mode"].label, "Calm Practice")
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
        XCTAssertEqual(app.buttons["quiz.time.mode"].label, "Calm Practice")
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

    func testReviewedScientificContextsRenderTheirRealCatalogProposals() throws {
        for fixture in try ReviewedScientificQuestionFixture.reviewedQuestions() {
            launch(fixture: fixture.progressJSON)
            tap("adventure.resume")
            let prefix = fixture.identifierPrefix
            XCTAssertTrue(app.staticTexts["\(prefix).question"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["\(prefix).question"].label, fixture.quiz.prompt)
            for (index, choice) in fixture.quiz.choices.enumerated() {
                let answer = button("\(prefix).answer.\(index)")
                XCTAssertEqual(answer.label, "Answer \(index + 1): \(choice.text)")
                XCTAssertTrue(isReachable(answer))
            }
            XCTAssertFalse(app.buttons["\(prefix).check"].isEnabled)
            capture("Reviewed scientific proposals \(fixture.name)")
            app.terminate()
        }
    }

    func testLargestTextStoryNextPreviousAndPauseControlsRemainReachable() {
        launch(category: "UICTContentSizeCategoryAccessibilityXXXL")
        tap("adventure.begin")
        tap("destination.sun")
        if app.buttons["adventure.explore"].exists { tap("adventure.explore") }
        let progress = app.descendants(matching: .any).matching(identifier: "story.progress")
            .firstMatch
        let cardCount = DiscoveryStoryCatalog.slides(destinationID: "sun", ageBand: .ages7To9).count
        XCTAssertGreaterThan(cardCount, 1)
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.value as? String, "Card 1 of \(cardCount)")
        tap("story.next")
        XCTAssertEqual(progress.value as? String, "Card 2 of \(cardCount)")
        XCTAssertTrue(progress.isHittable, "Next must scroll the new card's header into view")
        capture("Largest text Story Next restores the new card top")
        tap("story.previous")
        XCTAssertEqual(progress.value as? String, "Card 1 of \(cardCount)")
        XCTAssertTrue(progress.isHittable, "Previous must restore the prior card's header")
        tap("adventure.pause")
        XCTAssertTrue(app.scrollViews["adventure.pause.scroll"].waitForExistence(timeout: 5))
        tap("adventure.pause.resume")
        XCTAssertFalse(app.scrollViews["adventure.pause.scroll"].exists)
        XCTAssertTrue(app.buttons["story.next"].exists)
        tap("adventure.pause")
        capture("Largest text Pause panel scrolls to its actions")
        tap("adventure.pause.worlds")
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 5))
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

    func testNativeReduceMotionKeepsQuestionAndFeedbackUsable() {
        XCUIDevice.shared.orientation = .portrait
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let motion = settings.switches["Reduce Motion"]
        if !motion.waitForExistence(timeout: 1) {
            let motionPage = settings.staticTexts["Motion"].firstMatch
            if !motionPage.exists || !motionPage.isHittable {
                settingsLabel("Accessibility", in: settings).tap()
            }
            settingsLabel("Motion", in: settings).tap()
        }
        XCTAssertTrue(motion.waitForExistence(timeout: 10))
        let initiallyEnabled = motion.value as? String == "1"
        initialReduceMotion = initiallyEnabled
        defer { restoreNativeReduceMotion() }
        if !initiallyEnabled { setSettingsSwitch(motion, enabled: true, in: settings) }
        XCTAssertEqual(motion.value as? String, "1")
        XCUIDevice.shared.orientation = .landscapeLeft
        launch()
        openSunQuestion()
        capture("Native Reduce Motion Sun proposals")
        tap("quiz.answer.0")
        tap("quiz.check")
        capture("Native Reduce Motion explanatory feedback")
        tap("feedback.hint")
        tap("quiz.hint.close")
        tap(starAnswer().identifier)
        tap("quiz.check")
        XCTAssertEqual(button("feedback.continue").label, "Continue")
        tap("adventure.pause")
        tap("adventure.pause.worlds")
        tap("gravity.open")
        tap("gravity.world.moon")
        tap("gravity.angle.plus")
        tap("gravity.speed.plus")
        tap("gravity.launch")
        let field = app.otherElements["gravity.field"]
        XCTAssertTrue((field.value as? String ?? "").contains("Static flight paths"))
        tap("gravity.pause")
        for _ in 0..<8 {
            if field.isHittable { break }
            app.swipeUp()
        }
        capture("Native Reduce Motion static Moon and Earth trajectories")
    }

    private func settingsLabel(_ text: String, in settings: XCUIApplication) -> XCUIElement {
        let label = settings.staticTexts[text].firstMatch
        for _ in 0..<12 {
            if label.exists, label.isHittable { return label }
            settings.swipeUp()
        }
        let attachment = XCTAttachment(screenshot: settings.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(label.isHittable, "Settings must expose \(text)")
        return label
    }

    private func setSettingsSwitch(
        _ toggle: XCUIElement, enabled: Bool, in settings: XCUIApplication
    ) {
        let value = enabled ? "1" : "0"
        guard toggle.value as? String != value else { return }
        // Settings exposes the entire row as a switch. Hit its trailing toggle,
        // rather than the row's text at the accessibility element midpoint.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", value), object: toggle)
        let result = XCTWaiter.wait(for: [changed], timeout: 5)
        if result != .completed {
            let screenshot = XCTAttachment(screenshot: settings.screenshot())
            screenshot.name = "Native Reduce Motion switch did not reach \(value)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let hierarchy = XCTAttachment(string: settings.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertEqual(result, .completed, "Native Settings switch must reach \(value)")
        XCTAssertEqual(toggle.value as? String, value)
    }

    private func restoreNativeReduceMotion() {
        guard let original = initialReduceMotion else { return }
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.activate()
        let motion = settings.switches["Reduce Motion"]
        XCTAssertTrue(motion.waitForExistence(timeout: 5))
        setSettingsSwitch(motion, enabled: original, in: settings)
        let restored = motion.value as? String == (original ? "1" : "0")
        settings.terminate()
        if restored { initialReduceMotion = nil }
        XCTAssertTrue(
            restored, "The dedicated simulator's original Reduce Motion setting is restored")
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
        let exists = element.waitForExistence(timeout: 10)
        if !exists {
            capture("Missing \(identifier)")
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertTrue(exists, "Missing \(identifier)")
        reveal(element)
        return element
    }

    private func tap(_ identifier: String) {
        let element = button(identifier)
        guard isReachable(element) else {
            capture("Unreachable \(identifier)")
            XCTFail("Unreachable \(identifier)")
            return
        }
        element.tap()
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<18 {
            if isReachable(element) { return }
            let frame = visibleFrame(for: element)
            let target = activeScroll() ?? app
            if element.frame.midY < frame.midY { target.swipeDown() } else { target.swipeUp() }
        }
        capture("Unreachable \(element.identifier)")
    }

    private func activeScroll() -> XCUIElement? {
        for identifier in [
            "adventure.pause.scroll", "story.scroll", "quiz.scroll", "video.scroll",
            "feedback.scroll",
            "gravity.playground", "adventure.menu",
        ] {
            let scroll = app.scrollViews[identifier]
            if scroll.exists, scroll.isHittable { return scroll }
        }
        return nil
    }

    private func visibleFrame(for element: XCUIElement) -> CGRect {
        var frame = app.frame.insetBy(dx: 18, dy: 18)
        if element.identifier == "adventure.pause" { return frame }
        if let scroll = activeScroll() {
            frame = frame.intersection(scroll.frame.insetBy(dx: 4, dy: 8))
        }
        let pause = app.buttons["adventure.pause"]
        if pause.exists, pause.isHittable {
            let bottom = min(frame.maxY, pause.frame.minY - 8)
            frame.size.height = max(0, bottom - frame.minY)
        }
        return frame
    }

    private func isReachable(_ element: XCUIElement) -> Bool {
        element.isHittable
            && visibleFrame(for: element).contains(
                CGPoint(x: element.frame.midX, y: element.frame.midY))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
