import AstroContent
import AstroGameCore
import MachO
import UIKit
import XCTest

@MainActor
final class QuestionExperienceTests: XCTestCase {
    private let app = XCUIApplication()
    private var initialReduceMotion: Bool?

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        recordRunnerIdentity()
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

    func testBackgroundAndRestoredChallengeRequireExplicitResume() throws {
        launch(allowance: "30")
        openSunQuestion()
        turnSoundOff()
        tap("quiz.time.mode")
        XCTAssertEqual(app.buttons["quiz.time.mode"].label, "Calm Practice")
        tap("quiz.answer.0")
        XCUIDevice.shared.press(.home)
        app.activate()
        tap("adventure.pause.resume")
        guard
            let savedRemaining = try assertRunningSelectedChallenge(
                "Background Resume", maximumRemaining: 30)
        else { return }
        app.terminate()
        launch(reset: false, allowance: "30")
        tap("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.time.resume"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["quiz.check"].isEnabled)
        capture("Saved challenge waits for explicit resume")
        tap("quiz.time.resume")
        // Check Resume itself before any mode change could clear awaitingResume or expiry.
        _ = try assertRunningSelectedChallenge(
            "Restored Challenge Resume", maximumRemaining: savedRemaining)
    }

    private func assertRunningSelectedChallenge(_ context: String, maximumRemaining: Int) throws
        -> Int?
    {
        let started = ProcessInfo.processInfo.systemUptime
        let snapshot = try app.snapshot()
        let elements = snapshotElements(snapshot)
        let answers = elements.filter { $0.identifier == "quiz.answer.0" }
        let checks = elements.filter { $0.identifier == "quiz.check" }
        let modes = elements.filter { $0.identifier == "quiz.time.mode" }
        let timers = elements.filter { $0.identifier == "quiz.time.remaining" }
        let timerValue = timers.first?.value as? String
        let remaining = timerValue?.components(separatedBy: " ").first.flatMap { Int($0) }
        let conditions: [(String, Bool)] = [
            ("Resume disappeared", !elements.contains { $0.identifier == "quiz.time.resume" }),
            ("Check Answer enabled", checks.count == 1 && checks.first?.isEnabled == true),
            (
                "answer retained",
                answers.count == 1 && answers.first?.value as? String == "Selected"
            ),
            ("Challenge mode retained", modes.count == 1 && modes.first?.label == "Calm Practice"),
            (
                "countdown running",
                timers.count == 1 && timerValue == remaining.map { "\($0) seconds remaining" }
            ),
            (
                "saved time budget retained",
                remaining.map { $0 > 0 && $0 <= maximumRemaining } ?? false
            ),
            ("not expired", !elements.contains { $0.identifier == "quiz.time.more" }),
        ]
        let details =
            "\(context): one immediate AX snapshot after native Resume\n"
            + "Snapshot duration: \(ProcessInfo.processInfo.systemUptime - started)s\n"
            + "Timer: \(timerValue ?? "missing"); saved upper bound: \(maximumRemaining)s\n"
            + conditions.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
        let evidence = XCTAttachment(
            string: details + "\nCached hierarchy:\n\(snapshot.dictionaryRepresentation)")
        evidence.name = "\(context) immediate selected challenge state"
        evidence.lifetime = .keepAlways
        add(evidence)
        let resumed = conditions.allSatisfy { $0.1 }
        if !resumed { capture("\(context) did not resume the saved challenge") }
        XCTAssertTrue(resumed, details)
        return resumed ? remaining : nil
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
                let geometry = XCTAttachment(
                    string: "Proposal: \(answer.identifier), \(answer.frame)\n"
                        + "Uncovered viewport: \(visibleFrame(for: answer))\n\(app.debugDescription)"
                )
                geometry.name = "\(category) Sun proposal \(index + 1) capture geometry"
                geometry.lifetime = .keepAlways
                add(geometry)
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
        XCTAssertTrue(
            storyProgressIsFullyVisible("Card 2 of \(cardCount)"),
            "Next must scroll the complete new card's header into view")
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
        XCTAssertTrue(
            storyProgressIsFullyVisible("Card 1 of \(cardCount)"),
            "Previous must restore the complete prior card's header")
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
        let changedAt = ProcessInfo.processInfo.systemUptime
        var sampleCount = 0
        var lastEvaluation = "No Story header snapshot evaluated"
        var lastSnapshot: (any XCUIElementSnapshot)?
        let settled = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                let sampleStarted = ProcessInfo.processInfo.systemUptime
                guard sampleStarted - changedAt >= 0.75 else { return false }
                sampleCount += 1
                do {
                    // Evaluate identity and bounds from one AX tree, with no live queries per field.
                    let observation = try self.storyHeaderObservation(
                        expectedProgress, title: expectedTitle, excludingTitle: previousTitle)
                    lastSnapshot = observation.snapshot
                    let duration = ProcessInfo.processInfo.systemUptime - sampleStarted
                    lastEvaluation =
                        "Sample \(sampleCount), elapsed \(sampleStarted - changedAt)s, "
                        + "duration \(duration)s\n\(observation.details)"
                    return observation.ready
                } catch {
                    lastSnapshot = nil
                    lastEvaluation =
                        "Sample \(sampleCount), elapsed \(sampleStarted - changedAt)s, "
                        + "duration \(ProcessInfo.processInfo.systemUptime - sampleStarted)s\n"
                        + "Snapshot failed: \(error)"
                    return false
                }
            }, object: nil)
        let result = XCTWaiter.wait(for: [settled], timeout: 5)
        if result == .completed {
            let evaluation = XCTAttachment(string: lastEvaluation)
            evaluation.name = "Settled Story \(expectedProgress) evaluated geometry and timing"
            evaluation.lifetime = .keepAlways
            add(evaluation)
        }
        if result != .completed {
            capture("Unsettled Story \(expectedProgress)")
            let hierarchy =
                lastSnapshot.map { String(describing: $0.dictionaryRepresentation) }
                ?? "No successful snapshot in the last evaluated sample"
            let geometry = XCTAttachment(
                string: "Last evaluated Story header:\n\(lastEvaluation)\n"
                    + "Total snapshots: \(sampleCount)\nCached hierarchy:\n\(hierarchy)")
            geometry.name = "Unsettled Story card geometry and hierarchy"
            geometry.lifetime = .keepAlways
            add(geometry)
        }
        XCTAssertEqual(
            result, .completed,
            "The changed Story card must settle with its own title and restored header")
    }

    private func storyProgressIsFullyVisible(_ expectedProgress: String) -> Bool {
        do {
            return try storyHeaderObservation(expectedProgress).ready
        } catch {
            XCTFail("Cannot snapshot the restored Story header: \(error)")
            return false
        }
    }

    private func storyHeaderObservation(
        _ expectedProgress: String, title expectedTitle: String? = nil,
        excludingTitle previousTitle: String? = nil
    ) throws -> (ready: Bool, details: String, snapshot: any XCUIElementSnapshot) {
        let snapshot = try app.snapshot()
        let elements = snapshotElements(snapshot)
        let windows = elements.filter { $0.elementType == .window && validSnapshotFrame($0.frame) }
        let windowFrame =
            windows.max {
                $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
            }?.frame ?? .null
        let progress = elements.filter { $0.identifier == "story.progress" }
        let titles = elements.filter { $0.identifier == "story.title" }
        let scrolls = elements.filter { $0.identifier == "story.scroll" }
        let pause = elements.first { $0.identifier == "adventure.pause" }
        let progressFrame = progress.first?.frame ?? .null
        let titleFrame = titles.first?.frame ?? .null
        let scrollFrame = scrolls.first?.frame ?? .null
        let pauseFrame = pause?.frame ?? .null
        let progressValue = progress.first?.value as? String
        let titleLabel = titles.first?.label
        var viewport = CGRect.null
        if validSnapshotFrame(windowFrame), validSnapshotFrame(scrollFrame) {
            viewport = windowFrame.insetBy(dx: 18, dy: 18)
                .intersection(scrollFrame.insetBy(dx: 4, dy: 8))
            if validSnapshotFrame(pauseFrame),
                windowFrame.contains(CGPoint(x: pauseFrame.midX, y: pauseFrame.midY))
            {
                viewport.size.height = max(
                    0, min(viewport.maxY, pauseFrame.minY - 8) - viewport.minY)
            }
        }
        // Progress is a read-only glyph. Its complete bounds and exact value establish visibility;
        // the long title is revealed separately, and controls retain native hit-point/tap checks.
        let conditions: [(String, Bool)] = [
            ("main window valid", validSnapshotFrame(windowFrame)),
            ("one Story scroll", scrolls.count == 1 && validSnapshotFrame(scrollFrame)),
            ("one progress element", progress.count == 1 && validSnapshotFrame(progressFrame)),
            ("one title element", titles.count == 1 && validSnapshotFrame(titleFrame)),
            ("progress value matches", progressValue == expectedProgress),
            (
                "complete progress in viewport",
                validSnapshotFrame(viewport) && viewport.contains(progressFrame)
            ),
            ("title matches", expectedTitle.map { titleLabel == $0 } ?? true),
            ("title changed", previousTitle.map { titleLabel != $0 } ?? true),
            (
                "Pause sheet absent",
                !elements.contains { $0.identifier == "adventure.pause.scroll" }
            ),
        ]
        let details =
            "Progress: \(progressValue ?? "missing"), \(progressFrame)\n"
            + "Title: \(titleLabel ?? "missing"), \(titleFrame)\n"
            + "Window: \(windowFrame)\nStory scroll: \(scrollFrame)\n"
            + "Pause: \(pauseFrame)\nViewport: \(viewport)\n"
            + conditions.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
        return (conditions.allSatisfy { $0.1 }, details, snapshot)
    }

    private func snapshotElements(_ snapshot: any XCUIElementSnapshot)
        -> [any XCUIElementSnapshot]
    {
        [snapshot] + snapshot.children.flatMap { snapshotElements($0) }
    }

    private func validSnapshotFrame(_ frame: CGRect) -> Bool {
        !frame.isEmpty && !frame.isNull && !frame.isInfinite
            && frame.origin.x.isFinite && frame.origin.y.isFinite
            && frame.width.isFinite && frame.height.isFinite
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
        guard let motion = nativeReduceMotionSwitch(in: settings) else { return }
        guard let initialValue = motion.value as? String,
            initialValue == "0" || initialValue == "1"
        else {
            XCTFail("Native Reduce Motion value must be 0 or 1 before changing the setting")
            settings.terminate()
            return
        }
        let initiallyEnabled = initialValue == "1"
        initialReduceMotion = initiallyEnabled
        defer { restoreNativeReduceMotion() }
        if !initiallyEnabled {
            guard setSettingsSwitch(motion, enabled: true, in: settings) else { return }
        }
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
        // Pause is already visible beside Launch. Activate it before the 8.6-second flight
        // completes instead of spending that interval querying and revealing a moving control.
        let pause = app.buttons["gravity.pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 3))
        XCTAssertTrue(pause.isHittable, "Launch must keep the native Pause action visible")
        pause.press(forDuration: 0.1)
        XCTAssertTrue(app.buttons["gravity.resume"].waitForExistence(timeout: 3))
        XCTAssertTrue((field.value as? String ?? "").contains("Flight paused on Moon"))
        reveal(field)
        XCTAssertTrue(isReachable(field))
        capture("Native Reduce Motion static Moon and Earth trajectories")
    }

    private func nativeReduceMotionSwitch(in settings: XCUIApplication) -> XCUIElement? {
        let motion = settings.switches["Reduce Motion"]
        if !motion.waitForExistence(timeout: 1) {
            let motionPage = settings.staticTexts["Motion"].firstMatch
            if !motionPage.exists || !motionPage.isHittable {
                let accessibility = settingsLabel("Accessibility", in: settings)
                guard accessibility.exists, accessibility.isHittable else {
                    XCTFail("Native Settings Accessibility link must remain reachable")
                    return nil
                }
                accessibility.tap()
            }
            let motionLink = settingsLabel("Motion", in: settings)
            guard motionLink.exists, motionLink.isHittable else {
                XCTFail("Native Settings Motion link must remain reachable")
                return nil
            }
            motionLink.tap()
        }
        guard motion.waitForExistence(timeout: 10) else {
            let screenshot = XCTAttachment(screenshot: settings.screenshot())
            screenshot.name = "Native Reduce Motion switch missing after navigation"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let hierarchy = XCTAttachment(string: settings.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            XCTFail("Native Settings must expose Reduce Motion after navigation")
            return nil
        }
        return motion
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
    ) -> Bool {
        guard toggle.exists, toggle.isHittable else {
            XCTFail("Native Settings switch must exist and be reachable before activation")
            return false
        }
        let value = enabled ? "1" : "0"
        guard toggle.value as? String != value else { return true }
        // Settings can expose both a named row and its native switch child.
        // Activate the native switch when available, then verify the named row.
        let nativeSwitch = toggle.children(matching: .switch).firstMatch
        if nativeSwitch.exists {
            guard nativeSwitch.isHittable else {
                XCTFail("Native Settings switch child must be reachable before activation")
                return false
            }
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
        return result == .completed && toggle.value as? String == value
    }

    private func restoreNativeReduceMotion() {
        guard let original = initialReduceMotion else { return }
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.activate()
        defer { settings.terminate() }
        // Preferences may relaunch at its root after the app and orientation change.
        // Navigate to Motion again; never synthesize a touch for a missing element.
        guard let motion = nativeReduceMotionSwitch(in: settings) else { return }
        guard setSettingsSwitch(motion, enabled: original, in: settings) else { return }
        let restored = motion.value as? String == (original ? "1" : "0")
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
        guard element.exists else { return }
        let identifier = element.identifier
        var steps: [String] = []
        for step in 0..<18 {
            guard element.exists else { break }
            if fully ? isFullyVisible(element) : isReachable(element) { return }
            let frame = visibleFrame(for: element)
            guard !frame.isEmpty, !frame.isNull, !frame.isInfinite, frame.height > 40 else { break }
            let elementFrame = element.frame
            steps.append("\(step): \(elementFrame) in \(frame)")
            // The ScrollView's AX frame includes the bottom safe-area inset.
            // Center a whole card to leave space at both edges of the uncovered viewport.
            let gap = elementFrame.midY - frame.midY
            let distance = min(frame.height * 0.55, max(fully ? 12 : 40, abs(gap)))
            let direction: CGFloat = gap < 0 ? -1 : 1
            // Keep the physical pan outside the centered buttons, including Pause actions.
            let gutter = min(44, frame.width * 0.055)
            let dragX = frame.minX + gutter
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(
                CGVector(
                    dx: dragX - app.frame.minX,
                    dy: frame.midY + direction * distance / 2 - app.frame.minY))
            let end = origin.withOffset(
                CGVector(
                    dx: dragX - app.frame.minX,
                    dy: frame.midY - direction * distance / 2 - app.frame.minY))
            let velocity = XCUIGestureVelocity(
                rawValue: fully && elementFrame.height > frame.height * 0.75 ? 10 : 100)
            // Stop momentum before checking visibility or activating a revealed control.
            start.press(
                forDuration: 0.1, thenDragTo: end, withVelocity: velocity,
                thenHoldForDuration: 0.5)
        }
        capture("Unreachable \(identifier)")
        let finalFrame = element.exists ? "\(element.frame)" : "missing"
        let geometry = XCTAttachment(
            string: "Element: \(identifier)\nFrame: \(finalFrame)\n"
                + "Pan steps:\n\(steps.joined(separator: "\n"))\n\(app.debugDescription)")
        geometry.name = "Unreachable \(identifier) geometry and hierarchy"
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
        guard element.exists else { return false }
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

    private func recordRunnerIdentity() {
        let executable = Bundle(for: Self.self).executableURL?.path ?? "missing"
        var loadedUUID = "missing"
        var loadedPath = "missing"
        for index in 0..<_dyld_image_count() {
            guard let name = _dyld_get_image_name(index),
                String(cString: name).hasSuffix("/AstroAdventure-iOS-UITests"),
                let header = _dyld_get_image_header(index)
            else { continue }
            loadedPath = String(cString: name)
            let rawHeader = UnsafeRawPointer(header)
            let headerSize =
                header.pointee.magic == MH_MAGIC_64
                ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
            var command = rawHeader.advanced(by: headerSize)
            let end = command.advanced(by: Int(header.pointee.sizeofcmds))
            for _ in 0..<header.pointee.ncmds {
                guard command.advanced(by: MemoryLayout<load_command>.size) <= end else { break }
                let load = command.load(as: load_command.self)
                guard load.cmdsize >= MemoryLayout<load_command>.size,
                    command.advanced(by: Int(load.cmdsize)) <= end
                else { break }
                if load.cmd == LC_UUID, load.cmdsize >= MemoryLayout<uuid_command>.size {
                    loadedUUID = UUID(uuid: command.load(as: uuid_command.self).uuid).uuidString
                    break
                }
                command = command.advanced(by: Int(load.cmdsize))
            }
            break
        }
        let identity =
            "Question capture helper v16: gutter precision and complete geometry\n"
            + "Bundle executable: \(executable)\nLoaded image: \(loadedPath)\n"
            + "Loaded Mach-O UUID: \(loadedUUID)"
        print(identity)
        let attachment = XCTAttachment(string: identity)
        attachment.name = "Executing question test bundle identity"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
