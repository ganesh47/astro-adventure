import AVFoundation
import AstroContent
import AstroGameCore
import AstroWorld
import SwiftUI

public struct GameRootView: View {
    private enum ExplorerSection: String, CaseIterable, Identifiable {
        case solarSystem
        case technologyLab

        var id: String { rawValue }

        var title: String {
            switch self {
            case .solarSystem: "Solar System"
            case .technologyLab: "Technology Lab"
            }
        }

        var systemImage: String {
            switch self {
            case .solarSystem: "circle.hexagongrid.fill"
            case .technologyLab: "antenna.radiowaves.left.and.right"
            }
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    #if os(tvOS)
        @ScaledMetric(relativeTo: .headline) private var destinationCardWidth = 280.0
        private let menuMaximumWidth = 1100.0
        private let destinationFocusInset = 40.0
        private let destinationVerticalInset = 24.0
    #else
        @ScaledMetric(relativeTo: .headline) private var destinationCardWidth = 176.0
        private let menuMaximumWidth = 760.0
        private let destinationFocusInset = 12.0
        private let destinationVerticalInset = 12.0
    #endif
    @State private var session: MissionSession
    @State private var playground: ExplorationSession?
    @State private var showingPassport = false
    @State private var showingGravity = false
    @State private var isPaused = false
    @FocusState private var resumeFocused: Bool
    @State private var selectedSection: ExplorerSection = .solarSystem
    @FocusState private var primaryActionFocused: Bool
    @FocusState private var focusedDestinationID: String?
    private let onProgressChanged: (GameProgress) -> Void

    public init(
        lessons: [DestinationLesson],
        progress: GameProgress? = nil,
        planetMissions: [PlanetMission] = [],
        videoLessons: [VideoLesson] = [],
        onProgressChanged: @escaping (GameProgress) -> Void = { _ in }
    ) {
        _session = State(
            initialValue: MissionSession(
                lessons: lessons,
                progress: progress,
                quizProvider: QuizRoundCatalog.quizzes,
                planetMissions: planetMissions,
                videoLessons: videoLessons,
                questionChallengeAllowance: Self.questionChallengeAllowance
            )
        )
        self.onProgressChanged = onProgressChanged
    }

    private static var questionChallengeAllowance: Double {
        #if DEBUG
            let process = ProcessInfo.processInfo
            if process.arguments.contains("--ui-testing"),
                let raw = process.environment["ASTRO_UI_TEST_QUESTION_ALLOWANCE_SECONDS"],
                let seconds = Double(raw), seconds.isFinite, (1...300).contains(seconds)
            {
                return seconds
            }
        #endif
        return QuestionChallengeClock.defaultAllowance
    }

    public var body: some View {
        Group {
            if showingGravity {
                GravityPlaygroundView(onLeave: { showingGravity = false })
            } else if let playground {
                ExplorationPlaygroundView(
                    session: playground, videoLessons: session.videoLessons,
                    onLeave: leavePlayground
                )
                .onChange(of: playground.progress) { _, progress in
                    session.applyExplorationProgress(progress)
                    onProgressChanged(progress)
                }
                .onAppear { onProgressChanged(playground.progress) }
            } else {
                lifecycleManagedGame
            }
        }
        .sheet(isPresented: $showingPassport) {
            DiscoveryPassportView(
                progress: session.progress, adventures: ExplorationCatalog.adventures,
                lessons: session.lessons, onClose: { showingPassport = false })
        }
        .onChange(of: isPaused) {
            session.setQuestionPaused(.manual, isPaused: isPaused)
            if isPaused { session.pauseVideo() }
        }
        .onChange(of: scenePhase) {
            session.setQuestionPaused(.appInactive, isPaused: scenePhase != .active)
            if showingGravity { return }
            if scenePhase != .active, let playground {
                playground.send(.pause)
            } else if scenePhase != .active, session.phase != .missionPrompt {
                session.pauseVideo()
                isPaused = true
            }
        }
        #if canImport(UIKit)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: AVAudioSession.interruptionNotification)
            ) { notification in
                guard
                    let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey]
                        as? UInt,
                    type == AVAudioSession.InterruptionType.began.rawValue,
                    session.phase != .missionPrompt || playground != nil
                else { return }
                if showingGravity { return }
                if let playground {
                    playground.send(.pause)
                    return
                }
                session.pauseVideo()
                isPaused = true
            }
        #endif
    }

