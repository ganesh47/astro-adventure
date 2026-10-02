import AVFoundation
import AstroGameCore
import AstroWorld
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// A persistent play space: selecting aims, activating changes the toy, and discoveries stay visible.
@MainActor
public struct ExplorationPlaygroundView: View {
    private let session: ExplorationSession
    private let videoLessons: [VideoLesson]
    private let onLeave: () -> Void
    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var narrator = AVSpeechSynthesizer()
    @State private var topHUDHeight: CGFloat = 0
    @FocusState private var focusedControl: String?

    public init(
        session: ExplorationSession, videoLessons: [VideoLesson], onLeave: @escaping () -> Void
    ) {
        self.session = session
        self.videoLessons = videoLessons
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
            let compact = geometry.size.height < 520
            ZStack {
                ExplorationWorldView(
                    adventure: session.adventure, cursor: session.cursor,
                    isPaused: session.isPaused || session.overlay != nil
                        || session.cursor.phase == .celebrating
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(0)
                // Legibility scrims do not replace the interactive world.
                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: compact ? 135 : 210)
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.88)], startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: compact ? 110 : 210)
                }
                .ignoresSafeArea().allowsHitTesting(false)
                .zIndex(1)

                if session.cursor.phase == .playing, session.overlay == nil {
                    hotspotLayer(size: geometry.size, compact: compact)
                        .zIndex(2)
                    VStack(spacing: compact ? 5 : 15) {
                        VStack(spacing: compact ? 5 : 15) {
                            header(compact: compact)
                            invitation(compact: compact)
                        }
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: PlaygroundHUDHeight.self, value: proxy.size.height)
                            }
                            .allowsHitTesting(false)
                        }
                        Spacer(minLength: 0)
                        footer(compact: compact)
                    }
                    .padding(.horizontal, television ? 52 : 18)
                    .padding(.vertical, television ? 28 : 8)
                    .zIndex(3)
                }

                if session.cursor.phase == .arriving, session.overlay == nil {
                    arrival(compact: compact)
                        .zIndex(4)
                }
                if session.cursor.phase == .celebrating, session.overlay == nil {
                    postcard(compact: compact)
                        .zIndex(4)
                }
                if let overlay = session.overlay {
                    Color.black.opacity(0.58).ignoresSafeArea().zIndex(5)
                    overlayContent(overlay, compact: compact)
                        .zIndex(6)
                }
            }
        }
        .onPreferenceChange(PlaygroundHUDHeight.self) { topHUDHeight = $0 }
        .preferredColorScheme(.dark)
        .onAppear {
            focusedControl =
                session.cursor.phase == .arriving
                ? "begin" : "target.\(session.cursor.selectedTargetID)"
            speakCurrentState()
        }
        .onChange(of: focusedControl) {
            guard let id = focusedControl, id.hasPrefix("target."), session.overlay == nil else {
                return
            }
            session.send(.selectTarget(String(id.dropFirst(7))))
        }
        .onChange(of: session.cursor.phase) {
            focusedControl =
                session.cursor.phase == .celebrating
                ? "keepPlaying" : "target.\(session.cursor.selectedTargetID)"
            speakCurrentState()
        }
        .onChange(of: session.overlay) {
            if session.overlay == .pause {
                focusedControl = "resume"
            } else if session.overlay == .help, session.currentGoal != nil {
                focusedControl = "help.aim"
            } else if session.overlay == nil {
                focusedControl = "target.\(session.cursor.selectedTargetID)"
            } else {
                focusedControl = "overlay.close"
            }
            speakCurrentState()
        }
        .onChange(of: session.feedback) { speakCurrentState() }
        .onChange(of: narrationEnabled) { speakCurrentState() }
        .onChange(of: voiceOverEnabled) { speakCurrentState() }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                session.send(.pause)
                narrator.stopSpeaking(at: .immediate)
            }
        }
        .onDisappear { narrator.stopSpeaking(at: .immediate) }
        #if os(tvOS)
            .onPlayPauseCommand {
                if session.overlay != .clip { session.send(session.isPaused ? .resume : .pause) }
            }
            .onExitCommand {
                guard session.overlay != .clip else { return }
                if session.overlay != nil {
                    session.send(.closeOverlay)
                } else if session.cursor.carriedItemID != nil {
                    session.send(.cancelManipulation)
                } else {
                    session.send(.pause)
                }
            }
        #endif
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.adventure.title.uppercased())
                    .font(
                        .system(
                            size: television ? 36 : compact ? 19 : 28, weight: .black,
                            design: .rounded)
                    )
                    .foregroundStyle(.white)
                HStack(spacing: 7) {
                    Text("ASTRO ADVENTURE").font(
                        .system(size: compact ? 9 : 12, weight: .semibold, design: .rounded)
                    )
                    .tracking(2).foregroundStyle(.white.opacity(0.85))
                    ForEach(session.adventure.goals) { goal in
                        Image(
                            systemName: session.cursor.completedGoalIDs.contains(goal.id)
                                ? "sparkle" : "circle"
                        )
                        .font(.system(size: compact ? 11 : 16, weight: .bold))
                        .foregroundStyle(
                            session.cursor.completedGoalIDs.contains(goal.id)
                                ? Color.yellow : .white.opacity(0.7)
                        )
                        .accessibilityLabel(
                            "\(goal.title): \(session.cursor.completedGoalIDs.contains(goal.id) ? "discovered" : "waiting to be discovered")"
                        )
                    }
                }
            }
            Spacer(minLength: 6)
            HStack(spacing: compact ? 6 : 12) {
                utility("help", label: "Help", symbol: "lightbulb.fill", compact: compact) {
                    session.send(.requestHelp)
                }
                utility("journal", label: "Journal", symbol: "book.closed.fill", compact: compact) {
                    session.send(.openJournal)
                }
                utility("pause", label: "Pause", symbol: "pause.fill", compact: compact) {
                    session.send(.pause)
                }
            }
            #if os(tvOS)
                .focusSection()
            #endif
        }
        #if os(tvOS)
            .focusSection()
        #endif
    }

    private func invitation(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: compact ? 7 : 12) {
            companionImage
                .resizable().scaledToFit().frame(
                    width: compact ? 45 : television ? 88 : 70,
                    height: compact ? 45 : television ? 88 : 70
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.currentGoal?.title ?? "Make another discovery")
                    .font(
                        .system(
                            size: compact ? 12 : television ? 20 : 15, weight: .heavy,
                            design: .rounded)
                    )
                    .foregroundStyle(.yellow)
                Text(
                    session.currentGoal?.invitation.text(for: session.ageBand)
                        ?? "Your toys are ready. Try a new idea!"
                )
                .font(
                    .system(
                        size: compact ? 14 : television ? 25 : 20, weight: .semibold,
                        design: .rounded)
                )
                .foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("playground.goal")
            }
        }
        .padding(compact ? 8 : 14)
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: compact ? 16 : 24))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 16 : 24).stroke(
                .cyan.opacity(0.85), lineWidth: 2)
        )
        .frame(maxWidth: television ? 760 : compact ? 500 : 660, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }

    private func hotspotLayer(size: CGSize, compact: Bool) -> some View {
        let top: CGFloat = compact ? max(130, topHUDHeight + 36) : television ? 170 : 135
        let bottom: CGFloat = compact ? 150 : television ? 205 : 160
        let inset: CGFloat = television ? 130 : compact ? 50 : 55
        let adjusted =
            compact ? separatedHotspots(size: size, top: top, bottom: bottom, inset: inset) : [:]
        return ZStack {
            ForEach(session.availableTargets) { target in
                let id = "target.\(target.id)"
                let selected = session.cursor.selectedTargetID == target.id
                Button {
                    session.send(.selectTarget(target.id))
                    session.send(.activateTarget)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: target.symbol)
                            .font(.system(size: television ? 26 : compact ? 18 : 24, weight: .bold))
                            .frame(
                                width: television ? 62 : compact ? 44 : 54,
                                height: television ? 62 : compact ? 44 : 54
                            )
                            .background(
                                selected ? Color.yellow : Color.black.opacity(0.78), in: Circle()
                            )
                            .foregroundStyle(selected ? .black : .white)
                            .overlay(
                                Circle().stroke(
                                    selected ? Color.white : Color.cyan, lineWidth: selected ? 3 : 2
                                )
                            )
                            .shadow(color: selected ? .yellow.opacity(0.4) : .clear, radius: 12)
                        if !compact {
                            Text(target.name)
                                .font(
                                    .system(
                                        size: television ? 18 : compact ? 10 : 12, weight: .bold,
                                        design: .rounded)
                                )
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.black.opacity(0.86), in: Capsule())
                                .fixedSize()
                        }
                    }
                    .scaleEffect(focusedControl == id ? 1.12 : 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .focused($focusedControl, equals: id)
                .accessibilityIdentifier("playground.target.\(target.id)")
                .accessibilityLabel("\(target.verb) \(target.name)")
                .accessibilityHint(
                    "Changes the exploration model. You can also aim using the direction controls."
                )
                .accessibilityValue(selected ? "Aimed here" : "")
                .position(
                    x: adjusted[target.id]?.x ?? inset + CGFloat(target.position.x)
                        * max(1, size.width - 2 * inset),
                    y: adjusted[target.id]?.y ?? top + CGFloat(target.position.y)
                        * max(1, size.height - top - bottom)
                )
                #if os(tvOS)
                    .onMoveCommand { direction in moveFocus(direction) }
                #endif
            }
        }
        #if os(tvOS)
            .focusSection()
        #endif
    }

    /// Small phones keep generous independent touch targets. Horizontal relaxation preserves
    /// the scene's vertical arrangement and never changes the core's direction graph.
    private func separatedHotspots(size: CGSize, top: CGFloat, bottom: CGFloat, inset: CGFloat)
        -> [String: CGPoint]
    {
        let targets = session.availableTargets
        var points = targets.map { target in
            CGPoint(
                x: inset + CGFloat(target.position.x) * max(1, size.width - 2 * inset),
                y: top + CGFloat(target.position.y) * max(1, size.height - top - bottom))
        }
        guard points.count > 1 else {
            return Dictionary(uniqueKeysWithValues: zip(targets.map(\.id), points))
        }
        for _ in 0..<8 {
            for first in 0..<(points.count - 1) {
                for second in (first + 1)..<points.count {
                    let dy = abs(points[second].y - points[first].y)
                    guard dy < 54 else { continue }
                    let minimumX = sqrt(54 * 54 - dy * dy)
                    let dx = points[second].x - points[first].x
                    guard abs(dx) < minimumX else { continue }
                    let amount = (minimumX - abs(dx)) / 2 + 0.5
                    let sign: CGFloat = dx < 0 ? -1 : 1
                    points[first].x = min(
                        max(inset, points[first].x - sign * amount), size.width - inset)
                    points[second].x = min(
                        max(inset, points[second].x + sign * amount), size.width - inset)
                }
            }
        }
        return Dictionary(uniqueKeysWithValues: zip(targets.map(\.id), points))
    }

    private func footer(compact: Bool) -> some View {
        VStack(spacing: compact ? 3 : 10) {
            if !session.feedback.isEmpty,
                session.feedback != session.adventure.welcome.text(for: session.ageBand),
                session.feedback != session.currentGoal?.invitation.text(for: session.ageBand)
            {
                Text(session.feedback)
                    .font(
                        .system(
                            size: compact ? 12 : television ? 20 : 16, weight: .semibold,
                            design: .rounded)
                    )
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                    .padding(.horizontal, 12).padding(.vertical, compact ? 5 : 8)
                    .background(.black.opacity(0.8), in: Capsule())
                    .accessibilityIdentifier("playground.feedback")
                    .allowsHitTesting(false)
            }
            HStack(alignment: .bottom, spacing: compact ? 10 : 20) {
                #if !os(tvOS)
                    directionPad(compact: compact)
                #else
                    Label("Move to aim · Press to explore", systemImage: "dpad.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(15).background(
                            .black.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
                #endif
                Spacer(minLength: 2)
                VStack(alignment: .trailing, spacing: 3) {
                    if let target = session.selectedTarget {
                        Text(target.name).font(
                            .system(size: compact ? 11 : 17, weight: .bold, design: .rounded)
                        ).foregroundStyle(.white).allowsHitTesting(false)
                    }
                    Button {
                        session.send(.activateTarget)
                    } label: {
                        Label(
                            session.contextualVerb,
                            systemImage: session.selectedTarget?.symbol ?? "sparkles"
                        )
                        .font(
                            .system(
                                size: television ? 35 : compact ? 21 : 28, weight: .heavy,
                                design: .rounded)
                        )
                        .padding(.horizontal, television ? 36 : 24).padding(
                            .vertical, television ? 20 : compact ? 10 : 15)
                    }
                    .buttonStyle(PlaygroundActionStyle(highlighted: focusedControl == "action"))
                    .focused($focusedControl, equals: "action")
                    .accessibilityIdentifier("playground.action")
                    .disabled(session.selectedTarget == nil)
                    #if os(tvOS)
                        .onMoveCommand { direction in
                            switch direction {
                            case .up:
                                focusedControl = "target.\(session.cursor.selectedTargetID)"
                            case .left: focusedControl = "help"
                            case .right: focusedControl = "pause"
                            default: break
                            }
                        }
                    #endif
                }
            }
            #if os(tvOS)
                .focusSection()
            #endif
            Text(modelFootnote).font(
                .system(size: compact ? 9 : television ? 14 : 11, weight: .medium)
            )
            .foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)
            .accessibilityIdentifier("playground.modelLabel")
        }
    }

    private var modelFootnote: String {
        switch session.adventure.destinationID {
        case "mars":
            session.cursor.modelSettings["mars.water", default: 0] % 2 == 1
                ? "Ancient water model · We are imagining Mars long ago."
                : "Exploration model · Rocks and distances are simplified."
        case "mercury":
            "Impact and temperature models · We are testing ideas, not changing Mercury."
        default: "Ring model · Sizes, distances and speeds are simplified."
        }
    }

    private func directionPad(compact: Bool) -> some View {
        HStack(spacing: 3) {
            direction(.left, symbol: "arrow.left", compact: compact)
            VStack(spacing: 3) {
                direction(.up, symbol: "arrow.up", compact: compact)
                direction(.down, symbol: "arrow.down", compact: compact)
            }
            direction(.right, symbol: "arrow.right", compact: compact)
        }
        .padding(5).background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
    }

    private func direction(_ direction: ExplorationDirection, symbol: String, compact: Bool)
        -> some View
    {
        Button {
            session.send(.moveTarget(direction))
        } label: {
            Image(systemName: symbol).font(.system(size: 17, weight: .bold))
                .frame(width: 44, height: 44).background(
                    .white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain).accessibilityLabel("Aim \(direction.rawValue)")
        .accessibilityIdentifier("playground.move.\(direction.rawValue)")
    }

    private func utility(
        _ id: String, label: String, symbol: String, compact: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(
                    .system(size: television ? 23 : compact ? 17 : 21, weight: .bold)
                )
                .frame(width: television ? 58 : 44, height: television ? 58 : 44)
                .background(
                    focusedControl == id ? Color.white : Color.black.opacity(0.78), in: Circle()
                )
                .foregroundStyle(focusedControl == id ? .black : .cyan)
                .overlay(Circle().stroke(.cyan.opacity(0.9), lineWidth: 2))
                if !compact {
                    Text(label).font(.system(size: television ? 17 : 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).focused($focusedControl, equals: id)
        .accessibilityLabel(label).accessibilityIdentifier("playground.\(id)")
        #if os(tvOS)
            .onMoveCommand { direction in
                if direction == .down {
                    focusedControl = "target.\(session.cursor.selectedTargetID)"
                } else if direction == .left || direction == .right {
                    let controls = ["help", "journal", "pause"]
                    if let index = controls.firstIndex(of: id) {
                        let offset = direction == .left ? -1 : 1
                        focusedControl = controls[min(max(index + offset, 0), controls.count - 1)]
                    }
                }
            }
        #endif
    }

    private func arrival(compact: Bool) -> some View {
        modal(compact: compact) {
            companionImage.resizable().scaledToFit()
                .frame(height: compact ? 60 : 130).accessibilityHidden(true)
            Text(session.adventure.title).font(
                .system(size: compact ? 24 : 38, weight: .heavy, design: .rounded)
            ).foregroundStyle(.yellow)
            Text(session.adventure.welcome.text(for: session.ageBand)).font(
                .system(size: compact ? 16 : 24, weight: .medium, design: .rounded)
            )
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Button {
                session.send(.begin)
            } label: {
                Label("Let's explore!", systemImage: "sparkles")
            }
            .buttonStyle(PlaygroundActionStyle(highlighted: focusedControl == "begin"))
            .focused($focusedControl, equals: "begin").accessibilityIdentifier("playground.begin")
            Button("Worlds", action: leave).buttonStyle(.bordered).accessibilityIdentifier(
                "playground.worlds")
        }
    }

    private func postcard(compact: Bool) -> some View {
        // The existing frozen world is the postcard canvas; it never becomes a blank second render.
        VStack(spacing: compact ? 8 : 18) {
            VStack(spacing: 5) {
                Label("A discovery to keep", systemImage: "sparkles")
                    .font(compact ? .caption.bold() : .title3.bold()).foregroundStyle(.cyan)
                Text(session.adventure.postcardTitle)
                    .font(.system(size: compact ? 25 : 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center).foregroundStyle(.yellow)
                    .accessibilityIdentifier("playground.postcard")
            }
            .padding(compact ? 10 : 18)
            .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 22))
            Spacer(minLength: compact ? 70 : 180)
            VStack(spacing: compact ? 8 : 14) {
                Text("Your discoveries are safe in your journal.")
                    .font(compact ? .caption.bold() : .title3.bold()).foregroundStyle(.white)
                HStack(spacing: 20) {
                    Button {
                        session.send(.keepPlaying)
                    } label: {
                        Label("Keep playing", systemImage: "arrow.trianglehead.clockwise")
                    }
                    .buttonStyle(
                        PlaygroundActionStyle(highlighted: focusedControl == "keepPlaying")
                    )
                    .focused($focusedControl, equals: "keepPlaying")
                    .accessibilityIdentifier("playground.keepPlaying")
                    Button("Worlds", action: leave).buttonStyle(.bordered)
                        .accessibilityIdentifier("playground.worlds")
                }
                .font(.system(size: compact ? 18 : 27, weight: .bold, design: .rounded))
                #if os(tvOS)
                    .focusSection()
                #endif
            }
            .padding(compact ? 12 : 20)
            .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 22))
        }
        .padding(.horizontal, compact ? 22 : 52)
        .padding(.top, compact ? 12 : 70)
        .padding(.bottom, compact ? 12 : 65)
    }

    @ViewBuilder
    private func overlayContent(_ overlay: ExplorationOverlay, compact: Bool) -> some View {
        switch overlay {
        case .clip:
            ExplorationClipView(
                session: session,
                video: videoLessons.first { $0.id == session.adventure.videoLessonID })
        case .pause:
            modal(compact: compact) {
                Label("Taking a little break", systemImage: "pause.circle.fill").font(
                    .title2.bold()
                ).foregroundStyle(.cyan)
                Text("Your discoveries are safe. Come back when you're ready.")
                    .multilineTextAlignment(.center)
                Button {
                    session.send(.resume)
                } label: {
                    Label("Back to exploring", systemImage: "play.fill")
                }
                .buttonStyle(PlaygroundActionStyle(highlighted: focusedControl == "resume"))
                .focused($focusedControl, equals: "resume").accessibilityIdentifier(
                    "playground.resume")
                HStack(spacing: 16) {
                    Button {
                        narrationEnabled.toggle()
                    } label: {
                        Label(
                            narrationEnabled ? "Sound On" : "Sound Off",
                            systemImage: narrationEnabled
                                ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    .buttonStyle(.bordered).accessibilityIdentifier("playground.narration")
                    Button {
                        session.send(.resume)
                        session.send(.resetToy)
                    } label: {
                        Label("Reset toys", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered).accessibilityIdentifier("playground.reset")
                }
                Button("Worlds", action: leave).buttonStyle(.bordered).accessibilityIdentifier(
                    "playground.worlds")
            }
        case .help:
            modal(compact: compact) {
                Label("Try this idea", systemImage: "lightbulb.fill").font(.title2.bold())
                    .foregroundStyle(.yellow)
                Text(
                    session.currentGoal?.hint.text(for: session.ageBand)
                        ?? "Aim at a toy and press its action. Your discoveries stay in the journal."
                )
                .font(compact ? .body : .title3).multilineTextAlignment(.center).fixedSize(
                    horizontal: false, vertical: true
                )
                .accessibilityIdentifier("playground.hint")
                if let goal = session.currentGoal {
                    Button {
                        session.send(.closeOverlay)
                        session.send(.selectTarget(goal.suggestedTargetID))
                        focusedControl = "target.\(session.cursor.selectedTargetID)"
                    } label: {
                        Label("Aim there", systemImage: "scope")
                    }
                    .buttonStyle(PlaygroundActionStyle(highlighted: focusedControl == "help.aim"))
                    .focused($focusedControl, equals: "help.aim").accessibilityIdentifier(
                        "playground.help.aim")
                }
                if session.adventure.videoLessonID != nil {
                    Button {
                        session.send(.closeOverlay)
                        session.send(.openClip)
                    } label: {
                        Label("Watch a planet film", systemImage: "play.rectangle.fill")
                    }
                    .buttonStyle(.bordered).accessibilityIdentifier("playground.clip")
                }
                closeOverlayButton()
            }
        case .journal:
            modal(compact: compact) {
                Label("My discovery journal", systemImage: "book.closed.fill").font(.title2.bold())
                    .foregroundStyle(.yellow)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(
                            session.adventure.goals.filter {
                                session.cursor.completedGoalIDs.contains($0.id)
                            }
                        ) { goal in
                            VStack(alignment: .leading, spacing: 6) {
                                Label(goal.title, systemImage: "sparkles").font(.headline)
                                    .foregroundStyle(.cyan)
                                Text(goal.explanation.text(for: session.ageBand)).font(.body)
                                Text("Science source · NASA field guide").font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        if session.cursor.completedGoalIDs.isEmpty {
                            Text("Your first discovery is waiting. Try a toy in the world!").font(
                                .body)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: compact ? 100 : 300)
                closeOverlayButton()
            }
        }
    }

    private func closeOverlayButton() -> some View {
        Button {
            session.send(.closeOverlay)
        } label: {
            Label("Back to exploring", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered).focused($focusedControl, equals: "overlay.close")
        .accessibilityIdentifier("playground.overlay.close")
    }

    private func modal<Content: View>(compact: Bool, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(spacing: compact ? 10 : 20, content: content)
            .font(.system(size: compact ? 16 : 24, weight: .semibold, design: .rounded))
            .padding(compact ? 18 : 34)
            .frame(maxWidth: compact ? 540 : 820)
            .background(.black.opacity(0.91), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.cyan.opacity(0.8), lineWidth: 2))
            .padding(compact ? 12 : 40)
            #if os(tvOS)
                .focusSection()
            #endif
    }

    private func leave() {
        narrator.stopSpeaking(at: .immediate)
        session.send(.pause)
        onLeave()
    }

    private var companionImage: Image {
        guard let url = Bundle.module.url(forResource: "explorer-companion", withExtension: "png")
        else {
            return Image(systemName: "face.smiling.fill")
        }
        #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) { return Image(uiImage: image) }
        #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) { return Image(nsImage: image) }
        #endif
        return Image(systemName: "face.smiling.fill")
    }

    #if os(tvOS)
        private func moveFocus(_ direction: MoveCommandDirection) {
            guard session.overlay == nil else { return }
            let mapped: ExplorationDirection
            switch direction {
            case .up: mapped = .up
            case .down: mapped = .down
            case .left: mapped = .left
            case .right: mapped = .right
            default: return
            }
            let previous = session.cursor.selectedTargetID
            session.send(.moveTarget(mapped))
            if previous != session.cursor.selectedTargetID {
                focusedControl = "target.\(session.cursor.selectedTargetID)"
            } else {
                switch direction {
                case .up, .left: focusedControl = "help"
                case .right: focusedControl = "pause"
                default: focusedControl = "action"
                }
            }
        }
    #endif

    private func speakCurrentState() {
        narrator.stopSpeaking(at: .immediate)
        guard narrationEnabled, !voiceOverEnabled, scenePhase == .active,
            !session.isPaused || session.overlay == .help || session.overlay == .journal
        else { return }
        let text: String
        switch session.overlay {
        case .help:
            text =
                session.currentGoal?.hint.text(for: session.ageBand)
                ?? "Aim at a toy and press its action."
        case .journal: text = "Your discovery journal."
        case .clip, .pause: return
        case nil:
            if session.cursor.phase == .arriving {
                text = session.adventure.welcome.text(for: session.ageBand)
            } else if session.cursor.phase == .celebrating {
                text =
                    "\(session.adventure.postcardTitle). Your discoveries are safe in your journal."
            } else {
                text =
                    session.feedback.isEmpty
                    ? session.currentGoal?.invitation.text(for: session.ageBand)
                        ?? "Try another idea!" : session.feedback
            }
        }
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = session.ageBand == .ages4To6 ? 0.43 : 0.48
        narrator.speak(utterance)
    }
}

private struct PlaygroundHUDHeight: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlaygroundActionStyle: ButtonStyle {
    var highlighted: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(highlighted ? Color.white : Color.yellow, in: Capsule())
            .overlay(Capsule().stroke(.white, lineWidth: highlighted ? 4 : 2))
            .shadow(color: .yellow.opacity(highlighted ? 0.4 : 0.15), radius: highlighted ? 15 : 6)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
    }
}
