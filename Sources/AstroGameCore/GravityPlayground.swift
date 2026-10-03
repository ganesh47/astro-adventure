import Foundation

/// Mean surface gravity is a local approximation; rotation and air resistance are excluded.
public enum GravityWorld: String, CaseIterable, Codable, Identifiable, Sendable {
    case earth, moon, mars

    public var id: String { rawValue }

    public var kindName: String { self == .moon ? "moon" : "planet" }

    public var displayName: String {
        switch self {
        case .earth: "Earth"
        case .moon: "Moon"
        case .mars: "Mars"
        }
    }

    /// NASA's detailed fact sheets, in meters per second squared.
    public var gravityMetersPerSecondSquared: Double {
        switch self {
        case .earth: 9.82
        case .moon: 1.62
        case .mars: 3.73
        }
    }

    public var weightRelativeToEarth: Double {
        gravityMetersPerSecondSquared / GravityWorld.earth.gravityMetersPerSecondSquared
    }

    /// Sources belong in parent/educator contexts, rather than external child-facing links.
    public var sourceURL: String {
        switch self {
        case .earth: "https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html"
        case .moon: "https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html"
        case .mars: "https://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html"
        }
    }

    public static let gravityDefinitionSourceURL =
        "https://nssdc.gsfc.nasa.gov/planetary/factsheet/fact_notes.html"
}

/// The same launch means equal initial speed and angle, not equal force or power in watts.
public struct GravityLaunch: Equatable, Sendable {
    public static let angleRange: ClosedRange<Double> = 30...60
    public static let speedRange: ClosedRange<Double> = 4...8
    public static let massRange: ClosedRange<Double> = 0.25...10

    public let angleDegrees: Double
    public let speedMetersPerSecond: Double
    public let massKilograms: Double

    public init(
        angleDegrees: Double = 45, speedMetersPerSecond: Double = 6,
        massKilograms: Double = 1
    ) {
        self.angleDegrees = Self.normalized(angleDegrees, range: Self.angleRange, fallback: 45)
        self.speedMetersPerSecond = Self.normalized(
            speedMetersPerSecond, range: Self.speedRange, fallback: 6)
        self.massKilograms = Self.normalized(massKilograms, range: Self.massRange, fallback: 1)
    }

    private static func normalized(
        _ value: Double, range: ClosedRange<Double>, fallback: Double
    ) -> Double {
        value.isFinite ? min(max(value, range.lowerBound), range.upperBound) : fallback
    }
}

/// Simulation coordinates, independent of screen size. The ground is height zero.
public struct GravityPosition: Equatable, Sendable {
    public let xMeters: Double
    public let heightMeters: Double

    public init(xMeters: Double, heightMeters: Double) {
        self.xMeters = xMeters.isFinite ? max(0, xMeters) : 0
        self.heightMeters = heightMeters.isFinite ? max(0, heightMeters) : 0
    }
}

/// A bounded, flat-ground educational experiment, with no drag, wind or thrust.
/// Mass remains constant, and launch and landing have the same elevation.
public struct GravityTrajectory: Equatable, Sendable {
    public let world: GravityWorld
    public let launch: GravityLaunch

    public init(world: GravityWorld, launch: GravityLaunch = GravityLaunch()) {
        self.world = world
        self.launch = launch
    }

    public var initialHorizontalVelocity: Double {
        launch.speedMetersPerSecond * cos(launch.angleDegrees * .pi / 180)
    }

    public var initialVerticalVelocity: Double {
        launch.speedMetersPerSecond * sin(launch.angleDegrees * .pi / 180)
    }

    /// Flight duration in seconds. Playback must use the same time scale across worlds.
    public var flightTime: Double {
        2 * initialVerticalVelocity / world.gravityMetersPerSecondSquared
    }

    /// Horizontal landing distance in meters.
    public var range: Double { initialHorizontalVelocity * flightTime }

    /// Maximum height in meters above the launch/landing elevation.
    public var peakHeight: Double {
        initialVerticalVelocity * initialVerticalVelocity
            / (2 * world.gravityMetersPerSecondSquared)
    }

