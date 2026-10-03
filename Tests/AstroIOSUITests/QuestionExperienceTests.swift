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
                reveal(answer, fully: true)
                XCTAssertTrue(
                    isFullyVisible(answer),
                    "The entire Sun proposal must be visible: \(answer.frame) in \(visibleFrame(for: answer))"
                )
                capture("\(category) readable Sun proposal \(index + 1)")
            }
            tap("quiz.answer.0")
            tap("quiz.check")
            capture("\(category) readable explanatory feedback")
            XCTAssertTrue(isReachable(button("feedback.continue")))
            tap("feedback.hint")
            tap("quiz.hint.close")
            XCTAssertTrue(isReachable(button("quiz.back")))
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
                reveal(answer, fully: true)
                XCTAssertTrue(isFullyVisible(answer), "The entire proposal must be visible")
                capture("Reviewed \(fixture.name) proposal \(index + 1): \(choice.text)")
            }
            XCTAssertFalse(app.buttons["\(prefix).check"].isEnabled)
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
        let title = app.staticTexts["story.title"]
        let cardCount = DiscoveryStoryCatalog.slides(destinationID: "sun", ageBand: .ages7To9).count
        XCTAssertGreaterThan(cardCount, 1)
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let firstTitle = title.label
        XCTAssertEqual(progress.value as? String, "Card 1 of \(cardCount)")
        tap("story.next")
        waitForStoryCard("Card 2 of \(cardCount)", excludingTitle: firstTitle)
        XCTAssertEqual(progress.value as? String, "Card 2 of \(cardCount)")
        XCTAssertTrue(progress.isHittable, "Next must scroll the new card's header into view")
        capture("Largest text settled Story Next restores the new card top")
        reveal(title, fully: true)
        XCTAssertTrue(
            isFullyVisible(title),
            "The complete new card title must be readable: \(title.frame) in \(visibleFrame(for: title))"
        )
        capture("Largest text settled Story Next complete title")
        tap("story.previous")
        waitForStoryCard("Card 1 of \(cardCount)", title: firstTitle)
        XCTAssertEqual(progress.value as? String, "Card 1 of \(cardCount)")
        XCTAssertTrue(progress.isHittable, "Previous must restore the prior card's header")
        capture("Largest text settled Story Previous restores the first card top")
        reveal(title, fully: true)
        XCTAssertTrue(isFullyVisible(title))
        capture("Largest text settled Story Previous complete title")
        tap("adventure.pause")
        XCTAssertTrue(app.scrollViews["adventure.pause.scroll"].waitForExistence(timeout: 5))
        let resume = button("adventure.pause.resume")
        reveal(resume, fully: true)
        XCTAssertTrue(isFullyVisible(resume), "The complete native Resume action must be visible")
        capture("Largest text Pause Resume action fully visible")
        tap("adventure.pause.resume")
        XCTAssertFalse(app.scrollViews["adventure.pause.scroll"].exists)
        XCTAssertTrue(app.buttons["story.next"].exists)
        XCTAssertEqual(progress.value as? String, "Card 1 of \(cardCount)")
        tap("adventure.pause")
        let worlds = button("adventure.pause.worlds")
        reveal(worlds, fully: true)
        XCTAssertTrue(isFullyVisible(worlds), "The complete native Worlds action must be visible")
        capture("Largest text Pause Worlds action fully visible")
        tap("adventure.pause.worlds")
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 5))
    }

    private func waitForStoryCard(
        _ expectedProgress: String, title expectedTitle: String? = nil,
        excludingTitle previousTitle: String? = nil
    ) {
        let progress = app.descendants(matching: .any).matching(identifier: "story.progress")
            .firstMatch
        let title = app.staticTexts["story.title"]
        let changedAt = ProcessInfo.processInfo.systemUptime
        let settled = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                // The full header and long title are captured separately on compact screens.
                guard ProcessInfo.processInfo.systemUptime - changedAt >= 0.75,
                    progress.exists, title.exists,
                    progress.value as? String == expectedProgress,
                    self.isFullyVisible(progress)
                else { return false }
                if let expectedTitle, title.label != expectedTitle { return false }
                if let previousTitle, title.label == previousTitle { return false }
                return true
            }, object: progress)
        let result = XCTWaiter.wait(for: [settled], timeout: 5)
        if result != .completed {
            capture("Unsettled Story \(expectedProgress)")
            let geometry = XCTAttachment(
                string: "Progress: \(progress.value ?? "missing"), \(progress.frame)\n"
                    + "Title: \(title.label), \(title.frame)\n\(app.debugDescription)")
            geometry.name = "Unsettled Story card geometry and hierarchy"
            geometry.lifetime = .keepAlways
            add(geometry)
        }
        XCTAssertEqual(
            result, .completed,
            "The changed Story card must settle with its own title and restored header")
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
        reveal(field)
        XCTAssertTrue(isReachable(field))
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
        // Settings can expose both a named row and its native switch child.
        // Activate the native switch when available, then verify the named row.
        let nativeSwitch = toggle.children(matching: .switch).firstMatch
        if nativeSwitch.exists {
            XCTAssertTrue(nativeSwitch.isHittable)
            nativeSwitch.tap()
        } else {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
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
        let proposal =
            identifier.hasPrefix("quiz.answer.")
            || identifier.hasPrefix("mission.quiz.answer.")
        if !proposal { reveal(element, fully: true) }
        guard proposal ? isReachable(element) : isFullyVisible(element) else {
            capture("Unreachable \(identifier)")
            XCTFail("Unreachable \(identifier)")
            return
        }
        element.tap()
    }

    private func reveal(_ element: XCUIElement, fully: Bool = false) {
        for _ in 0..<18 {
            if fully ? isFullyVisible(element) : isReachable(element) { return }
            let frame = visibleFrame(for: element)
            guard !frame.isEmpty, !frame.isNull, !frame.isInfinite, frame.height > 40 else { break }
            // The ScrollView's AX frame includes the bottom safe-area inset.
            // Start and end the real drag inside the uncovered content viewport.
            let gap: CGFloat
            if fully, element.frame.minY < frame.minY {
                gap = element.frame.minY - frame.minY
            } else if fully, element.frame.maxY > frame.maxY {
                gap = element.frame.maxY - frame.maxY
            } else {
                gap = element.frame.midY - frame.midY
            }
            let distance = min(frame.height * 0.55, max(fully ? 12 : 40, abs(gap)))
            let direction: CGFloat = gap < 0 ? -1 : 1
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(
                CGVector(
                    dx: frame.midX - app.frame.minX,
                    dy: frame.midY + direction * distance / 2 - app.frame.minY))
            let end = origin.withOffset(
                CGVector(
                    dx: frame.midX - app.frame.minX,
                    dy: frame.midY - direction * distance / 2 - app.frame.minY))
            // Stop momentum before checking visibility or activating a revealed control.
            start.press(
                forDuration: 0.1, thenDragTo: end, withVelocity: .slow,
                thenHoldForDuration: 0.25)
        }
        capture("Unreachable \(element.identifier)")
        let geometry = XCTAttachment(
            string: "Element: \(element.identifier)\nFrame: \(element.frame)\n"
                + "Uncovered viewport: \(visibleFrame(for: element))\n\(app.debugDescription)")
        geometry.name = "Unreachable \(element.identifier) geometry and hierarchy"
        geometry.lifetime = .keepAlways
        add(geometry)
    }

    private func activeScroll() -> XCUIElement? {
        for identifier in [
            "adventure.pause.scroll", "story.scroll", "quiz.scroll", "video.scroll",
            "feedback.scroll",
            "gravity.playground", "adventure.menu",
        ] {
            let scroll = app.scrollViews[identifier]
            if scroll.exists, hasVisibleGeometry(scroll), scroll.isHittable { return scroll }
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
        if pause.exists, hasVisibleGeometry(pause), pause.isHittable {
            let bottom = min(frame.maxY, pause.frame.minY - 8)
            frame.size.height = max(0, bottom - frame.minY)
        }
        return frame
    }

    private func isReachable(_ element: XCUIElement) -> Bool {
        guard element.exists, hasVisibleGeometry(element) else { return false }
        let frame = element.frame
        guard visibleFrame(for: element).contains(CGPoint(x: frame.midX, y: frame.midY)) else {
            return false
        }
        // XCTest can fail the method while querying an offscreen activation point.
        return element.isHittable
    }

    private func isFullyVisible(_ element: XCUIElement) -> Bool {
        guard element.exists, hasVisibleGeometry(element) else { return false }
        return visibleFrame(for: element).contains(element.frame) && element.isHittable
    }

    private func hasVisibleGeometry(_ element: XCUIElement) -> Bool {
        let frame = element.frame
        return !frame.isEmpty && !frame.isNull && !frame.isInfinite
            && app.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
