import Foundation
import XCTest

@testable import AstroContent
@testable import AstroGameCore

final class QuizPictureCatalogTests: XCTestCase {
    func testEveryBundledQuestionAndReviewHasAuthoredPictureChoices() throws {
        let lessons = try LessonCatalog.bundled()
        var questionCount = 0
        var choiceCount = 0

        func inspect(_ quiz: QuizContent, context: String) throws {
            questionCount += 1
            choiceCount += quiz.choices.count
            for choice in quiz.choices {
                let picture = try XCTUnwrap(choice.picture, "\(context): \(choice.id)")
                XCTAssertFalse(picture.label.trimmingCharacters(in: .whitespaces).isEmpty)
                XCTAssertFalse((picture.detail ?? "").isEmpty)
                if picture.scene == .waterCoverage {
                    let fraction = try XCTUnwrap(picture.fraction, choice.id)
                    XCTAssertTrue((0...1).contains(fraction), choice.id)
                } else {
                    XCTAssertNil(picture.fraction, choice.id)
                }
            }
            XCTAssertEqual(
                Set(quiz.choices.compactMap { $0.picture?.label }).count,
                quiz.choices.count,
                "\(context) needs distinct answer proposals")
        }

        for lesson in lessons {
            for band in AgeBand.allCases {
                try inspect(lesson.content[band].quiz, context: "\(lesson.id) \(band)")
                for quiz in QuizRoundCatalog.quizzes(destinationID: lesson.id, ageBand: band) {
                    try inspect(quiz, context: "\(lesson.id) round \(band)")
                }
            }
        }
        for mission in try PlanetMissionCatalog.bundled() {
            for question in mission.questions {
                for band in AgeBand.allCases {
                    try inspect(question.content[band], context: "\(question.id) \(band)")
                    try inspect(
                        question.reviewContent[band], context: "\(question.id) review \(band)")
                }
            }
        }
        for video in try VideoLessonCatalog.bundled() {
            for checkpoint in video.checkpoints {
                for band in AgeBand.allCases {
                    try inspect(
                        checkpoint.question.content[band],
                        context: "\(checkpoint.id) \(band)")
                    try inspect(
                        checkpoint.question.reviewContent[band],
                        context: "\(checkpoint.id) review \(band)")
                }
            }
        }

        XCTAssertEqual(questionCount, 873)
        XCTAssertEqual(choiceCount, 2_328)
    }

    func testAnswerPositionMixingPreservesAuthoredPicturePayloads() throws {
        let destinations = [
            "sun", "venus", "earth", "moon", "jupiter", "saturn", "uranus", "neptune",
            "pluto", "ceres", "space-technology-lab",
        ]
        for destination in destinations {
            for band in AgeBand.allCases {
                let authored: [QuizContent]
                if destination == "space-technology-lab" {
                    authored = SpaceTechnologyCatalog.quizzes(ageBand: band)
                } else {
                    authored = try XCTUnwrap(
                        SolarSystemExpansionCatalog.quizzes(
                            destinationID: destination, ageBand: band))
                }
                let mixed = QuizRoundCatalog.quizzes(destinationID: destination, ageBand: band)
                XCTAssertEqual(mixed.count, authored.count)
                for (original, reordered) in zip(authored, mixed) {
                    XCTAssertEqual(original.correctChoiceID, reordered.correctChoiceID)
                    let originalChoices = Dictionary(
                        uniqueKeysWithValues: original.choices.map { ($0.id, $0) })
                    for choice in reordered.choices {
                        XCTAssertEqual(choice, originalChoices[choice.id])
                    }
                }
            }
        }
    }

