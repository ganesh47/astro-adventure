import AVFoundation
import AstroGameCore
import Observation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// A native, offline player. Learning prompts and rewards belong to MissionSession.
@MainActor
struct VideoLessonView: View {
    let session: MissionSession
    var isPaused = false

    @State private var driver = VideoPlaybackDriver()
    @State private var narrator = AVSpeechSynthesizer()
    @State private var showingTranscript = false
    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @FocusState private var primaryFocused: Bool
    @FocusState private var focusedChoiceIndex: Int?

    private var band: AgeBand { session.activeMissionAgeBand }
    private var lesson: VideoLesson? { session.activeVideoLesson }
    private var segment: VideoSegment? {
        guard let lesson else { return nil }
        let seconds = session.videoPlaybackSeconds
        return lesson.segments.first { seconds >= $0.startTime && seconds < $0.endTime }
            ?? lesson.segments.last
    }
    private var fallbackCard: MissionCard? {
        guard let cards = lesson?.fallbackCards, !cards.isEmpty else { return nil }
        return cards[min(session.videoFallbackCardIndex, cards.count - 1)]
    }

    var body: some View {
        #if os(tvOS)
            content.onPlayPauseCommand { togglePlayback() }
        #else
            content
        #endif
    }

    private var content: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 520
            ScrollView {
                VStack(spacing: compact ? 8 : 18) {
                    header(compact: compact)
                    switch session.phase {
                    case .videoPlayback:
                        if session.isVideoFallback {
                            fallbackContent(compact: compact)
                        } else {
                            playbackContent(size: proxy.size)
                        }
                    case .videoCheckpoint:
                        checkpointContent(wide: proxy.size.width > 700 || compact, compact: compact)
                    case .videoFeedback:
                        feedbackContent(compact: compact)
                    case .videoComplete:
                        completionContent(compact: compact)
                    default:
                        EmptyView()
                    }
                    if let lesson {
                        Text(lesson.credit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, compact ? 24 : 40)
                .padding(.vertical, compact ? 8 : 20)
            }
        }
        .background(Color(red: 0.025, green: 0.045, blue: 0.09).opacity(0.96))
        .preferredColorScheme(.dark)
        .onAppear {
            primaryFocused = true
            if let lesson {
                let url = Bundle.module.url(forResource: lesson.resourceName, withExtension: "mp4")
                driver.configure(url: url, lesson: lesson, session: session)
            }
            synchronizePlayback()
        }
        .onChange(of: session.phase) {
            if session.phase == .videoCheckpoint {
                focusedChoiceIndex = 0
            } else {
                primaryFocused = true
            }
            synchronizePlayback()
            speakForState()
        }
        .onChange(of: session.isVideoPlaying) { synchronizePlayback() }
        .onChange(of: session.isVideoFallback) {
            synchronizePlayback()
            speakForState()
        }
        .onChange(of: session.videoSeekTarget) { synchronizePlayback() }
        .onChange(of: segment?.id) { speakForState() }
        .onChange(of: session.videoFallbackCardIndex) { speakForState() }
        .onChange(of: session.isShowingHint) {
            if session.isShowingHint { speak(session.currentQuiz?.hint) }
        }
        .onChange(of: isPaused) { pauseIfNeeded() }
        .onChange(of: scenePhase) { pauseIfNeeded() }
        .onChange(of: narrationEnabled) { speakForState() }
        .onChange(of: voiceOverEnabled) { speakForState() }
        .onDisappear {
            session.pauseVideo()
            narrator.stopSpeaking(at: .immediate)
            driver.stop()
        }
        .sheet(isPresented: $showingTranscript) { transcript }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Label("SPACE CINEMA", systemImage: "play.rectangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan)
                Text(lesson?.title ?? "Planet discovery film")
                    .font(compact ? .headline : .title2.bold())
                if !compact {
                    Text(band.modeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                narrationEnabled.toggle()
            } label: {
                Label(
                    narrationEnabled ? "Sound On" : "Sound Off",
                    systemImage: narrationEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .accessibilityLabel(narrationEnabled ? "Sound On" : "Sound Off")
            .accessibilityIdentifier("video.narration")
            Button {
                session.returnToWorlds()
            } label: {
                Label("Worlds", systemImage: "globe")
            }
            .accessibilityIdentifier("video.worlds")
        }
        .frame(maxWidth: .infinity)
        .videoFocusSection()
    }

    private func playbackContent(size: CGSize) -> some View {
        let compact = size.height < 520
        return Group {
            if compact {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 8) {
                        videoSurface(height: max(100, size.height - 190))
                        caption(compact: true)
                        filmProgress
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 8) { playbackButtons }
                        .frame(width: 165)
                        .videoFocusSection()
                }
            } else {
                VStack(spacing: 14) {
                    videoSurface(height: 380)
                    caption(compact: false)
                    filmProgress
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 18) { playbackButtons }
                        VStack(spacing: 12) { playbackButtons }
                    }
                    .videoFocusSection()
                    Text("Your film pauses for two clue challenges. Take all the time you need.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func videoSurface(height: Double) -> some View {
        NativeVideoSurface(player: driver.player)
            .aspectRatio(16 / 9, contentMode: .fit)
            .frame(maxHeight: height)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                if !driver.isReady { ProgressView("Preparing your film…") }
            }
            .accessibilityLabel("NASA planet film")
            .accessibilityValue(session.isVideoPlaying ? "Playing" : "Paused")
    }

    private func caption(compact: Bool) -> some View {
        Text(segment?.narration[band] ?? "")
            .font(compact ? .caption : .body)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("video.caption")
    }

    @ViewBuilder private var filmProgress: some View {
        if let duration = lesson?.duration {
            ProgressView(value: session.videoPlaybackSeconds, total: duration)
                .accessibilityLabel("Film progress")
                .accessibilityValue(
                    "\(Int(session.videoPlaybackSeconds)) of \(Int(duration)) seconds")
        }
    }

    @ViewBuilder private var playbackButtons: some View {
        Button {
            togglePlayback()
        } label: {
            Label(
                session.isVideoPlaying ? "Pause" : "Play",
                systemImage: session.isVideoPlaying ? "pause.fill" : "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(!driver.isReady || isPaused || scenePhase != .active)
        .focused($primaryFocused)
        .accessibilityIdentifier(session.isVideoPlaying ? "video.pause" : "video.play")
        Button {
            session.videoSeek(to: max(0, session.videoPlaybackSeconds - 10))
        } label: {
            Label("Back 10s", systemImage: "gobackward.10")
        }
        .accessibilityIdentifier("video.seek.backward")
        Button {
            session.videoSeek(to: session.videoPlaybackSeconds + 10)
        } label: {
            Label("Ahead 10s", systemImage: "goforward.10")
        }
        .accessibilityIdentifier("video.seek.forward")
        transcriptButton
    }

    private func fallbackContent(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 18) {
            Label("Let's discover with pictures", systemImage: "photo.on.rectangle")
                .font(.headline)
            if let card = fallbackCard {
                discoveryImage(card.imageName)
                    .frame(maxHeight: compact ? 100 : 260)
                Text(card.title).font(.title3.bold())
                Text(card.body[band])
                    .font(compact ? .caption : .body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("The film could not play. You can learn the same clues here.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Check the clue") { session.continueVideoFallback() }
                .buttonStyle(.borderedProminent)
                .focused($primaryFocused)
                .accessibilityIdentifier("video.fallback")
            transcriptButton
        }
        .frame(maxWidth: .infinity)
        .videoFocusSection()
    }

    private func checkpointContent(wide: Bool, compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 24) {
            Label("PAUSE & WONDER", systemImage: "lightbulb.fill")
                .font(compact ? .caption.bold() : .headline.bold()).foregroundStyle(.yellow)
            if let quiz = session.currentQuiz {
                Text(quiz.prompt)
                    .font(compact ? .headline : .title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("video.question")
                if wide {
                    HStack(spacing: compact ? 10 : 20) { choices(quiz, compact: compact) }
                        .videoFocusSection()
                } else {
                    VStack(spacing: 14) { choices(quiz, compact: compact) }
                        .videoFocusSection()
                }
                if session.isShowingHint {
                    Label(quiz.hint, systemImage: "sparkles")
                        .font(.body)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                }
            }
            HStack(spacing: 18) {
                Button {
                    session.requestHint()
                } label: {
                    Label("Hint", systemImage: "lightbulb")
                }
                .accessibilityIdentifier("video.hint")
                Button {
                    session.replayVideoClue()
                } label: {
                    Label("Replay the clue", systemImage: "gobackward")
                }
                .accessibilityIdentifier("video.replay")
            }
            .videoFocusSection()
        }
        .padding(.vertical, compact ? 4 : 24)
    }

    @ViewBuilder private func choices(_ quiz: QuizContent, compact: Bool) -> some View {
        ForEach(Array(quiz.choices.enumerated()), id: \.element.id) { index, choice in
            Button {
                session.submitAnswer(at: index)
            } label: {
                Text(choice.text)
                    .font(compact ? .subheadline.bold() : .headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: compact ? 36 : 60)
                    .padding(compact ? 8 : 12)
            }
            .buttonStyle(.bordered)
            .focused($focusedChoiceIndex, equals: index)
            .accessibilityIdentifier("video.answer.\(index)")
        }
    }

    private func feedbackContent(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 24) {
            Image(systemName: session.wasLastAnswerCorrect ? "star.fill" : "sparkles")
                .font(.system(size: compact ? 30 : 60))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text(session.wasLastAnswerCorrect ? "Clue discovered!" : "Keep exploring!")
                .font(compact ? .headline : .title.bold())
            Text(session.lastFeedback)
                .font(compact ? .body : .title3)
                .multilineTextAlignment(.center)
            Button(session.wasLastAnswerCorrect ? "Continue" : "Try again") { session.confirm() }
                .buttonStyle(.borderedProminent)
                .focused($primaryFocused)
                .accessibilityIdentifier("video.continue")
            if !session.wasLastAnswerCorrect {
                Button("Replay the clue") { session.replayVideoClue() }
                    .accessibilityIdentifier("video.replay")
            }
        }
        .padding(.vertical, compact ? 4 : 35)
        .frame(maxWidth: .infinity)
        .videoFocusSection()
    }

    private func completionContent(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 24) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: compact ? 30 : 70)).foregroundStyle(.cyan)
                .accessibilityHidden(true)
            Text("Space cinema complete!").font(compact ? .headline : .title.bold())
            Text("You watched, wondered, and discovered two new clues.")
                .font(compact ? .body : .title3)
                .multilineTextAlignment(.center)
            Button("Continue exploring") { session.confirm() }
                .buttonStyle(.borderedProminent)
                .focused($primaryFocused)
                .accessibilityIdentifier("video.continue")
            transcriptButton
        }
        .padding(.vertical, compact ? 4 : 35)
        .frame(maxWidth: .infinity)
        .videoFocusSection()
    }

