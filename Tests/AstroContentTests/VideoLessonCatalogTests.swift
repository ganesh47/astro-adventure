import AVFoundation
import CryptoKit
import Foundation
import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class VideoLessonCatalogTests: XCTestCase {
    func testEveryPlanetHasAnOfflineFilmAndThreeCompleteAgeAdaptations() throws {
        let lessons = try VideoLessonCatalog.bundled()
        XCTAssertEqual(
            lessons.map(\.destinationID),
            [
                "mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune",
            ])
        for lesson in lessons {
            XCTAssertEqual(lesson.duration, 60)
            XCTAssertEqual(lesson.segments.map(\.startTime), [0, 20, 40])
            XCTAssertEqual(lesson.segments.map(\.endTime), [20, 40, 60])
            XCTAssertEqual(lesson.checkpoints.map(\.time), [20, 40])
            XCTAssertEqual(lesson.checkpoints.map(\.replayStartTime), [0, 20])
            XCTAssertEqual(lesson.fallbackCards.count, 3)
            for (index, segment) in lesson.segments.enumerated() {
                for ageBand in AgeBand.allCases {
                    XCTAssertEqual(
                        segment.narration[ageBand], lesson.fallbackCards[index].body[ageBand])
                    XCTAssertFalse(segment.narration[ageBand].isEmpty)
                }
            }
            XCTAssertNotEqual(
                lesson.segments[0].narration[.ages4To6], lesson.segments[0].narration[.ages10To12])
        }
    }

    func testCheckpointsCannotBeOutsideTheirTeachingSegment() throws {
        var object = try encodedCatalog()
        var checkpoints = try XCTUnwrap(object[0]["checkpoints"] as? [[String: Any]])
        checkpoints[0]["time"] = 61
        object[0]["checkpoints"] = checkpoints
        XCTAssertThrowsError(
            try VideoLessonCatalog.decode(JSONSerialization.data(withJSONObject: object))
        ) { error in
            XCTAssertEqual(
                error as? VideoLessonCatalogError, .invalidCheckpoint("mercury-checkpoint-1"))
        }
    }

    func testReviewCopyMustAlsoContainAValidAnswer() throws {
        var object = try encodedCatalog()
        var checkpoints = try XCTUnwrap(object[0]["checkpoints"] as? [[String: Any]])
        var question = try XCTUnwrap(checkpoints[0]["question"] as? [String: Any])
        var reviews = try XCTUnwrap(question["reviewContent"] as? [String: Any])
        var junior = try XCTUnwrap(reviews["ages4To6"] as? [String: Any])
        junior["correctChoiceID"] = "missing"
        reviews["ages4To6"] = junior
        question["reviewContent"] = reviews
        checkpoints[0]["question"] = question
        object[0]["checkpoints"] = checkpoints
        XCTAssertThrowsError(
            try VideoLessonCatalog.decode(JSONSerialization.data(withJSONObject: object))
        ) { error in
            XCTAssertEqual(
                error as? VideoLessonCatalogError,
                .invalidQuestion("mercury-checkpoint-1", .ages4To6))
        }
    }

    func testAllEightMoviesDecodeAsSilentSixtySecond720pAssetsWithinBudget() async throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        var totalBytes = 0
        let recordsURL = root.appendingPathComponent("scripts/video_media_sources.json")
        let sourceCatalog = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: recordsURL)) as? [String: Any])
        let sourceRecords = try XCTUnwrap(sourceCatalog["records"] as? [[String: Any]])
        for lesson in try VideoLessonCatalog.bundled() {
            let url = root.appendingPathComponent("Sources/AstroUI/Resources/LearningVideos")
                .appendingPathComponent(lesson.resourceName + ".mp4")
            let data = try Data(contentsOf: url)
            XCTAssertGreaterThan(data.count, 100_000, lesson.id)
            XCTAssertEqual(
                String(data: data.subdata(in: 4..<8), encoding: .ascii), "ftyp", lesson.id)
            let sourceRecord = try XCTUnwrap(
                sourceRecords.first { $0["destinationID"] as? String == lesson.destinationID })
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(hash, sourceRecord["outputSHA256"] as? String, lesson.id)
            totalBytes += data.count
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            XCTAssertEqual(duration.seconds, 60, accuracy: 0.05, lesson.id)
            let playable = try await asset.load(.isPlayable)
            XCTAssertTrue(playable, lesson.id)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            XCTAssertEqual(tracks.count, 1, lesson.id)
            let track = try XCTUnwrap(tracks.first)
            let size = try await track.load(.naturalSize)
            XCTAssertEqual(size.width, 1280, lesson.id)
            XCTAssertEqual(size.height, 720, lesson.id)
            let frameRate = try await track.load(.nominalFrameRate)
            XCTAssertEqual(frameRate, 30, lesson.id)
            let descriptions = try await track.load(.formatDescriptions)
            XCTAssertEqual(
                CMFormatDescriptionGetMediaSubType(try XCTUnwrap(descriptions.first)),
                kCMVideoCodecType_H264, lesson.id)
            let audio = try await asset.loadTracks(withMediaType: .audio)
            XCTAssertTrue(audio.isEmpty, "\(lesson.id) must not include uncertain source music")
        }
        XCTAssertLessThan(totalBytes, 100 * 1024 * 1024)
    }

    private func encodedCatalog() throws -> [[String: Any]] {
        let data = try JSONEncoder().encode(VideoLessonCatalog.bundled())
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }
}