    func testSharedChoiceIDsKeepTheirContextualMeaning() throws {
        let mercury = QuizRoundCatalog.quizzes(destinationID: "mercury", ageBand: .ages7To9)
        let europa = QuizRoundCatalog.quizzes(destinationID: "europa", ageBand: .ages7To9)
        let innerOrbit = try XCTUnwrap(mercury[0].choices.first { $0.id == "sun" }?.picture)
        let smallStar = try XCTUnwrap(europa[0].choices.first { $0.id == "sun" }?.picture)
        XCTAssertEqual(innerOrbit.scene, .innerOrbit)
        XCTAssertEqual(smallStar.scene, .star)
        XCTAssertNotEqual(innerOrbit, smallStar)

        let surfaceOcean = try XCTUnwrap(
            mercury[2].choices.first { $0.id == "deep_ocean" }?.picture)
        let subsurfaceOcean = try XCTUnwrap(
            europa[2].choices.first { $0.id == "deep_ocean" }?.picture)
        XCTAssertEqual(surfaceOcean.scene, .oceanCirculation)
        XCTAssertEqual(subsurfaceOcean.scene, .subsurfaceOcean)
        XCTAssertTrue(surfaceOcean.detail?.contains("surface ocean") == true)
        XCTAssertTrue(subsurfaceOcean.detail?.contains("beneath") == true)
        XCTAssertNotEqual(surfaceOcean, subsurfaceOcean)
    }

    func testAgeSpecificChangesToAnOptionHaveAgeSpecificPictures() throws {
        let mission = try XCTUnwrap(
            PlanetMissionCatalog.bundled().first { $0.id == "venus-backward-spinner" })
        let question = try XCTUnwrap(
            mission.questions.first { $0.conceptID == "venus-backward-spinner-retrograde" })
        let id = "venus-backward-spinner-retrograde-option-1"
        let young = try XCTUnwrap(
            question.content[.ages4To6].choices.first { $0.id == id }?.picture)
        let older = try XCTUnwrap(
            question.content[.ages7To9].choices.first { $0.id == id }?.picture)
        XCTAssertEqual(young.scene, .sameSpins)
        XCTAssertEqual(older.scene, .stillWorld)
        XCTAssertEqual(young.label, "Exactly the same way")
        XCTAssertEqual(older.label, "It does not spin at all")
        XCTAssertEqual(
            question.reviewContent[.ages7To9].choices.first { $0.id == id }?.picture, older)
    }

    func testLightTimeProposalsNameOneJourneyAndUseDistinctDurations() throws {
        for lesson in try LessonCatalog.bundled() where lesson.id != "space-technology-lab" {
            for band in AgeBand.allCases {
                let quiz = try XCTUnwrap(
                    QuizRoundCatalog.quizzes(destinationID: lesson.id, ageBand: band)
                        .first { $0.correctChoiceID.contains("-light") })
                let target = lesson.id == "sun" ? "Earth" : lesson.displayName
                XCTAssertTrue(quiz.prompt.contains(target), quiz.prompt)
                let expectedJourney = "Sunlight travelling from the Sun to \(target)"
                for choice in quiz.choices {
                    XCTAssertEqual(choice.picture?.scene, .duration)
                    XCTAssertEqual(choice.picture?.detail, expectedJourney)
                    XCTAssertEqual(choice.picture?.label, choice.text)
                }
                let values = try quiz.choices.map { try XCTUnwrap(minutes(in: $0.text)) }
                XCTAssertEqual(Set(values).count, quiz.choices.count, "\(lesson.id) \(band)")
            }
        }
        for destination in ["sun", "earth", "moon"] {
            let quiz = try XCTUnwrap(
                QuizRoundCatalog.quizzes(destinationID: destination, ageBand: .ages7To9)
                    .first { $0.correctChoiceID == "\(destination)-light-correct" })
            XCTAssertEqual(
                Set(quiz.choices.map(\.text)), Set(["8.3 min", "6 min", "43 min"]))
        }
    }

