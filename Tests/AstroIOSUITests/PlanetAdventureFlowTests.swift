import UIKit
import XCTest

@MainActor
final class PlanetAdventureFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run {
            XCUIDevice.shared.orientation = .landscapeLeft
            app.launchArguments = [
                "--ui-testing", "--reset-ui-testing-progress", "--legacy-learning",
            ]
            app.launch()
        }
    }

    func testTouchComparisonAndModelActivities() {
        tap("adventure.begin")
        for missionID in ["mercury-heat-and-shadow", "mercury-speedy-year"] {
            tap("destination.mercury")
            tap("adventure.explore")
            let sound = app.buttons["mission.narration"]
            XCTAssertTrue(sound.waitForExistence(timeout: 5))
            if sound.label == "Sound On" { sound.tap() }
            XCTAssertEqual(sound.label, "Sound Off")
            selectMission(missionID)
            tap("mission.start")
            finishMission()
            capture("Touch \(missionID) celebration")
            tap("results.continue")
            tap("mission.worlds")
        }
    }

    func testTabletPortraitClueAndFilmLayouts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Portrait layout applies to iPad")
        }
        XCUIDevice.shared.orientation = .portrait
        tap("adventure.begin")
        tap("destination.mercury")
        tap("adventure.explore")
        tap("mission.select.mercury-crater-detective")
        tap("mission.start")
        capture("Tablet portrait clue")
        XCTAssertTrue(app.buttons["story.next"].isHittable)
        tap("story.next")
        capture("Tablet portrait question")
        XCTAssertTrue(app.buttons["quiz.answer.0"].isHittable)
        tap("adventure.pause")
        tap("adventure.pause.worlds")
        tap("adventure.explore")
        tap("video.start.mercury")
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 10))
        capture("Tablet portrait film")
        XCTAssertTrue(app.buttons["video.play"].isHittable)
        XCUIDevice.shared.orientation = .landscapeRight
        capture("Tablet landscape film")
        XCTAssertTrue(app.buttons["video.play"].isHittable)
    }

    func testNativeVideoSeekingReplayAndPausedResume() {
        tap("adventure.begin")
        tap("destination.mercury")
        tap("adventure.explore")
        tap("video.start.mercury")
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 10))
        capture("Touch offline film")
        tap("video.transcript")
        tap("video.transcript.close")
        tap("video.play")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["adventure.pause.resume"].waitForExistence(timeout: 10))
        tap("adventure.pause.resume")
        // XCTest can wait for playback to settle until the first authored checkpoint.
        // Returning from the background must preserve either paused state.
        if !app.buttons["video.answer.0"].exists {
            XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 5))
        }
        XCTAssertFalse(app.buttons["video.pause"].exists, "Returning must not restart playback")
        seekToVideoQuestion()
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        tap("video.hint")
        tap("video.replay")
        tap("adventure.pause")
        tap("adventure.pause.resume")
        seekToVideoQuestion()
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--legacy-learning"]
        app.launch()
        tap("adventure.resume")
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        capture("Touch paused film question")
        solveVideoQuestion()
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 5))
        seekToVideoQuestion()
        solveVideoQuestion()
        XCTAssertTrue(app.buttons["video.play"].waitForExistence(timeout: 5))
        tap("video.play")
        XCTAssertTrue(app.staticTexts["Space cinema complete!"].waitForExistence(timeout: 35))
        capture("Touch film completion")
        tap("video.worlds")
        XCTAssertFalse(app.buttons["destination.mercury"].label.contains("Stamped"))
    }

    private func seekToVideoQuestion() {
        // Seek while paused: machine speed must not race a disappearing playback control.
        for _ in 0..<3 {
            if app.buttons["video.answer.0"].exists { return }
            tap("video.seek.forward")
        }
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 5))
    }

    private func finishMission() {
        for _ in 0..<40 {
            if app.buttons["results.continue"].exists { return }
            if app.buttons["story.next"].exists {
                tap("story.next")
            } else if app.buttons["activity.option.0"].exists {
                solveActivity()
            } else if app.buttons["quiz.answer.0"].exists {
                solveQuestion()
            } else if app.buttons["feedback.continue"].exists {
                tap("feedback.continue")
            } else {
                XCTFail("Missing mission progression action")
                return
            }
        }
        XCTFail("Mission did not complete")
    }

    private func solveVideoQuestion() {
        XCTAssertTrue(app.buttons["video.answer.0"].waitForExistence(timeout: 10))
        for index in 0..<3 {
            let answer = app.buttons["video.answer.\(index)"]
            if !answer.exists { continue }
            answer.tap()
            let feedback = app.buttons["video.continue"]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let correct = feedback.label == "Continue"
            feedback.tap()
            if correct { return }
        }
        XCTFail("Video question must be solvable")
    }

    func testTouchMissionActivityPassportAndResume() {
        tap("adventure.begin")
        tap("destination.mercury")
        tap("adventure.explore")
        let mission = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "mission.select.mercury")
        ).firstMatch
        XCTAssertTrue(mission.waitForExistence(timeout: 10))
        mission.tap()
        tap("mission.start")
        tap("story.next")
        tap("quiz.hint")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--legacy-learning"]
        app.launch()
        tap("adventure.resume")
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))

        for _ in 0..<40 {
            if app.buttons["results.continue"].exists { break }
            if app.buttons["story.next"].exists {
                tap("story.next")
                continue
            }
            if app.buttons["activity.option.0"].exists {
                solveActivity()
                continue
            }
            if app.buttons["quiz.answer.0"].exists {
                solveQuestion()
                continue
            }
            if app.buttons["feedback.continue"].exists {
                tap("feedback.continue")
                continue
            }
            XCTFail("The mission must offer an accessible next action")
            break
        }
        XCTAssertTrue(app.buttons["results.continue"].waitForExistence(timeout: 5))
        capture("Touch mission celebration")
        tap("results.continue")
        XCTAssertTrue(
            app.otherElements["mission.passport"].exists || app.buttons["mission.worlds"].exists)
        tap("mission.worlds")
        XCTAssertTrue(app.buttons["destination.mercury"].label.contains("Stamped"))
    }

    private func solveQuestion() {
        for index in 0..<3 {
            let answer = app.buttons["quiz.answer.\(index)"]
            if !answer.exists { continue }
            answer.tap()
            let feedback = app.buttons["feedback.continue"]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let correct = feedback.label == "Continue"
            feedback.tap()
            if correct { return }
        }
        XCTFail("Every question must be solvable with its visible choices")
    }

    private func solveActivity() {
        for index in 0..<2 {
            tap("activity.option.\(index)")
            if app.buttons["activity.check"].exists { tap("activity.check") }
            let feedback = app.buttons["feedback.continue"]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let correct = feedback.label == "Continue"
            feedback.tap()
            if correct { return }
        }
        XCTFail("The science activity must be solvable")
    }

    private func tap(_ id: String) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing action: \(id)")
        if !button.isHittable { app.swipeUp() }
        button.tap()
    }

    private func selectMission(_ id: String) {
        XCTContext.runActivity(named: "Reveal and select mission \(id)") { _ in
            let button = app.buttons["mission.select.\(id)"]
            XCTAssertTrue(button.waitForExistence(timeout: 10))
            let missions = app.scrollViews.firstMatch
            capture("Chooser before revealing \(id)")
            for _ in 0..<8 {
                let visible = missions.frame.intersection(app.frame)
                if button.frame.minY >= visible.minY && button.frame.maxY <= visible.maxY {
                    break
                }
                let delta = button.frame.midY - visible.midY
                let distance = min(abs(delta), visible.height * 0.45)
                let start = missions.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.08, dy: delta > 0 ? 0.75 : 0.25))
                let end = start.withOffset(CGVector(dx: 0, dy: delta > 0 ? -distance : distance))
                start.press(
                    forDuration: 0.1, thenDragTo: end, withVelocity: .slow,
                    thenHoldForDuration: 0.25)
            }
            capture("Before selecting \(id)")
            captureHierarchy("Before selecting \(id)")
            XCTAssertGreaterThanOrEqual(button.frame.minY, missions.frame.minY)
            XCTAssertLessThanOrEqual(button.frame.maxY, missions.frame.maxY)
            XCTAssertTrue(button.isHittable, "Mission card must be visible before selection")
            button.tap()
            capture("After selecting \(id)")
            captureHierarchy("After selecting \(id)")
        }
    }

    private func captureHierarchy(_ name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