    /// Weight in newtons, distinct from the launch object's mass in kilograms.
    public var weight: Double { launch.massKilograms * world.gravityMetersPerSecondSquared }

    /// The baseline uses identical launch settings, including mass and initial speed.
    public var earthComparison: GravityTrajectory {
        GravityTrajectory(world: .earth, launch: launch)
    }

    /// Time is clamped to the physical flight; there is no below-ground extrapolation.
    public func position(elapsed: Double) -> GravityPosition {
        let time: Double
        if elapsed.isFinite {
            time = min(max(0, elapsed), flightTime)
        } else {
            time = elapsed > 0 ? flightTime : 0
        }
        if time == flightTime { return GravityPosition(xMeters: range, heightMeters: 0) }
        return GravityPosition(
            xMeters: initialHorizontalVelocity * time,
            heightMeters: initialVerticalVelocity * time
                - 0.5 * world.gravityMetersPerSecondSquared * time * time)
    }

    /// An odd, bounded count includes the exact start, apex and landing.
    public func sampledPositions(sampleCount: Int = 81) -> [GravityPosition] {
        let boundedCount = min(max(3, sampleCount), 201)
        let count = boundedCount.isMultiple(of: 2) ? boundedCount + 1 : boundedCount
        return (0..<count).map { index in
            let time =
                index == count / 2
                ? flightTime / 2 : flightTime * Double(index) / Double(count - 1)
            return position(elapsed: time)
        }
    }
}

public struct GravityDisplayPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// One isotropic meter-to-point scale fits all worlds for the same launch settings.
/// Share this projection between the selected-world path and the Earth ghost.
public struct GravityProjection: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let padding: Double
    public let pointsPerMeter: Double
    public let maximumRangeMeters: Double
    public let maximumHeightMeters: Double

    public init(launch: GravityLaunch, width: Double, height: Double, padding: Double = 16) {
        self.width = width.isFinite ? min(max(1, width), 100_000) : 1
        self.height = height.isFinite ? min(max(1, height), 100_000) : 1
        let requestedPadding = padding.isFinite ? padding : 16
        self.padding = min(max(0, requestedPadding), min(self.width, self.height) / 4)
        let trajectories = GravityWorld.allCases.map {
            GravityTrajectory(world: $0, launch: launch)
        }
        self.maximumRangeMeters = trajectories.map(\.range).max() ?? 1
        self.maximumHeightMeters = trajectories.map(\.peakHeight).max() ?? 1
        self.pointsPerMeter = min(
            (self.width - 2 * self.padding) / self.maximumRangeMeters,
            (self.height - 2 * self.padding) / self.maximumHeightMeters)
    }

    public func project(_ position: GravityPosition) -> GravityDisplayPoint {
        GravityDisplayPoint(
            x: padding + position.xMeters * pointsPerMeter,
            y: height - padding - position.heightMeters * pointsPerMeter)
    }
}

public enum GravityFlightPhase: String, Equatable, Sendable {
    case ready, flying, paused, landed
}

/// A resumable observation snapshot contains no learning score or mastery evidence.
public struct GravityFlightSnapshot: Equatable, Sendable {
    public let trajectory: GravityTrajectory
    public let elapsedSeconds: Double
    public let generation: UInt64

    public init(trajectory: GravityTrajectory, elapsedSeconds: Double, generation: UInt64 = 0) {
        self.trajectory = trajectory
        self.elapsedSeconds =
            elapsedSeconds.isFinite
            ? min(max(0, elapsedSeconds), trajectory.flightTime) : 0
        self.generation = generation
    }
}

/// The caller supplies monotonic seconds, such as process uptime, rather than wall-clock dates.
/// Each callback captures its launch generation; stale callbacks cannot affect a replacement.
public struct GravityFlightClock: Equatable, Sendable {
    public private(set) var trajectory: GravityTrajectory?
    public private(set) var elapsedSeconds: Double = 0
    public private(set) var generation: UInt64 = 0
    public private(set) var phase: GravityFlightPhase = .ready

