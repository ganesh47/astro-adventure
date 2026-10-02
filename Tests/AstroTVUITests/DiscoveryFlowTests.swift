import XCTest

@MainActor
final class DiscoveryFlowTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run {
            app.launchArguments = [
                "--ui-testing", "--reset-ui-testing-progress", "--legacy-learning",
            ]
            app.launch()
        }
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

        let mission = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "mission.select.mercury")
        ).firstMatch
        XCTAssertTrue(mission.waitForExistence(timeout: 10))
        select(mission.identifier)
        select("mission.start")

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

        // Crater Detective's first correct answer in Explorer mode is position 1.
        // Deliberately choose another clue, then recover without losing the discovery.
        select("quiz.answer.0")
        XCTAssertTrue(app.buttons["feedback.continue"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["feedback.continue"].label, "Try Again")
        select("feedback.continue")

        for _ in 0..<30 {
            if app.buttons["results.continue"].exists { break }
            if app.buttons["story.next"].exists {
                select("story.next")
                continue
            }
            if app.buttons["activity.option.0"].exists {
                var solvedActivity = false
                for answer in 0..<2 {
                    select("activity.option.\(answer)")
                    if app.buttons["activity.check"].exists { select("activity.check") }
                    let feedback = app.buttons["feedback.continue"]
                    XCTAssertTrue(feedback.waitForExistence(timeout: 5))
                    solvedActivity = feedback.label == "Continue"
                    select("feedback.continue")
                    if solvedActivity { break }
                }
                XCTAssertTrue(solvedActivity)
                continue
            }
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
        XCTAssertTrue(app.staticTexts["Discovery saved in your Passport"].exists)
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
        app.launchArguments = ["--ui-testing", "--legacy-learning"]
        app.launch()
        XCTAssertTrue(app.buttons["adventure.begin"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["adventure.begin"].label, "Continue Adventure")
        select("adventure.begin")
        XCTAssertTrue(mercury.waitForExistence(timeout: 5))
        XCTAssertTrue(mercury.label.contains("Stamped"), "Stamp must survive an app relaunch")
    }

    func testMissionCursorResumesAcrossRelaunch() {
        select("adventure.begin")
        focus("destination.mercury")
        select("adventure.explore")
        let mission = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "mission.select.mercury")
        ).firstMatch
        XCTAssertTrue(mission.waitForExistence(timeout: 10))
        select(mission.identifier)
        select("mission.start")
        select("story.next")
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 5))
        remote.press(.playPause)
        select("adventure.pause.worlds")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--legacy-learning"]
        app.launch()
        select("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))
        capture("Resumed learning question")
    }

    func testRemoteComparisonAndModelActivities() {
        select("adventure.begin")
        for missionID in ["mercury-heat-and-shadow", "mercury-speedy-year"] {
            focus("destination.mercury")
            select("adventure.explore")
            select("mission.select.\(missionID)")
            select("mission.start")
            for _ in 0..<40 {
                if app.buttons["results.continue"].exists { break }
                if app.buttons["story.next"].exists {
                    select("story.next")
                } else if app.buttons["activity.option.0"].exists {
                    solveActivity()
                } else if app.buttons["quiz.answer.0"].exists {
                    solveQuestion(prefix: "quiz")
                } else if app.buttons["feedback.continue"].exists {
                    select("feedback.continue")
                } else {
                    XCTFail("Missing mission progression action")
                    break
                }
            }
            XCTAssertTrue(app.buttons["results.continue"].waitForExistence(timeout: 5))
            capture("Remote \(missionID) celebration")
            select("results.continue")
            select("mission.worlds")
        }
    }

    func testRemoteNativeVideoSeekingReplayAndPausedResume() {
        select("adventure.begin")
        focus("destination.mercury")
        select("adventure.explore")
        select("video.start.mercury")
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 10))
        capture("Television offline film")
        select("video.transcript")
        select("video.transcript.close")
        seekToVideoQuestion()
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        select("video.hint")
        select("video.replay")
        remote.press(.playPause)
        if app.buttons["adventure.pause.resume"].exists { select("adventure.pause.resume") }
        seekToVideoQuestion()
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--legacy-learning"]
        app.launch()
        select("adventure.resume")
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        capture("Television restored film question")
        solveQuestion(prefix: "video")
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 5))
        seekToVideoQuestion()
        solveQuestion(prefix: "video")
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 5))
        select("video.play")
        XCTAssertTrue(app.staticTexts["Space cinema complete!"].waitForExistence(timeout: 35))
        capture("Television film completion")
        select("video.worlds")
        XCTAssertFalse(app.buttons["destination.mercury"].label.contains("Stamped"))
    }

    private func seekToVideoQuestion() {
        // Core seeking is deterministic while paused, regardless of remote-focus latency.
        for _ in 0..<3 {
            if app.buttons["video.answer.0"].exists { return }
            select("video.seek.forward")
        }
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 5))
    }

    private func solveQuestion(prefix: String) {
        let feedbackID = prefix == "video" ? "video.continue" : "feedback.continue"
        XCTAssertTrue(app.buttons["\(prefix).answer.0"].waitForExistence(timeout: 10))
        for index in 0..<3 {
            let identifier = "\(prefix).answer.\(index)"
            if !app.buttons[identifier].exists { continue }
            select(identifier)
            let feedback = app.buttons[feedbackID]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let correct = feedback.label == "Continue"
            select(feedbackID)
            if correct { return }
        }
        XCTFail("Question must be solvable")
    }

    private func solveActivity() {
        for index in 0..<2 {
            select("activity.option.\(index)")
            if app.buttons["activity.check"].exists {
                capture("Television model outcome")
                select("activity.check")
            }
            let feedback = app.buttons["feedback.continue"]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let correct = feedback.label == "Continue"
            select("feedback.continue")
            if correct { return }
        }
        XCTFail("Activity must be solvable")
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