    private var transcriptButton: some View {
        Button {
            session.pauseVideo()
            narrator.stopSpeaking(at: .immediate)
            showingTranscript = true
        } label: {
            Label("Read the story", systemImage: "text.book.closed")
        }
        .accessibilityIdentifier("video.transcript")
    }

    private var transcript: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson?.title ?? "Film transcript").font(.title.bold())
                ForEach(lesson?.segments ?? []) { item in
                    Text("\(Int(item.startTime))–\(Int(item.endTime)) seconds").font(.headline)
                    Text(item.narration[band]).fixedSize(horizontal: false, vertical: true)
                }
                Text(lesson?.credit ?? "").font(.caption)
                Button("Back to discovery") { showingTranscript = false }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("video.transcript.close")
            }
            .padding(40)
        }
    }

    @ViewBuilder private func discoveryImage(_ name: String) -> some View {
        if let url = Bundle.module.url(forResource: name, withExtension: "jpg"),
            let image = platformImage(url)
        {
            image.resizable().scaledToFit().accessibilityHidden(true)
        }
    }

    private func platformImage(_ url: URL) -> Image? {
        #if canImport(UIKit)
            return UIImage(contentsOfFile: url.path).map(Image.init(uiImage:))
        #elseif canImport(AppKit)
            return NSImage(contentsOf: url).map(Image.init(nsImage:))
        #else
            return nil
        #endif
    }

    private func togglePlayback() {
        guard session.phase == .videoPlayback, !session.isVideoFallback else { return }
        if session.isVideoPlaying { session.pauseVideo() } else { session.playVideo() }
        synchronizePlayback()
        speakForState()
    }

    private func synchronizePlayback() {
        let blocked = isPaused || scenePhase != .active || showingTranscript
        driver.synchronize(blocked: blocked)
        if blocked
            || (session.phase == .videoPlayback && !session.isVideoPlaying
                && !session.isVideoFallback)
        {
            narrator.stopSpeaking(at: .immediate)
        } else if session.phase == .videoPlayback && session.isVideoPlaying {
            speakForState()
        }
    }

    private func pauseIfNeeded() {
        if isPaused || scenePhase != .active {
            session.pauseVideo()
            narrator.stopSpeaking(at: .immediate)
        }
        synchronizePlayback()
    }

    private func speakForState() {
        let copy: String?
        switch session.phase {
        case .videoPlayback:
            copy =
                session.isVideoFallback
                ? fallbackCard?.body[band]
                : (session.isVideoPlaying ? segment?.narration[band] : nil)
        case .videoCheckpoint:
            copy = session.currentQuiz.map { quiz in
                quiz.prompt + ". " + quiz.choices.map(\.text).joined(separator: ". ")
            }
        case .videoFeedback:
            copy = session.lastFeedback
        case .videoComplete:
            copy = "Space cinema complete! Continue exploring whenever you are ready."
        default:
            copy = nil
        }
        speak(copy)
    }

    private func speak(_ copy: String?) {
        narrator.stopSpeaking(at: .immediate)
        guard narrationEnabled, !voiceOverEnabled, !isPaused,
            scenePhase == .active, !showingTranscript
        else { return }
        guard let copy, !copy.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: copy)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = band == .ages4To6 ? 0.43 : 0.48
        narrator.speak(utterance)
    }
}