    @ViewBuilder
    private var lifecycleManagedGame: some View {
        #if os(tvOS)
            if session.phase == .missionPrompt {
                game
            } else {
                game
                    .onPlayPauseCommand { isPaused.toggle() }
                    .sheet(isPresented: $isPaused) { pausePanel }
                    .onExitCommand {
                        session.back()
                    }
            }
        #else
            game
                .safeAreaInset(edge: .bottom) {
                    if session.phase != .missionPrompt {
                        HStack {
                            Spacer()
                            Button {
                                isPaused = true
                            } label: {
                                Label("Pause", systemImage: "pause.circle.fill")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("adventure.pause")
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.7))
                    }
                }
                .sheet(isPresented: $isPaused) { pausePanel }
        #endif
    }

    private var game: some View {
        ZStack {
            AstroWorldView(
                lessons: session.lessons,
                selectedDestinationID: session.focusedLesson?.id,
                isExploring: session.phase != .missionPrompt && session.phase != .navigation
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.6), .clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            if isVideoPhase {
                VideoLessonView(session: session, isPaused: isPaused)
            } else if isPlanetAdventurePhase {
                PlanetAdventureView(session: session, isPaused: isPaused)
            } else if session.phase == .quizFeedback {
                QuestionFeedbackView(
                    session: session, onStory: { session.revisitBonusStory() }, isPaused: isPaused)
            } else if session.phase == .quizRoundComplete,
                let lesson = session.focusedLesson
            {
                QuizRoundResultsView(
                    destinationName: lesson.displayName,
                    score: session.roundScore,
                    stars: session.roundStars,
                    correctAnswers: session.roundCorrectAnswers,
                    totalQuestions: session.quizQuestions.count,
                    bestStreak: session.roundBestStreak,
                    leaderboard: session.progress.leaderboard,
                    onContinue: { continueToNextAdventure() }
                )
            } else if session.phase == .discoveryCard,
                let lesson = session.focusedLesson
            {
                DiscoveryStoryView(
                    destinationName: lesson.displayName,
                    ageBand: session.ageBand,
                    slides: DiscoveryStoryCatalog.slides(
                        destinationID: lesson.id,
                        ageBand: session.ageBand
                    ),
                    quizQuestionCount: QuizRoundCatalog.quizzes(
                        destinationID: lesson.id,
                        ageBand: session.ageBand
                    ).count,
                    onComplete: {
                        session.confirm()
                    },
                    onBack: {
                        session.back()
                    },
                    isPaused: isPaused,
                    resumeQuestionLabel: session.progress.bonusQuizRun == nil
                        ? nil : "Resume Question \(session.quizQuestionIndex + 1)"
                )
                .id("\(lesson.id)-\(session.ageBand.rawValue)")
            } else if session.phase == .quiz,
                let lesson = session.focusedLesson,
                session.currentQuiz != nil
            {
                QuizChallengeView(
                    session: session, destinationName: lesson.displayName,
                    ageBand: session.activeRoundAgeBand ?? session.ageBand,
                    questionIndex: session.quizQuestionIndex,
                    questionCount: session.quizQuestions.count,
                    onBack: { session.back() }, isPaused: isPaused
                )
                .id("\(lesson.id)-\(session.ageBand.rawValue)-quiz")
            } else {
                GeometryReader { proxy in
                    let compact = proxy.size.height < 520
                    let horizontalInset = compact ? 48.0 : 28.0
                    let verticalInset = compact ? 10.0 : 28.0
                    let panelInset = compact ? 14.0 : 26.0
                    let panelWidth = min(menuMaximumWidth, proxy.size.width - 2 * horizontalInset)

                    ScrollView {
                        VStack(spacing: compact ? 8 : 20) {
                            header(compact: compact)
                            if session.phase != .navigation {
                                Spacer(minLength: compact ? 4 : 20)
                            }
                            missionPanel(
                                compact: compact, contentWidth: panelWidth - 2 * panelInset)
                            if compact { Spacer(minLength: 0) }
                        }
                        .frame(
                            minHeight: max(0, proxy.size.height - 2 * verticalInset),
                            alignment: .top
                        )
                        .padding(.horizontal, horizontalInset)
                        .padding(.vertical, verticalInset)
                    }
                    .accessibilityIdentifier("adventure.menu")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: session.progress) { _, progress in
            onProgressChanged(progress)
        }
        .onChange(of: session.phase) { _, phase in
            switch phase {
            case .missionPrompt, .navigation, .quizFeedback, .missionComplete:
                primaryActionFocused = true
            default:
                primaryActionFocused = false
            }
        }
        .onAppear {
            primaryActionFocused = true
        }
    }

    private var isVideoPhase: Bool {
        switch session.phase {
        case .videoPlayback, .videoCheckpoint, .videoFeedback, .videoComplete: true
        default: false
        }
    }

    private var isPlanetAdventurePhase: Bool {
        switch session.phase {
        case .missionSelection, .missionBriefing, .missionClue, .missionQuestion,
            .missionActivity, .missionStepFeedback, .planetMissionComplete, .deepDive,
            .reviewQuestion, .reviewFeedback, .reviewComplete:
            true
        default: false
        }
    }

    private func header(compact: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                headerBrand(compact: compact).fixedSize()
                Spacer(minLength: 16)
                headerControls.fixedSize()
            }
            VStack(alignment: .leading, spacing: 12) {
                headerBrand(compact: compact)
                headerControls
            }
        }
    }