    func testNumericAndShapeProposalsAreNotSharedPhotographs() throws {
        let mars = QuizRoundCatalog.quizzes(destinationID: "mars", ageBand: .ages7To9)
        XCTAssertTrue(mars[1].choices.allSatisfy { $0.picture?.scene == .sizeComparison })
        XCTAssertEqual(
            Set(mars[1].choices.compactMap { $0.picture?.label }),
            Set(["1/2 × Earth", "1 × Earth", "2 × Earth"]))
        XCTAssertTrue(mars[2].choices.allSatisfy { $0.picture?.scene == .canyonLength })
        XCTAssertTrue(mars[3].choices.allSatisfy { $0.picture?.scene == .volcanoWidth })
        for question in [mars[2], mars[3]] {
            XCTAssertTrue(question.choices.allSatisfy { $0.picture?.label == $0.text })
        }
        let saturn = try XCTUnwrap(
            VideoLessonCatalog.bundled().first { $0.destinationID == "saturn" })
        let shapes = saturn.checkpoints[0].question.content[.ages7To9].choices
        XCTAssertEqual(
            Set(shapes.compactMap { $0.picture?.scene.rawValue }),
            Set(["hexagon", "triangle", "line"]))
    }

    func testFeatureMeasurementsKeepTheirPhysicalEndpoints() throws {
        for band in AgeBand.allCases {
            let mercury = QuizRoundCatalog.quizzes(destinationID: "mercury", ageBand: band)
            let europa = QuizRoundCatalog.quizzes(destinationID: "europa", ageBand: band)
            XCTAssertTrue(mercury[1].choices.allSatisfy { $0.picture?.scene == .craterWidth })
            XCTAssertTrue(europa[4].choices.allSatisfy { $0.picture?.scene == .flybyDistance })
            let hollows = try XCTUnwrap(mercury[3].choices.first { $0.id == "bright_hollows" })
            XCTAssertEqual(hollows.picture?.scene, .hollows)
        }
        let missions = try PlanetMissionCatalog.bundled()
        let expected: [String: QuizPicture.Scene] = [
            "A change in orbital distance": .changingOrbitDistance,
            "Only the diameter of the planet": .planetDiameter,
            "Pulls the Sun closer to Venus": .movingSun,
            "Changes the Sun’s position instead of energy flow": .movingSun,
            "The spacecraft-size clock": .spacecraftSize,
            "Only the spacecraft’s dimensions": .spacecraftSize,
            "The distance from a classroom": .classroomDistance,
            "A classroom to a nearby city": .classroomDistance,
            "A fixed distance from Earth": .earthWorldDistance,
            "An unchanging Earth-to-Neptune separation": .earthWorldDistance,
        ]
        var found = Set<String>()
        for mission in missions {
            for question in mission.questions {
                for band in AgeBand.allCases {
                    for quiz in [question.content[band], question.reviewContent[band]] {
                        for choice in quiz.choices {
                            guard let scene = expected[choice.text] else { continue }
                            XCTAssertEqual(choice.picture?.scene, scene, choice.text)
                            found.insert(choice.text)
                        }
                    }
                }
            }
        }
        XCTAssertEqual(found, Set(expected.keys))
    }

    func testTechnologyProposalsHaveTheirOwnMeaningfulScenes() throws {
        let quizzes = QuizRoundCatalog.quizzes(
            destinationID: "space-technology-lab", ageBand: .ages7To9)
        let choices = quizzes.flatMap(\.choices)
        let expected: [String: QuizPicture.Scene] = [
            "tech_satellite_parts": .solarPanels,
            "tech_satellite_wings": .wingedSatellite,
            "tech_satellite_sails": .sailingSatellite,
            "tech_suit_life": .spacesuit,
            "tech_suit_wings": .wingedSuit,
            "tech_suit_room": .crewSuit,
            "tech_empty_tank": .emptyTank,
            "tech_telescope_near": .movingStars,
            "tech_dsn_rotation": .spin,
        ]
        for (id, scene) in expected {
            let choice = try XCTUnwrap(choices.first { $0.id == id })
            XCTAssertEqual(choice.picture?.scene, scene)
            XCTAssertEqual(choice.picture?.label, choice.text)
        }
    }

