import AstroGameCore
import Foundation
import XCTest

@testable import AstroServices

final class ProgressStoreTests: XCTestCase {
    func testJSONStoreRoundTripsVersionedProgress() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let expected = GameProgress(
            selectedAgeBand: .ages4To6,
            destinations: [
                "mercury": DestinationProgress(
                    isScanned: true,
                    masteryScore: 25,
                    reviewBox: 1
                )
            ]
        )
        let store = JSONProgressStore(fileURL: fileURL)

        try await store.save(expected)
        let restored = try await store.load()

        XCTAssertEqual(restored, expected)
        XCTAssertEqual(restored?.schemaVersion, GameProgress.currentSchemaVersion)
    }

    func testVersionOneProgressMigratesWithoutLosingDestinationData() async throws {
        let legacyJSON = """
            {
              "schemaVersion": 1,
              "missionID": "signal-sweep",
              "selectedAgeBand": "ages7To9",
              "destinations": {
                "mars": {
                  "isScanned": true,
                  "isQuizCompleted": true,
                  "correctAnswers": 1,
                  "attempts": 1,
                  "masteryScore": 25,
                  "reviewBox": 1
                }
              }
            }
            """
        let decoded = try JSONDecoder().decode(GameProgress.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(decoded.schemaVersion, GameProgress.currentSchemaVersion)
        XCTAssertTrue(decoded.destinations["mars"]?.isQuizCompleted == true)
        XCTAssertEqual(decoded.totalScore, 0)
        XCTAssertTrue(decoded.leaderboard.isEmpty)
    }
}
