import Foundation
import Observation

/// A guided playground's logical state. Cosmetic animation and physics never complete goals.
@MainActor
@Observable
public final class ExplorationSession {
    public static let maximumImpactCount = 12
    public static let maximumClipSeconds: Double = 60

    public let adventure: ExplorationAdventure
    public private(set) var progress: GameProgress
    public private(set) var cursor: ExplorationCursor
    public private(set) var overlay: ExplorationOverlay?
    public private(set) var feedback: String
    public private(set) var isPaused: Bool

    public var ageBand: AgeBand { cursor.ageBand }
    public var currentGoal: ExplorationGoal? {
        adventure.goals.first { !cursor.completedGoalIDs.contains($0.id) }
    }
    public var selectedTarget: ExplorationTarget? {
        availableTargets.first { $0.id == cursor.selectedTargetID }
    }
    public var contextualVerb: String { selectedTarget?.verb ?? "Explore" }
    public var availableTargets: [ExplorationTarget] {
        adventure.targets.filter { $0.requiredObservations.isSubset(of: cursor.observations) }
    }

    public init(adventure: ExplorationAdventure, progress: GameProgress) {
        self.adventure = adventure
        var updated = progress
        updated.schemaVersion = GameProgress.currentSchemaVersion
        // Only this planet's retired learning route is replaced by its new arrival.
        if updated.activeRun?.destinationID == adventure.destinationID {
            updated.activeRun = nil
        }
        let restored = updated.explorationCursor.flatMap {
            Self.isValid($0, for: adventure, progress: updated) ? $0 : nil
        }
        let selected = Self.initialTarget(in: adventure)?.id ?? ""
        let starting =
            restored
            ?? ExplorationCursor(
                adventureID: adventure.id, revision: adventure.revision,
                ageBand: progress.selectedAgeBand, selectedTargetID: selected
            )
        self.cursor = starting
        updated.explorationCursor = starting
        self.progress = updated
        self.feedback =
            restored != nil && starting.phase != .arriving
            ? Self.resumeFeedback(for: starting, in: adventure)
            : adventure.welcome.text(for: starting.ageBand)
        let restoredSuspended = restored != nil && starting.phase != .arriving
        self.overlay = restoredSuspended ? .pause : nil
        self.isPaused = restoredSuspended
    }

    public func send(_ command: ExplorationCommand, now: Date = Date()) {
        switch command {
        case .resume, .closeOverlay:
            overlay = nil
            isPaused = false
            return
        case .pause:
            guard !isPaused else { return }
            overlay = .pause
            isPaused = true
            return
        default:
            guard !isPaused else { return }
        }

        switch command {
        case .begin:
            guard cursor.phase == .arriving else { return }
            cursor.phase = .playing
            feedback = currentGoal?.invitation.text(for: ageBand) ?? feedback
        case .selectTarget(let id):
            guard cursor.phase == .playing, availableTargets.contains(where: { $0.id == id })
            else { return }
            cursor.selectedTargetID = id
        case .moveTarget(let direction):
            guard cursor.phase == .playing else { return }
            moveTarget(direction)
        case .activateTarget:
            guard cursor.phase == .playing, let target = selectedTarget else { return }
            guard apply(target.interaction, at: target) else { return }
            cursor.avatarAnchorID = target.id
            feedback = target.response.text(for: ageBand)
            completeEligibleGoals(now: now)
        case .adjustModel(let id, let amount):
            guard cursor.phase == .playing, amount != 0,
                let target = availableTargets.first(where: {
                    if case .adjust(let model, _) = $0.interaction { return model == id }
                    return false
                }),
                case .adjust(_, let observations) = target.interaction,
                adjustModel(id, by: amount, observations: observations)
            else { return }
            cursor.selectedTargetID = target.id
            cursor.avatarAnchorID = target.id
            feedback = target.response.text(for: ageBand)
            completeEligibleGoals(now: now)
        case .requestHelp:
            overlay = .help
            isPaused = true
            feedback = currentGoal?.hint.text(for: ageBand) ?? "Keep exploring your playground."
        case .openJournal:
            overlay = .journal
            isPaused = true
        case .openClip:
            guard adventure.videoLessonID != nil else { return }
            overlay = .clip
            isPaused = true
        case .keepPlaying:
            guard cursor.phase == .celebrating else { return }
            cursor.phase = .playing
            feedback = "Your discovery is saved. Keep playing and see what changes!"
        case .resetToy:
            guard cursor.phase == .playing else { return }
            cursor.carriedItemID = nil
            cursor.placements = [:]
            cursor.modelSettings = [:]
            let target = availableTargets.first?.id ?? ""
            cursor.selectedTargetID = target
            cursor.avatarAnchorID = target
            feedback = "The toys are ready again. Your discoveries are saved."
        case .cancelManipulation:
            guard cursor.phase == .playing, cursor.carriedItemID != nil else { return }
            cursor.carriedItemID = nil
            feedback = "Your kit is back at its starting place."
        case .pause, .resume, .closeOverlay:
            return
        }
        persist()
    }

