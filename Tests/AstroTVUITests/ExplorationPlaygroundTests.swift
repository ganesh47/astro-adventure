import XCTest

@MainActor
final class ExplorationPlaygroundTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = [
            "--ui-testing", "--reset-ui-testing-progress", "--legacy-playgrounds",
        ]
        app.launch()
    }

    func testRemoteThreePlaygroundsAndSavedCreation() {
        select("adventure.begin")
        open("mercury")
        capture("Mercury remote play invitation")
        XCTAssertFalse(app.buttons["playground.action"].exists, "Each action has one control")
        remote.press(.menu)
        XCTAssertTrue(app.buttons["playground.resume"].waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(app.buttons["playground.target.mercury-small-impact"].hasFocus)
        let invitation = app.staticTexts["playground.goal"].label
        focus("playground.target.mercury-large-impact")
        XCTAssertEqual(
            app.staticTexts["playground.goal"].label, invitation, "Aiming must not make a discovery"
        )
        selectTarget("mercury-small-impact")
        XCTAssertFalse(app.buttons["playground.target.mercury-small-impact"].exists)
        XCTAssertTrue(app.buttons["playground.target.mercury-large-impact"].hasFocus)
        XCTAssertTrue(app.staticTexts["playground.progress"].label.contains("1 of 2 tried"))
        selectTarget("mercury-large-impact")
        capture("Mercury remote two crater patterns")
        select("playground.next")
        selectTarget("mercury-ejecta-trail")
        select("playground.next")
        XCTAssertFalse(app.buttons["playground.target.mercury-sensor"].exists)
        selectTarget("mercury-sunlit-sensor-site")
        capture("Mercury one remaining sensor action")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--legacy-playgrounds"]
        app.launch()
        select("playground.resume")
        let restoredFocus = XCTWaiter.wait(
            for: [
                XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "hasFocus == true"),
                    object: app.buttons["playground.resume"])
            ], timeout: 5)
        capture("Restored legacy pause focus")
        let restoredHierarchy = XCTAttachment(string: app.debugDescription)
        restoredHierarchy.name = "Restored legacy pause hierarchy"
        restoredHierarchy.lifetime = .keepAlways
        add(restoredHierarchy)
        XCTAssertEqual(restoredFocus, .completed, "Restored play focuses explicit resume")
        select("playground.resume")
        XCTAssertFalse(app.buttons["playground.target.mercury-sunlit-sensor-site"].exists)
        XCTAssertTrue(app.buttons["playground.target.mercury-shadow-sensor-site"].hasFocus)
        selectTarget("mercury-shadow-sensor-site")
        assertPostcard("Mercury remote created postcard")
        remote.press(.menu)
        XCTAssertTrue(app.buttons["playground.resume"].waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(app.buttons["playground.keepPlaying"].hasFocus)
        select("playground.keepPlaying")
        selectTarget("mercury-shadow-sensor-site")
        let freePlayTool = app.buttons["playground.target.mercury-shadow-sensor-site"]
        XCTAssertTrue(freePlayTool.hasFocus, "Free play keeps the tool the child just used")
        XCTAssertGreaterThanOrEqual(freePlayTool.frame.minX, app.frame.minX + 50)
        XCTAssertLessThanOrEqual(freePlayTool.frame.maxX, app.frame.maxX - 50)
        XCTAssertFalse(app.staticTexts["playground.postcard"].exists)
        capture("Mercury free play tools")
        select("playground.pause")
        select("playground.journal")
        XCTAssertTrue(app.staticTexts["My discovery journal"].waitForExistence(timeout: 5))
        capture("Mercury remote discovery journal")
        select("playground.overlay.close")
        select("playground.pause")
        select("playground.reset")
        select("playground.pause")
        select("playground.worlds")

        open("mars")
        capture("Mars remote two landmark actions")
        selectTarget("mars-crater-landmark")
        selectTarget("mars-rock-landmark")
        select("playground.next")
        selectTarget("mars-layered-rock")
        capture("Mars remote brushed layers")
        selectTarget("mars-rock-camera")
        capture("Mars remote photographed rock")
        select("playground.next")
        selectTarget("mars-water-model")
        XCTAssertTrue(
            app.staticTexts["playground.modelLabel"].label.contains("Ancient water model"))
        selectTarget("mars-deposit-compare")
        assertPostcard("Mars remote created postcard")
        select("playground.worlds")

        open("saturn")
        capture("Saturn remote two ice actions")
        XCTAssertFalse(app.buttons["playground.target.saturn-ice-kit"].exists)
        selectTarget("saturn-inner-orbit")
        XCTAssertTrue(app.buttons["playground.target.saturn-outer-orbit"].hasFocus)
        selectTarget("saturn-outer-orbit")
        capture("Saturn remote both ice pieces")
        select("playground.next")
        selectTarget("saturn-watch-motion")
        capture("Saturn remote orbit motion")
        select("playground.next")
        selectTarget("saturn-edge-view")
        assertPostcard("Saturn remote edge-view postcard")
        select("playground.worlds")
    }

    func testRemoteHelpClipAndPausePreservePlay() {
        select("adventure.begin")
        open("mars")
        XCTAssertTrue(app.buttons["playground.target.mars-crater-landmark"].hasFocus)
        selectTarget("mars-crater-landmark")
        select("playground.pause")
        select("playground.help")
        XCTAssertTrue(app.staticTexts["playground.hint"].waitForExistence(timeout: 5))
        select("playground.help.aim")
        XCTAssertTrue(app.buttons["playground.target.mars-rock-landmark"].hasFocus)
        select("playground.pause")
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
        XCTAssertTrue(app.buttons["playground.target.mars-rock-landmark"].hasFocus)
        selectTarget("mars-rock-landmark")
        select("playground.next")
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

@MainActor
final class PhotoSafariTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launch()
    }

    func testThreePhotoSafarisAndPassportWithRemote() {
        select("adventure.begin")
        openSafari("mercury")
        XCTAssertTrue(app.buttons["safari.choice.mercury-horizon"].hasFocus)
        capture("Photo Safari Mercury clue with real images")
        select("safari.choice.saturn-portrait")
        XCTAssertTrue(app.staticTexts["safari.hint"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["safari.progress"].label, "Photo 1 of 3")
        capture("Photo Safari gentle visual hint")
        select("safari.showMe")
        XCTAssertTrue(app.buttons["safari.next"].hasFocus)
        capture("Photo Safari Mercury photo and discovery")
        select("safari.next")
        select("safari.choice.mercury-caloris")
        capture("Photo Safari Mercury annotated mosaic")
        select("safari.next")
        select("safari.choice.mercury-hollows")
        select("safari.next")
        XCTAssertTrue(app.staticTexts["safari.collection"].waitForExistence(timeout: 5))
        capture("Photo Safari Mercury saved collection")
        select("safari.album.mercury-photo-basin")
        XCTAssertTrue(app.staticTexts["safari.caption"].label.contains("Dashed lines"))
        remote.press(.menu)
        select("safari.worlds")
        openSafari("mars")
        select("safari.choice.tech-rover")
        capture("Photo Safari Mars real rover discovery")
        select("safari.next")
        select("safari.choice.mars-landscape")
        capture("Photo Safari Mars uncropped panorama")
        select("safari.next")
        select("safari.choice.mars-polar-cap")
        capture("Photo Safari Mars telescope images")
        select("safari.next")
        select("safari.worlds")
        openSafari("saturn")
        capture("Photo Safari Saturn photo clue")
        select("safari.choice.saturn-portrait")
        select("safari.next")
        select("safari.choice.saturn-earth-smiled")
        capture("Photo Safari Saturn backlit rings")
        select("safari.next")
        select("safari.choice.earth-blue-marble")
        capture("Photo Safari Earth our familiar home")
        select("safari.next")
        capture("Photo Safari Saturn collection")
        select("safari.worlds")
        select("playground.passport")
        XCTAssertTrue(
            app.buttons["passport.photo.mercury-photo-craters"].waitForExistence(timeout: 5))
        capture("Photo Safari passport with real photos")
        select("passport.photo.mercury-photo-craters")
        capture("Photo Safari passport full photo")
        select("passport.photo.close")
        select("passport.close")
    }

    func testPauseRelaunchAndRestorePhotoRevealWithRemote() {
        select("adventure.begin")
        openSafari("mercury")
        select("safari.choice.mercury-horizon")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        select("safari.return")
        XCTAssertTrue(app.buttons["safari.resume"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["safari.resume"].hasFocus)
        capture("Photo Safari restored pause")
        let narration = app.buttons["safari.narration"]
        let previous = narration.label
        select("safari.narration")
        XCTAssertNotEqual(previous, narration.label)
        select("safari.resume")
        XCTAssertTrue(app.staticTexts["safari.fact"].exists)
        XCTAssertTrue(app.buttons["safari.next"].hasFocus)
        select("safari.next")
        XCTAssertTrue(app.buttons["safari.choice.tech-rover"].hasFocus)
        remote.press(.playPause)
        XCTAssertTrue(app.buttons["safari.resume"].waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(app.buttons["safari.choice.tech-rover"].hasFocus)
        for id in [
            "safari.choice.tech-rover", "safari.choice.mercury-caloris", "safari.showMe",
            "safari.options",
        ] {
            focus(id)
            let frame = app.buttons[id].frame
            XCTAssertGreaterThanOrEqual(frame.minX, app.frame.minX + 48)
            XCTAssertLessThanOrEqual(frame.maxX, app.frame.maxX - 48)
            XCTAssertGreaterThanOrEqual(frame.minY, app.frame.minY + 24)
            XCTAssertLessThanOrEqual(frame.maxY, app.frame.maxY - 24)
        }
        for _ in 0..<2 {
            select("safari.showMe")
            select("safari.next")
        }
        select("safari.worlds")
        select("playground.passport")
        select("passport.photo.mercury-photo-craters")
        XCTAssertTrue(app.buttons["passport.photo.close"].waitForExistence(timeout: 5))
        capture("Photo Safari restored collection in full screen passport")
        select("passport.photo.close")
        select("passport.close")
    }

    private func openSafari(_ destination: String) {
        if !app.buttons["destination.\(destination)"].exists {
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
        select("destination.\(destination)")
        XCTAssertTrue(app.buttons["safari.showMe"].waitForExistence(timeout: 10))
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
