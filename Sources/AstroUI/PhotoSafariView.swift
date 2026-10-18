import AVFoundation
import AstroGameCore
import SwiftUI

/// Photo-led play: one visual clue, two real images, a discovery to keep.
@MainActor
public struct PhotoSafariView: View {
    private let session: PhotoSafariSession
    private let onLeave: () -> Void
    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var narrator = AVSpeechSynthesizer()
    @FocusState private var focus: String?

    public init(session: PhotoSafariSession, onLeave: @escaping () -> Void) {
        self.session = session
        self.onLeave = onLeave
    }

    private var television: Bool {
        #if os(tvOS)
            true
        #else
            false
        #endif
    }

    public var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 540
            ZStack {
                Color(red: 0.035, green: 0.055, blue: 0.095).ignoresSafeArea()
                VStack(spacing: compact ? 7 : 18) {
                    header(compact: compact)
                    if let stop = session.albumStop {
                        reveal(stop, compact: compact, fromAlbum: true)
                    } else if let stop = session.revealedStop {
                        reveal(stop, compact: compact, fromAlbum: false)
                    } else if session.isCollection {
                        collection(compact: compact)
                    } else if let stop = session.currentStop {
                        hunt(stop, size: geometry.size, compact: compact)
                    }
                }
                .padding(.horizontal, television ? 52 : 18)
                .padding(.vertical, television ? 28 : compact ? 8 : 18)
                .allowsHitTesting(!session.isPaused)
                .accessibilityHidden(session.isPaused)
                if session.isPaused {
                    Color.black.opacity(0.82).ignoresSafeArea()
                    pausePanel(compact: compact)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if session.isArriving { session.begin() }
            focus = preferredFocus
            speak()
        }
        .onChange(of: session.revealedStop?.id) { refreshFocus() }
        .onChange(of: session.isCollection) { refreshFocus() }
        .onChange(of: session.albumStopID) { refreshFocus() }
        .onChange(of: session.isPaused) { refreshFocus() }
        .onChange(of: session.hint) { speak() }
        .onChange(of: narrationEnabled) { speak() }
        .onChange(of: voiceOverEnabled) { speak() }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                session.pause()
                narrator.stopSpeaking(at: .immediate)
            }
        }
        .onDisappear { narrator.stopSpeaking(at: .immediate) }
        #if os(tvOS)
            .onExitCommand {
                if session.isPaused {
                    session.resume()
                } else if session.albumStop != nil {
                    session.closeCollectedPhoto()
                } else {
                    session.pause()
                }
            }
            .onPlayPauseCommand {
                if session.isPaused { session.resume() } else { session.pause() }
            }
        #endif
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.safari.title)
                    .font(
                        .system(
                            size: television ? 34 : compact ? 20 : 28, weight: .black,
                            design: .rounded)
                    )
                    .foregroundStyle(.white)
                Text(
                    session.isCollection
                        ? "Your photo collection"
                        : "Photo \(min(session.collectedCount + (session.revealedStop == nil ? 1 : 0), session.safari.stops.count)) of \(session.safari.stops.count)"
                )
                .font(
                    .system(
                        size: television ? 22 : compact ? 11 : 16, weight: .semibold,
                        design: .rounded)
                )
                .foregroundStyle(.cyan)
                .accessibilityIdentifier("safari.progress")
            }
            Spacer()
            Button("Options", systemImage: "line.3.horizontal") { session.pause() }
                .font(.system(size: television ? 24 : compact ? 13 : 18, weight: .bold))
                .buttonStyle(.bordered)
                .focused($focus, equals: "options")
                .accessibilityIdentifier("safari.options")
                #if os(tvOS)
                    .onMoveCommand { direction in
                        if direction == .down { focus = preferredFocus }
                    }
                #endif
        }
    }

    private func hunt(_ stop: PhotoSafariStop, size: CGSize, compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 18) {
            Text(stop.clue.text(for: session.ageBand))
                .font(
                    .system(
                        size: television ? 36 : compact ? 20 : 28, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(.white).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("safari.clue")
            Spacer(minLength: 0)
            HStack(spacing: compact ? 14 : 32) {
                ForEach(stop.photos) { photo in
                    Button {
                        session.choosePhoto(photo.id)
                    } label: {
                        VStack(alignment: .leading, spacing: compact ? 4 : 10) {
                            SpacePhotoImage(photo: photo)
                                .frame(height: min(330, max(90, size.height * 0.34)))
                                .frame(maxWidth: .infinity)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 14))
                            Text(photo.title)
                                .font(
                                    .system(
                                        size: television ? 26 : compact ? 13 : 19, weight: .bold,
                                        design: .rounded)
                                )
                                .foregroundStyle(.white)
                            Text(photo.credit)
                                .font(.system(size: television ? 16 : compact ? 9 : 12))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(3).frame(
                                    maxWidth: .infinity, minHeight: compact ? 22 : 40,
                                    alignment: .topLeading)
                        }
                        .padding(compact ? 10 : 16)
                        .background(Color(red: 0.075, green: 0.1, blue: 0.16))
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 22))
                        .overlay {
                            RoundedRectangle(cornerRadius: compact ? 14 : 22)
                                .stroke(
                                    focus == "choice.\(photo.id)" ? .white : .white.opacity(0.25),
                                    lineWidth: focus == "choice.\(photo.id)" ? 4 : 1)
                        }
                    }
                    #if os(tvOS)
                        .buttonStyle(.card)
                    #else
                        .buttonStyle(.plain)
                    #endif
                    .focused($focus, equals: "choice.\(photo.id)")
                    .accessibilityLabel(photo.title)
                    .accessibilityHint(
                        "Open this space photo. Hints and Show me are always available."
                    )
                    .accessibilityIdentifier("safari.choice.\(photo.id)")
                    #if os(tvOS)
                        .onMoveCommand { direction in
                            if direction == .up { focus = "options" }
                            if direction == .down { focus = "showMe" }
                        }
                    #endif
                }
            }
            Spacer(minLength: 0)
            if let hint = session.hint {
                Label(hint, systemImage: "lightbulb.fill")
                    .font(
                        .system(
                            size: television ? 25 : compact ? 13 : 19, weight: .semibold,
                            design: .rounded)
                    )
                    .foregroundStyle(.yellow).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("safari.hint")
            }
            Button("Show me", systemImage: "sparkles") { session.showMe() }
                .font(
                    .system(
                        size: television ? 26 : compact ? 15 : 21, weight: .bold, design: .rounded)
                )
                .buttonStyle(.bordered)
                .focused($focus, equals: "showMe")
                .accessibilityIdentifier("safari.showMe")
                #if os(tvOS)
                    .onMoveCommand { direction in
                        if direction == .up { focus = "choice.\(stop.photos[0].id)" }
                    }
                #endif
            if !compact {
                Text(
                    television
                        ? "Left or right to choose · Press to open a photo"
                        : "Tap a photo to explore it"
                )
                .font(.system(size: television ? 22 : 14)).foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func reveal(_ stop: PhotoSafariStop, compact: Bool, fromAlbum: Bool) -> some View {
        VStack(spacing: compact ? 6 : 14) {
            if let photo = stop.discoveryPhoto {
                SpacePhotoImage(photo: photo)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 22))
                Text(stop.title)
                    .font(
                        .system(
                            size: television ? 34 : compact ? 20 : 28, weight: .heavy,
                            design: .rounded)
                    )
                    .foregroundStyle(.yellow)
                Text(stop.fact.text(for: session.ageBand))
                    .font(
                        .system(
                            size: television ? 28 : compact ? 16 : 23, weight: .semibold,
                            design: .rounded)
                    )
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("safari.fact")
                Text(photo.caption)
                    .font(.system(size: television ? 20 : compact ? 11 : 15))
                    .foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("safari.caption")
                Text(photo.credit)
                    .font(.system(size: television ? 17 : compact ? 9 : 12))
                    .foregroundStyle(.white.opacity(0.75)).multilineTextAlignment(.center)
                    .accessibilityIdentifier("safari.credit")
            }
            Button(
                fromAlbum
                    ? "Back to my photos"
                    : session.collectedCount == session.safari.stops.count
                        ? "See my photos" : "Next photo",
                systemImage: fromAlbum ? "arrow.backward" : "arrow.right"
            ) {
                if fromAlbum { session.closeCollectedPhoto() } else { session.next() }
            }
            .font(
                .system(size: television ? 28 : compact ? 17 : 23, weight: .bold, design: .rounded)
            )
            .buttonStyle(.borderedProminent).tint(.yellow).foregroundStyle(.black)
            .focused($focus, equals: fromAlbum ? "album.back" : "next")
            .accessibilityIdentifier(fromAlbum ? "safari.album.back" : "safari.next")
        }
    }

    private func collection(compact: Bool) -> some View {
        VStack(spacing: compact ? 10 : 24) {
            Text("Your \(session.safari.destinationID.capitalized) photos are saved!")
                .font(
                    .system(
                        size: television ? 40 : compact ? 23 : 32, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(.yellow).multilineTextAlignment(.center)
                .accessibilityIdentifier("safari.collection")
            Text("Choose a photo to look again.")
                .font(.system(size: television ? 26 : compact ? 14 : 20, weight: .semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            HStack(spacing: compact ? 12 : 28) {
                ForEach(session.safari.stops) { stop in
                    if let photo = stop.discoveryPhoto {
                        Button {
                            session.openCollectedPhoto(stop.id)
                        } label: {
                            VStack(spacing: 10) {
                                SpacePhotoImage(photo: photo).frame(
                                    height: compact ? 115 : television ? 280 : 210)
                                Text(stop.title)
                                    .font(
                                        .system(
                                            size: television ? 25 : compact ? 13 : 19,
                                            weight: .bold, design: .rounded)
                                    )
                                    .foregroundStyle(.white).multilineTextAlignment(.center)
                            }
                            .padding(compact ? 8 : 18)
                            .background(.black, in: RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        focus == "album.\(stop.id)" ? .white : .white.opacity(0.25),
                                        lineWidth: focus == "album.\(stop.id)" ? 4 : 1)
                            }
                        }
                        #if os(tvOS)
                            .buttonStyle(.card)
                        #else
                            .buttonStyle(.plain)
                        #endif
                        .focused($focus, equals: "album.\(stop.id)")
                        .accessibilityIdentifier("safari.album.\(stop.id)")
                    }
                }
            }
            Spacer(minLength: 0)
            Button("Explore another world", systemImage: "globe.americas.fill", action: leave)
                .font(
                    .system(
                        size: television ? 28 : compact ? 17 : 23, weight: .bold, design: .rounded)
                )
                .buttonStyle(.borderedProminent).tint(.yellow).foregroundStyle(.black)
                .accessibilityIdentifier("safari.worlds")
        }
    }

    private func pausePanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 24) {
            Text("Photo Safari paused").font(compact ? .title2.bold() : .largeTitle.bold())
            Text("Your discoveries are saved. Take your time.").font(compact ? .body : .title3)
            Button("Continue Photo Safari", systemImage: "play.fill") { session.resume() }
                .buttonStyle(.borderedProminent).tint(.yellow).foregroundStyle(.black)
                .focused($focus, equals: "resume").accessibilityIdentifier("safari.resume")
            Button(
                narrationEnabled ? "Narration On" : "Narration Off",
                systemImage: "speaker.wave.2.fill"
            ) {
                narrationEnabled.toggle()
            }
            .buttonStyle(.bordered).accessibilityIdentifier("safari.narration")
            Button("Worlds", systemImage: "globe.americas.fill", action: leave)
                .buttonStyle(.bordered).accessibilityIdentifier("safari.worlds")
        }
        .font(.system(size: compact ? 17 : 26, weight: .semibold, design: .rounded))
        .padding(compact ? 20 : 44)
        .foregroundStyle(.white)
        .background(
            Color(red: 0.05, green: 0.08, blue: 0.13), in: RoundedRectangle(cornerRadius: 28))
    }

    private var preferredFocus: String {
        if session.isPaused { return "resume" }
        if session.albumStop != nil { return "album.back" }
        if session.revealedStop != nil { return "next" }
        if session.isCollection { return "album.\(session.safari.stops.first?.id ?? "")" }
        return "choice.\(session.currentStop?.photos.first?.id ?? "")"
    }

    private func refreshFocus() {
        focus = preferredFocus
        speak()
    }

    private func speak() {
        narrator.stopSpeaking(at: .immediate)
        guard narrationEnabled, !voiceOverEnabled, !session.isPaused, scenePhase == .active else {
            return
        }
        let text =
            (session.albumStop ?? session.revealedStop)?.fact.text(for: session.ageBand)
            ?? session.hint
            ?? session.currentStop?.clue.text(for: session.ageBand)
            ?? "Your space photos are saved. Choose one to look again, or explore another world."
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = session.ageBand == .ages4To6 ? 0.43 : 0.48
        narrator.speak(utterance)
    }

    private func leave() {
        narrator.stopSpeaking(at: .immediate)
        session.pause()
        onLeave()
    }
}

struct SpacePhotoImage: View {
    let photo: SpacePhoto
    var body: some View {
        Group {
            if let image = discoveryImage(named: photo.imageName) {
                image.resizable().scaledToFit()
            } else {
                Label("Photo unavailable", systemImage: "photo")
                    .foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityLabel(photo.title)
    }
}