extension View {
    @ViewBuilder fileprivate func videoFocusSection() -> some View {
        #if os(tvOS)
            focusSection()
        #else
            self
        #endif
    }
}

/// Time observers feed the deterministic core; they never award a reward themselves.
@MainActor
@Observable
private final class VideoPlaybackDriver {
    let player = AVPlayer()
    private(set) var isReady = false
    private var session: MissionSession?
    private var blocked = false
    private var seeking = false
    private var generation = 0
    private var timeObserver: Any?
    private var boundaryObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var failureObserver: NSObjectProtocol?

    func configure(url: URL?, lesson: VideoLesson, session: MissionSession) {
        stop()
        self.session = session
        let generation = self.generation
        guard let url else {
            session.videoFailed()
            return
        }
        let item = AVPlayerItem(url: url)
        player.isMuted = true
        player.allowsExternalPlayback = false
        player.replaceCurrentItem(with: item)
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.statusChanged()
            }
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.updateTime(seconds)
            }
        }
        let boundaries = lesson.checkpoints.map {
            NSValue(time: CMTime(seconds: $0.time, preferredTimescale: 600))
        }
        if !boundaries.isEmpty {
            boundaryObserver = player.addBoundaryTimeObserver(forTimes: boundaries, queue: .main) {
                [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, self.generation == generation else { return }
                    self.updateTime(self.player.currentTime().seconds)
                }
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.didEnd()
            }
        }
        failureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.failed()
            }
        }
        if session.videoPlaybackSeconds > 0 {
            seeking = true
            let target = session.videoPlaybackSeconds
            player.seek(
                to: CMTime(seconds: target, preferredTimescale: 600),
                toleranceBefore: .zero, toleranceAfter: .zero
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.seekCompleted(target: target, generation: generation)
                }
            }
        }
    }

    func synchronize(blocked: Bool) {
        self.blocked = blocked
        guard let session else {
            player.pause()
            return
        }
        if let target = session.videoSeekTarget, !seeking {
            seeking = true
            let generation = self.generation
            player.pause()
            player.seek(
                to: CMTime(seconds: target, preferredTimescale: 600),
                toleranceBefore: .zero, toleranceAfter: .zero
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.seekCompleted(target: target, generation: generation)
                }
            }
            return
        }
        if isReady && !blocked && !seeking && session.phase == .videoPlayback
            && session.isVideoPlaying && !session.isVideoFallback
        {
            player.play()
        } else {
            player.pause()
        }
    }

    private func seekCompleted(target: Double, generation: Int) {
        guard generation == self.generation else { return }
        seeking = false
        // A newer seek/checkpoint may arrive before the old AVPlayer seek finishes.
        // Only consume the intent this completion actually applied.
        if session?.videoSeekTarget == target { session?.videoSeekCompleted() }
        synchronize(blocked: blocked)
    }

    private func statusChanged() {
        switch player.currentItem?.status {
        case .readyToPlay:
            isReady = true
            synchronize(blocked: blocked)
        case .failed:
            failed()
        default:
            break
        }
    }

    private func updateTime(_ seconds: Double) {
        guard seconds.isFinite, !blocked, !seeking,
            let session, session.phase == .videoPlayback, session.isVideoPlaying,
            !session.isVideoFallback
        else { return }
        // Read the player now: an observer event queued before a seek is stale.
        session.playbackTimeChanged(seconds: player.currentTime().seconds)
        if session.phase != .videoPlayback || !session.isVideoPlaying { player.pause() }
    }

    private func didEnd() {
        guard !blocked, !seeking, let session,
            session.phase == .videoPlayback, session.isVideoPlaying,
            !session.isVideoFallback, session.videoSeekTarget == nil,
            let lesson = session.activeVideoLesson,
            player.currentTime().seconds >= lesson.duration - 0.3
        else { return }
        session.videoDidEnd()
        player.pause()
    }

    private func failed() {
        player.pause()
        isReady = false
        session?.videoFailed()
    }

    func stop() {
        generation += 1
        player.pause()
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let boundaryObserver { player.removeTimeObserver(boundaryObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        if let failureObserver { NotificationCenter.default.removeObserver(failureObserver) }
        statusObserver?.invalidate()
        timeObserver = nil
        boundaryObserver = nil
        endObserver = nil
        failureObserver = nil
        statusObserver = nil
        player.replaceCurrentItem(with: nil)
        isReady = false
        seeking = false
        session = nil
    }
}

#if canImport(UIKit)
    private struct NativeVideoSurface: UIViewRepresentable {
        let player: AVPlayer
        func makeUIView(context: Context) -> NativeVideoLayerView {
            let view = NativeVideoLayerView()
            view.videoLayer.player = player
            return view
        }
        func updateUIView(_ view: NativeVideoLayerView, context: Context) {
            view.videoLayer.player = player
        }
        static func dismantleUIView(_ view: NativeVideoLayerView, coordinator: ()) {
            view.videoLayer.player = nil
        }
    }

    private final class NativeVideoLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var videoLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
#elseif canImport(AppKit)
    private struct NativeVideoSurface: NSViewRepresentable {
        let player: AVPlayer
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspect
            view.wantsLayer = true
            view.layer = layer
            return view
        }
        func updateNSView(_ view: NSView, context: Context) {
            (view.layer as? AVPlayerLayer)?.player = player
        }
        static func dismantleNSView(_ view: NSView, coordinator: ()) {
            (view.layer as? AVPlayerLayer)?.player = nil
        }
    }
#endif