    func testAuthoredAxesAndDirectionsAreDistinctFromGenericMotion() throws {
        let missions = try PlanetMissionCatalog.bundled()
        let expected: [String: [String: QuizPicture.Scene]] = [
            "mercury-speedy-year-rotation": [
                "Turn in place": .spin,
                "Turn once around its own axis": .spin,
                "The axial rotation period": .spin,
            ],
            "venus-backward-spinner-retrograde": [
                "The other way": .retrogradeSpin,
                "Its spin is opposite to most planets": .retrogradeSpin,
                "Axial spin is reversed, not its orbital direction": .retrogradeSpin,
                "Exactly the same way": .sameSpins,
            ],
            "earth-season-tracker-tilt": [
                "Earth’s tilt": .tiltedSpin,
                "The tilt of Earth’s axis": .tiltedSpin,
                "Axial tilt changing illumination": .tiltedSpin,
            ],
            "uranus-sideways-seasons-tilt": [
                "A sideways globe": .sidewaysSpin,
                "A nearly sideways axis": .sidewaysSpin,
                "Extreme axial tilt near 98 degrees": .sidewaysSpin,
                "A globe standing upright": .uprightSpin,
                "An almost upright axis": .uprightSpin,
                "An axis nearly perpendicular to the orbital plane": .uprightSpin,
            ],
            "neptune-tritons-backward-orbit-retrograde-orbit": [
                "The opposite way": .oppositeMotion,
                "Its orbit is opposite to Neptune’s spin": .oppositeMotion,
                "Orbital revolution opposite to the planet’s rotation": .oppositeMotion,
                "Exactly the same way": .sameMotion,
            ],
        ]
        var inspected = Set<String>()
        for question in missions.flatMap(\.questions) {
            guard let variants = expected[question.conceptID] else { continue }
            for band in AgeBand.allCases {
                for quiz in [question.content[band], question.reviewContent[band]] {
                    for choice in quiz.choices {
                        guard let scene = variants[choice.text] else { continue }
                        XCTAssertEqual(choice.picture?.scene, scene)
                        inspected.insert("\(question.conceptID):\(choice.text)")
                    }
                }
            }
        }
        XCTAssertEqual(inspected.count, expected.values.reduce(0) { $0 + $1.count })
    }

    func testOceanCoverageAndLifeScopeAreAuthoredAsDifferentProposals() throws {
        let earthVideo = try XCTUnwrap(
            VideoLessonCatalog.bundled().first { $0.destinationID == "earth" })
        for band in [AgeBand.ages7To9, .ages10To12] {
            let question = earthVideo.checkpoints[1].question
            for quiz in [question.content[band], question.reviewContent[band]] {
                let proposals = quiz.choices.compactMap(\.picture)
                XCTAssertTrue(proposals.allSatisfy { $0.scene == .waterCoverage })
                XCTAssertEqual(Set(proposals.compactMap(\.fraction)), Set([0.71, 0.10, 0.0]))
            }
        }
        let lifeMission = try XCTUnwrap(
            PlanetMissionCatalog.bundled().first { $0.id == "earth-our-water-world" })
        let life = lifeMission.questions[2].content[.ages4To6]
        XCTAssertEqual(life.choices.first { $0.text == "Earth" }?.picture?.scene, .livingEarth)
        XCTAssertEqual(
            life.choices.first { $0.text == "Every planet" }?.picture?.scene, .livingWorlds)
        let europa = QuizRoundCatalog.quizzes(destinationID: "europa", ageBand: .ages7To9)
        XCTAssertEqual(
            europa[2].choices.first { $0.text == "A deep salty ocean" }?.picture?.scene,
            .subsurfaceOcean)
    }

