import AstroGameCore
import Foundation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// An ungraded controlled experiment. It never writes scores, checkpoints or learning progress.
@MainActor
public struct GravityPlaygroundView: View {
    private let onLeave: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var selectedWorld = GravityWorld.earth
    @State private var angleDegrees = 45.0
    @State private var speedMetersPerSecond = 6.0
    @State private var prediction: GravityPrediction?
    @State private var clock = GravityFlightClock()
    @State private var playbackTask: Task<Void, Never>?
    @State private var isVisible = false
    @FocusState private var focusedControl: String?

    public init(onLeave: @escaping () -> Void) {
        self.onLeave = onLeave
    }

    private var television: Bool {
        #if os(tvOS)
            true
        #else
            false
        #endif
    }

    private var launch: GravityLaunch {
        GravityLaunch(
            angleDegrees: angleDegrees, speedMetersPerSecond: speedMetersPerSecond,
            massKilograms: 1)
    }

    private var trajectory: GravityTrajectory {
        clock.trajectory ?? GravityTrajectory(world: selectedWorld, launch: launch)
    }

    private var canAdjust: Bool { clock.phase == .ready || clock.phase == .landed }

    public var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = television ? 64 : 20
            let availableWidth = max(1, min(1700, geometry.size.width) - 2 * horizontalPadding)
            let wide = availableWidth >= 860 && !dynamicTypeSize.isAccessibilitySize
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.10, blue: 0.23), .black],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(alignment: .leading, spacing: television ? 24 : 18) {
                            header
                            worldPicker(
                                horizontal: availableWidth >= 660
                                    && !dynamicTypeSize.isAccessibilitySize)
                            if wide {
                                HStack(alignment: .top, spacing: 24) {
                                    flightField(height: television ? 390 : 300)
                                        .frame(width: availableWidth * 0.56)
                                    experimentControls(showComparison: true)
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                experimentControls(showComparison: false)
                                flightField(height: geometry.size.height < 520 ? 140 : 260)
                                if clock.phase == .landed {
                                    comparison
                                        .padding(television ? 24 : 16)
                                        .background(
                                            .white.opacity(0.06),
                                            in: RoundedRectangle(cornerRadius: 26))
                                }
                            }
                            assumptions
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, television ? 36 : 18)
                        .frame(maxWidth: 1700)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .accessibilityIdentifier("gravity.playground")
                    .onChange(of: clock.phase) {
                        if clock.phase == .flying, !wide {
                            scroll.scrollTo("gravity.flight-controls", anchor: .center)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isVisible = true
            focusedControl = "world.\(selectedWorld.rawValue)"
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                pauseFlight()
                focusedControl = nil
            } else {
                // Foregrounding never automatically resumes a child's experiment.
                focusedControl = clock.phase == .paused ? "resume" : primaryControlID
            }
        }
        .onDisappear {
            isVisible = false
            stopPlayback()
            clock.reset()
        }
        #if os(tvOS)
            .onPlayPauseCommand {
                if clock.phase == .flying {
                    pauseFlight()
                } else if clock.phase == .paused {
                    resumeFlight()
                }
            }
            .onExitCommand { leave() }
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    title.fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 12)
                    worldsButton.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 12) {
                    title
                    worldsButton
                }
            }
            Text("Same ball. Different gravity. Make a guess, try it, then compare!")
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var title: some View {
        Text("Gravity Playground")
            .font(.largeTitle.weight(.black))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var worldsButton: some View {
        actionButton("Worlds", symbol: "globe", id: "worlds", action: leave)
    }

    @ViewBuilder
    private func worldPicker(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                HStack(alignment: .top, spacing: 14) { worldButtons }
            } else {
                VStack(spacing: 12) { worldButtons }
            }
        }
        .modifier(GravityFocusSection())
    }

    private var worldButtons: some View {
        ForEach(GravityWorld.allCases) { world in
            Button {
                guard canAdjust else { return }
                if selectedWorld != world {
                    clearObservation()
                    selectedWorld = world
                }
            } label: {
                HStack(spacing: 14) {
                    GravityPlanetMark(world: world)
                        .frame(width: television ? 72 : 48, height: television ? 72 : 48)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(world.displayName).font(.title2.weight(.bold))
                        Text(world.kindName.capitalized).font(.caption)
                        Text("\(percentage(for: world)) of Earth’s pull")
                            .font(.subheadline)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(
                GravityButtonStyle(
                    highlighted: focusedControl == "world.\(world.rawValue)",
                    selected: selectedWorld == world)
            )
            .focused($focusedControl, equals: "world.\(world.rawValue)")
            .disabled(!canAdjust)
            .accessibilityIdentifier("gravity.world.\(world.rawValue)")
            .accessibilityLabel(
                "\(world.displayName), \(world.kindName), \(percentage(for: world)) of Earth’s gravity"
            )
            .accessibilityHint("Keeps the same ball, angle and starting speed.")
            .accessibilityAddTraits(selectedWorld == world ? .isSelected : [])
        }
    }

    private func flightField(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Height ↑").font(.caption.weight(.semibold))
                Spacer()
                Text("One scale for every world").font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            GravityFlightField(
                trajectory: trajectory, elapsedSeconds: clock.elapsedSeconds,
                hasLaunched: clock.trajectory != nil, reduceMotion: reduceMotion,
                television: television
            )
            .frame(height: height)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Gravity flight comparison")
            .accessibilityValue(fieldDescription)
            .accessibilityIdentifier("gravity.field")
            HStack(alignment: .top) {
                Text("Distance →")
            }
            .font(.caption).foregroundStyle(.white.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            Text(
                "Longest flight at these settings: \(number(GravityTrajectory(world: .moon, launch: launch).range)) m"
            )
            .font(.caption).foregroundStyle(.white.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { fieldLegend }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 10) { fieldLegend }
            }
            if reduceMotion {
                Text("Motion reduced: still flight paths show the comparison.")
                    .font(.caption).foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(television ? 24 : 16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 26))
    }

    private var fieldLegend: some View {
        Group {
            HStack(spacing: 8) {
                Rectangle().fill(.cyan).frame(width: 26, height: 4)
                Text("\(selectedWorld.displayName) · solid path")
            }
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { _ in
                        Rectangle().fill(.white.opacity(0.75)).frame(width: 7, height: 3)
                    }
                }
                Text("Earth · dashed path")
            }
        }
        .font(.caption).foregroundStyle(.white)
    }

    private func experimentControls(showComparison: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Same ball · Mass stays 1 kg")
                .font(.headline).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Mass stays one kilogram. The same ball on every world.")
            if clock.phase == .ready {
                predictionControls
            } else {
                Text(statusText)
                    .font(.title3.weight(.bold)).foregroundStyle(.cyan)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("gravity.status")
            }
            launchSettings
            flightControls
                .id("gravity.flight-controls")
            if clock.phase == .landed, showComparison {
                comparison
            } else if clock.phase == .paused {
                Text(
                    "Your ball stays here. Choose Resume to keep watching, or Try again to start over."
                )
                .font(.body).foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(television ? 24 : 16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 26))
    }

    private var predictionControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                selectedWorld == .earth
                    ? "Try Earth first. Then choose another world!"
                    : "Will it stay up longer than on Earth?"
            )
            .font(.title3.weight(.bold)).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            ForEach(GravityPrediction.allCases) { choice in
                Button {
                    prediction = choice
                } label: {
                    Text(choice.rawValue)
                        .font(.headline).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(
                    GravityButtonStyle(
                        highlighted: focusedControl == "prediction.\(choice.id)",
                        selected: prediction == choice)
                )
                .focused($focusedControl, equals: "prediction.\(choice.id)")
                .accessibilityIdentifier("gravity.prediction.\(choice.id)")
                .accessibilityAddTraits(prediction == choice ? .isSelected : [])
            }
            Text("Make a guess, or launch and explore.")
                .font(.caption).foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(GravityFocusSection())
    }

    private var launchSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepper(
                title: "Angle", value: "\(Int(angleDegrees))°", id: "angle",
                canDecrease: angleDegrees > GravityLaunch.angleRange.lowerBound,
                canIncrease: angleDegrees < GravityLaunch.angleRange.upperBound,
                decrease: { adjustAngle(-15) }, increase: { adjustAngle(15) })
            stepper(
                title: "Starting speed", value: "\(Int(speedMetersPerSecond)) m/s", id: "speed",
                canDecrease: speedMetersPerSecond > GravityLaunch.speedRange.lowerBound,
                canIncrease: speedMetersPerSecond < GravityLaunch.speedRange.upperBound,
                decrease: { adjustSpeed(-2) }, increase: { adjustSpeed(2) })
            Text("Same starting speed and angle on every world.")
                .font(.caption).foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stepper(
        title: String, value: String, id: String, canDecrease: Bool, canIncrease: Bool,
        decrease: @escaping () -> Void, increase: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title): \(value)")
                .font(.headline).monospacedDigit().foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                adjustmentButton(
                    title: "Decrease \(title.lowercased())", symbol: "minus", id: "\(id).minus",
                    disabled: !canAdjust || !canDecrease, action: decrease)
                adjustmentButton(
                    title: "Increase \(title.lowercased())", symbol: "plus", id: "\(id).plus",
                    disabled: !canAdjust || !canIncrease, action: increase)
            }
            .modifier(GravityFocusSection())
        }
    }

    private func adjustmentButton(
        title: String, symbol: String, id: String, disabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: television ? 44 : 32)
        }
        .buttonStyle(GravityButtonStyle(highlighted: focusedControl == id))
        .focused($focusedControl, equals: id)
        .disabled(disabled)
        .accessibilityLabel(title)
        .accessibilityIdentifier("gravity.\(id)")
    }

    private var flightControls: some View {
        VStack(spacing: 12) {
            if clock.phase == .ready {
                actionButton("Launch!", symbol: "arrow.up.right", id: "launch", prominent: true) {
                    startFlight(replay: false)
                }
            } else {
                if clock.phase == .flying {
                    actionButton("Pause", symbol: "pause.fill", id: "pause", action: pauseFlight)
                } else if clock.phase == .paused {
                    actionButton(
                        "Resume", symbol: "play.fill", id: "resume", prominent: true,
                        action: resumeFlight)
                }
                if clock.phase != .flying {
                    actionButton(
                        "Try again", symbol: "arrow.clockwise", id: "relaunch",
                        prominent: clock.phase == .landed
                    ) { startFlight(replay: true) }
                }
            }
        }
        .modifier(GravityFocusSection())
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let prediction {
                Text("Your guess: \(prediction.rawValue.lowercased()). What did you notice?")
                    .font(.body).foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            metric("Height", value: "\(number(trajectory.peakHeight)) m")
            metric("Distance", value: "\(number(trajectory.range)) m")
            metric("Hang time", value: "\(number(trajectory.flightTime)) seconds")
            metric("Weight: pull on this ball", value: "\(number(trajectory.weight)) N")
            Text(
                "The ball’s weight here is \(percentage(for: selectedWorld)) of its Earth weight. Weight is a pull, measured in newtons (N). Its mass stays 1 kg."
            )
            .font(.body).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            Text(comparisonExplanation)
                .font(.body).foregroundStyle(.cyan)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("gravity.comparison")
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).foregroundStyle(.white.opacity(0.8))
            Text(value).font(.title3.weight(.bold)).monospacedDigit().foregroundStyle(.white)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var assumptions: some View {
        Text(
            "Our pretend test uses flat ground and steady gravity. We leave out air pushing on the ball. These drawings compare a ball’s motion; they cannot change how your body feels here."
        )
        .font(.caption).foregroundStyle(.white.opacity(0.8))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("gravity.assumptions")
    }

    private func actionButton(
        _ title: String, symbol: String, id: String, prominent: Bool = false,
        disabled: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: television ? 40 : 28)
        }
        .buttonStyle(
            GravityButtonStyle(highlighted: focusedControl == id, prominent: prominent)
        )
        .focused($focusedControl, equals: id)
        .disabled(disabled)
        .accessibilityIdentifier("gravity.\(id)")
    }

    private var primaryControlID: String {
        switch clock.phase {
        case .ready: "launch"
        case .flying: "pause"
        case .paused: "resume"
        case .landed: "relaunch"
        }
    }

    private var statusText: String {
        switch clock.phase {
        case .ready: "Ready to try"
        case .flying: reduceMotion ? "Watching the still paths" : "Watch the ball!"
        case .paused: "Paused — take your time"
        case .landed: "Now compare your paths!"
        }
    }

    private var comparisonExplanation: String {
        if selectedWorld == .earth {
            return "This is our Earth baseline. Choose Moon or Mars and keep the same launch."
        }
        let ratio = trajectory.flightTime / trajectory.earthComparison.flightTime
        return
            "\(selectedWorld.displayName)’s gentler pull keeps this launch up about \(number(ratio)) times as long as Earth’s."
    }

    private var fieldDescription: String {
        switch clock.phase {
        case .ready:
            "\(selectedWorld.displayName) selected. Dashed Earth comparison path. Same one kilogram ball, angle and starting speed."
        case .flying:
            reduceMotion
                ? "Static flight paths for \(selectedWorld.displayName) and Earth."
                : "The ball is in flight on \(selectedWorld.displayName). The dashed path is Earth."
        case .paused:
            "Flight paused on \(selectedWorld.displayName). Choose Resume to continue."
        case .landed:
            "\(selectedWorld.displayName) flight complete. Height \(number(trajectory.peakHeight)) meters. Distance \(number(trajectory.range)) meters. Hang time \(number(trajectory.flightTime)) seconds."
        }
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    private func percentage(for world: GravityWorld) -> String {
        world == .earth ? "100%" : "\(number(world.weightRelativeToEarth * 100))%"
    }

    private func clearObservation() {
        stopPlayback()
        clock.reset()
        prediction = nil
    }

    private func adjustAngle(_ delta: Double) {
        guard canAdjust else { return }
        let next = GravityLaunch(angleDegrees: angleDegrees + delta).angleDegrees
        guard next != angleDegrees else { return }
        clearObservation()
        angleDegrees = next
    }

    private func adjustSpeed(_ delta: Double) {
        guard canAdjust else { return }
        let next = GravityLaunch(speedMetersPerSecond: speedMetersPerSecond + delta)
            .speedMetersPerSecond
        guard next != speedMetersPerSecond else { return }
        clearObservation()
        speedMetersPerSecond = next
    }

    private func startFlight(replay: Bool) {
        guard isVisible, scenePhase == .active, clock.phase != .flying else { return }
        let token: UInt64?
        if replay {
            guard clock.phase == .paused || clock.phase == .landed else { return }
            token = clock.relaunch(
                world: selectedWorld, launch: launch, at: ProcessInfo.processInfo.systemUptime)
        } else {
            token = clock.launch(
                world: selectedWorld, launch: launch, at: ProcessInfo.processInfo.systemUptime)
        }
        guard let token else { return }
        stopPlayback()
        focusedControl = "pause"
        runPlayback(generation: token)
    }

    private func runPlayback(generation token: UInt64) {
        playbackTask = Task { @MainActor in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                guard token == clock.generation, isVisible, clock.phase == .flying else { return }
                guard scenePhase == .active else {
                    pauseFlight()
                    return
                }
                if clock.advance(to: ProcessInfo.processInfo.systemUptime, generation: token) {
                    playbackTask = nil
                    landed()
                    return
                }
            }
        }
    }

    private func pauseFlight() {
        guard clock.phase == .flying else { return }
        let token = clock.generation
        let didLand = clock.pause(at: ProcessInfo.processInfo.systemUptime, generation: token)
        stopPlayback()
        if didLand { landed() } else { focusedControl = "resume" }
    }

    private func resumeFlight() {
        guard isVisible, scenePhase == .active else { return }
        let token = clock.generation
        guard clock.resume(at: ProcessInfo.processInfo.systemUptime, generation: token) else {
            return
        }
        stopPlayback()
        focusedControl = "pause"
        runPlayback(generation: token)
    }

    private func landed() {
        focusedControl = "relaunch"
        #if canImport(UIKit)
            if voiceOverEnabled, scenePhase == .active {
                UIAccessibility.post(notification: .announcement, argument: fieldDescription)
            }
        #endif
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func leave() {
        guard isVisible else { return }
        isVisible = false
        stopPlayback()
        clock.reset()
        onLeave()
    }
}

