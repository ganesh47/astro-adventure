import Foundation

public struct ExplorationText: Codable, Equatable, Sendable {
    public let young: String
    public let middle: String
    public let older: String

    public init(_ young: String, _ middle: String? = nil, _ older: String? = nil) {
        self.young = young
        self.middle = middle ?? young
        self.older = older ?? middle ?? young
    }

    public func text(for age: AgeBand) -> String {
        switch age {
        case .ages4To6: young
        case .ages7To9: middle
        case .ages10To12: older
        }
    }
}

public struct ExplorationPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public enum ExplorationDirection: String, Codable, Sendable { case up, down, left, right }

/// Logical effects are deterministic. Rendering and cosmetic physics never award discoveries.
public enum ExplorationInteraction: Codable, Equatable, Sendable {
    case observe(String)
    case impact(size: Int)
    case pickUp(String)
    case place(item: String, observation: String)
    case adjust(model: String, observations: [String])
}

public struct ExplorationTarget: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public let verb: String
    public let position: ExplorationPoint
    public let interaction: ExplorationInteraction
    public let requiredObservations: Set<String>
    public let response: ExplorationText

    public init(
        id: String, name: String, symbol: String, verb: String,
        position: ExplorationPoint, interaction: ExplorationInteraction,
        requiredObservations: Set<String> = [], response: ExplorationText
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.verb = verb
        self.position = position
        self.interaction = interaction
        self.requiredObservations = requiredObservations
        self.response = response
    }
}

public struct ExplorationGoal: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let invitation: ExplorationText
    public let hint: ExplorationText
    public let requiredObservations: Set<String>
    public let suggestedTargetID: String
    public let conceptID: String
    public let explanation: ExplorationText
    public let sourceURL: String

    public init(
        id: String, title: String, invitation: ExplorationText, hint: ExplorationText,
        requiredObservations: Set<String>, suggestedTargetID: String, conceptID: String,
        explanation: ExplorationText, sourceURL: String
    ) {
        self.id = id
        self.title = title
        self.invitation = invitation
        self.hint = hint
        self.requiredObservations = requiredObservations
        self.suggestedTargetID = suggestedTargetID
        self.conceptID = conceptID
        self.explanation = explanation
        self.sourceURL = sourceURL
    }
}

public struct ExplorationAdventure: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let destinationID: String
    public let title: String
    public let revision: Int
    public let welcome: ExplorationText
    public let goals: [ExplorationGoal]
    public let targets: [ExplorationTarget]
    public let postcardTitle: String
    public let videoLessonID: String?

    public init(
        id: String, destinationID: String, title: String, revision: Int = 1,
        welcome: ExplorationText, goals: [ExplorationGoal], targets: [ExplorationTarget],
        postcardTitle: String, videoLessonID: String? = nil
    ) {
        self.id = id
        self.destinationID = destinationID
        self.title = title
        self.revision = revision
        self.welcome = welcome
        self.goals = goals
        self.targets = targets
        self.postcardTitle = postcardTitle
        self.videoLessonID = videoLessonID
    }
}

public enum ExplorationPhase: String, Codable, Sendable { case arriving, playing, celebrating }
public enum ExplorationOverlay: String, Sendable { case help, journal, clip, pause }

public struct ExplorationCursor: Codable, Equatable, Sendable {
    public var adventureID: String
    public var revision: Int
    public var ageBand: AgeBand
    public var phase: ExplorationPhase = .arriving
    public var selectedTargetID: String
    public var avatarAnchorID: String
    public var carriedItemID: String?
    public var observations: Set<String> = []
    public var completedGoalIDs: Set<String> = []
    public var placements: [String: String] = [:]
    public var modelSettings: [String: Int] = [:]
    public var clipSeconds: Double = 0
    public var clipCheckpointIDs: Set<String> = []

    public init(adventureID: String, revision: Int, ageBand: AgeBand, selectedTargetID: String) {
        self.adventureID = adventureID
        self.revision = revision
        self.ageBand = ageBand
        self.selectedTargetID = selectedTargetID
        self.avatarAnchorID = selectedTargetID
    }
}

public struct ExplorationCompletion: Codable, Equatable, Sendable {
    public let completedAt: Date
    public let ageBand: AgeBand
    public let postcard: ExplorationCursor
    public init(completedAt: Date, ageBand: AgeBand, postcard: ExplorationCursor) {
        self.completedAt = completedAt
        self.ageBand = ageBand
        self.postcard = postcard
    }
}

public enum ExplorationCommand: Equatable, Sendable {
    case begin
    case selectTarget(String)
    case moveTarget(ExplorationDirection)
    case activateTarget
    case adjustModel(String, by: Int)
    case requestHelp
    case openJournal
    case openClip
    case closeOverlay
    case pause
    case resume
    case keepPlaying
    case resetToy
    case cancelManipulation
}
