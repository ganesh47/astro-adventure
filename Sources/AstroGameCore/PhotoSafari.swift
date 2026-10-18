import Foundation
import Observation

/// Reviewed spacecraft and telescope imagery; captions distinguish mosaics and processed views.
public struct SpacePhoto: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let imageName: String
    public let credit: String
    public let sourceURL: String
    public let caption: String

    public init(
        id: String, title: String, imageName: String, credit: String,
        sourceURL: String, caption: String
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.credit = credit
        self.sourceURL = sourceURL
        self.caption = caption
    }
}

public struct PhotoSafariStop: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let clue: ExplorationText
    public let hint: ExplorationText
    public let photos: [SpacePhoto]
    public let discoveryPhotoID: String
    public let fact: ExplorationText

    public init(
        id: String, title: String, clue: ExplorationText, hint: ExplorationText,
        photos: [SpacePhoto], discoveryPhotoID: String, fact: ExplorationText
    ) {
        self.id = id
        self.title = title
        self.clue = clue
        self.hint = hint
        self.photos = photos
        self.discoveryPhotoID = discoveryPhotoID
        self.fact = fact
    }

    public var discoveryPhoto: SpacePhoto? { photos.first { $0.id == discoveryPhotoID } }
}

public struct PhotoSafari: Equatable, Identifiable, Sendable {
    public let id: String
    public let destinationID: String
    public let title: String
    public let stops: [PhotoSafariStop]

    public init(id: String, destinationID: String, title: String, stops: [PhotoSafariStop]) {
        self.id = id
        self.destinationID = destinationID
        self.title = title
        self.stops = stops
    }

    /// Use the existing bounded save cursor and once-only ledger, with new IDs for the new activity.
    /// Selecting the next target acknowledges a reveal, so that boundary also survives relaunch.
    public var adventure: ExplorationAdventure {
        ExplorationAdventure(
            id: id, destinationID: destinationID, title: title,
            welcome: ExplorationText(
                "Look at real space photos. Follow three clues and make a photo collection!"),
            goals: stops.map { stop in
                ExplorationGoal(
                    id: stop.id, title: stop.title, invitation: stop.clue, hint: stop.hint,
                    requiredObservations: ["photo.\(stop.id)"], suggestedTargetID: stop.id,
                    conceptID: "photo.\(stop.id)", explanation: stop.fact,
                    sourceURL: stop.discoveryPhoto?.sourceURL ?? "https://science.nasa.gov/"
                )
            },
            targets: stops.enumerated().map { index, stop in
                ExplorationTarget(
                    id: stop.id, name: stop.title, symbol: "camera.fill", verb: "Discover photo",
                    position: ExplorationPoint(0.25 + Double(index) * 0.2, 0.5),
                    interaction: .observe("photo.\(stop.id)"),
                    requiredObservations: Set(stops.prefix(index).map { "photo.\($0.id)" }),
                    response: stop.fact
                )
            },
            postcardTitle: "My \(destinationID.capitalized) space photos"
        )
    }
}

@MainActor
@Observable
public final class PhotoSafariSession {
    public let safari: PhotoSafari
    private let play: ExplorationSession
    public private(set) var hint: String?
    public private(set) var albumStopID: String?

    public var progress: GameProgress { play.progress }
    public var ageBand: AgeBand { play.ageBand }
    public var isPaused: Bool { play.isPaused }
    public var isArriving: Bool { play.cursor.phase == .arriving }
    public var isCollection: Bool { play.currentGoal == nil && play.cursor.phase == .playing }
    public var collectedCount: Int { play.cursor.completedGoalIDs.count }
    public var currentStop: PhotoSafariStop? {
        safari.stops.first { $0.id == play.currentGoal?.id }
    }
    public var revealedStop: PhotoSafariStop? {
        guard !isCollection else { return nil }
        return safari.stops.first {
            $0.id == play.cursor.selectedTargetID && play.cursor.completedGoalIDs.contains($0.id)
        }
    }
    public var albumStop: PhotoSafariStop? { safari.stops.first { $0.id == albumStopID } }

    public init(safari: PhotoSafari, progress: GameProgress) {
        self.safari = safari
        self.play = ExplorationSession(adventure: safari.adventure, progress: progress)
    }

    public func begin() { play.send(.begin) }
    public func pause() { play.send(.pause) }
    public func resume() { play.send(.resume) }

    public func choosePhoto(_ id: String, now: Date = Date()) {
        guard !isPaused, !isArriving, revealedStop == nil, let stop = currentStop,
            stop.photos.contains(where: { $0.id == id })
        else { return }
        guard id == stop.discoveryPhotoID else {
            hint = stop.hint.text(for: ageBand)
            return
        }
        discover(stop, now: now)
    }

    /// Looking with help is a discovery too. No correctness, points, or retries gate the collection.
    public func showMe(now: Date = Date()) {
        guard !isPaused, !isArriving, revealedStop == nil, let stop = currentStop else { return }
        discover(stop, now: now)
    }

    public func next() {
        guard !isPaused, revealedStop != nil else { return }
        hint = nil
        if play.cursor.phase == .celebrating {
            play.send(.keepPlaying)
        } else if let stop = currentStop {
            play.send(.selectTarget(stop.id))
        }
    }

    public func openCollectedPhoto(_ stopID: String) {
        guard !isPaused, isCollection, safari.stops.contains(where: { $0.id == stopID }) else {
            return
        }
        albumStopID = stopID
    }

    public func closeCollectedPhoto() { albumStopID = nil }

    private func discover(_ stop: PhotoSafariStop, now: Date) {
        hint = nil
        play.send(.selectTarget(stop.id), now: now)
        play.send(.activateTarget, now: now)
    }
}