private enum GravityPrediction: String, CaseIterable, Identifiable {
    case longer = "Longer"
    case same = "About the same"
    case shorter = "Shorter"

    var id: String {
        switch self {
        case .longer: "longer"
        case .same: "same"
        case .shorter: "shorter"
        }
    }
}

private struct GravityFocusSection: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
            content.focusSection()
        #else
            content
        #endif
    }
}

private struct GravityButtonStyle: ButtonStyle {
    var highlighted: Bool
    var selected = false
    var prominent = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 18).padding(.vertical, 14)
            .background(
                prominent
                    ? Color.blue : selected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        highlighted ? .white : selected ? .cyan : .white.opacity(0.2),
                        lineWidth: highlighted ? 3 : 1)
            )
            .opacity(enabled ? configuration.isPressed ? 0.8 : 1 : 0.45)
    }
}

private struct GravityFlightField: View {
    let trajectory: GravityTrajectory
    let elapsedSeconds: Double
    let hasLaunched: Bool
    let reduceMotion: Bool
    let television: Bool

    var body: some View {
        Canvas { context, size in
            let radius: CGFloat = television ? 13 : 9
            let projection = GravityProjection(
                launch: trajectory.launch, width: Double(size.width), height: Double(size.height),
                padding: Double(radius + 14))
            let groundY = CGFloat(projection.height - projection.padding)
            let terrain = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
            context.fill(Path(terrain), with: .color(terrainColor.opacity(0.4)))
            var ground = Path()
            ground.move(to: CGPoint(x: CGFloat(projection.padding), y: groundY))
            ground.addLine(to: CGPoint(x: size.width - CGFloat(projection.padding), y: groundY))
            context.stroke(ground, with: .color(.white.opacity(0.6)), lineWidth: 2)
            for index in 0...4 {
                let x = CGFloat(
                    projection.padding + projection.maximumRangeMeters * Double(index) / 4
                        * projection.pointsPerMeter)
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: groundY))
                tick.addLine(to: CGPoint(x: x, y: groundY + 6))
                context.stroke(tick, with: .color(.white.opacity(0.6)), lineWidth: 2)
            }