    /// Accept media timing only while its overlay owns playback, ignoring stale callbacks.
    public func updateClipSeconds(_ seconds: Double) {
        updateClipProgress(seconds: seconds, checkpointIDs: cursor.clipCheckpointIDs)
    }

    public func updateClipProgress(seconds: Double, checkpointIDs: Set<String>) {
        guard overlay == .clip, seconds.isFinite,
            checkpointIDs.isSubset(of: ["segment-0", "segment-1"])
        else { return }
        let bounded = min(max(seconds, 0), Self.maximumClipSeconds)
        let checkpoints = cursor.clipCheckpointIDs.union(checkpointIDs)
        guard cursor.clipSeconds != bounded || cursor.clipCheckpointIDs != checkpoints else {
            return
        }
        cursor.clipSeconds = bounded
        cursor.clipCheckpointIDs = checkpoints
        persist()
    }

    private func persist() {
        progress.explorationCursor = cursor
    }

    private func apply(_ interaction: ExplorationInteraction, at target: ExplorationTarget) -> Bool
    {
        switch interaction {
        case .observe(let observation):
            cursor.observations.insert(observation)
        case .impact(let size):
            guard size == 0 || size == 1 else { return false }
            let observation = size == 0 ? "impact.small" : "impact.large"
            cursor.observations.insert(observation)
            let countID = "\(observation).count"
            cursor.modelSettings[countID] = min(
                (cursor.modelSettings[countID] ?? 0) + 1, Self.maximumImpactCount)
        case .pickUp(let item):
            guard cursor.carriedItemID == nil || cursor.carriedItemID == item else {
                feedback = "Place the kit you are carrying, or put it back first."
                return false
            }
            cursor.placements[item] = nil
            cursor.carriedItemID = item
        case .place(let item, let observation):
            guard cursor.carriedItemID == item else {
                feedback = "Pick up this site's kit before placing it here."
                return false
            }
            cursor.placements[item] = target.id
            cursor.carriedItemID = nil
            cursor.observations.insert(observation)
        case .adjust(let model, let observations):
            return adjustModel(model, by: 1, observations: observations)
        }
        return true
    }

    private func adjustModel(_ id: String, by amount: Int, observations: [String]) -> Bool {
        guard !observations.isEmpty else { return false }
        let count = observations.count
        let offset = amount % count
        let setting = ((cursor.modelSettings[id] ?? 0) + offset + count) % count
        cursor.modelSettings[id] = setting
        cursor.observations.insert(observations[setting])
        return true
    }

    private func completeEligibleGoals(now: Date) {
        var completed = false
        for goal in adventure.goals where !cursor.completedGoalIDs.contains(goal.id) {
            guard goal.requiredObservations.isSubset(of: cursor.observations) else { break }
            cursor.completedGoalIDs.insert(goal.id)
            feedback = goal.explanation.text(for: ageBand)
            completed = true
        }
        guard completed, !adventure.goals.isEmpty,
            cursor.completedGoalIDs.count == adventure.goals.count
        else { return }
        cursor.phase = .celebrating
        // Commit the postcard, destination stamp, and terminal cursor as one observable snapshot.
        var updated = progress
        if updated.explorationCompletions[adventure.id] == nil {
            updated.explorationCompletions[adventure.id] = ExplorationCompletion(
                completedAt: now, ageBand: ageBand, postcard: cursor)
        }
        var destination = updated.destinations[adventure.destinationID] ?? DestinationProgress()
        destination.isScanned = true
        destination.isQuizCompleted = true
        destination.bestRoundStars = max(destination.bestRoundStars, 3)
        updated.destinations[adventure.destinationID] = destination
        updated.explorationCursor = cursor
        progress = updated
    }

