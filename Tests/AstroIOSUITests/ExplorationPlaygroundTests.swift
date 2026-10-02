import UIKit
import XCTest

@MainActor
final class ExplorationPlaygroundTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launchArguments = ["--ui-testing", "--reset-ui-testing-progress"]
        app.launch()
    }

    func testAllThreeLivingPlaygroundsAndPassport() {
        tap("adventure.begin")
        for planet in ["mercury", "mars", "saturn"] {
            enter(planet)
            for (index, target) in targets(for: planet).enumerated() {
                tap("playground.target.\(target)")
                if planet == "mars", index == 3 { capture("Mars rock investigation") }
                if planet == "saturn", index == 4 { capture("Saturn separate moving particles") }
            }
            XCTAssertTrue(app.staticTexts["playground.postcard"].waitForExistence(timeout: 10))
            capture("\(planet) discovery postcard")
            tap("playground.keepPlaying")
            capture("\(planet) open playground")
            tap("playground.pause")
            tap("playground.reset")
            XCTAssertFalse(
                app.staticTexts["playground.postcard"].exists, "Reset must not award again")
            tap("playground.pause")
            tap("playground.worlds")
            XCTAssertTrue(app.buttons["destination.\(planet)"].label.contains("Stamped"))
        }
        tap("playground.passport")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "passport.postcard.mercury")
                .firstMatch.waitForExistence(timeout: 10))
        capture("Playground passport preserves creations")
        showPostcard("mars")
        capture("Passport saved Mars creation")
        showPostcard("saturn")
        capture("Passport saved Saturn creation")
        tap("passport.close")
    }

    func testCarriedSensorRestoresPausedWithDiscoveries() {
        tap("adventure.begin")
        enter("mercury")
        for target in targets(for: "mercury").prefix(4) { tap("playground.target.\(target)") }
        XCTAssertEqual(
            app.staticTexts["playground.feedback"].label,
            "Your portable sensor is ready for another site.")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        tap("playground.resume")
        XCTAssertTrue(app.staticTexts["Taking a little break"].waitForExistence(timeout: 10))
        capture("Carried sensor restored paused")
        tap("playground.resume")
        tap("playground.target.mercury-sunlit-sensor-site")
        XCTAssertEqual(
            app.staticTexts["playground.feedback"].label,
            "Sunlit ground gives the warmer reading in our model.")
        tap("playground.target.mercury-sensor")
        tap("playground.target.mercury-shadow-sensor-site")
        XCTAssertTrue(app.staticTexts["playground.postcard"].waitForExistence(timeout: 10))
    }

    func testOptionalFilmInvitesPlayWithoutAnswersAndPausesOnBackground() {
        tap("adventure.begin")
        enter("mercury")
        tap("playground.help")
        tap("playground.clip")
        XCTAssertTrue(app.buttons["playground.clip.play"].waitForExistence(timeout: 10))
        tap("playground.clip.transcript")
        tap("playground.clip.transcript")
        tap("playground.clip.ahead")
        tap("playground.clip.ahead")
        XCTAssertTrue(app.buttons["playground.clip.try"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["video.answer.0"].exists)
        capture("Film invitation keeps the NASA frame")
        tap("playground.clip.continue")
        tap("playground.clip.play")
        XCUIDevice.shared.press(.home)
        app.activate()
        if app.buttons["playground.resume"].waitForExistence(timeout: 3) {
            tap("playground.resume")
            tap("playground.help")
            tap("playground.clip")
        }
        let play = app.buttons["playground.clip.play"]
        if play.exists {
            XCTAssertEqual(play.label, "Play film", "Foregrounding must not autoplay")
        }
        tap("playground.clip.close")
        XCTAssertTrue(
            app.buttons["playground.target.mercury-small-impact"].waitForExistence(timeout: 10))
        XCTAssertFalse(
            app.staticTexts["playground.postcard"].exists, "Watching cannot award an adventure")
    }

    func testTabletPortraitPlayableTargetsAndHelp() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad layout") }
        XCUIDevice.shared.orientation = .portrait
        tap("adventure.begin")
        enter("mars")
        XCTAssertTrue(app.buttons["playground.target.mars-crater-landmark"].isHittable)
        capture("iPad portrait living Mars")
        tap("playground.help")
        XCTAssertTrue(app.staticTexts["playground.hint"].exists)
        capture("iPad portrait spoken help")
        tap("playground.help.aim")
        tap("playground.action")
        XCTAssertEqual(
            app.staticTexts["playground.feedback"].label,
            "Crater landmark explored. The outcrop is another stop.")
    }

    func testMissingFilmUsesPicturesAndStillAllowsDiscovery() {
        app.terminate()
        app.launchArguments.append("--missing-playground-media")
        app.launch()
        tap("adventure.begin")
        enter("mercury")
        tap("playground.help")
        tap("playground.clip")
        XCTAssertTrue(
            app.staticTexts["Let's use pictures instead. Your playground is ready."]
                .waitForExistence(timeout: 10))
        capture("Missing film illustrated observation")
        tap("playground.clip.try")
        for target in targets(for: "mercury") { tap("playground.target.\(target)") }
        XCTAssertTrue(app.staticTexts["playground.postcard"].waitForExistence(timeout: 10))
    }

    private func enter(_ planet: String) {
        tap("destination.\(planet)")
        tap("adventure.explore")
        tap("playground.begin")
    }

    private func targets(for planet: String) -> [String] {
        switch planet {
        case "mercury":
            [
                "mercury-small-impact", "mercury-large-impact", "mercury-ejecta-trail",
                "mercury-sensor", "mercury-sunlit-sensor-site", "mercury-sensor",
                "mercury-shadow-sensor-site",
            ]
        case "mars":
            [
                "mars-crater-landmark", "mars-rock-landmark", "mars-layered-rock",
                "mars-rock-camera", "mars-water-model", "mars-deposit-compare",
            ]
        default:
            [
                "saturn-ice-kit", "saturn-inner-orbit", "saturn-ice-kit",
                "saturn-outer-orbit", "saturn-watch-motion", "saturn-edge-view",
            ]
        }
    }

    private func tap(_ id: String) {
        let button = app.buttons[id]
        if id.hasPrefix("destination.") {
            for _ in 0..<6 {
                if button.exists && button.isHittable { break }
                app.scrollViews.firstMatch.swipeLeft()
            }
        }
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(id)")
        if !button.isHittable, app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(button.isEnabled, "Disabled \(id)")
        XCTAssertTrue(button.isHittable, "Unreachable \(id): \(button.frame)")
        button.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func showPostcard(_ planet: String) {
        let card = app.descendants(matching: .any)
            .matching(identifier: "passport.postcard.\(planet)").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let scroll = app.scrollViews["passport.scroll"]
        for _ in 0..<6 {
            let delta = scroll.frame.minY + 8 - card.frame.minY
            if abs(delta) < 8 { break }
            let startY: CGFloat = delta > 0 ? 0.2 : 0.8
            let endY = min(max(startY + delta / scroll.frame.height, 0.15), 0.85)
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(
                    forDuration: 0.1,
                    thenDragTo: scroll.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: endY)),
                    withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(card.isHittable)
    }
}
