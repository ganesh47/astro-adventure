import AstroGameCore
import Foundation
import XCTest

final class GravityPlaygroundTests: XCTestCase {
    func testWorldsUseReviewedNASAValuesAndSources() {
        XCTAssertEqual(GravityWorld.allCases, [.earth, .moon, .mars])
        XCTAssertEqual(GravityWorld.earth.gravityMetersPerSecondSquared, 9.82)
        XCTAssertEqual(GravityWorld.moon.gravityMetersPerSecondSquared, 1.62)
        XCTAssertEqual(GravityWorld.mars.gravityMetersPerSecondSquared, 3.73)
        XCTAssertEqual(GravityWorld.earth.weightRelativeToEarth, 1)
        XCTAssertEqual(GravityWorld.moon.weightRelativeToEarth, 1.62 / 9.82, accuracy: 1e-12)
        for world in GravityWorld.allCases {
            XCTAssertEqual(URL(string: world.sourceURL)?.host, "nssdc.gsfc.nasa.gov")
            XCTAssertTrue(world.sourceURL.hasSuffix("\(world.rawValue)fact.html"))
            XCTAssertEqual(world.id, world.rawValue)
            XCTAssertFalse(world.displayName.isEmpty)
        }
    }

    func testLaunchBoundsAndNonFiniteInputsCannotCreateInvalidPhysics() {
        let invalid = GravityLaunch(
            angleDegrees: .nan, speedMetersPerSecond: .infinity, massKilograms: -.infinity)
        XCTAssertEqual(invalid, GravityLaunch())
        let bounded = GravityLaunch(angleDegrees: -1, speedMetersPerSecond: 100, massKilograms: 0)
        XCTAssertEqual(bounded.angleDegrees, 30)
        XCTAssertEqual(bounded.speedMetersPerSecond, 8)
        XCTAssertEqual(bounded.massKilograms, 0.25)
        XCTAssertEqual(GravityLaunch(angleDegrees: 100).angleDegrees, 60)
        XCTAssertEqual(GravityLaunch(speedMetersPerSecond: -1).speedMetersPerSecond, 4)
        XCTAssertEqual(GravityLaunch(massKilograms: 100).massKilograms, 10)
        for world in GravityWorld.allCases {
            let trajectory = GravityTrajectory(world: world, launch: invalid)
            XCTAssertTrue(trajectory.flightTime.isFinite)
            XCTAssertGreaterThan(trajectory.flightTime, 0)
            XCTAssertGreaterThan(trajectory.range, 0)
        }
    }

    func testAnalyticTrajectoryHasExactOriginApexAndLanding() {
        let launch = GravityLaunch(angleDegrees: 45, speedMetersPerSecond: 6)
        for world in GravityWorld.allCases {
            let trajectory = GravityTrajectory(world: world, launch: launch)
            let g = world.gravityMetersPerSecondSquared
            let vy = 6 * sin(Double.pi / 4)
            XCTAssertEqual(trajectory.flightTime, 2 * vy / g, accuracy: 1e-12)
            XCTAssertEqual(trajectory.range, 36 / g, accuracy: 1e-12)
            XCTAssertEqual(trajectory.peakHeight, 9 / g, accuracy: 1e-12)
            XCTAssertEqual(
                trajectory.position(elapsed: 0), GravityPosition(xMeters: 0, heightMeters: 0))
            let apex = trajectory.position(elapsed: trajectory.flightTime / 2)
            XCTAssertEqual(apex.xMeters, trajectory.range / 2, accuracy: 1e-12)
            XCTAssertEqual(apex.heightMeters, trajectory.peakHeight, accuracy: 1e-12)
            XCTAssertEqual(
                trajectory.position(elapsed: trajectory.flightTime),
                GravityPosition(xMeters: trajectory.range, heightMeters: 0))
            XCTAssertEqual(
                trajectory.position(elapsed: trajectory.flightTime + 100),
                trajectory.position(elapsed: trajectory.flightTime))
        }
    }

