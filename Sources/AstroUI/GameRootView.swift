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

    @State private var session: MissionSession
    @State private var selectedSection: ExplorerSection = .solarSystem
    @FocusState private var primaryActionFocused: Bool
    @FocusState private var focusedDestinationID: String?
    private let onProgressChanged: (GameProgress) -> Void

    public init(
        lessons: [DestinationLesson],
        progress: GameProgress? = nil,
        onProgressChanged: @escaping (GameProgress) -> Void = { _ in }
    ) {
        _session = State(
            initialValue: MissionSession(
                lessons: lessons,
                progress: progress,
                quizProvider: QuizRoundCatalog.quizzes
            )
        )
        self.onProgressChanged = onProgressChanged
    }

    public var body: some View {
        #if os(tvOS)
            if session.phase == .missionPrompt {
                game
            } else {
                game
                    .onExitCommand {
                        session.back()
                    }
            }
        #else
            game
        #endif
    }

    private var game: some View {
        ZStack {
            AstroWorldView(lessons: session.lessons)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.6), .clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            if session.phase == .quizRoundComplete,
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
                    onContinue: { session.confirm() }
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
                    }
                )
                .id("\(lesson.id)-\(session.ageBand.rawValue)")
            } else if session.phase == .quiz,
                let lesson = session.focusedLesson,
                let quiz = session.currentQuiz
            {
                QuizChallengeView(
                    destinationName: lesson.displayName,
                    ageBand: session.ageBand,
                    quiz: quiz,
                    isShowingHint: session.isShowingHint,
                    completedCount: session.completedDestinationCount,
                    totalCount: session.lessons.count,
                    questionIndex: session.quizQuestionIndex,
                    questionCount: session.quizQuestions.count,
                    score: session.roundScore,
                    streak: session.currentStreak,
                    onSelectAnswer: { index in
                        session.submitAnswer(at: index)
                    },
                    onHint: {
                        session.requestHint()
                    },
                    onBack: {
                        session.back()
                    }
                )
                .id("\(lesson.id)-\(session.ageBand.rawValue)-quiz")
            } else {
                GeometryReader { proxy in
                    let compact = proxy.size.height < 520

                    VStack(spacing: compact ? 8 : 20) {
                        header(compact: compact)
                        Spacer(minLength: compact ? 4 : 20)
                        missionPanel(compact: compact)
                        if compact {
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, compact ? 48 : 28)
                    .padding(.vertical, compact ? 10 : 28)
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
            case .discoveryCard, .quiz, .quizRoundComplete:
                primaryActionFocused = false
            }
        }
        .onAppear {
            primaryActionFocused = true
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: compact ? 0 : 4) {
                Text("ASTRO ADVENTURE")
                    .font((compact ? Font.subheadline : Font.headline).weight(.black))
                    .tracking(1.5)
                if !compact {
                    Text("Explore • Learn • Play")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

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
            }
            .accessibilityLabel(
                "Explorer mode, \(session.ageBand.modeName), \(session.ageBand.displayName)"
            )
        }
    }

    @ViewBuilder
    private func missionPanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 18) {
            switch session.phase {
            case .missionPrompt:
                Text(
                    session.completedDestinationCount > 0
                        ? "Welcome back, Explorer!"
                        : "Ready to explore space?"
                )
                .font((compact ? Font.title2 : Font.largeTitle).bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                Text(
                    session.completedDestinationCount > 0
                        ? "Keep exploring, discover surprising facts, and grow your score."
                        : "Pick a world or technology lab, see real space photos, then play a picture quiz."
                )
                .font(compact ? .subheadline : .title3)
                .multilineTextAlignment(.center)
                .lineLimit(compact ? 1 : nil)
                .minimumScaleFactor(0.8)
                missionSteps(compact: compact)
                primaryButton(
                    session.completedDestinationCount > 0
                        ? "Continue Adventure"
                        : "Begin Adventure",
                    systemImage: "rocket.fill"
                ) {
                    session.confirm()
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
                sectionSelector(compact: compact)
                destinationSelector(compact: compact)
                primaryButton(
                    "Explore \(session.focusedLesson?.displayName ?? "Adventure")",
                    systemImage: "sparkles"
                ) {
                    session.confirm()
                }

            case .discoveryCard:
                Text("\(session.focusedLesson?.displayName ?? "World") discovered!")
                    .font((compact ? Font.title2 : Font.largeTitle).bold())
                Text(session.focusedContent?.discoveryText ?? "")
                    .font(compact ? .subheadline : .title3)
                    .multilineTextAlignment(.center)
                    .lineLimit(compact ? 2 : nil)
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
                if session.wasLastAnswerCorrect {
                    HStack(spacing: 18) {
                        Label("\(session.roundScore) points", systemImage: "star.circle.fill")
                            .foregroundStyle(.yellow)
                        Label("\(session.currentStreak) streak", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.headline.weight(.bold))
                }
                primaryButton(session.wasLastAnswerCorrect ? "Continue" : "Try Again") {
                    session.confirm()
                }

            case .quizRoundComplete:
                EmptyView()

            case .missionComplete:
                Image(systemName: "sparkles")
                    .font(.system(size: compact ? 34 : 52))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Mission complete!")
                    .font((compact ? Font.title2 : Font.largeTitle).bold())
                Text("You matched three space clues like a real explorer.")
                    .font(compact ? .subheadline : .title3)
                    .multilineTextAlignment(.center)
                primaryButton("Explore Again", systemImage: "arrow.clockwise") {
                    session.confirm()
                }
            }

            Text(progressSummary)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: 760)
        .padding(compact ? 14 : 26)
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
                missionStep("See NASA photos", systemImage: "photo.fill", compact: compact)
                missionStep("Play a quiz", systemImage: "gamecontroller.fill", compact: compact)
            }

            VStack(spacing: 8) {
                missionStep(
                    "Pick an adventure", systemImage: "globe.americas.fill", compact: compact)
                missionStep("See NASA photos", systemImage: "photo.fill", compact: compact)
                missionStep("Play a quiz", systemImage: "gamecontroller.fill", compact: compact)
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
        HStack(spacing: compact ? 8 : 12) {
            ForEach(ExplorerSection.allCases) { section in
                Button {
                    selectSection(section)
                } label: {
                    Label(section.title, systemImage: section.systemImage)
                        .font((compact ? Font.caption : Font.subheadline).weight(.black))
                        .padding(.horizontal, compact ? 4 : 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(compact ? .small : .regular)
                .tint(selectedSection == section ? .cyan : .gray.opacity(0.55))
                .accessibilityHint("Shows \(section.title) adventures")
            }
        }
    }

    private func destinationSelector(compact: Bool) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: compact ? 8 : 12) {
                ForEach(sectionLessons, id: \.element.id) { index, lesson in
                    Button {
                        selectDestination(at: index)
                        #if os(tvOS)
                            session.confirm()
                        #endif
                    } label: {
                        VStack(spacing: compact ? 2 : 4) {
                            Text(lesson.displayName)
                                .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                                .lineLimit(1)
                            Text(lesson.kind.uppercased())
                                .font(.caption2.weight(.black))
                                .tracking(0.8)
                                .foregroundStyle(.secondary)
                            if session.progress.destinations[lesson.id]?.isQuizCompleted == true {
                                Label("Collected", systemImage: "checkmark.seal.fill")
                                    .font(compact ? .caption2 : .caption)
                            } else if index == session.focusedDestinationIndex {
                                Label("Selected", systemImage: "checkmark.circle.fill")
                                    .font(compact ? .caption2 : .caption)
                            } else {
                                Text("Explore")
                                    .font(compact ? .caption2 : .caption)
                            }
                        }
                        .frame(
                            minWidth: compact ? 112 : 138,
                            minHeight: compact ? 56 : nil
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(compact ? .small : .regular)
                    .tint(index == session.focusedDestinationIndex ? .cyan : .gray)
                    .focused($focusedDestinationID, equals: lesson.id)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: 720)
        .frame(height: compact ? 70 : nil)
        .onChange(of: focusedDestinationID) { _, destinationID in
            guard
                let destinationID,
                let index = session.lessons.firstIndex(where: { $0.id == destinationID })
            else { return }
            selectDestination(at: index)
        }
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
            "Worlds explored \(completed) of \(lessons.count)"
        case .technologyLab:
            "Technology labs completed \(completed) of \(lessons.count)"
        }
    }

    private func selectSection(_ section: ExplorerSection) {
        guard selectedSection != section else { return }
        selectedSection = section
        guard let first = sectionLessons.first else { return }
        selectDestination(at: first.offset)
        focusedDestinationID = first.element.id
    }

    private func selectDestination(at index: Int) {
        while session.focusedDestinationIndex != index {
            session.focusNext()
        }
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
        .buttonStyle(.bordered)
    }
}
