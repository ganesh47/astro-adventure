import XCTest

@MainActor
final class GravityPlaygroundTests: XCTestCase {
    private let app = XCUIApplication()
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launchEnvironment = [:]
        app.launch()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testRemoteFocusAndEarthMoonMarsComparisonsKeepTheSameLaunch() {
        let navigation = openFromMercury()
        assertWorldKindsAndMass()
        for id in [
            "gravity.world.earth", "gravity.world.moon", "gravity.world.mars",
            "gravity.prediction.longer", "gravity.prediction.same", "gravity.prediction.shorter",
            "gravity.angle.minus", "gravity.angle.plus", "gravity.speed.minus",
            "gravity.speed.plus",
            "gravity.launch", "gravity.worlds",
        ] {
            focus(id)
            assertFocusedControlFits(id)
            capture("tvOS gravity focused \(id)")
        }
        assertSettings(angle: 45, speed: 6)
        XCTAssertTrue(fieldValue.contains("Earth selected"), "Focus alone must not select a world")
        select("gravity.launch")
        waitForLanding(on: "Earth")
        assertMetric("Height", value: "0.9 m")
        assertMetric("Distance", value: "3.7 m")
        assertMetric("Hang time", value: "0.9 seconds")
        assertMetric("Weight: pull on this ball", value: "9.8 N")
        XCTAssertTrue(app.staticTexts["gravity.comparison"].label.contains("Earth baseline"))
        capture("tvOS gravity Earth baseline 45 degrees 6 meters per second")

        select("gravity.world.moon")
        assertSettings(angle: 45, speed: 6)
        select("gravity.prediction.longer")
        select("gravity.launch")
        waitForLanding(on: "Moon")
        assertMetric("Height", value: "5.6 m")
        assertMetric("Distance", value: "22.2 m")
        assertMetric("Hang time", value: "5.2 seconds")
        assertMetric("Weight: pull on this ball", value: "1.6 N")
        assertWeightCaption(percentage: "16.5%")
        XCTAssertTrue(app.staticTexts["gravity.comparison"].label.contains("6.1 times as long"))
        capture("tvOS gravity Moon and Earth same launch comparison")

        select("gravity.world.mars")
        assertSettings(angle: 45, speed: 6)
        select("gravity.launch")
        waitForLanding(on: "Mars")
        assertMetric("Height", value: "2.4 m")
        assertMetric("Distance", value: "9.7 m")
        assertMetric("Hang time", value: "2.3 seconds")
        assertMetric("Weight: pull on this ball", value: "3.7 N")
        assertWeightCaption(percentage: "38.0%")
        XCTAssertTrue(app.staticTexts["gravity.comparison"].label.contains("2.6 times as long"))
        capture("tvOS gravity Mars and Earth same launch comparison")
        assertAssumptions()
        select("gravity.worlds")
        assertNavigationUnchanged(navigation)
        capture("tvOS gravity Worlds preserves Mercury selection and passport")
    }