    func testLowerGravityIncreasesHeightRangeAndHangTimeButDecreasesWeight() {
        let earth = GravityTrajectory(world: .earth)
        let mars = GravityTrajectory(world: .mars)
        let moon = GravityTrajectory(world: .moon)
        XCTAssertLessThan(earth.flightTime, mars.flightTime)
        XCTAssertLessThan(mars.flightTime, moon.flightTime)
        XCTAssertLessThan(earth.peakHeight, mars.peakHeight)
        XCTAssertLessThan(mars.peakHeight, moon.peakHeight)
        XCTAssertLessThan(earth.range, mars.range)
        XCTAssertLessThan(mars.range, moon.range)
        XCTAssertGreaterThan(earth.weight, mars.weight)
        XCTAssertGreaterThan(mars.weight, moon.weight)
        for world in GravityWorld.allCases {
            let trajectory = GravityTrajectory(world: world)
            let ratio =
                world.gravityMetersPerSecondSquared
                / GravityWorld.earth.gravityMetersPerSecondSquared
            XCTAssertEqual(trajectory.flightTime * ratio, earth.flightTime, accuracy: 1e-12)
            XCTAssertEqual(trajectory.range * ratio, earth.range, accuracy: 1e-12)
            XCTAssertEqual(trajectory.peakHeight * ratio, earth.peakHeight, accuracy: 1e-12)
            XCTAssertEqual(trajectory.weight / earth.weight, ratio, accuracy: 1e-12)
        }
    }

    func testMassChangesWeightWithoutChangingVacuumMotion() {
        for world in GravityWorld.allCases {
            let light = GravityTrajectory(world: world, launch: GravityLaunch(massKilograms: 1))
            let heavy = GravityTrajectory(world: world, launch: GravityLaunch(massKilograms: 4))
            XCTAssertEqual(light.flightTime, heavy.flightTime)
            XCTAssertEqual(light.range, heavy.range)
            XCTAssertEqual(light.peakHeight, heavy.peakHeight)
            XCTAssertEqual(light.sampledPositions(), heavy.sampledPositions())
            XCTAssertEqual(heavy.weight, light.weight * 4)
        }
    }

    func testEarthGhostUsesUnchangedLaunchAndDeterministicPath() {
        let launch = GravityLaunch(angleDegrees: 60, speedMetersPerSecond: 8, massKilograms: 2)
        let first = GravityTrajectory(world: .moon, launch: launch)
        let repeated = GravityTrajectory(world: .moon, launch: launch)
        XCTAssertEqual(first, repeated)
        XCTAssertEqual(first.sampledPositions(), repeated.sampledPositions())
        XCTAssertEqual(first.earthComparison, GravityTrajectory(world: .earth, launch: launch))
        XCTAssertEqual(first.earthComparison.launch, first.launch)
    }

    func testAllBoundedLaunchesStopAtGroundAndIncludeApex() {
        for world in GravityWorld.allCases {
            for angle in [30.0, 45, 60] {
                for speed in [4.0, 6, 8] {
                    let trajectory = GravityTrajectory(
                        world: world,
                        launch: GravityLaunch(
                            angleDegrees: angle, speedMetersPerSecond: speed))
                    for count in [Int.min, 2, 80, 81, Int.max] {
                        let positions = trajectory.sampledPositions(sampleCount: count)
                        XCTAssertGreaterThanOrEqual(positions.count, 3)
                        XCTAssertLessThanOrEqual(positions.count, 201)
                        XCTAssertEqual(
                            positions.first, GravityPosition(xMeters: 0, heightMeters: 0))
                        XCTAssertEqual(
                            positions.last,
                            GravityPosition(xMeters: trajectory.range, heightMeters: 0))
                        XCTAssertEqual(
                            positions[positions.count / 2].heightMeters, trajectory.peakHeight,
                            accuracy: 1e-12)
                        XCTAssertTrue(
                            positions.allSatisfy { $0.heightMeters >= 0 && $0.xMeters >= 0 })
                        XCTAssertTrue(
                            zip(positions, positions.dropFirst()).allSatisfy { pair in
                                pair.0.xMeters <= pair.1.xMeters
                            })
                    }
                }
            }
        }
    }