    private func moveTarget(_ direction: ExplorationDirection) {
        guard let origin = selectedTarget else { return }
        let candidates = availableTargets.filter { target in
            let dx = target.position.x - origin.position.x
            let dy = target.position.y - origin.position.y
            switch direction {
            case .up: return dy < -0.000_001
            case .down: return dy > 0.000_001
            case .left: return dx < -0.000_001
            case .right: return dx > 0.000_001
            }
        }
        let nearest = candidates.min { lhs, rhs in
            let left =
                pow(lhs.position.x - origin.position.x, 2)
                + pow(lhs.position.y - origin.position.y, 2)
            let right =
                pow(rhs.position.x - origin.position.x, 2)
                + pow(rhs.position.y - origin.position.y, 2)
            return left == right ? lhs.id < rhs.id : left < right
        }
        if let nearest { cursor.selectedTargetID = nearest.id }
    }

    private static func initialTarget(in adventure: ExplorationAdventure) -> ExplorationTarget? {
        let available = adventure.targets.filter { $0.requiredObservations.isEmpty }
        return available.first { $0.id == adventure.goals.first?.suggestedTargetID }
            ?? available.first
    }

    private static func resumeFeedback(
        for cursor: ExplorationCursor, in adventure: ExplorationAdventure
    ) -> String {
        if let item = cursor.carriedItemID,
            let target = adventure.targets.first(where: {
                if case .pickUp(let candidate) = $0.interaction { return candidate == item }
                return false
            })
        {
            return "You are carrying the \(target.name.lowercased()). Choose where to place it."
        }
        return adventure.goals.first { !cursor.completedGoalIDs.contains($0.id) }?
            .invitation.text(for: cursor.ageBand)
            ?? "Your discovery is saved. Keep playing and see what changes!"
    }

    private static func isValid(
        _ cursor: ExplorationCursor, for adventure: ExplorationAdventure, progress: GameProgress
    ) -> Bool {
        guard cursor.adventureID == adventure.id, cursor.revision == adventure.revision,
            cursor.clipSeconds.isFinite, (0...maximumClipSeconds).contains(cursor.clipSeconds),
            cursor.clipCheckpointIDs.isSubset(of: ["segment-0", "segment-1"])
        else { return false }
        let targetIDs = Set(adventure.targets.map(\.id))
        guard targetIDs.contains(cursor.selectedTargetID), targetIDs.contains(cursor.avatarAnchorID)
        else { return false }
        var observationIDs = Set<String>()
        var itemIDs = Set<String>()
        var models: [String: Int] = [:]
        for target in adventure.targets {
            switch target.interaction {
            case .observe(let observation), .place(_, let observation):
                observationIDs.insert(observation)
            case .impact(let size):
                let observation = size == 0 ? "impact.small" : "impact.large"
                observationIDs.insert(observation)
                models["\(observation).count"] = maximumImpactCount + 1
            case .pickUp(let item):
                itemIDs.insert(item)
            case .adjust(let model, let observations):
                observationIDs.formUnion(observations)
                models[model] = observations.count
            }
        }
        guard cursor.observations.isSubset(of: observationIDs),
            cursor.modelSettings.allSatisfy({ id, value in
                value >= 0 && value < (models[id] ?? 0)
            }),
            cursor.carriedItemID.map({ itemIDs.contains($0) && cursor.placements[$0] == nil })
                ?? true,
            cursor.placements.allSatisfy({ item, targetID in
                guard itemIDs.contains(item),
                    let target = adventure.targets.first(where: { $0.id == targetID }),
                    case .place(let expectedItem, let observation) = target.interaction
                else { return false }
                return item == expectedItem && cursor.observations.contains(observation)
                    && target.requiredObservations.isSubset(of: cursor.observations)
            }),
            adventure.targets.first(where: { $0.id == cursor.selectedTargetID })?
                .requiredObservations.isSubset(of: cursor.observations) == true
        else { return false }
        let goalIDs = Set(adventure.goals.map(\.id))
        guard cursor.completedGoalIDs.isSubset(of: goalIDs) else { return false }
        var foundIncomplete = false
        for goal in adventure.goals {
            if cursor.completedGoalIDs.contains(goal.id) {
                guard !foundIncomplete, goal.requiredObservations.isSubset(of: cursor.observations)
                else { return false }
            } else {
                foundIncomplete = true
            }
        }
        if !adventure.goals.isEmpty, !foundIncomplete {
            guard progress.explorationCompletions[adventure.id] != nil,
                cursor.phase != .arriving
            else { return false }
        } else if cursor.phase == .celebrating {
            return false
        }
        return cursor.phase != .arriving
            || (cursor.observations.isEmpty && cursor.completedGoalIDs.isEmpty
                && cursor.carriedItemID == nil && cursor.placements.isEmpty
                && cursor.modelSettings.isEmpty)
    }
}