    private var lastTimestamp: Double?
    private var latestTimestamp: Double?

    public init() {}

    /// Restoration freezes the same position, and invalidates callbacks from the old clock.
    public init(restoring snapshot: GravityFlightSnapshot) {
        trajectory = snapshot.trajectory
        elapsedSeconds = snapshot.elapsedSeconds
        generation = snapshot.generation &+ 1
        phase = elapsedSeconds == snapshot.trajectory.flightTime ? .landed : .paused
    }

    public var position: GravityPosition? { trajectory?.position(elapsed: elapsedSeconds) }

    /// Pause/update before taking a snapshot when the most recent clock tick is not current.
    public var snapshot: GravityFlightSnapshot? {
        guard let trajectory else { return nil }
        return GravityFlightSnapshot(
            trajectory: trajectory, elapsedSeconds: elapsedSeconds, generation: generation)
    }

    /// A duplicate launch never restarts an existing flight, including one that is paused.
    @discardableResult
    public mutating func launch(
        world: GravityWorld, launch: GravityLaunch = GravityLaunch(), at timestamp: Double
    ) -> UInt64? {
        guard phase == .ready else { return nil }
        return start(world: world, launch: launch, at: timestamp)
    }

    /// Replay/replacement is an explicit action; all prior-generation callbacks become stale.
    @discardableResult
    public mutating func relaunch(
        world: GravityWorld, launch: GravityLaunch = GravityLaunch(), at timestamp: Double
    ) -> UInt64? {
        start(world: world, launch: launch, at: timestamp)
    }

    /// Returns true only on the first transition to landed, for one result announcement.
    @discardableResult
    public mutating func advance(to timestamp: Double, generation expectedGeneration: UInt64)
        -> Bool
    {
        guard expectedGeneration == generation, phase == .flying,
            validTimestamp(timestamp), let lastTimestamp, let trajectory
        else { return false }
        elapsedSeconds = min(trajectory.flightTime, elapsedSeconds + (timestamp - lastTimestamp))
        latestTimestamp = timestamp
        if elapsedSeconds == trajectory.flightTime {
            phase = .landed
            self.lastTimestamp = nil
            return true
        }
        self.lastTimestamp = timestamp
        return false
    }

    /// Pausing may finish a flight whose landing already occurred before this event.
    /// Returns true only for that first landing; otherwise a valid event freezes the position.
    @discardableResult
    public mutating func pause(at timestamp: Double, generation expectedGeneration: UInt64) -> Bool
    {
        guard expectedGeneration == generation, phase == .flying, validTimestamp(timestamp)
        else { return false }
        let landed = advance(to: timestamp, generation: expectedGeneration)
        if phase == .flying {
            phase = .paused
            lastTimestamp = nil
        }
        return landed
    }

    /// Time spent paused is excluded. A restored clock accepts a fresh monotonic time origin.
    @discardableResult
    public mutating func resume(at timestamp: Double, generation expectedGeneration: UInt64) -> Bool
    {
        guard expectedGeneration == generation, phase == .paused, validTimestamp(timestamp)
        else { return false }
        lastTimestamp = timestamp
        latestTimestamp = timestamp
        phase = .flying
        return true
    }

    /// Leaving the playground can invalidate callbacks without manufacturing a landing.
    public mutating func reset() {
        generation &+= 1
        trajectory = nil
        elapsedSeconds = 0
        phase = .ready
        lastTimestamp = nil
        latestTimestamp = nil
    }

    private func validTimestamp(_ timestamp: Double) -> Bool {
        timestamp.isFinite && timestamp >= 0 && timestamp >= (latestTimestamp ?? 0)
    }

    private mutating func start(
        world: GravityWorld, launch: GravityLaunch, at timestamp: Double
    ) -> UInt64? {
        guard validTimestamp(timestamp) else { return nil }
        generation &+= 1
        trajectory = GravityTrajectory(world: world, launch: launch)
        elapsedSeconds = 0
        phase = .flying
        lastTimestamp = timestamp
        latestTimestamp = timestamp
        return generation
    }
}