    private func headerBrand(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 0 : 4) {
            Text("ASTRO ADVENTURE")
                .font((compact ? Font.subheadline : Font.headline).weight(.black))
                .tracking(1.5)
            if !compact {
                Text("Your Discovery Passport awaits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var headerControls: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Button("Passport", systemImage: "book.closed.fill") { showingPassport = true }
                .accessibilityIdentifier("playground.passport")

            Menu {
                ForEach(AgeBand.allCases) { ageBand in
                    Button {
                        session.ageBand = ageBand
                    } label: {
                        Label(
                            "\(ageBand.modeName) · \(ageBand.displayName)",
                            systemImage: session.ageBand == ageBand ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                Label(session.ageBand.modeName, systemImage: "person.2.fill")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(session.isRoundInProgress || isPlanetAdventurePhase || isVideoPhase)
            .accessibilityLabel(
                "Explorer mode, \(session.ageBand.modeName), \(session.ageBand.displayName)"
            )
        }
    }

    @ViewBuilder
    private func missionPanel(compact: Bool, contentWidth: Double) -> some View {
        VStack(spacing: compact ? 8 : 18) {
            switch session.phase {
            case .missionPrompt:
                Text(
                    session.completedDestinationCount > 0
                        ? "Welcome back, Explorer!"
                        : "Mission Control calling!"
                )
                .font((compact ? Font.title2 : Font.largeTitle).bold())
                .multilineTextAlignment(.center)
                Text(
                    session.completedDestinationCount > 0
                        ? "Mission Control is ready! Collect discovery stamps by exploring new worlds."
                        : "Meet your robot crew. Make craters, explore with a rover, and build moving rings."
                )
                .font(compact ? .subheadline : .title3)
                .multilineTextAlignment(.center)
                missionSteps(compact: compact)
                primaryButton(
                    session.completedDestinationCount > 0
                        ? "Continue Adventure"
                        : "Begin Adventure",
                    systemImage: "rocket.fill"
                ) {
                    session.confirm()
                }
                .accessibilityIdentifier("adventure.begin")
                if let cursor = session.progress.explorationCursor,
                    let adventure = ExplorationCatalog.adventures.first(where: {
                        $0.id == cursor.adventureID
                    })
                {
                    secondaryButton("Return to \(adventure.title)", systemImage: "play.fill") {
                        openPlayground(adventure)
                    }
                    .accessibilityIdentifier("playground.resume")
                }
                if session.hasSavedAdventure {
                    secondaryButton(
                        "Resume \(session.savedAdventureTitle ?? "Adventure")",
                        systemImage: "play.fill"
                    ) {
                        session.resumeSavedAdventure()
                    }
                    .accessibilityIdentifier("adventure.resume")
                }
                #if os(tvOS)
                    Label(
                        "Press Back on the Siri Remote to leave",
                        systemImage: "chevron.backward.circle"
                    )
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))
                #endif

            case .navigation:
                Text(
                    selectedSection == .solarSystem
                        ? "Choose your next world"
                        : "Enter the Space Technology Lab"
                )
                .font((compact ? Font.title3 : Font.title2).bold())
                .multilineTextAlignment(.center)
                sectionSelector(compact: compact)
                if let recommendation = recommendedLesson {
                    Text("Mission Control suggests: \(recommendation.displayName)")
                        .font((compact ? Font.subheadline : Font.title3).bold())
                        .multilineTextAlignment(.center)
                }
                destinationSelector(compact: compact, contentWidth: contentWidth)
                navigationPrimaryAction
                if let destination = session.focusedLesson?.id,
                    ExplorationCatalog.adventure(destinationID: destination) != nil
                {
                    secondaryButton("More missions and films", systemImage: "book.closed") {
                        session.confirm()
                    }
                    .accessibilityIdentifier("playground.legacy")
                }
                secondaryButton("Try the Gravity Playground", systemImage: "arrow.up.right") {
                    showingGravity = true
                }
                .accessibilityIdentifier("gravity.open")
                if !session.dueReviewQuestions.isEmpty {
                    secondaryButton("Play a Memory Adventure", systemImage: "brain.head.profile") {
                        session.startReview()
                    }
                    .accessibilityIdentifier("review.start")
                }

            case .discoveryCard:
                Text("\(session.focusedLesson?.displayName ?? "World") discovered!")
                    .font((compact ? Font.title2 : Font.largeTitle).bold())
                Text(session.focusedContent?.discoveryText ?? "")
                    .font(compact ? .subheadline : .title3)
                    .multilineTextAlignment(.center)
                primaryButton("Check the Clue", systemImage: "sparkles") {
                    session.confirm()
                }
                secondaryButton("Back to Worlds") {
                    session.back()
                }

            case .quiz:
                Text(session.focusedContent?.quiz.prompt ?? "Discovery check")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                quizChoices
                HStack {
                    secondaryButton("Back") {
                        session.back()
                    }
                    secondaryButton("Hint", systemImage: "lightbulb.fill") {
                        session.requestHint()
                    }
                }
                if session.isShowingHint {
                    Text(session.focusedContent?.quiz.hint ?? "")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

            case .quizFeedback:
                Image(systemName: session.wasLastAnswerCorrect ? "star.fill" : "arrow.clockwise")
                    .font(.system(size: compact ? 30 : 44))
                    .foregroundStyle(session.wasLastAnswerCorrect ? .yellow : .cyan)
                    .accessibilityHidden(true)
                Text(session.lastFeedback)
                    .font((compact ? Font.title3 : Font.title2).bold())
                    .multilineTextAlignment(.center)
                Text(
                    session.wasLastAnswerCorrect
                        ? "Clue discovered!" : "Take your time. Hints are always welcome."
                )
                .font(compact ? .subheadline : .title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
                primaryButton(session.wasLastAnswerCorrect ? "Continue" : "Try Again") {
                    session.confirm()
                }
                .accessibilityIdentifier("feedback.continue")

            case .quizRoundComplete:
                EmptyView()

            case .missionComplete:
                Image(systemName: "sparkles")
                    .font(.system(size: compact ? 34 : 52))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Mission complete!")
                    .font((compact ? Font.title2 : Font.largeTitle).bold())
                Text("Your passport is full! Different worlds have different clues.")
                    .font(compact ? .subheadline : .title3)
                    .multilineTextAlignment(.center)
                primaryButton("Explore Again", systemImage: "arrow.clockwise") {
                    session.confirm()
                }
            default:
                EmptyView()
            }

            Text(progressSummary)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(compact ? 14 : 26)
        .frame(maxWidth: menuMaximumWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }

    private func missionSteps(compact: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: compact ? 6 : 10) {
                missionStep(
                    "Pick an adventure", systemImage: "globe.americas.fill", compact: compact)
                missionStep(
                    "Try your tools", systemImage: "wrench.and.screwdriver.fill", compact: compact)
                missionStep(
                    "Make discoveries", systemImage: "sparkles", compact: compact)
            }

            VStack(spacing: 8) {
                missionStep(
                    "Pick an adventure", systemImage: "globe.americas.fill", compact: compact)
                missionStep(
                    "Try your tools", systemImage: "wrench.and.screwdriver.fill", compact: compact)
                missionStep(
                    "Make discoveries", systemImage: "sparkles", compact: compact)
            }
        }
    }

    private func missionStep(_ title: String, systemImage: String, compact: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font((compact ? Font.caption : Font.footnote).weight(.bold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 6 : 9)
            .background(.white.opacity(0.1), in: Capsule())
    }

    private func sectionSelector(compact: Bool) -> some View {
        let spacing = compact ? 8.0 : 12.0
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        return layout {
            ForEach(ExplorerSection.allCases) { section in
                Button {
                    selectSection(section)
                } label: {
                    Label(section.title, systemImage: section.systemImage)
                        .font((compact ? Font.caption : Font.subheadline).weight(.black))
                        .padding(.horizontal, compact ? 4 : 10)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(compact ? .small : .regular)
                .tint(selectedSection == section ? .cyan : .gray.opacity(0.55))
                .accessibilityHint("Shows \(section.title) adventures")
                .accessibilityIdentifier("destination.section.\(section.rawValue)")
            }
        }
    }

    private func destinationSelector(compact: Bool, contentWidth: Double) -> some View {
        let cardWidth = min(
            destinationCardWidth, max(1, contentWidth - 2 * destinationFocusInset))
        return ScrollView(.horizontal) {
            // These lightweight cards must report their full cross-axis height before scrolling.
            HStack(spacing: compact ? 8 : 12) {
                ForEach(sectionLessons, id: \.element.id) { index, lesson in
                    let selected = index == session.focusedDestinationIndex
                    let focused = focusedDestinationID == lesson.id
                    Button {
                        selectDestination(at: index)
                        #if os(tvOS)
                            exploreFocusedDestination()
                        #endif
                    } label: {
                        VStack(spacing: compact ? 2 : 4) {
                            Text(lesson.displayName)
                                .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                            Text(lesson.kind.uppercased())
                                .font(.caption2.weight(.black))
                                .tracking(0.8)
                            if session.progress.destinations[lesson.id]?.isQuizCompleted == true {
                                Label("Stamped", systemImage: "checkmark.seal.fill")
                                    .font(compact ? .caption2 : .caption)
                            } else if index == session.focusedDestinationIndex {
                                Label("Selected", systemImage: "checkmark.circle.fill")
                                    .font(compact ? .caption2 : .caption)
                            } else {
                                Text("Explore")
                                    .font(compact ? .caption2 : .caption)
                            }
                            let missions = session.planetMissions.filter {
                                $0.destinationID == lesson.id
                            }
                            if let adventure = ExplorationCatalog.adventure(
                                destinationID: lesson.id)
                            {
                                Label("Living playground", systemImage: "gamecontroller.fill")
                                    .font(.caption2.bold())
                                if session.progress.explorationCompletions[adventure.id] != nil {
                                    Text("Postcard collected").font(.caption2)
                                }
                            } else if !missions.isEmpty {
                                Text(
                                    "\(missions.filter { session.progress.completedMissionIDs.contains($0.id) }.count)/3 missions"
                                )
                                .font(.caption2.bold())
                            }
                        }
                        .multilineTextAlignment(.center)
                        .foregroundStyle(selected ? Color.black : Color.white)
                        .padding(compact ? 8 : 16)
                        .frame(width: cardWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            selected ? Color.cyan : Color(red: 0.11, green: 0.15, blue: 0.22),
                            in: RoundedRectangle(cornerRadius: compact ? 14 : 20)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: compact ? 14 : 20)
                                .stroke(
                                    focused ? Color.white : Color.white.opacity(0.3),
                                    lineWidth: focused ? 4 : 1)
                        }
                        .scaleEffect(focused && !reduceMotion ? 1.04 : 1)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedDestinationID, equals: lesson.id)
                    .accessibilityIdentifier("destination.\(lesson.id)")
                }
            }
            .padding(.horizontal, destinationFocusInset)
            .padding(.vertical, destinationVerticalInset)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("destination.selector")
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .onChange(of: focusedDestinationID) { _, destinationID in
            guard
                let destinationID,
                let index = session.lessons.firstIndex(where: { $0.id == destinationID })
            else { return }
            selectDestination(at: index)
        }
    }

    @ViewBuilder
    private var navigationPrimaryAction: some View {
        #if os(tvOS)
            // Bridge the whole card row to its centered action without changing the chosen world.
            HStack {
                Spacer(minLength: 0)
                exploreDestinationButton
                Spacer(minLength: 0)
            }
            .focusSection()
        #else
            exploreDestinationButton
        #endif
    }

    private var exploreDestinationButton: some View {
        primaryButton(
            "Explore \(session.focusedLesson?.displayName ?? "Adventure")",
            systemImage: "sparkles"
        ) {
            exploreFocusedDestination()
        }
        .accessibilityIdentifier("adventure.explore")
    }

    private var sectionLessons: [(offset: Int, element: DestinationLesson)] {
        Array(session.lessons.enumerated()).filter { _, lesson in
            let isTechnologyLab = lesson.id == "space-technology-lab"
            return selectedSection == .technologyLab ? isTechnologyLab : !isTechnologyLab
        }
    }

    private var progressSummary: String {
        let lessons = sectionLessons.map(\.element)
        let completed = lessons.filter {
            session.progress.destinations[$0.id]?.isQuizCompleted == true
        }.count

        return switch selectedSection {
        case .solarSystem:
            "Discovery Passport · \(completed) world stamps · \(session.progress.explorationCompletions.count) playground postcards"
        case .technologyLab:
            "Discovery Passport · \(completed) of \(lessons.count) lab stamps"
        }
    }

    private var recommendedLesson: DestinationLesson? {
        if let playground = sectionLessons.first(where: { _, lesson in
            guard let adventure = ExplorationCatalog.adventure(destinationID: lesson.id) else {
                return false
            }
            return session.progress.explorationCompletions[adventure.id] == nil
        }) {
            return playground.element
        }
        if let unfinished = sectionLessons.first(where: { _, lesson in
            session.planetMissions.contains {
                $0.destinationID == lesson.id
                    && !session.progress.completedMissionIDs.contains($0.id)
            }
        }) {
            return unfinished.element
        }
        return sectionLessons.first {
            session.progress.destinations[$0.element.id]?.isQuizCompleted != true
        }?.element
    }

    private func continueToNextAdventure() {
        session.exploreNextDestination()
        selectedSection =
            session.focusedLesson?.id == "space-technology-lab" ? .technologyLab : .solarSystem
    }

    private var pausePanel: some View {
        VStack(spacing: 24) {
            Label("Mission paused", systemImage: "pause.circle.fill")
                .font(.largeTitle.bold())
            Text("Take your time, Explorer. Your discoveries are safe.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Move to choose. Press to explore. Back returns. Hints help you learn.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button("Resume Adventure") { isPaused = false }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .focused($resumeFocused)
                .accessibilityIdentifier("adventure.pause.resume")
            Button("Return to Worlds") {
                session.returnToWorlds()
                isPaused = false
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("adventure.pause.worlds")
        }
        .padding(48)
        .onAppear { resumeFocused = true }
    }

    private func selectSection(_ section: ExplorerSection) {
        guard session.phase == .navigation else { return }
        guard selectedSection != section else { return }
        selectedSection = section
        guard let first = sectionLessons.first else { return }
        selectDestination(at: first.offset)
        focusedDestinationID = first.element.id
    }

    private func exploreFocusedDestination() {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--legacy-learning") {
                session.confirm()
                return
            }
        #endif
        if let destination = session.focusedLesson?.id,
            let adventure = ExplorationCatalog.adventure(destinationID: destination)
        {
            openPlayground(adventure)
        } else {
            session.confirm()
        }
    }

    private func openPlayground(_ adventure: ExplorationAdventure) {
        playground = ExplorationSession(adventure: adventure, progress: session.progress)
    }

    private func leavePlayground() {
        guard let active = playground else { return }
        active.send(.pause)
        session.applyExplorationProgress(active.progress)
        onProgressChanged(active.progress)
        playground = nil
        session.returnToWorlds()
    }

    private func selectDestination(at index: Int) {
        session.selectDestination(at: index)
    }

    private var quizChoices: some View {
        VStack(spacing: 10) {
            ForEach(
                Array((session.focusedContent?.quiz.choices ?? []).enumerated()),
                id: \.element.id
            ) { index, choice in
                Button {
                    session.submitAnswer(at: index)
                } label: {
                    Text(choice.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private func primaryButton(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .focused($primaryActionFocused)
    }

    private func secondaryButton(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .buttonStyle(.bordered)
    }
}
