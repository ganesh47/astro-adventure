import AVFoundation
import AstroContent
import AstroGameCore
import Observation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

@MainActor
struct ExplorationClipView: View {
    let session: ExplorationSession
    let video: VideoLesson?
    @State private var player = ObservationFilmPlayer()
    @State private var playback: ObservationPlaybackState
    @State private var narrator = AVSpeechSynthesizer()
    @State private var transcript = false
    @AppStorage("astro.narrationEnabled") private var soundOn = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @FocusState private var primaryFocused: Bool

    init(session: ExplorationSession, video: VideoLesson?) {
        self.session = session
        self.video = video
        _playback = State(
            initialValue: ObservationPlaybackState(
                duration: video?.duration ?? 60,
                checkpoints: video?.checkpoints.map(\.time) ?? [],
                seconds: session.cursor.clipSeconds,
                acknowledged: session.cursor.clipCheckpointIDs
            ))
    }

    private var segment: VideoSegment? {
        let seconds =
            playback.pendingCheckpoint == nil ? playback.seconds : max(0, playback.seconds - 0.01)
        return video?.segments.first { seconds >= $0.startTime && seconds < $0.endTime }
            ?? video?.segments.last
    }

    // Keep the preceding observation visible rather than the first frame after a cut.
    // The saved semantic checkpoint stays exactly at its authored boundary.
    private var pictureSeconds: Double {
        playback.pendingCheckpoint == nil ? playback.seconds : max(0, playback.seconds - 0.05)
    }

    private var television: Bool {
        #if os(tvOS)
            true
        #else
            false
        #endif
    }

