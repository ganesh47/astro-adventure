import XCTest

@MainActor
final class ExplorationPlaygroundTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launch()
    }

    func testRemoteThreePlaygroundsAndSavedCreation() {
        select("adventure.begin")
        open("mercury")
        capture("Mercury remote play invitation")
        let invitation = app.staticTexts["playground.goal"].label
        focus("playground.target.mercury-large-impact")
        XCTAssertEqual(
            app.staticTexts["playground.goal"].label, invitation, "Aiming must not make a discovery"
        )
        selectTarget("mercury-small-impact")
        selectTarget("mercury-large-impact")
        capture("Mercury remote two crater patterns")
        selectTarget("mercury-ejecta-trail")
        selectTarget("mercury-sensor")
        remote.press(.menu)
        XCTAssertFalse(
            app.buttons["playground.resume"].exists, "Back puts down a held kit before pausing")
        selectTarget("mercury-sensor")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        select("playground.resume")
        select("playground.resume")
        selectTarget("mercury-sunlit-sensor-site")
        selectTarget("mercury-sensor")
        selectTarget("mercury-shadow-sensor-site")
        assertPostcard("Mercury remote created postcard")
        select("playground.keepPlaying")
        select("playground.journal")
        XCTAssertTrue(app.staticTexts["My discovery journal"].waitForExistence(timeout: 5))
        capture("Mercury remote discovery journal")
        select("playground.overlay.close")
        select("playground.pause")
        select("playground.reset")
        select("playground.pause")
        select("playground.worlds")

        open("mars")
        selectTarget("mars-crater-landmark")
        selectTarget("mars-rock-landmark")
        selectTarget("mars-layered-rock")
        capture("Mars remote brushed layers")
        selectTarget("mars-rock-camera")
        capture("Mars remote photographed rock")
        selectTarget("mars-water-model")
        XCTAssertTrue(
            app.staticTexts["playground.modelLabel"].label.contains("Ancient water model"))
        selectTarget("mars-deposit-compare")
        assertPostcard("Mars remote created postcard")
        select("playground.worlds")

        open("saturn")
        selectTarget("saturn-ice-kit")
        selectTarget("saturn-inner-orbit")
        selectTarget("saturn-ice-kit")
        selectTarget("saturn-outer-orbit")
        capture("Saturn remote both ice pieces")
        selectTarget("saturn-watch-motion")
        capture("Saturn remote orbit motion")
        selectTarget("saturn-edge-view")
        assertPostcard("Saturn remote edge-view postcard")
        select("playground.worlds")
    }

    func testRemoteHelpClipAndPausePreservePlay() {
        select("adventure.begin")
        open("mars")
        select("playground.help")
        XCTAssertTrue(app.staticTexts["playground.hint"].waitForExistence(timeout: 5))
        select("playground.help.aim")
        XCTAssertTrue(app.buttons["playground.target.mars-crater-landmark"].hasFocus)
        select("playground.help")
        select("playground.clip")
        XCTAssertTrue(app.buttons["playground.clip.play"].waitForExistence(timeout: 10))
        capture("Mars remote optional observational clip")
        select("playground.clip.ahead")
        select("playground.clip.ahead")
        XCTAssertTrue(app.buttons["playground.clip.continue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["playground.clip.try"].exists)
        capture("Mars remote paused observation with retained NASA frame")
        select("playground.clip.close")
        select("playground.pause")
        let sound = app.buttons["playground.narration"]
        let previous = sound.label
        select("playground.narration")
        XCTAssertNotEqual(sound.label, previous)
        select("playground.resume")
        selectTarget("mars-crater-landmark")
        selectTarget("mars-rock-landmark")
        XCTAssertTrue(
            app.buttons["playground.target.mars-layered-rock"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["playground.postcard"].exists)
    }

    private func open(_ destination: String) {
        if !app.buttons["destination.\(destination)"].exists {
            // The horizontal lazy world strip creates later planets as remote focus scrolls it.
            let visible = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH 'destination.'")
            ).firstMatch
            if visible.exists { focus(visible.identifier) }
            for _ in 0..<12 {
                if app.buttons["destination.\(destination)"].exists { break }
                remote.press(.right)
                _ = XCTWaiter.wait(
                    for: [
                        XCTNSPredicateExpectation(
                            predicate: NSPredicate(format: "exists == true"),
                            object: app.buttons["destination.\(destination)"])
                    ], timeout: 0.3)
            }
        }
        focus("destination.\(destination)")
        select("adventure.explore")
        select("playground.begin")
    }

    private func selectTarget(_ target: String) { select("playground.target.\(target)") }

    private func assertPostcard(_ name: String) {
        XCTAssertTrue(app.staticTexts["playground.postcard"].waitForExistence(timeout: 10))
        capture(name)
    }

    private func select(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        focus(id, file: file, line: line)
        remote.press(.select)
    }

    private func focus(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[id]
        XCTAssertTrue(target.waitForExistence(timeout: 10), "Missing \(id)", file: file, line: line)
        var previousFrame: CGRect?
        var previousHorizontal = false
        for _ in 0..<24 {
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
                || abs(deltaY) < 35
            if previousFrame == focused.frame { horizontal = !previousHorizontal }
            previousFrame = focused.frame
            previousHorizontal = horizontal
            remote.press(horizontal ? (deltaX > 0 ? .right : .left) : (deltaY > 0 ? .down : .up))
            _ = XCTWaiter.wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "hasFocus == true"), object: target)
                ], timeout: 0.25)
        }
        capture("Unreachable \(id)")
        XCTFail("Remote could not focus \(id).\n\(app.debugDescription)", file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