    func testColorProposalsKeepTheirToneAcrossDestinationsAndAnswerPositions() throws {
        let expected: [String: QuizPicture.Tone] = [
            "White light, often pictured gold or orange": .gold,
            "Cream and golden clouds": .cream,
            "Blue oceans and white clouds": .blueWhite,
            "Gray rock with dark lava plains": .gray,
            "Cream, orange and brown cloud bands": .gold,
            "Pale gold clouds and bright icy rings": .gold,
            "Pale blue-green": .blueGreen,
            "Blue with bright white clouds": .blueWhite,
            "Tan, white and rusty red": .rust,
            "Dark gray with brilliant white spots": .gray,
        ]
        let destinations = [
            "sun", "venus", "earth", "moon", "jupiter", "saturn", "uranus", "neptune",
            "pluto", "ceres",
        ]
        for destination in destinations {
            for band in AgeBand.allCases {
                let colors = QuizRoundCatalog.quizzes(destinationID: destination, ageBand: band)[1]
                for choice in colors.choices {
                    let tone = try XCTUnwrap(expected[choice.text], choice.text)
                    XCTAssertEqual(choice.picture?.tone, tone)
                }
            }
        }
    }

    func testGeneratedFeaturesAndSpecialOrbitCentersHaveExplicitVariants() throws {
        let expected: [String: QuizPicture.Scene] = [
            "Magnetic loops and solar prominences": .solarLoops,
            "A heart-shaped nitrogen-ice plain": .heartPlain,
            "Bright salt deposits in Occator Crater": .saltSpots,
            "It keeps nearly the same face toward Earth": .synchronousMoon,
            "It rotates almost completely on its side": .sidewaysSpin,
            "A ≈25-day equator spin; a ≈230-million-year galactic orbit": .galacticOrbit,
            "A 243-day backward spin; a 225-day year": .retrogradeSpinOrbit,
            "A 27.3-day spin and 27.3-day orbit": .synchronousMoon,
        ]
        var found = Set<String>()
        for destination in ["sun", "venus", "moon", "uranus", "pluto", "ceres"] {
            let choices = QuizRoundCatalog.quizzes(destinationID: destination, ageBand: .ages7To9)
                .flatMap(\.choices)
            for choice in choices {
                if let scene = expected[choice.text] {
                    XCTAssertEqual(choice.picture?.scene, scene)
                    found.insert(choice.text)
                }
            }
        }
        XCTAssertEqual(found, Set(expected.keys))
    }