    private var videoURL: URL? {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                ProcessInfo.processInfo.arguments.contains("--missing-playground-media")
            {
                return nil
            }
        #endif
        return video.flatMap {
            Bundle.module.url(forResource: $0.resourceName, withExtension: "mp4")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 550
            VStack(spacing: compact ? 8 : 16) {
                HStack(alignment: .top, spacing: 16) {
                    Text(video?.title ?? "Look closer")
                        .font(.system(size: television ? 30 : compact ? 18 : 24, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Button("Back to playground", systemImage: "arrow.backward") { close() }
                        .font(.system(size: television ? 22 : compact ? 14 : 17, weight: .semibold))
                        .accessibilityIdentifier("playground.clip.close")
                }
                .frame(maxWidth: .infinity)
                #if os(tvOS)
                    .focusSection()
                #endif
                ScrollView {
                    VStack(spacing: compact ? 10 : 20) {
                        if compact || television {
                            HStack(alignment: .top, spacing: 20) {
                                picture.frame(maxWidth: .infinity)
                                VStack(spacing: 12) { controls }
                                    .font(.system(size: television ? 24 : 16, weight: .semibold))
                                    .frame(width: television ? 390 : 240)
                            }
                        } else {
                            picture.frame(maxHeight: min(440, geometry.size.height * 0.45))
                            controls
                        }
                        if let segment {
                            Text(segment.narration[session.ageBand])
                                .font(compact ? .caption : .body)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("playground.clip.caption")
                        }
                        if transcript {
                            ForEach(video?.segments ?? []) { item in
                                Text(item.narration[session.ageBand])
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Text(
                            video?.credit ?? "NASA imagery is available in the planet field guide."
                        )
                        .font(.caption2).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(compact ? 18 : 36)
            .frame(maxWidth: 1250)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.025, green: 0.04, blue: 0.09))
        .onAppear {
            primaryFocused = true
            player.configure(
                url: videoURL,
                checkpoints: playback.checkpoints,
                seconds: pictureSeconds,
                onTime: { seconds in
                    playback.timeChanged(seconds)
                    synchronize()
                }
            )
        }
        .onChange(of: playback) {
            session.updateClipProgress(
                seconds: playback.seconds, checkpointIDs: playback.acknowledged)
        }
        .onChange(of: segment?.id) { speakCaption() }
        .onChange(of: scenePhase) { if scenePhase != .active { pause() } }
        .onChange(of: session.overlay) { if session.overlay != .clip { pause() } }
        .onChange(of: voiceOver) { speakCaption() }
        .onChange(of: soundOn) { speakCaption() }
        #if canImport(UIKit)
            .onReceive(
                NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            ) { _ in
                pause()
            }
        #endif
        .onDisappear {
            pause()
            player.stop()
        }
        #if os(tvOS)
            .onPlayPauseCommand { toggle() }
            .onExitCommand { close() }
        #endif
    }

    private var picture: some View {
        ZStack {
            if player.hasFailed {
                if let segment,
                    let url = Bundle.module.url(
                        forResource: segment.imageName, withExtension: "jpg"),
                    let image = platformImage(url)
                {
                    image.resizable().scaledToFit()
                } else {
                    Image(systemName: "sparkles").font(.system(size: 80)).foregroundStyle(.cyan)
                }
            } else {
                NativeVideoSurface(player: player.player)
                if !player.isReady { ProgressView("Preparing your observation…") }
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityLabel(
            player.hasFailed ? "Illustrated planet observation" : "NASA planet film"
        )
        .accessibilityValue(playback.isPlaying ? "Playing" : "Paused")
    }

    @ViewBuilder private var controls: some View {
        if player.hasFailed {
            Text("Let's use pictures instead. Your playground is ready.")
                .font(.headline).multilineTextAlignment(.center)
            Button("Try it in the playground", systemImage: "gamecontroller.fill") { close() }
                .buttonStyle(.borderedProminent).focused($primaryFocused)
                .accessibilityIdentifier("playground.clip.try")
        } else if playback.pendingCheckpoint != nil || playback.seconds >= playback.duration {
            Text(
                playback.pendingCheckpoint.flatMap {
                    ExplorationCatalog.filmObservation(
                        destinationID: session.adventure.destinationID, checkpoint: $0
                    )?.text(for: session.ageBand)
                } ?? session.currentGoal?.invitation.text(for: session.ageBand)
                    ?? "What could you try with your tools?"
            )
            .font(.headline).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            Button("Try it in the playground", systemImage: "gamecontroller.fill") { close() }
                .buttonStyle(.borderedProminent).focused($primaryFocused)
                .accessibilityIdentifier("playground.clip.try")
            if playback.pendingCheckpoint != nil {
                Button("Continue film", systemImage: "play.fill") {
                    playback.continueFilm()
                    synchronize()
                }.accessibilityIdentifier("playground.clip.continue")
            }
            Button("Replay observation", systemImage: "gobackward") {
                seek(max(0, playback.seconds - 20))
            }.accessibilityIdentifier("playground.clip.replay")
        } else {
            Button(
                playback.isPlaying ? "Pause film" : "Play film",
                systemImage: playback.isPlaying ? "pause.fill" : "play.fill"
            ) { toggle() }
            .buttonStyle(.borderedProminent).focused($primaryFocused)
            .disabled(!player.isReady || scenePhase != .active || session.overlay != .clip)
            .accessibilityIdentifier("playground.clip.play")
            if television {
                VStack(spacing: 12) { seekControls }
                    .font(.system(size: 24, weight: .semibold))
                    .lineLimit(1)
            } else {
                HStack { seekControls }
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        Button(transcript ? "Hide transcript" : "Read transcript", systemImage: "text.book.closed")
        {
            pause()
            transcript.toggle()
        }.accessibilityIdentifier("playground.clip.transcript")
    }

    @ViewBuilder private var seekControls: some View {
        Button("Back 10s", systemImage: "gobackward.10") { seek(playback.seconds - 10) }
            .accessibilityIdentifier("playground.clip.back")
        Button("Ahead 10s", systemImage: "goforward.10") { seek(playback.seconds + 10) }
            .accessibilityIdentifier("playground.clip.ahead")
    }

    private func close() {
        pause()
        session.send(.closeOverlay)
    }
    private func pause() {
        playback.pause()
        player.pause()
        narrator.stopSpeaking(at: .immediate)
    }
    private func toggle() {
        guard scenePhase == .active, session.overlay == .clip else { return }
        if playback.isPlaying {
            pause()
        } else {
            transcript = false
            playback.play()
            synchronize()
            speakCaption()
        }
    }
    private func seek(_ seconds: Double) {
        pause()
        playback.seek(to: seconds)
        player.seek(to: pictureSeconds)
    }
    private func synchronize() {
        if playback.isPlaying && scenePhase == .active && session.overlay == .clip {
            player.play()
        } else {
            player.pause()
            narrator.stopSpeaking(at: .immediate)
            if playback.pendingCheckpoint != nil { player.seek(to: pictureSeconds) }
        }
    }
    private func speakCaption() {
        narrator.stopSpeaking(at: .immediate)
        guard soundOn, !voiceOver, playback.isPlaying, scenePhase == .active,
            let copy = segment?.narration[session.ageBand]
        else { return }
        let utterance = AVSpeechUtterance(string: copy)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        narrator.speak(utterance)
    }
    private func platformImage(_ url: URL) -> Image? {
        #if canImport(UIKit)
            UIImage(contentsOfFile: url.path).map(Image.init(uiImage:))
        #elseif canImport(AppKit)
            NSImage(contentsOf: url).map(Image.init(nsImage:))
        #else
            nil
        #endif
    }
}

/// Presentation-only AVFoundation adapter. Semantic time events feed the pure playback state.
@MainActor
@Observable
final class ObservationFilmPlayer {
    let player = AVPlayer()
    private(set) var isReady = false
    private(set) var hasFailed = false
    private var generation = 0
    private var seeking = false
    private var seekRevision = 0
    private var wantsPlay = false
    private var timeObserver: Any?
    private var boundaryObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var failureObserver: NSObjectProtocol?
    private var endObserver: NSObjectProtocol?
    private var onTime: ((Double) -> Void)?

    func configure(
        url: URL?, checkpoints: [Double], seconds: Double, onTime: @escaping (Double) -> Void
    ) {
        stop()
        self.onTime = onTime
        guard let url else {
            hasFailed = true
            return
        }
        let item = AVPlayerItem(url: url)
        player.isMuted = true
        player.allowsExternalPlayback = false
        player.replaceCurrentItem(with: item)
        let run = generation
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == run else { return }
                self.isReady = self.player.currentItem?.status == .readyToPlay
                if self.player.currentItem?.status == .failed { self.fail() }
                if self.isReady && self.wantsPlay && !self.seeking { self.player.play() }
            }
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick(generation: run) }
        }
        boundaryObserver = player.addBoundaryTimeObserver(
            forTimes: checkpoints.map {
                NSValue(time: CMTime(seconds: $0, preferredTimescale: 600))
            }, queue: .main
        ) { [weak self] in
            Task { @MainActor [weak self] in self?.tick(generation: run) }
        }
        failureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == run else { return }
                self.fail()
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == run, !self.seeking, self.wantsPlay else {
                    return
                }
                let end = self.player.currentTime().seconds
                let duration = self.player.currentItem?.duration.seconds ?? .nan
                guard end.isFinite, duration.isFinite, end >= duration - 0.3 else { return }
                self.onTime?(end)
                self.pause()
            }
        }
        seek(to: seconds)
    }
    func play() {
        wantsPlay = true
        if isReady && !seeking && !hasFailed { player.play() }
    }
    func pause() {
        wantsPlay = false
        player.pause()
    }
    func seek(to seconds: Double) {
        guard seconds.isFinite else { return }
        player.pause()
        seeking = true
        wantsPlay = false
        seekRevision += 1
        let seek = seekRevision
        let run = generation
        player.seek(
            to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == run, self.seekRevision == seek else { return }
                self.seeking = false
                if self.wantsPlay && self.isReady && !self.hasFailed { self.player.play() }
            }
        }
    }
    private func tick(generation: Int) {
        guard self.generation == generation, !seeking, player.rate > 0 else { return }
        let seconds = player.currentTime().seconds
        if seconds.isFinite { onTime?(seconds) }
    }
    private func fail() {
        pause()
        hasFailed = true
        isReady = false
    }
    func stop() {
        generation += 1
        player.pause()
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let boundaryObserver { player.removeTimeObserver(boundaryObserver) }
        if let failureObserver { NotificationCenter.default.removeObserver(failureObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        statusObserver?.invalidate()
        timeObserver = nil
        boundaryObserver = nil
        failureObserver = nil
        endObserver = nil
        statusObserver = nil
        onTime = nil
        player.replaceCurrentItem(with: nil)
        isReady = false
        hasFailed = false
        seeking = false
        wantsPlay = false
    }
}
