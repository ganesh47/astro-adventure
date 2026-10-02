import Foundation

/// Optional observation pauses invite play; they never test answers or award progress.
public struct ObservationPlaybackState: Equatable, Sendable {
    public let duration: Double
    public let checkpoints: [Double]
    public private(set) var seconds: Double
    public private(set) var acknowledged: Set<String>
    public private(set) var pendingCheckpoint: Int?
    public private(set) var isPlaying = false

    public init(
        duration: Double, checkpoints: [Double], seconds: Double = 0,
        acknowledged: Set<String> = []
    ) {
        let normalizedDuration = max(1, duration.isFinite ? duration : 60)
        self.duration = normalizedDuration
        self.checkpoints = checkpoints.filter { $0.isFinite && $0 > 0 && $0 < normalizedDuration }
            .sorted()
        self.seconds = seconds.isFinite ? min(max(0, seconds), self.duration) : 0
        self.acknowledged = acknowledged.intersection(
            Set(self.checkpoints.indices.map { "segment-\($0)" }))
        if let next = self.checkpoints.indices.first(where: {
            !self.acknowledged.contains("segment-\($0)") && self.checkpoints[$0] <= self.seconds
        }) {
            self.seconds = self.checkpoints[next]
            self.pendingCheckpoint = next
        }
    }

    public mutating func play() {
        guard pendingCheckpoint == nil, seconds < duration else { return }
        isPlaying = true
    }

    public mutating func pause() { isPlaying = false }

    public mutating func seek(to requested: Double) {
        guard requested.isFinite else { return }
        isPlaying = false
        update(to: requested)
    }

    public mutating func timeChanged(_ time: Double) {
        guard isPlaying, pendingCheckpoint == nil, time.isFinite else { return }
        update(to: time)
    }

    public mutating func continueFilm() {
        guard let pendingCheckpoint else { return }
        acknowledged.insert("segment-\(pendingCheckpoint)")
        self.pendingCheckpoint = nil
        isPlaying = false
    }

    private mutating func update(to requested: Double) {
        let target = min(max(0, requested), duration)
        if let pendingCheckpoint, target >= checkpoints[pendingCheckpoint] {
            seconds = checkpoints[pendingCheckpoint]
            isPlaying = false
            return
        }
        pendingCheckpoint = nil
        if let next = checkpoints.indices.first(where: {
            !acknowledged.contains("segment-\($0)") && checkpoints[$0] <= target
        }) {
            seconds = checkpoints[next]
            pendingCheckpoint = next
            isPlaying = false
        } else {
            seconds = target
            if target == duration { isPlaying = false }
        }
    }
}