    func testQualitativeProposalsHaveDifferentRenderRelevantMetadata() throws {
        var quizzes: [QuizContent] = []
        for lesson in try LessonCatalog.bundled() {
            for band in AgeBand.allCases {
                quizzes.append(lesson.content[band].quiz)
                quizzes += QuizRoundCatalog.quizzes(destinationID: lesson.id, ageBand: band)
            }
        }
        for mission in try PlanetMissionCatalog.bundled() {
            for question in mission.questions {
                for band in AgeBand.allCases {
                    quizzes += [question.content[band], question.reviewContent[band]]
                }
            }
        }
        for video in try VideoLessonCatalog.bundled() {
            for checkpoint in video.checkpoints {
                for band in AgeBand.allCases {
                    quizzes += [
                        checkpoint.question.content[band],
                        checkpoint.question.reviewContent[band],
                    ]
                }
            }
        }

        // These share an illustrative diagram with an explicit displayed quantity.
        // Qualitative text alone does not permit an otherwise identical picture.
        let quantityScenes: Set<QuizPicture.Scene> = [
            .distance, .duration, .craterWidth, .canyonLength, .volcanoWidth, .flybyDistance,
        ]
        for quiz in quizzes {
            var grouped: [String: [QuizPicture]] = [:]
            for choice in quiz.choices {
                let picture = try XCTUnwrap(choice.picture, choice.text)
                let signature = renderedSignature(picture)
                grouped[signature, default: []].append(picture)
            }
            for pictures in grouped.values where pictures.count > 1 {
                XCTAssertTrue(
                    quantityScenes.contains(pictures[0].scene),
                    "Qualitative proposals share a drawing: \(quiz.prompt)")
                XCTAssertEqual(Set(pictures.map(\.label)).count, pictures.count)
                for picture in pictures {
                    XCTAssertNotNil(
                        picture.label.range(of: #"[0-9]"#, options: .regularExpression),
                        "A shared numeric diagram needs an explicit quantity: \(picture.label)")
                    XCTAssertNotNil(
                        picture.label.range(
                            of:
                                #"\b(AU|min|minutes?|hr|hours?|seconds?|kilometres|days?|years?)\b"#,
                            options: .regularExpression),
                        "A shared numeric diagram needs its unit: \(picture.label)")
                }
            }
        }
        XCTAssertEqual(quizzes.count, 873)
    }

    func testReviewedLiquidsLightingAndClockProposalsUseTheirAuthoredVariants() throws {
        let expected: [String: [String: QuizPicture.Scene]] = [
            "saturn-two-moon-mysteries-titan-lakes": [
                "Methane and ethane": .hydrocarbonLake,
                "Liquid methane and ethane": .hydrocarbonLake,
                "Surface hydrocarbon liquids rather than liquid water": .hydrocarbonLake,
                "Warm water like home": .pond,
                "Warm liquid water like Earth’s": .pond,
                "Earth-like warm surface water oceans": .ocean,
            ],
            "earth-season-tracker-sun-angle": [
                "Light aimed straight at the patch": .directSunlight,
                "The more direct beam": .directSunlight,
                "A beam concentrated over a smaller area": .directSunlight,
                "Light spread far sideways": .slantedSunlight,
                "The more slanting beam": .slantedSunlight,
                "A beam spread over a larger area": .slantedSunlight,
            ],
            "uranus-sideways-seasons-polar-light": [
                "The other can be dark": .polarIllumination,
                "One pole is lit while the other is dark": .polarIllumination,
                "Prolonged illumination at one pole and darkness at the other": .polarIllumination,
                "The Sun switches off for all planets": .darkSun,
                "A cessation of the Sun’s energy production": .darkSun,
            ],
            "venus-backward-spinner-solar-clock": [
                "Yes, they can differ": .unequalClocks,
                "No, clocks must match": .equalClocks,
            ],
        ]
        var found: [String: Set<String>] = [:]
        var hydrocarbonInstances = 0
        for mission in try PlanetMissionCatalog.bundled() {
            for question in mission.questions {
                guard let proposals = expected[question.conceptID] else { continue }
                for band in AgeBand.allCases {
                    for quiz in [question.content[band], question.reviewContent[band]] {
                        for choice in quiz.choices {
                            guard let scene = proposals[choice.text] else { continue }
                            XCTAssertEqual(choice.picture?.scene, scene, choice.text)
                            found[question.conceptID, default: []].insert(choice.text)
                            if scene == .hydrocarbonLake { hydrocarbonInstances += 1 }
                        }
                    }
                }
            }
        }
        for (concept, proposals) in expected {
            XCTAssertEqual(found[concept], Set(proposals.keys), concept)
        }
        XCTAssertEqual(hydrocarbonInstances, 6)
    }

    func testOrbitShadowOceanAndHoopDrawingsMatchAuthoredScientificMeanings() throws {
        // Explicit physical meanings: orbital centers, illuminated versus unlit surfaces,
        // water states/flow geometry, and connected versus independently moving rings.
        let expected: [String: [String: QuizPicture.Scene]] = [
            "mercury-crater-detective-rays": [
                "Water pours out": .craterWaterFlow,
                "Water from a hidden lake": .hiddenLakeFlow,
                "A permanent liquid-water river": .riverFlow,
            ],
            "mercury-crater-detective-caloris": [
                "A deep blue ocean": .oceanBasin,
                "A basin filled by an Earth-like ocean": .oceanBasin,
            ],
            "mercury-heat-and-shadow-air": [
                "A global warm ocean": .oceanCirculation,
                "Ocean circulation carrying warmth everywhere": .oceanCirculation,
            ],
            "mercury-heat-and-shadow-shadow-ice": [
                "A dark polar crater": .shadow,
                "A permanently shadowed polar crater": .shadow,
                "A cold trap with no direct solar illumination": .shadow,
            ],
            "mercury-speedy-year-orbit": [
                "One trip around the Sun": .orbit,
                "One full orbit around the Sun": .orbit,
            ],
            "mercury-speedy-year-rotation": [
                "Travel around the Sun": .orbit,
                "Travel once around the Sun": .orbit,
                "The orbital period": .orbit,
            ],
            "venus-radar-explorer-volcanoes": [
                "Earth-like blue oceans": .ocean
            ],
            "venus-backward-spinner-rotation-orbit": [
                "One Sun trip": .orbit,
                "One full orbit": .orbit,
                "The orbital period": .orbit,
            ],
            "earth-our-water-world-oceans": [
                "Oceans": .ocean,
                "Liquid-water oceans": .ocean,
                "A global liquid-water ocean": .ocean,
            ],
            "earth-season-tracker-tilt": [
                "The Sun switching off": .darkSun,
                "The Sun switching off each winter": .darkSun,
                "The Sun ceasing emission in winter": .darkSun,
            ],
            "earth-season-tracker-sun-angle": [
                "A beam with no light at all": .noSunlight,
                "No incoming radiation": .noSunlight,
            ],
            "mars-ancient-water-detective-valleys": [
                "Water long ago": .ancientRiver,
                "Liquid water flowed there in the past": .ancientRiver,
                "Past surface flow shaped connected channels": .ancientRiver,
            ],
            "mars-ancient-water-detective-deltas": [
                "A river leaving sand and mud": .riverDelta,
                "A river depositing sediment near a lake": .riverDelta,
                "Sediment deposited as flow enters quieter water": .riverDelta,
            ],
            "mars-landforms-and-seasons-volcano": [
                "A wave frozen into rock": .rockWave,
                "A single liquid-ocean wave": .liquidWave,
            ],
            "mars-landforms-and-seasons-canyon": [
                "A tiny pond": .pond,
                "A small shallow pond": .pond,
                "A pond with no crustal deformation": .pond,
            ],
            "saturn-ring-builder-particles": [
                "One solid hoop": .solidRing,
                "One solid metal hoop": .solidRing,
                "A rigid connected annulus": .solidRing,
            ],
            "saturn-ring-builder-orbits": [
                "Saturn": .ringParticleOrbits,
                "Our spaceship only": .spaceshipOrbit,
                "They are glued into one wheel": .rigidRingRotation,
                "They follow their own orbits": .ringParticleOrbits,
                "Independent orbits with distance-dependent speeds": .ringParticleOrbits,
                "Rigid-body rotation of a single solid structure": .rigidRingRotation,
            ],
            "saturn-two-moon-mysteries-titan-lakes": [
                "Warm water like home": .pond,
                "Warm liquid water like Earth’s": .pond,
                "Earth-like warm surface water oceans": .ocean,
            ],
            "neptune-the-distant-sun-distance": [
                "Earth": .earthWorld
            ],
            "neptune-the-distant-sun-sunlight": [
                "Neptune turns light completely off": .stoppedLight,
                "The planet switches the speed of light to zero": .stoppedLight,
            ],
            "neptune-tritons-backward-orbit-capture": [
                "It may have been captured": .capturedMoon,
                "Its orbit suggests an ancient capture": .capturedMoon,
                "A hypothesis supported by orbital evidence": .capturedMoon,
            ],
            "neptune-tritons-backward-orbit-icy-jets": [
                "Earth-like ocean beaches": .waterBeach,
                "The moon must have Earth-like surface oceans": .ocean,
            ],
            "mercury-video-concept-1": [
                "A ball of water": .waterSphere,
                "A planet covered by an ocean": .waterSphere,
                "A global liquid-water ocean": .waterSphere,
            ],
            "mercury-video-concept-2": [
                "In cold shadows": .shadow,
                "Deep craters remain in shadow": .shadow,
                "Permanent shade limits solar heating": .shadow,
            ],
            "earth-video-concept-1": [
                "The Sun turns off": .darkSun,
                "The Sun switches off every night": .darkSun,
                "The Sun stops producing light at night": .darkSun,
            ],
            "earth-video-concept-2": [
                "Ocean": .ocean
            ],
            "mars-video-concept-1": [
                "A red liquid ocean": .redLiquidOcean,
                "A global red-water ocean": .redLiquidOcean,
            ],
            "mars-video-concept-2": [
                "A tiny lake": .pond,
                "A tiny pond": .pond,
                "A small liquid-water lake": .pond,
            ],
            "saturn-video-concept-2": [
                "One solid hoop": .solidRing,
                "One solid sheet of metal": .solidRing,
                "A single rigid metal hoop": .solidRing,
            ],
            "neptune-video-concept-1": [
                "Earth": .earthWorld
            ],
        ]
        var questions: [LearningQuestion] = []
        for mission in try PlanetMissionCatalog.bundled() { questions += mission.questions }
        for video in try VideoLessonCatalog.bundled() {
            questions += video.checkpoints.map(\.question)
        }
        var found: [String: Set<String>] = [:]
        var choiceInstances = 0
        for question in questions {
            guard let proposals = expected[question.conceptID] else { continue }
            for band in AgeBand.allCases {
                for quiz in [question.content[band], question.reviewContent[band]] {
                    for choice in quiz.choices {
                        guard let scene = proposals[choice.text] else { continue }
                        XCTAssertEqual(choice.picture?.scene, scene, choice.text)
                        found[question.conceptID, default: []].insert(choice.text)
                        choiceInstances += 1
                    }
                }
            }
        }
        for (concept, proposals) in expected {
            XCTAssertEqual(found[concept], Set(proposals.keys), concept)
        }
        XCTAssertEqual(found.values.reduce(0) { $0 + $1.count }, 77)
        XCTAssertEqual(choiceInstances, 158)
    }

    private func renderedSignature(_ picture: QuizPicture) -> String {
        // Only metadata consumed by the drawing counts. Detail and unused tone
        // cannot disguise two visually identical qualitative proposals.
        let tone: String
        switch picture.scene {
        case .rockyWorld, .moon, .gasWorld, .icyWorld, .dwarfWorld, .rust, .clouds, .forest,
            .rings, .solidRing, .sidewaysSpin, .uprightSpin, .tiltedSpin, .stillWorld, .storm:
            tone = picture.tone?.rawValue ?? ""
        case .ocean:
            tone = picture.tone == .blueWhite ? "blueWhite" : ""
        default:
            tone = ""
        }
        let fraction =
            picture.scene == .waterCoverage ? picture.fraction.map { String($0) } ?? "" : ""
        let ratio = picture.scene == .sizeComparison ? picture.label : ""
        return "\(picture.scene.rawValue)|\(fraction)|\(tone)|\(ratio)"
    }

    private func minutes(in text: String) -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*(hours?|hrs?|minutes?|min|seconds?|sec)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        guard !matches.isEmpty else { return nil }
        return matches.reduce(0) { total, match in
            guard let numberRange = Range(match.range(at: 1), in: text),
                let unitRange = Range(match.range(at: 2), in: text),
                let value = Double(text[numberRange])
            else { return total }
            let unit = text[unitRange].lowercased()
            let multiplier = unit.hasPrefix("h") ? 60.0 : unit.hasPrefix("s") ? 1.0 / 60 : 1.0
            return total + value * multiplier
        }
    }
}
