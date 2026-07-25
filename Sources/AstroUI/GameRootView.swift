import AstroGameCore
import AstroWorld
import SwiftUI

public struct GameRootView: View {
    @State private var session: MissionSession

    public init(lessons: [DestinationLesson]) {
        _session = State(initialValue: MissionSession(lessons: lessons))
    }

    public var body: some View {
        #if os(tvOS)
            game
                .onMoveCommand { direction in
                    switch direction {
                    case .left, .up:
                        session.focusPrevious()
                    case .right, .down:
                        session.focusNext()
                    default:
                        break
                    }
                }
                .onExitCommand {
                    session.back()
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

            VStack(spacing: 20) {
                header
                Spacer()
                missionPanel
            }
            .padding(28)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ASTRO ADVENTURE")
                    .font(.headline.weight(.black))
                    .tracking(1.5)
                Text("Signal Sweep")
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
                Text("Ready, space explorer?")
                    .font(.largeTitle.bold())
                Text("Scan three worlds and collect their clue cards.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                primaryButton("Start Mission", systemImage: "play.fill") {
                    session.confirm()
                }

            case .navigation:
                Text("Choose a world to scan")
                    .font(.title2.bold())
                destinationSelector
                primaryButton("Scan \(session.focusedLesson?.displayName ?? "World")") {
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
                primaryButton(session.wasLastAnswerCorrect ? "Continue" : "Try Again") {
                    session.confirm()
                }

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
                "Discovery cards \(session.completedDestinationCount)/\(session.lessons.count)"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 760)
        .padding(26)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
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
                        } else {
                            Text(index == session.focusedDestinationIndex ? "Focused" : "Explore")
                                .font(.caption)
                        }
                    }
                    .frame(minWidth: 112)
                }
                .buttonStyle(
                    SelectableButtonStyle(isSelected: index == session.focusedDestinationIndex)
                )
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
                .buttonStyle(
                    SelectableButtonStyle(isSelected: index == session.focusedQuizChoiceIndex)
                )
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

private struct SelectableButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .white : .white.opacity(0.25), lineWidth: 2)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