            let earth = trajectory.earthComparison
            drawPath(
                earth.sampledPositions(), projection: projection, radius: radius,
                context: context, color: .white.opacity(0.65), dashed: true)
            if hasLaunched {
                let positions: [GravityPosition]
                if reduceMotion {
                    positions = trajectory.sampledPositions()
                } else {
                    let current = trajectory.position(elapsed: elapsedSeconds)
                    positions =
                        trajectory.sampledPositions().filter { $0.xMeters <= current.xMeters } + [
                            current
                        ]
                }
                drawPath(
                    positions, projection: projection, radius: radius, context: context,
                    color: .cyan, dashed: false)
                let earthPosition = earth.position(
                    elapsed: reduceMotion ? earth.flightTime : elapsedSeconds)
                drawBall(
                    at: point(earthPosition, projection: projection, radius: radius),
                    radius: radius, ghost: true, context: context)
            }
            let ballPosition = trajectory.position(
                elapsed: hasLaunched ? reduceMotion ? trajectory.flightTime : elapsedSeconds : 0)
            drawBall(
                at: point(ballPosition, projection: projection, radius: radius),
                radius: radius, ghost: false, context: context)
        }
        .allowsHitTesting(false)
    }

    private var terrainColor: Color {
        switch trajectory.world {
        case .earth: .green
        case .moon: .gray
        case .mars: .orange
        }
    }

    private func point(
        _ position: GravityPosition, projection: GravityProjection, radius: CGFloat
    ) -> CGPoint {
        let projected = projection.project(position)
        return CGPoint(x: projected.x, y: projected.y - Double(radius))
    }

    private func drawPath(
        _ positions: [GravityPosition], projection: GravityProjection, radius: CGFloat,
        context: GraphicsContext, color: Color, dashed: Bool
    ) {
        var path = Path()
        for (index, position) in positions.enumerated() {
            let point = point(position, projection: projection, radius: radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        context.stroke(
            path, with: .color(color),
            style: StrokeStyle(
                lineWidth: television ? 4 : 3, lineCap: .round, dash: dashed ? [9, 8] : []))
    }

    private func drawBall(at point: CGPoint, radius: CGFloat, ghost: Bool, context: GraphicsContext)
    {
        let rect = CGRect(
            x: point.x - radius, y: point.y - radius, width: 2 * radius, height: 2 * radius)
        let ball = Path(ellipseIn: rect)
        if ghost {
            context.stroke(
                ball, with: .color(.white.opacity(0.8)),
                style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
        } else {
            context.fill(ball, with: .color(.white))
            context.stroke(ball, with: .color(.cyan), lineWidth: 3)
            let stripe = CGRect(
                x: point.x - radius * 0.55, y: point.y - radius * 0.75, width: radius * 0.5,
                height: radius * 1.5)
            context.fill(Path(roundedRect: stripe, cornerRadius: radius / 4), with: .color(.purple))
        }
    }
}

private struct GravityPlanetMark: View {
    let world: GravityWorld

    var body: some View {
        Canvas { context, size in
            let diameter = min(size.width, size.height)
            let bounds = CGRect(x: 1, y: 1, width: diameter - 2, height: diameter - 2)
            let disc = Path(ellipseIn: bounds)
            let color: Color = world == .earth ? .blue : world == .moon ? .gray : .orange
            context.fill(disc, with: .color(color))
            context.clip(to: disc)
            for index in 0..<4 {
                let x = diameter * [0.18, 0.57, 0.36, 0.72][index]
                let y = diameter * [0.22, 0.48, 0.73, 0.18][index]
                let width = diameter * (world == .moon ? 0.18 : 0.3)
                let patch = CGRect(
                    x: x, y: y, width: width, height: width * (world == .earth ? 1.35 : 0.8))
                context.fill(
                    Path(ellipseIn: patch),
                    with: .color(
                        world == .earth
                            ? .green : world == .moon ? .black.opacity(0.25) : .red.opacity(0.45)))
            }
            context.stroke(disc, with: .color(.white.opacity(0.7)), lineWidth: 2)
        }
    }
}
