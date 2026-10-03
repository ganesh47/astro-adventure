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

    func testReviewedScientificContextsRenderTheirRealCatalogProposals() throws {
        for fixture in try ReviewedScientificQuestionFixture.reviewedQuestions() {
            launch(fixture: fixture.progressJSON)
            select("adventure.resume")
            let prefix = fixture.identifierPrefix
            XCTAssertTrue(app.staticTexts["\(prefix).question"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["\(prefix).question"].label, fixture.quiz.prompt)
            for (index, choice) in fixture.quiz.choices.enumerated() {
                let identifier = "\(prefix).answer.\(index)"
                focus(identifier)
                XCTAssertEqual(app.buttons[identifier].label, "Answer \(index + 1): \(choice.text)")
                XCTAssertTrue(app.buttons[identifier].hasFocus)
                XCTAssertTrue(
                    visibleFrame(for: identifier).contains(app.buttons[identifier].frame),
                    "The entire focused proposal must be visible")
                capture("Television reviewed \(fixture.name) proposal \(index + 1): \(choice.text)")
            }
            XCTAssertFalse(app.buttons["\(prefix).check"].isEnabled)
            app.terminate()
        }
    }

    func testStoryCardChangesResetHeaderWithBottomControlFocusAndPauseResume() {
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            launch(category: category)
            select("adventure.begin")
            select("destination.sun")
            let progress = app.descendants(matching: .any).matching(identifier: "story.progress")
                .firstMatch
            let title = app.staticTexts["story.title"]
            XCTAssertTrue(progress.waitForExistence(timeout: 10))
            XCTAssertTrue(title.waitForExistence(timeout: 5))
            XCTAssertFalse(title.frame.isEmpty)
            let firstProgress = progress.value as? String
            let firstTitle = title.label
            XCTAssertTrue(firstProgress?.hasPrefix("Card 1 of ") == true)
            focus("story.next")
            XCTAssertTrue(app.buttons["story.next"].hasFocus)
            capture("\(category) Story bottom Next has native focus")
            remote.press(.select)
            waitForStoryCard("Card 2 of ", excludingTitle: firstTitle)
            XCTAssertTrue((progress.value as? String)?.hasPrefix("Card 2 of ") == true)
            XCTAssertTrue(
                visibleFrame(for: "story.progress").contains(progress.frame),
                "Next must restore the new header")
            XCTAssertTrue(
                visibleFrame(for: "story.title").contains(title.frame),
                "The new card title must be visible")
            capture("\(category) Story Next resets header after bottom focus")
            select("story.previous")
            waitForStoryCard("Card 1 of ", title: firstTitle)
            XCTAssertEqual(progress.value as? String, firstProgress)
            XCTAssertTrue(
                visibleFrame(for: "story.progress").contains(progress.frame),
                "Previous must restore the header")
            XCTAssertTrue(visibleFrame(for: "story.title").contains(title.frame))
            capture("\(category) Story Previous restores settled first card header")
            remote.press(.playPause)
            XCTAssertTrue(app.buttons["adventure.pause.resume"].waitForExistence(timeout: 5))
            select("adventure.pause.resume")
            XCTAssertTrue(progress.waitForExistence(timeout: 5))
            XCTAssertEqual(progress.value as? String, firstProgress)
            focus("story.next")
            XCTAssertTrue(app.buttons["story.next"].hasFocus)
            capture("\(category) Story Resume restores reachable native controls")
            app.terminate()
        }
    }

    private func waitForStoryCard(
        _ progressPrefix: String, title expectedTitle: String? = nil,
        excludingTitle previousTitle: String? = nil
    ) {
        let progress = app.descendants(matching: .any).matching(identifier: "story.progress")
            .firstMatch
        let title = app.staticTexts["story.title"]
        let changedAt = ProcessInfo.processInfo.systemUptime
        let settled = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                // Capture after the authored 0.45-second transition as well as the header reset.
                guard ProcessInfo.processInfo.systemUptime - changedAt >= 0.75,
                    progress.exists, title.exists,
                    (progress.value as? String)?.hasPrefix(progressPrefix) == true,
                    self.visibleFrame(for: "story.progress").contains(progress.frame),
                    self.visibleFrame(for: "story.title").contains(title.frame)
                else { return false }
                if let expectedTitle, title.label != expectedTitle { return false }
                if let previousTitle, title.label == previousTitle { return false }
                return true
            }, object: progress)
        XCTAssertEqual(
            XCTWaiter.wait(for: [settled], timeout: 5), .completed,
            "The changed Story card must settle with its own title and complete header visible")
    }

    private func launch(
        reset: Bool = true, allowance: String? = nil, category: String = "UICTContentSizeCategoryL",
        fixture: String? = nil
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
            let overlap = max(
                0,
                min(target.frame.maxY, focused.frame.maxY)
                    - max(target.frame.minY, focused.frame.minY))
            let sharesRow = overlap > min(target.frame.height, focused.frame.height) * 0.5
            var horizontal =
                target.frame.minX > focused.frame.maxX || target.frame.maxX < focused.frame.minX
                || abs(deltaY) <= 40 || (sharesRow && abs(deltaX) > abs(deltaY))
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

    private func visibleFrame(for identifier: String) -> CGRect {
        var frame = app.frame.insetBy(dx: 24, dy: 24)
        let scrollIdentifier =
            identifier.hasPrefix("video.")
            ? "video.scroll"
            : identifier.hasPrefix("story.") ? "story.scroll" : "quiz.scroll"
        let scroll = app.scrollViews[scrollIdentifier]
        if scroll.exists {
            frame = frame.intersection(scroll.frame.insetBy(dx: 8, dy: 8))
        }
        let pause = app.buttons["adventure.pause"]
        if pause.exists, !pause.frame.isEmpty, frame.intersects(pause.frame) {
            frame.size.height = max(0, min(frame.maxY, pause.frame.minY - 8) - frame.minY)
        }
        return frame
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
