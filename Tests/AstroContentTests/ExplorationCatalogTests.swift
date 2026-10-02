import Foundation
import XCTest

@testable import AstroContent
@testable import AstroGameCore

@MainActor
final class ExplorationCatalogTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testThreeContinuousAdventuresHaveNineSourcedGoalsAndSpatialTargets() throws {
        let adventures = ExplorationCatalog.adventures
        XCTAssertEqual(
            adventures.map(\.id),
            ["mercury-crater-crew", "mars-rover-expedition", "saturn-ring-workshop"])
        XCTAssertEqual(adventures.flatMap(\.goals).count, 9)
        XCTAssertNil(ExplorationCatalog.adventure(destinationID: "venus"))
        var ids = Set<String>()
        let videos = try VideoLessonCatalog.bundled()
        for adventure in adventures {
            XCTAssertEqual(
                ExplorationCatalog.adventure(destinationID: adventure.destinationID), adventure)
            XCTAssertTrue(ids.insert(adventure.id).inserted)
            XCTAssertEqual(adventure.goals.count, 3)
            XCTAssertGreaterThan(adventure.revision, 0)
            XCTAssertFalse(adventure.postcardTitle.isEmpty)
            XCTAssertTrue(videos.contains { $0.id == adventure.videoLessonID })
            assertIndependentCopy(adventure.welcome)
            let targetIDs = Set(adventure.targets.map(\.id))
            for goal in adventure.goals {
                XCTAssertTrue(ids.insert(goal.id).inserted, goal.id)
                XCTAssertTrue(ids.insert(goal.conceptID).inserted, goal.conceptID)
                XCTAssertFalse(goal.requiredObservations.isEmpty)
                XCTAssertTrue(targetIDs.contains(goal.suggestedTargetID), goal.id)
                assertIndependentCopy(goal.invitation)
                assertIndependentCopy(goal.hint)
                assertIndependentCopy(goal.explanation)
                let source = try XCTUnwrap(URL(string: goal.sourceURL))
                XCTAssertEqual(source.scheme, "https")
                XCTAssertTrue(
                    source.host == "nasa.gov" || source.host?.hasSuffix(".nasa.gov") == true)
                XCTAssertTrue(reviewedSources.contains(goal.sourceURL), goal.id)
            }
            for target in adventure.targets {
                XCTAssertTrue(ids.insert(target.id).inserted, target.id)
                XCTAssertTrue((0.15...0.85).contains(target.position.x), target.id)
                XCTAssertTrue((0.20...0.75).contains(target.position.y), target.id)
                XCTAssertFalse(target.name.isEmpty)
                XCTAssertFalse(target.verb.isEmpty)
                XCTAssertFalse(target.symbol.isEmpty)
                assertIndependentCopy(target.response)
                for age in AgeBand.allCases {
                    XCTAssertLessThanOrEqual(
                        target.response.text(for: age).split(whereSeparator: \.isWhitespace).count,
                        24,
                        target.id)
                }
            }
        }
        let encoded = try JSONEncoder().encode(adventures)
        XCTAssertEqual(
            try JSONDecoder().decode([ExplorationAdventure].self, from: encoded), adventures)
    }

    func testEveryAuthoredAdventureCompletesThroughActionsInEveryAgeMode() throws {
        for adventure in ExplorationCatalog.adventures {
            for age in AgeBand.allCases {
                let session = ExplorationSession(
                    adventure: adventure, progress: GameProgress(selectedAgeBand: age))
                XCTAssertEqual(session.feedback, adventure.welcome.text(for: age))
                session.send(.begin, now: now)
                let stages = try XCTUnwrap(journeys[adventure.destinationID])
                for (index, targets) in stages.enumerated() {
                    XCTAssertEqual(session.currentGoal?.id, adventure.goals[index].id)
                    for target in targets { activate(target, in: session) }
                    XCTAssertEqual(session.cursor.completedGoalIDs.count, index + 1)
                    XCTAssertEqual(
                        session.feedback, adventure.goals[index].explanation.text(for: age))
                }
                XCTAssertEqual(session.cursor.phase, .celebrating)
                XCTAssertEqual(session.cursor.completedGoalIDs, Set(adventure.goals.map(\.id)))
                let postcard = try XCTUnwrap(session.progress.explorationCompletions[adventure.id])
                XCTAssertEqual(postcard.ageBand, age)
                XCTAssertEqual(postcard.postcard, session.cursor)
                XCTAssertTrue(
                    session.progress.destinations[adventure.destinationID]?.isScanned == true)
                XCTAssertEqual(session.progress.totalScore, 0, "Play does not require quiz points")
                session.send(.keepPlaying, now: now)
                for target in stages.flatMap({ $0 }) { activate(target, in: session) }
                XCTAssertEqual(session.progress.explorationCompletions[adventure.id], postcard)
                XCTAssertEqual(session.progress.explorationCompletions.count, 1)
            }
        }
    }

    func testMercuryNeedsBothImpactPatternsAndMovesTheSameSensor() throws {
        let session = try makeSession("mercury")
        XCTAssertFalse(session.availableTargets.contains { $0.id == "mercury-ejecta-trail" })
        activate("mercury-large-impact", in: session)
        XCTAssertEqual(session.cursor.observations, ["impact.large"])
        XCTAssertTrue(session.cursor.completedGoalIDs.isEmpty)
        activate("mercury-small-impact", in: session)
        XCTAssertEqual(session.cursor.completedGoalIDs, ["mercury-two-impacts"])
        XCTAssertFalse(session.availableTargets.contains { $0.id == "mercury-shadow-sensor-site" })
        activate("mercury-ejecta-trail", in: session)
        activate("mercury-sunlit-sensor-site", in: session)
        XCTAssertFalse(session.cursor.observations.contains("mercury.sensor.sunlit"))
        activate("mercury-sensor", in: session)
        activate("mercury-sunlit-sensor-site", in: session)
        XCTAssertEqual(session.cursor.placements["mercury.sensor"], "mercury-sunlit-sensor-site")
        activate("mercury-sensor", in: session)
        XCTAssertNil(session.cursor.placements["mercury.sensor"])
        XCTAssertTrue(session.cursor.observations.contains("mercury.sensor.sunlit"))
        activate("mercury-shadow-sensor-site", in: session)
        XCTAssertEqual(session.cursor.placements["mercury.sensor"], "mercury-shadow-sensor-site")
        XCTAssertEqual(session.cursor.phase, .celebrating)
    }

    func testMercuryRestoresACarriedSensorAndFinishesTheAuthoredAdventure() throws {
        let adventure = try XCTUnwrap(ExplorationCatalog.adventure(destinationID: "mercury"))
        for age in AgeBand.allCases {
            let session = ExplorationSession(
                adventure: adventure, progress: GameProgress(selectedAgeBand: age))
            session.send(.begin, now: now)
            for id in [
                "mercury-small-impact", "mercury-large-impact", "mercury-ejecta-trail",
                "mercury-sensor",
            ] { activate(id, in: session) }
            XCTAssertEqual(session.cursor.carriedItemID, "mercury.sensor")
            XCTAssertEqual(session.cursor.completedGoalIDs.count, 2)
            let data = try JSONEncoder().encode(session.progress)
            let saved = try JSONDecoder().decode(GameProgress.self, from: data)
            let restored = ExplorationSession(adventure: adventure, progress: saved)
            XCTAssertTrue(restored.isPaused)
            XCTAssertEqual(restored.overlay, .pause)
            XCTAssertEqual(restored.cursor.carriedItemID, "mercury.sensor")
            XCTAssertEqual(restored.currentGoal?.id, "mercury-sun-and-shadow")
            restored.send(.resume, now: now)
            for id in [
                "mercury-sunlit-sensor-site", "mercury-sensor", "mercury-shadow-sensor-site",
            ] { activate(id, in: restored) }
            XCTAssertEqual(restored.cursor.phase, .celebrating)
            XCTAssertEqual(restored.cursor.completedGoalIDs, Set(adventure.goals.map(\.id)))
            XCTAssertEqual(restored.progress.explorationCompletions.count, 1)
            let postcard = try XCTUnwrap(restored.progress.explorationCompletions[adventure.id])
            XCTAssertEqual(postcard.ageBand, age)
            XCTAssertEqual(postcard.postcard, restored.cursor)
        }
    }

    func testFilmObservationsMatchTheActualPrecedingSegmentsInEveryAgeMode() throws {
        let videos = try VideoLessonCatalog.bundled()
        let cases: [(destination: String, checkpoint: Int, segmentID: String, topics: [String])] = [
            ("mercury", 0, "mercury-segment-1", ["crater"]),
            ("mercury", 1, "mercury-segment-2", ["shadow", "shade"]),
            ("mars", 0, "mars-segment-1", ["model", "visualization"]),
            ("mars", 1, "mars-segment-2", ["volcano"]),
            ("saturn", 0, "saturn-segment-1", ["six", "hexagon"]),
            ("saturn", 1, "saturn-segment-2", ["ring"]),
        ]
        for item in cases {
            let adventure = try XCTUnwrap(
                ExplorationCatalog.adventure(destinationID: item.destination))
            let video = try XCTUnwrap(videos.first { $0.id == adventure.videoLessonID })
            let checkpoint = video.checkpoints[item.checkpoint]
            let preceding = try XCTUnwrap(
                video.segments.first {
                    $0.startTime == checkpoint.replayStartTime && $0.endTime == checkpoint.time
                })
            XCTAssertEqual(preceding.id, item.segmentID)
            let observation = try XCTUnwrap(
                ExplorationCatalog.filmObservation(
                    destinationID: item.destination, checkpoint: item.checkpoint))
            assertIndependentCopy(observation)
            for age in AgeBand.allCases {
                // Check the authored prompt against the real bundled narration, not a mock film.
                let watched = preceding.narration[age].lowercased()
                let prompt = observation.text(for: age).lowercased()
                XCTAssertTrue(item.topics.contains { watched.contains($0) }, preceding.id)
                XCTAssertTrue(item.topics.contains { prompt.contains($0) }, preceding.id)
                XCTAssertFalse(
                    adventure.goals.contains {
                        $0.invitation.text(for: age) == observation.text(for: age)
                    }, "Film noticing is independent of the current playground goal")
            }
        }
        XCTAssertNil(ExplorationCatalog.filmObservation(destinationID: "venus", checkpoint: 0))
        XCTAssertNil(ExplorationCatalog.filmObservation(destinationID: "mercury", checkpoint: -1))
        XCTAssertNil(ExplorationCatalog.filmObservation(destinationID: "saturn", checkpoint: 2))
    }

    func testMarsPhotoAndComparisonNeedTheirEarlierObservations() throws {
        let session = try makeSession("mars")
        XCTAssertFalse(session.availableTargets.contains { $0.id == "mars-layered-rock" })
        session.send(.adjustModel("mars.water", by: 1), now: now)
        XCTAssertFalse(session.cursor.observations.contains("mars.model.water"))
        activate("mars-crater-landmark", in: session)
        activate("mars-rock-landmark", in: session)
        XCTAssertFalse(session.availableTargets.contains { $0.id == "mars-rock-camera" })
        activate("mars-layered-rock", in: session)
        XCTAssertFalse(session.availableTargets.contains { $0.id == "mars-water-model" })
        activate("mars-rock-camera", in: session)
        session.send(.adjustModel("mars.compare", by: 1), now: now)
        XCTAssertFalse(session.cursor.observations.contains("mars.deposits.compared"))
        activate("mars-water-model", in: session)
        XCTAssertEqual(session.cursor.modelSettings["mars.water"], 1)
        XCTAssertEqual(session.cursor.completedGoalIDs.count, 2)
        activate("mars-deposit-compare", in: session)
        XCTAssertEqual(session.cursor.modelSettings["mars.compare"], 1)
        XCTAssertEqual(session.cursor.phase, .celebrating)
    }

    func testSaturnRetainsBothOrbitDiscoveriesAndNeedsTheEdgeView() throws {
        let session = try makeSession("saturn")
        activate("saturn-ice-kit", in: session)
        activate("saturn-outer-orbit", in: session)
        XCTAssertFalse(session.availableTargets.contains { $0.id == "saturn-watch-motion" })
        activate("saturn-ice-kit", in: session)
        XCTAssertTrue(session.cursor.observations.contains("saturn.ring.outer"))
        activate("saturn-inner-orbit", in: session)
        XCTAssertTrue(session.cursor.observations.contains("saturn.ring.inner"))
        XCTAssertFalse(session.availableTargets.contains { $0.id == "saturn-edge-view" })
        activate("saturn-watch-motion", in: session)
        XCTAssertEqual(session.cursor.modelSettings["saturn.motion"], 1)
        session.send(.adjustModel("saturn.view", by: 2), now: now)
        XCTAssertTrue(session.cursor.observations.contains("saturn.view.face"))
        XCTAssertFalse(session.cursor.observations.contains("saturn.view.edge"))
        XCTAssertEqual(session.cursor.completedGoalIDs.count, 2)
        activate("saturn-edge-view", in: session)
        XCTAssertEqual(session.cursor.modelSettings["saturn.view"], 1)
        XCTAssertEqual(session.cursor.phase, .celebrating)
    }

    private func assertIndependentCopy(
        _ copy: ExplorationText, file: StaticString = #filePath, line: UInt = #line
    ) {
        let strings = AgeBand.allCases.map { copy.text(for: $0) }
        XCTAssertEqual(Set(strings).count, 3, file: file, line: line)
        XCTAssertTrue(strings.allSatisfy { !$0.isEmpty }, file: file, line: line)
    }

    private func makeSession(_ destinationID: String) throws -> ExplorationSession {
        let adventure = try XCTUnwrap(ExplorationCatalog.adventure(destinationID: destinationID))
        let session = ExplorationSession(adventure: adventure, progress: GameProgress())
        session.send(.begin, now: now)
        return session
    }

    private func activate(_ id: String, in session: ExplorationSession) {
        XCTAssertTrue(session.availableTargets.contains { $0.id == id }, id)
        session.send(.selectTarget(id), now: now)
        XCTAssertEqual(session.selectedTarget?.id, id)
        session.send(.activateTarget, now: now)
    }

    private let journeys: [String: [[String]]] = [
        "mercury": [
            ["mercury-small-impact", "mercury-large-impact"],
            ["mercury-ejecta-trail"],
            [
                "mercury-sensor", "mercury-sunlit-sensor-site", "mercury-sensor",
                "mercury-shadow-sensor-site",
            ],
        ],
        "mars": [
            ["mars-crater-landmark", "mars-rock-landmark"],
            ["mars-layered-rock", "mars-rock-camera"],
            ["mars-water-model", "mars-deposit-compare"],
        ],
        "saturn": [
            ["saturn-ice-kit", "saturn-inner-orbit", "saturn-ice-kit", "saturn-outer-orbit"],
            ["saturn-watch-motion"],
            ["saturn-edge-view"],
        ],
    ]

    // Offline validation uses only the primary sources actually read during authoring.
    private let reviewedSources: Set<String> = [
        "https://www.nasa.gov/solar-system/asteroid-day-and-impact-craters/",
        "https://science.nasa.gov/mercury/facts/",
        "https://science.nasa.gov/mission/msl-curiosity/science/",
        "https://science.nasa.gov/photojournal/how-a-delta-forms-where-river-meets-lake/",
        "https://science.nasa.gov/saturn/facts/",
        "https://science.nasa.gov/mission/cassini/science/rings/",
    ]
}
