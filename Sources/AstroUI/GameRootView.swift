import AstroContent
import AstroGameCore
import AstroWorld
import SwiftUI

public struct GameRootView: View {
    @State private var session: MissionSession
    @FocusState private var primaryActionFocused: Bool
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
                VStack(spacing: 20) {
                    header
                    Spacer()
                    missionPanel
                }
                .padding(28)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: session.progress) { _, progress in
            onProgressChanged(progress)
        }
        .onChange(of: session.phase) {
            primaryActionFocused = true
        }
        .onAppear {
            primaryActionFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ASTRO ADVENTURE")
                    .font(.headline.weight(.black))
                    .tracking(1.5)
                Text("Explore • Learn • Play")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
    private var missionPanel: some View {
        VStack(spacing: 18) {
            switch session.phase {
            case .missionPrompt:
                Text(
                    session.completedDestinationCount > 0
                        ? "Welcome back, Explorer!"
                        : "Ready to explore space?"
                )
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                Text(
                    session.completedDestinationCount > 0
                        ? "Keep exploring, discover surprising facts, and grow your score."
                        : "Pick a world, see real space photos, then play a quick picture quiz."
                )
                .font(.title3)
                .multilineTextAlignment(.center)
                missionSteps
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
                Text("Choose your next world")
                    .font(.title2.bold())
                destinationSelector
                primaryButton(
                    "Explore \(session.focusedLesson?.displayName ?? "World")",
                    systemImage: "sparkles"
                ) {
                    session.confirm()
                }

            case .discoveryCard:
                Text("\(session.focusedLesson?.displayName ?? "World") discovered!")
                    .font(.largeTitle.bold())
                Text(session.focusedContent?.discoveryText ?? "")
                    .font(.title3)
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
                    .font(.system(size: 44))
                    .foregroundStyle(session.wasLastAnswerCorrect ? .yellow : .cyan)
                    .accessibilityHidden(true)
                Text(session.lastFeedback)
                    .font(.title2.bold())
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
                    .font(.system(size: 52))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Mission complete!")
                    .font(.largeTitle.bold())
                Text("You matched three space clues like a real explorer.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                primaryButton("Explore Again", systemImage: "arrow.clockwise") {
                    session.confirm()
                }
            }

            Text(
                "Worlds explored \(session.completedDestinationCount) of \(session.lessons.count)"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: 760)
        .padding(26)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }

    private var missionSteps: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                missionStep("Pick a world", systemImage: "globe.americas.fill")
                missionStep("See NASA photos", systemImage: "photo.fill")
                missionStep("Play a quiz", systemImage: "gamecontroller.fill")
            }

            VStack(spacing: 8) {
                missionStep("Pick a world", systemImage: "globe.americas.fill")
                missionStep("See NASA photos", systemImage: "photo.fill")
                missionStep("Play a quiz", systemImage: "gamecontroller.fill")
            }
        }
    }

    private func missionStep(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.bold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.1), in: Capsule())
    }

    private var destinationSelector: some View {
        HStack(spacing: 12) {
            ForEach(Array(session.lessons.enumerated()), id: \.element.id) { index, lesson in
                Button {
                    while session.focusedDestinationIndex != index {
                        session.focusNext()
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(lesson.displayName)
                            .font(.headline)
                        if session.progress.destinations[lesson.id]?.isQuizCompleted == true {
                            Label("Collected", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                        } else if index == session.focusedDestinationIndex {
                            Label("Selected", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                        } else {
                            Text("Explore")
                                .font(.caption)
                        }
                    }
                    .frame(minWidth: 112)
                }
                .buttonStyle(.bordered)
                .tint(index == session.focusedDestinationIndex ? .cyan : .gray)
            }
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