    func testRemotePauseReplayDoubleSelectAndBackKeepObservationUngraded() {
        let navigation = openFromMercury()
        select("gravity.world.moon")
        select("gravity.angle.plus")
        select("gravity.speed.plus")
        assertSettings(angle: 60, speed: 8)
        select("gravity.launch")
        remote.press(.playPause)
        XCTAssertTrue(app.buttons["gravity.resume"].waitForExistence(timeout: 3))
        assertFocusedControlFits("gravity.resume")
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))
        XCTAssertFalse(app.buttons["gravity.world.mars"].isEnabled)
        XCTAssertFalse(app.buttons["gravity.angle.minus"].isEnabled)
        XCTAssertFalse(app.buttons["gravity.speed.minus"].isEnabled)
        capture("tvOS gravity Play Pause freezes Moon flight")

        focus("gravity.relaunch")
        assertFocusedControlFits("gravity.relaunch")
        remote.press(.select)
        // Replay deliberately moves focus to Pause. A second Select is a Pause action,
        // rather than a second launch; the replacement must remain safe and ungraded.
        remote.press(.select)
        XCTAssertTrue(app.buttons["gravity.resume"].waitForExistence(timeout: 3))
        assertFocusedControlFits("gravity.resume")
        XCTAssertFalse(app.staticTexts["gravity.comparison"].exists)
        assertSettings(angle: 60, speed: 8)
        capture("tvOS gravity double Select safely pauses replacement flight")
        let landed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.staticTexts["gravity.comparison"])
        landed.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [landed], timeout: 9), .completed)
        XCTAssertTrue(app.buttons["gravity.resume"].exists)
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))

        remote.press(.playPause)
        XCTAssertTrue(app.buttons["gravity.pause"].waitForExistence(timeout: 3))
        assertFocusedControlFits("gravity.pause")
        waitForLanding(on: "Moon", timeout: 12)
        assertFocusedControlFits("gravity.relaunch")
        assertMetric("Hang time", value: "8.6 seconds")
        assertWeightCaption(percentage: "16.5%")
        XCTAssertFalse(app.buttons["gravity.resume"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "gravity.relaunch").count, 1)
        capture("tvOS gravity resumed replacement finishes once")
        remote.press(.menu)
        assertNavigationUnchanged(navigation)
    }

    private var field: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "gravity.field").firstMatch
    }

    private var fieldValue: String { field.value as? String ?? "" }

    private struct NavigationSnapshot {
        let exploreLabel: String
        let mercuryLabel: String
        let passportLabel: String
    }

    private func openFromMercury() -> NavigationSnapshot {
        select("adventure.begin")
        // TV card selection activates an adventure, so aim with the remote without Select.
        focus("destination.mercury")
        focus("gravity.open")
        let explore = app.buttons["adventure.explore"]
        XCTAssertTrue(explore.waitForExistence(timeout: 5))
        XCTAssertTrue(explore.label.contains("Mercury"))
        XCTAssertTrue(passportSummary.waitForExistence(timeout: 5))
        let snapshot = NavigationSnapshot(
            exploreLabel: explore.label,
            mercuryLabel: app.buttons["destination.mercury"].label,
            passportLabel: passportSummary.label)
        remote.press(.select)
        XCTAssertTrue(app.buttons["gravity.world.earth"].waitForExistence(timeout: 10))
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        return snapshot
    }

    private var passportSummary: XCUIElement {
        app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Discovery Passport ·")
        ).firstMatch
    }

    private func assertNavigationUnchanged(_ snapshot: NavigationSnapshot) {
        XCTAssertTrue(app.buttons["adventure.explore"].waitForExistence(timeout: 10))
        XCTAssertTrue(passportSummary.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["adventure.explore"].label, snapshot.exploreLabel)
        XCTAssertEqual(app.buttons["destination.mercury"].label, snapshot.mercuryLabel)
        XCTAssertEqual(passportSummary.label, snapshot.passportLabel)
        XCTAssertFalse(app.scrollViews["gravity.playground"].exists)
    }

    private func assertWorldKindsAndMass() {
        XCTAssertTrue(app.buttons["gravity.world.earth"].label.contains("Earth, planet"))
        XCTAssertTrue(app.buttons["gravity.world.moon"].label.contains("Moon, moon"))
        XCTAssertTrue(app.buttons["gravity.world.mars"].label.contains("Mars, planet"))
        XCTAssertTrue(
            app.staticTexts["Mass stays one kilogram. The same ball on every world."].exists)
    }

    private func assertSettings(angle: Int, speed: Int) {
        XCTAssertTrue(app.staticTexts["Angle: \(angle)°"].exists)
        XCTAssertTrue(app.staticTexts["Starting speed: \(speed) m/s"].exists)
    }

    private func assertMetric(_ title: String, value: String) {
        let metric = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", title, value)
        ).firstMatch
        XCTAssertTrue(metric.waitForExistence(timeout: 3), "Missing metric \(title): \(value)")
    }

    private func assertWeightCaption(percentage: String) {
        let caption = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "The ball’s weight here is ")
        ).firstMatch
        XCTAssertTrue(caption.exists)
        XCTAssertTrue(caption.label.contains(percentage))
        XCTAssertTrue(caption.label.contains("measured in newtons"))
        XCTAssertTrue(caption.label.contains("mass stays 1 kg"))
    }

    private func assertAssumptions() {
        let text = app.staticTexts["gravity.assumptions"]
        XCTAssertTrue(text.exists)
        XCTAssertTrue(text.label.contains("flat ground and steady gravity"))
        XCTAssertTrue(text.label.contains("leave out air"))
        XCTAssertTrue(text.label.contains("cannot change how your body feels"))
    }

    private func waitForLanding(on world: String, timeout: TimeInterval = 10) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS %@", "\(world) flight complete"),
            object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
        XCTAssertTrue(app.staticTexts["gravity.comparison"].exists)
        XCTAssertTrue(app.buttons["gravity.relaunch"].exists)
        XCTAssertFalse(app.buttons["gravity.pause"].exists)
    }

    private func select(_ identifier: String) {
        focus(identifier)
        remote.press(.select)
    }

    private func assertFocusedControlFits(_ identifier: String) {
        let control = app.buttons[identifier]
        XCTAssertEqual(
            XCTWaiter.wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "hasFocus == true"), object: control)
                ], timeout: 3), .completed, "Native focus must settle on \(identifier)")
        XCTAssertTrue(control.hasFocus)
        let viewport = app.scrollViews["gravity.playground"].frame.intersection(app.frame)
        XCTAssertGreaterThanOrEqual(control.frame.minY, viewport.minY - 0.5)
        XCTAssertLessThanOrEqual(control.frame.maxY, viewport.maxY + 0.5)
        XCTAssertGreaterThanOrEqual(control.frame.minX, viewport.minX - 0.5)
        XCTAssertLessThanOrEqual(control.frame.maxX, viewport.maxX + 0.5)
    }

    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier]
        XCTAssertTrue(
            target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        XCTAssertTrue(target.isEnabled, "Disabled \(identifier)", file: file, line: line)
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
                ],
                timeout: 0.3)
        }
        capture("tvOS gravity remote focus failure \(identifier)")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "tvOS gravity focus failure hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Remote could not focus \(identifier)", file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