    func testInvalidElapsedValuesRemainAtSafeEndpoints() {
        let trajectory = GravityTrajectory(world: .moon)
        let origin = GravityPosition(xMeters: 0, heightMeters: 0)
        XCTAssertEqual(trajectory.position(elapsed: -.infinity), origin)
        XCTAssertEqual(trajectory.position(elapsed: .nan), origin)
        XCTAssertEqual(trajectory.position(elapsed: -20), origin)
        XCTAssertEqual(
            trajectory.position(elapsed: .infinity),
            GravityPosition(xMeters: trajectory.range, heightMeters: 0))
    }

    func testProjectionUsesEqualMeterScaleForBothAxesAndAllWorlds() {
        let launch = GravityLaunch()
        let projection = GravityProjection(launch: launch, width: 640, height: 320)
        let origin = projection.project(GravityPosition(xMeters: 0, heightMeters: 0))
        let meter = projection.project(GravityPosition(xMeters: 1, heightMeters: 1))
        XCTAssertEqual(meter.x - origin.x, projection.pointsPerMeter, accuracy: 1e-12)
        XCTAssertEqual(origin.y - meter.y, projection.pointsPerMeter, accuracy: 1e-12)
        let earth = GravityTrajectory(world: .earth, launch: launch)
        let moon = GravityTrajectory(world: .moon, launch: launch)
        let earthLanding = projection.project(earth.position(elapsed: earth.flightTime))
        let moonLanding = projection.project(moon.position(elapsed: moon.flightTime))
        XCTAssertEqual(
            (moonLanding.x - origin.x) / (earthLanding.x - origin.x),
            moon.range / earth.range, accuracy: 1e-12)
        XCTAssertEqual(projection.maximumRangeMeters, moon.range)
        XCTAssertEqual(projection.maximumHeightMeters, moon.peakHeight)
    }

    func testCommonProjectionFitsAllWorldsInBothOrientations() {
        for angle in [30.0, 45, 60] {
            for speed in [4.0, 6, 8] {
                let launch = GravityLaunch(angleDegrees: angle, speedMetersPerSecond: speed)
                for size in [(width: 320.0, height: 640.0), (width: 640.0, height: 320.0)] {
                    let projection = GravityProjection(
                        launch: launch, width: size.width, height: size.height)
                    for world in GravityWorld.allCases {
                        let trajectory = GravityTrajectory(world: world, launch: launch)
                        for position in trajectory.sampledPositions() {
                            let point = projection.project(position)
                            XCTAssertGreaterThanOrEqual(point.x, projection.padding - 1e-9)
                            XCTAssertLessThanOrEqual(
                                point.x, projection.width - projection.padding + 1e-9)
                            XCTAssertGreaterThanOrEqual(point.y, projection.padding - 1e-9)
                            XCTAssertLessThanOrEqual(
                                point.y, projection.height - projection.padding + 1e-9)
                        }
                    }
                }
            }
        }
    }

    func testInvalidProjectionDimensionsStillProduceFiniteCoordinates() {
        let projection = GravityProjection(
            launch: GravityLaunch(), width: .nan, height: -5, padding: .infinity)
        XCTAssertTrue(projection.pointsPerMeter.isFinite)
        XCTAssertGreaterThan(projection.pointsPerMeter, 0)
        let point = projection.project(GravityTrajectory(world: .moon).position(elapsed: 2))
        XCTAssertTrue(point.x.isFinite)
        XCTAssertTrue(point.y.isFinite)
    }

