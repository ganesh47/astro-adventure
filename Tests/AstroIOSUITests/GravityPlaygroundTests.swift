import UIKit
import XCTest

@MainActor
final class GravityPlaygroundTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testEarthAndMoonShareLaunchSettingsWithoutChangingWorldProgress() {
        launchApp()
        let navigation = openFromMercury()
        assertWorldKindsAndMass()
        assertSettings(angle: 45, speed: 6)
        tap("gravity.launch")
        waitForLanding(on: "Earth")
        XCTAssertTrue(app.staticTexts["gravity.comparison"].label.contains("Earth baseline"))
        assertMetric("Height", value: "0.9 m")
        assertMetric("Distance", value: "3.7 m")
        assertMetric("Hang time", value: "0.9 seconds")
        assertMetric("Weight: pull on this ball", value: "9.8 N")
        reveal(field)
        capture("iOS gravity Earth baseline 45 degrees 6 meters per second")

        tap("gravity.world.moon")
        assertSettings(angle: 45, speed: 6)
        XCTAssertTrue(fieldValue.contains("Moon selected"))
        XCTAssertFalse(app.staticTexts["gravity.comparison"].exists)
        tap("gravity.prediction.longer")
        tap("gravity.launch")
        waitForLanding(on: "Moon")
        assertMetric("Height", value: "5.6 m")
        assertMetric("Distance", value: "22.2 m")
        assertMetric("Hang time", value: "5.2 seconds")
        assertMetric("Weight: pull on this ball", value: "1.6 N")
        XCTAssertTrue(app.staticTexts["gravity.comparison"].label.contains("6.1 times as long"))
        assertWeightCaption(percentage: "16.5%")
        reveal(field)
        capture("iOS gravity Moon comparison same 45 degree 6 meter per second launch")
        assertAssumptions()
        tap("gravity.worlds")
        assertNavigationUnchanged(navigation)
        capture("iOS gravity return preserves Mercury selection and passport")
    }

    func testPausedMoonRequiresForegroundResumeAndReplaySurvivesDoubleTap() {
        launchApp()
        let navigation = openFromMercury()
        tap("gravity.world.moon")
        tap("gravity.angle.plus")
        tap("gravity.speed.plus")
        assertSettings(angle: 60, speed: 8)
        tap("gravity.launch")
        pauseVisibleFlight()
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))
        XCTAssertFalse(app.buttons["gravity.world.mars"].isEnabled)
        XCTAssertFalse(app.buttons["gravity.angle.minus"].isEnabled)
        XCTAssertFalse(app.buttons["gravity.speed.minus"].isEnabled)
        capture("iOS gravity Moon paused with immutable launch settings")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["gravity.resume"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["gravity.pause"].exists)
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))
        capture("iOS gravity foreground waits for explicit Resume")
        // This exceeds the entire 8.6-second model flight, proving backgrounding did not
        // continue or complete the paused observation.
        assertRemainsPaused(for: 9)

        let replay = reach("gravity.relaunch")
        replay.doubleTap()
        XCTAssertTrue(app.buttons["gravity.pause"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["gravity.relaunch"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "gravity.pause").count, 1)
        pauseVisibleFlight()
        assertSettings(angle: 60, speed: 8)
        capture("iOS gravity double tap starts one replacement flight then pauses")
        tap("gravity.resume")
        waitForLanding(on: "Moon", timeout: 12)
        assertMetric("Hang time", value: "8.6 seconds")
        assertMetric("Weight: pull on this ball", value: "1.6 N")
        assertWeightCaption(percentage: "16.5%")
        reveal(field)
        capture("iOS gravity Moon resumed replacement completes once")
        XCTAssertFalse(app.buttons["gravity.resume"].exists)
        XCTAssertFalse(app.buttons["gravity.pause"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "gravity.relaunch").count, 1)
        tap("gravity.worlds")
        assertNavigationUnchanged(navigation)
    }

    func testBackgroundingAnActivelyFlyingBallRequiresExplicitResume() {
        launchApp()
        let navigation = openFromMercury()
        tap("gravity.world.moon")
        tap("gravity.angle.plus")
        tap("gravity.speed.plus")
        tap("gravity.launch")
        XCTAssertTrue(app.buttons["gravity.pause"].waitForExistence(timeout: 2))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["gravity.resume"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["gravity.pause"].exists)
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))
        assertRemainsPaused(for: 9)
        capture("iOS gravity active flight freezes across background and foreground")
        tap("gravity.resume")
        waitForLanding(on: "Moon", timeout: 12)
        tap("gravity.worlds")
        assertNavigationUnchanged(navigation)
    }

    func testTabletPortraitGravityCardsAndControlsGrowAtLargestAccessibilitySize() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Portrait gravity layout is supported on iPad; iPhone is landscape-only")
        }
        XCUIDevice.shared.orientation = .portrait
        var normalCardHeight: CGFloat = 0
        for (name, category) in [
            ("Default", "UICTContentSizeCategoryL"),
            ("Accessibility XXXL", "UICTContentSizeCategoryAccessibilityXXXL"),
        ] {
            launchApp(contentSize: category)
            XCTAssertGreaterThan(app.frame.height, app.frame.width, "Actual app must be portrait")
            let navigation = openFromMercury()
            assertWorldKindsAndMass()
            let moon = reach("gravity.world.moon")
            if normalCardHeight == 0 {
                normalCardHeight = moon.frame.height
            } else {
                XCTAssertGreaterThan(
                    moon.frame.height, normalCardHeight * 1.3,
                    "Accessibility text must grow the card instead of shrinking the text")
            }
            capture("iPad portrait \(name) gravity world cards")
            moon.press(forDuration: 0.15)
            assertSettings(angle: 45, speed: 6)
            tap("gravity.prediction.longer")
            reach("gravity.launch")
            capture("iPad portrait \(name) reachable gravity launch controls")
            tap("gravity.launch")
            waitForLanding(on: "Moon")
            reveal(field)
            capture("iPad portrait \(name) gravity Moon and Earth paths")
            let explanation = app.staticTexts["gravity.comparison"]
            reveal(explanation)
            XCTAssertTrue(explanation.label.contains("6.1 times as long"))
            assertMetric("Weight: pull on this ball", value: "1.6 N")
            assertWeightCaption(percentage: "16.5%")
            capture("iPad portrait \(name) gravity weight mass and comparison")
            assertAssumptions()
            capture("iPad portrait \(name) gravity model assumptions")
            tap("gravity.worlds")
            assertNavigationUnchanged(navigation)
            app.terminate()
        }
    }

    private var field: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "gravity.field").firstMatch
    }

    private var fieldValue: String { field.value as? String ?? "" }

    private func launchApp(contentSize: String = "UICTContentSizeCategoryL") {
        app.launchArguments = [
            "--ui-testing", "--reset-ui-testing-progress",
            "-UIPreferredContentSizeCategoryName", contentSize,
        ]
        app.launchEnvironment = [:]
        app.launch()
    }

    private struct NavigationSnapshot {
        let exploreLabel: String
        let mercuryLabel: String
        let passportLabel: String
    }

    private func openFromMercury() -> NavigationSnapshot {
        tap("adventure.begin")
        tap("destination.mercury")
        let explore = app.buttons["adventure.explore"]
        XCTAssertTrue(explore.waitForExistence(timeout: 10))
        XCTAssertTrue(explore.label.contains("Mercury"))
        XCTAssertTrue(passportSummary.waitForExistence(timeout: 5))
        let snapshot = NavigationSnapshot(
            exploreLabel: explore.label,
            mercuryLabel: app.buttons["destination.mercury"].label,
            passportLabel: passportSummary.label)
        tap("gravity.open")
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
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        reveal(text)
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

    private func pauseVisibleFlight() {
        let pause = app.buttons["gravity.pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 3))
        XCTAssertTrue(pause.isHittable, "Launch must keep Pause visible")
        pause.press(forDuration: 0.1)
        let resumed = app.buttons["gravity.resume"].waitForExistence(timeout: 3)
        if !resumed { capture("iOS gravity Pause failed to expose Resume") }
        XCTAssertTrue(resumed)
        XCTAssertFalse(app.staticTexts["gravity.comparison"].exists)
    }

    private func assertRemainsPaused(for seconds: TimeInterval) {
        let landed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.staticTexts["gravity.comparison"])
        landed.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [landed], timeout: seconds), .completed)
        XCTAssertTrue(app.buttons["gravity.resume"].exists)
        XCTAssertTrue(fieldValue.contains("Flight paused on Moon"))
    }

    private func tap(_ identifier: String) {
        reach(identifier).press(forDuration: 0.15)
    }

    @discardableResult
    private func reach(_ identifier: String) -> XCUIElement {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(identifier)")
        if identifier == "destination.mercury" {
            revealDestinationCard(button)
        } else {
            reveal(button)
        }
        XCTAssertTrue(button.isEnabled, "Disabled \(identifier)")
        XCTAssertTrue(button.isHittable, "Unreachable \(identifier)")
        return button
    }

    private func revealDestinationCard(_ card: XCUIElement) {
        let row = app.scrollViews["destination.selector"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        reveal(row)
        for _ in 0..<8 {
            let visible = row.frame.intersection(app.frame)
            if card.frame.minX >= visible.minX && card.frame.maxX <= visible.maxX {
                return
            }
            let delta = card.frame.midX - visible.midX
            let distance = min(abs(delta), visible.width * 0.45)
            let start = row.coordinate(
                withNormalizedOffset: CGVector(dx: delta > 0 ? 0.75 : 0.25, dy: 0.5))
            start.press(
                forDuration: 0.1,
                thenDragTo: start.withOffset(CGVector(dx: delta > 0 ? -distance : distance, dy: 0)),
                withVelocity: .slow, thenHoldForDuration: 0.25)
        }
        failWithEvidence("Mercury card could not be fully revealed")
    }

    private func reveal(_ element: XCUIElement) {
        let gravity = app.scrollViews["gravity.playground"]
        let scroll = gravity.exists ? gravity : app.scrollViews["adventure.menu"]
        XCTAssertTrue(scroll.exists, "Missing containing scroll view for \(element.identifier)")
        for _ in 0..<16 {
            var visible = scroll.frame.intersection(app.frame)
            if !gravity.exists {
                let pause = app.buttons["adventure.pause"]
                if pause.exists, pause.frame.minY > visible.minY {
                    visible.size.height = min(visible.maxY, pause.frame.minY) - visible.minY
                }
            }
            XCTAssertGreaterThan(visible.height, 0)
            let frame = element.frame
            if frame.minY >= visible.minY - 0.5 && frame.maxY <= visible.maxY + 0.5 { return }
            if frame.height > visible.height,
                visible.contains(CGPoint(x: visible.midX, y: frame.midY))
            {
                // Long accessibility paragraphs remain readable through ordinary scrolling.
                return
            }
            let delta = frame.midY - visible.midY
            let distance = min(abs(delta), visible.height * 0.45)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
                CGVector(
                    dx: visible.minX + visible.width * 0.08,
                    dy: visible.minY + visible.height * (delta > 0 ? 0.75 : 0.25)))
            start.press(
                forDuration: 0.1,
                thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta > 0 ? -distance : distance)),
                withVelocity: .slow, thenHoldForDuration: 0.25)
        }
        failWithEvidence("Element \(element.identifier) could not be revealed")
    }

    private func failWithEvidence(_ message: String) {
        capture(message)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = message + " hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail(message)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
