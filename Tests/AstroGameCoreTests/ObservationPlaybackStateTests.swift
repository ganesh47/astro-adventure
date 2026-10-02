import AstroGameCore
import XCTest

final class ObservationPlaybackStateTests: XCTestCase {
    func testForwardSeekingCannotSkipInvitationsAndContinueDoesNotAutoplay() {
        var state = ObservationPlaybackState(duration: 60, checkpoints: [20, 40])
        state.seek(to: 59)
        XCTAssertEqual(state.seconds, 20)
        XCTAssertEqual(state.pendingCheckpoint, 0)
        state.continueFilm()
        state.continueFilm()
        XCTAssertFalse(state.isPlaying)
        state.seek(to: 59)
        XCTAssertEqual(state.seconds, 40)
        XCTAssertEqual(state.pendingCheckpoint, 1)
        XCTAssertEqual(state.acknowledged, ["segment-0"])
    }

    func testReplayRestorationAndDuplicateTimeEventsAreSafe() {
        var state = ObservationPlaybackState(duration: 60, checkpoints: [20, 40], seconds: 41)
        XCTAssertEqual(state.seconds, 20)
        XCTAssertFalse(state.isPlaying)
        state.play()
        XCTAssertFalse(state.isPlaying)
        state.seek(to: 10)
        state.play()
        state.timeChanged(21)
        state.timeChanged(45)
        XCTAssertEqual(state.seconds, 20)
        state.continueFilm()
        state.seek(to: 0)
        state.play()
        state.timeChanged(25)
        XCTAssertNil(state.pendingCheckpoint)
        XCTAssertEqual(state.seconds, 25)
        state.pause()
        state.timeChanged(45)
        XCTAssertEqual(state.seconds, 25)
        let restored = ObservationPlaybackState(
            duration: 60, checkpoints: [20, 40], seconds: state.seconds,
            acknowledged: state.acknowledged)
        XCTAssertFalse(restored.isPlaying)
        XCTAssertEqual(restored.acknowledged, ["segment-0"])
    }

    func testInvalidEventsAndEndClamping() {
        var state = ObservationPlaybackState(
            duration: 60, checkpoints: [20, 40],
            acknowledged: ["segment-0", "segment-1", "invalid"])
        state.seek(to: .nan)
        XCTAssertEqual(state.seconds, 0)
        state.play()
        state.timeChanged(100)
        XCTAssertEqual(state.seconds, 60)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.acknowledged.count, 2)
    }
}
