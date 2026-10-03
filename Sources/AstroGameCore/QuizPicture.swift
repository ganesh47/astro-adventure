import Foundation

/// Authored meaning for an offline schematic. This describes an answer proposal,
/// including a distractor, and never contains correctness or reward information.
public struct QuizPicture: Codable, Equatable, Sendable {
    public enum Scene: String, Codable, CaseIterable, Sendable {
        case star, rockyWorld, moon, gasWorld, icyWorld, dwarfWorld
        case clouds, ice, ocean, forest, desert, crater, canyon, volcano, blocks
        case aurora, rings, spacecraft, telescope, gravity, cube, sunlight, reflection, rust
        case distance, duration, spinOrbit, thinAtmosphere, storm, magnet, solarPanels
        case robot, rocket, orbit, temperature, shadow, signal, computer, laboratory
        case paint, mountain, spacesuit, antenna, rain, sound, vehicle, city, measurement
        case tools, solidRing, hexagon, triangle, line, nameTag, clothing, rockLayers, lamp
        case stillWorld, seasonalIce, steadyIce, escapingIce, sizeComparison
        case plume, rope, singleImage
        case wingedSuit, crewSuit, wingedSatellite, sailingSatellite, emptyTank, ironCave
        case spin, retrogradeSpin, sidewaysSpin, uprightSpin, moonOrbit, galacticOrbit
        case oppositeSpins, sameSpins, livingEarth, livingWorlds, waterCoverage
        case subsurfaceOcean, innerOrbit
        case tiltedSpin, oppositeMotion, sameMotion
        case solarLoops, heartPlain, saltSpots, synchronousMoon
        case retrogradeSpinOrbit
        case hollows, craterWidth, canyonLength, volcanoWidth, flybyDistance
        case planetDiameter, spacecraftSize, classroomDistance, earthWorldDistance
        case changingOrbitDistance, movingSun, movingStars
    }

    public enum Tone: String, Codable, Sendable {
        case cream, gold, blueGreen, blueWhite, gray, rust, green
    }

    public let scene: Scene
    public let label: String
    public let detail: String?
    public let fraction: Double?
    public let tone: Tone?

    public init(
        scene: Scene, label: String, detail: String? = nil, fraction: Double? = nil,
        tone: Tone? = nil
    ) {
        self.scene = scene
        self.label = label
        self.detail = detail
        self.fraction = fraction
        self.tone = tone
    }
}
