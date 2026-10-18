import Foundation
import XCTest

@testable import AstroContent
@testable import AstroGameCore

@MainActor
final class PhotoSafariTests: XCTestCase {
    func testNineStopsUseBundledCreditedPhotosAndAgeSpecificFacts() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let images = root.appendingPathComponent("Sources/AstroUI/Resources/DiscoveryImages")
        XCTAssertEqual(
            PhotoSafariCatalog.safaris.map(\.destinationID), ["mercury", "mars", "saturn"])
        var stopIDs = Set<String>()
        for safari in PhotoSafariCatalog.safaris {
            XCTAssertEqual(safari.stops.count, 3)
            XCTAssertFalse(ExplorationCatalog.adventures.contains { $0.id == safari.id })
            for stop in safari.stops {
                XCTAssertTrue(stopIDs.insert(stop.id).inserted)
                XCTAssertEqual(stop.photos.count, 2)
                XCTAssertEqual(Set(stop.photos.map(\.id)).count, 2)
                XCTAssertNotNil(stop.discoveryPhoto)
                XCTAssertEqual(Set(AgeBand.allCases.map { stop.fact.text(for: $0) }).count, 3)
                for photo in stop.photos {
                    XCTAssertTrue(
                        FileManager.default.fileExists(
                            atPath: images.appendingPathComponent(photo.imageName + ".jpg").path))
                    XCTAssertFalse(photo.credit.isEmpty)
                    XCTAssertFalse(photo.caption.isEmpty)
                    let source = try XCTUnwrap(URL(string: photo.sourceURL))
                    XCTAssertEqual(source.scheme, "https")
                    XCTAssertTrue(source.host?.hasSuffix(".nasa.gov") == true)
                }
            }
        }
        XCTAssertEqual(stopIDs.count, 9)
    }

    func testChoicesHelpAndRevealAcknowledgmentForEveryAgeAndWorld() throws {
        for safari in PhotoSafariCatalog.safaris {
            for age in AgeBand.allCases {
                let play = PhotoSafariSession(
                    safari: safari, progress: GameProgress(selectedAgeBand: age))
                play.showMe()
                XCTAssertEqual(play.collectedCount, 0, "Arrival does not award a photo")
                play.begin()
                for (index, stop) in safari.stops.enumerated() {
                    XCTAssertEqual(play.currentStop?.id, stop.id)
                    let saved = play.progress
                    play.choosePhoto("not-a-choice")
                    play.choosePhoto(
                        try XCTUnwrap(stop.photos.first { $0.id != stop.discoveryPhotoID }).id)
                    XCTAssertNotNil(play.hint)
                    XCTAssertEqual(play.progress, saved, "Looking at another image has no penalty")
                    play.pause()
                    play.showMe()
                    play.choosePhoto(stop.discoveryPhotoID)
                    XCTAssertEqual(play.progress, saved, "Pause blocks discovery")
                    play.resume()
                    if index.isMultiple(of: 2) {
                        play.choosePhoto(stop.discoveryPhotoID)
                    } else {
                        play.showMe()
                    }
                    XCTAssertEqual(play.revealedStop?.id, stop.id)
                    XCTAssertEqual(play.collectedCount, index + 1)
                    XCTAssertNil(play.hint)
                    play.showMe()
                    play.choosePhoto(stop.discoveryPhotoID)
                    XCTAssertEqual(
                        play.collectedCount, index + 1, "Reveal cannot skip another clue")
                    play.next()
                    XCTAssertNil(play.revealedStop)
                }
                XCTAssertTrue(play.isCollection)
                XCTAssertEqual(play.progress.explorationCompletions.count, 1)
                XCTAssertTrue(
                    play.progress.destinations[safari.destinationID]?.isQuizCompleted == true)
                play.openCollectedPhoto(safari.stops[0].id)
                XCTAssertEqual(play.albumStop?.id, safari.stops[0].id)
                play.closeCollectedPhoto()
                XCTAssertNil(play.albumStop)
            }
        }
    }

    func testRelaunchRestoresBothRevealAndNextClueAndFinalAlbum() throws {
        let safari = PhotoSafariCatalog.safaris[1]
        var play = PhotoSafariSession(safari: safari, progress: GameProgress())
        play.begin()
        for stop in safari.stops {
            play.showMe()
            play = try restored(play)
            XCTAssertTrue(play.isPaused)
            XCTAssertEqual(play.revealedStop?.id, stop.id)
            play.resume()
            play.next()
            play = try restored(play)
            XCTAssertNil(play.revealedStop)
            XCTAssertTrue(play.isPaused)
            play.resume()
        }
        XCTAssertTrue(play.isCollection)
        let completed = play.progress
        play.showMe()
        play.next()
        XCTAssertEqual(play.progress, completed)
        XCTAssertLessThan(try JSONEncoder().encode(completed).count, 20_000)
    }

    func testHistoricalPostcardSurvivesAndReplayDoesNotAwardAgain() throws {
        let old = ExplorationCatalog.adventures[0]
        var progress = GameProgress()
        let postcard = ExplorationCursor(
            adventureID: old.id, revision: old.revision, ageBand: .ages4To6,
            selectedTargetID: old.targets[0].id)
        progress.explorationCompletions[old.id] = ExplorationCompletion(
            completedAt: .distantPast, ageBand: .ages4To6, postcard: postcard)
        let safari = PhotoSafariCatalog.safaris[0]
        let first = PhotoSafariSession(safari: safari, progress: progress)
        first.begin()
        for _ in safari.stops {
            first.showMe()
            first.next()
        }
        let completion = first.progress.explorationCompletions[safari.id]
        XCTAssertEqual(
            first.progress.explorationCompletions[old.id], progress.explorationCompletions[old.id])
        var replayProgress = first.progress
        replayProgress.explorationCursor = nil
        let replay = PhotoSafariSession(safari: safari, progress: replayProgress)
        replay.begin()
        for _ in safari.stops {
            replay.showMe()
            replay.next()
        }
        XCTAssertEqual(replay.progress.explorationCompletions[safari.id], completion)
        XCTAssertEqual(replay.progress.explorationCompletions.count, 2)
    }

    private func restored(_ session: PhotoSafariSession) throws -> PhotoSafariSession {
        let saved = try JSONDecoder().decode(
            GameProgress.self, from: JSONEncoder().encode(session.progress))
        return PhotoSafariSession(safari: session.safari, progress: saved)
    }
}
