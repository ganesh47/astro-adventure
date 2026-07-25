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
}