    func testPauseResumeExcludesPausedTimeAndRejectsDuplicateLaunch() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .moon, at: 100))
        XCTAssertNil(clock.launch(world: .earth, at: 100.1))
        clock.advance(to: 100.5, generation: token)
        clock.pause(at: 100.75, generation: token)
        XCTAssertEqual(clock.phase, .paused)
        XCTAssertEqual(clock.elapsedSeconds, 0.75, accuracy: 1e-12)
        let pausedPosition = clock.position
        XCTAssertNil(clock.launch(world: .earth, at: 200))
        clock.advance(to: 200, generation: token)
        XCTAssertEqual(clock.position, pausedPosition)
        XCTAssertTrue(clock.resume(at: 500, generation: token))
        XCTAssertFalse(clock.resume(at: 500, generation: token))
        clock.advance(to: 500.25, generation: token)
        XCTAssertEqual(clock.elapsedSeconds, 1, accuracy: 1e-12)
        XCTAssertEqual(clock.trajectory?.world, .moon)
    }

    func testBackwardDuplicateAndInvalidTimestampsCannotMoveOrOvercountFlight() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .moon, at: 100))
        clock.advance(to: 101, generation: token)
        let elapsed = clock.elapsedSeconds
        for time in [100.5, 101, -1, .nan, .infinity] {
            XCTAssertFalse(clock.advance(to: time, generation: token))
            XCTAssertEqual(clock.elapsedSeconds, elapsed)
        }
        clock.pause(at: 100, generation: token)
        XCTAssertEqual(clock.phase, .flying)
        clock.advance(to: 101.5, generation: token)
        XCTAssertEqual(clock.elapsedSeconds, 1.5)
        clock.pause(at: 101.5, generation: token)
        XCTAssertFalse(clock.resume(at: 101, generation: token))
        XCTAssertEqual(clock.phase, .paused)
        XCTAssertTrue(clock.resume(at: 200, generation: token))
        clock.advance(to: 200.5, generation: token)
        XCTAssertEqual(clock.elapsedSeconds, 2)
    }

    func testRestorationKeepsPositionPausedAndInvalidatesOldGeneration() throws {
        var original = GravityFlightClock()
        let token = try XCTUnwrap(original.launch(world: .moon, at: 100))
        original.pause(at: 101, generation: token)
        let snapshot = try XCTUnwrap(original.snapshot)
        var restored = GravityFlightClock(restoring: snapshot)
        XCTAssertEqual(restored.position, original.position)
        XCTAssertEqual(restored.trajectory, original.trajectory)
        XCTAssertEqual(restored.phase, .paused)
        XCTAssertNotEqual(restored.generation, token)
        XCTAssertFalse(restored.resume(at: 1, generation: token))
        let restoredToken = restored.generation
        XCTAssertTrue(restored.resume(at: 1, generation: restoredToken))
        XCTAssertFalse(restored.advance(to: 3, generation: token))
        restored.advance(to: 1.5, generation: restoredToken)
        XCTAssertEqual(restored.elapsedSeconds, 1.5)
    }

    func testRelaunchInvalidatesStaleTicksPauseResumeAndResults() throws {
        var clock = GravityFlightClock()
        let first = try XCTUnwrap(clock.launch(world: .moon, at: 10))
        clock.advance(to: 11, generation: first)
        let launch = GravityLaunch(angleDegrees: 60, speedMetersPerSecond: 8)
        let replacement = try XCTUnwrap(clock.relaunch(world: .mars, launch: launch, at: 12))
        XCTAssertNotEqual(first, replacement)
        XCTAssertEqual(clock.elapsedSeconds, 0)
        XCTAssertEqual(clock.trajectory?.launch, launch)
        XCTAssertFalse(clock.advance(to: 100, generation: first))
        XCTAssertFalse(clock.pause(at: 100, generation: first))
        XCTAssertFalse(clock.resume(at: 100, generation: first))
        XCTAssertEqual(clock.phase, .flying)
        clock.advance(to: 12.5, generation: replacement)
        XCTAssertEqual(clock.elapsedSeconds, 0.5)
        XCTAssertEqual(clock.trajectory?.world, .mars)
    }

    func testInvalidRelaunchDoesNotDestroyCurrentFlight() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .moon, at: 10))
        clock.advance(to: 11, generation: token)
        let before = clock
        for time in [9, .nan, .infinity, -1] {
            XCTAssertNil(clock.relaunch(world: .earth, at: time))
            XCTAssertEqual(clock, before)
        }
    }

    func testLandingEmitsOnceAndCannotResumeOrOverrunGround() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .earth, at: 10))
        let trajectory = try XCTUnwrap(clock.trajectory)
        XCTAssertTrue(clock.advance(to: 100, generation: token))
        XCTAssertEqual(clock.phase, .landed)
        XCTAssertEqual(clock.elapsedSeconds, trajectory.flightTime)
        XCTAssertEqual(clock.position, GravityPosition(xMeters: trajectory.range, heightMeters: 0))
        XCTAssertFalse(clock.advance(to: 200, generation: token))
        XCTAssertFalse(clock.pause(at: 200, generation: token))
        XCTAssertFalse(clock.resume(at: 200, generation: token))
        XCTAssertNil(clock.launch(world: .earth, at: 200))
        let restored = GravityFlightClock(restoring: try XCTUnwrap(clock.snapshot))
        XCTAssertEqual(restored.phase, .landed)
        XCTAssertEqual(restored.position, clock.position)
    }

    func testPauseAtCompletedFlightReportsLandingOnce() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .earth, at: 1))
        XCTAssertTrue(clock.pause(at: 10, generation: token))
        XCTAssertEqual(clock.phase, .landed)
        XCTAssertFalse(clock.pause(at: 10, generation: token))
    }

    func testPlaybackUsesSharedSecondsRatherThanEqualFlightDurations() throws {
        var earth = GravityFlightClock()
        var moon = GravityFlightClock()
        let earthToken = try XCTUnwrap(earth.launch(world: .earth, at: 10))
        let moonToken = try XCTUnwrap(moon.launch(world: .moon, at: 10))
        XCTAssertTrue(earth.advance(to: 11, generation: earthToken))
        XCTAssertFalse(moon.advance(to: 11, generation: moonToken))
        XCTAssertEqual(earth.phase, .landed)
        XCTAssertEqual(moon.phase, .flying)
        XCTAssertEqual(moon.elapsedSeconds, 1)
        XCTAssertGreaterThan(try XCTUnwrap(moon.position).heightMeters, 0)
        XCTAssertEqual(try XCTUnwrap(earth.position).heightMeters, 0)
    }

    func testResetOnLeavingPlaygroundInvalidatesAllOldCallbacks() throws {
        var clock = GravityFlightClock()
        let token = try XCTUnwrap(clock.launch(world: .moon, at: 1))
        clock.advance(to: 2, generation: token)
        clock.reset()
        XCTAssertEqual(clock.phase, .ready)
        XCTAssertEqual(clock.elapsedSeconds, 0)
        XCTAssertNil(clock.trajectory)
        XCTAssertNil(clock.position)
        XCTAssertNil(clock.snapshot)
        XCTAssertFalse(clock.advance(to: 100, generation: token))
        XCTAssertFalse(clock.resume(at: 100, generation: token))
        let replacement = try XCTUnwrap(clock.launch(world: .earth, at: 1))
        XCTAssertNotEqual(replacement, token)
    }

    func testInvalidSnapshotsCannotRestoreOutOfBoundsElapsedTime() {
        let trajectory = GravityTrajectory(world: .moon)
        let invalid = GravityFlightSnapshot(trajectory: trajectory, elapsedSeconds: .nan)
        XCTAssertEqual(GravityFlightClock(restoring: invalid).elapsedSeconds, 0)
        let pastLanding = GravityFlightSnapshot(trajectory: trajectory, elapsedSeconds: 100)
        XCTAssertEqual(GravityFlightClock(restoring: pastLanding).phase, .landed)
        XCTAssertEqual(pastLanding.elapsedSeconds, trajectory.flightTime)
    }
}
