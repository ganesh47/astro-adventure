import AstroGameCore
import SwiftUI

@MainActor
struct QuestionFeedbackView: View {
    let session: MissionSession
    var identifierPrefix = "feedback"
    var onStory: (() -> Void)?
    var onReplay: (() -> Void)?
    var isPaused = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @State private var narrator = QuestionNarrator()
    @State private var appeared = false
    @FocusState private var continueFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 520
            let interaction = session.questionInteraction
            ScrollView {
                VStack(spacing: compact ? 12 : 24) {
                    Label(
                        session.wasLastAnswerCorrect ? "Discovery connected!" : "Let's look again",
                        systemImage: session.wasLastAnswerCorrect ? "star.fill" : "arrow.clockwise"
                    )
                    .font(compact ? .title3.bold() : .largeTitle.bold())
                    .foregroundStyle(session.wasLastAnswerCorrect ? .yellow : .cyan)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.92)
                    let layout =
                        proxy.size.width > 700 && !dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(HStackLayout(alignment: .center, spacing: 24))
                        : AnyLayout(VStackLayout(spacing: 20))
                    layout {
                        if let choice = feedbackChoice {
                            VStack(spacing: 12) {
                                if let picture = choice.picture {
                                    QuizPictureView(picture: picture, compact: compact)
                                }
                                Text(choice.text).font(.headline)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }.frame(maxWidth: 460)
                        }
                        VStack(spacing: 16) {
                            Text(session.lastFeedback).font(compact ? .body : .title2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            if !session.wasLastAnswerCorrect, let quiz = session.currentQuiz {
                                Text(quiz.hint).font(.body)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(
                                session.wasLastAnswerCorrect
                                    ? (session.lastAnswerUsedHelp
                                        ? "You connected the clue with help. Keep exploring!"
                                        : "You connected the clue. Keep exploring!")
                                    : "Your discoveries are safe. Try another idea or revisit the clue."
                            )
                            .font(.body).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Button(session.wasLastAnswerCorrect ? "Continue" : "Try Again") {
                        session.continueQuestionFeedback(interaction: interaction)
                    }
                    .font(.headline).buttonStyle(.borderedProminent)
                    .focused($continueFocused)
                    .disabled(isPaused)
                    .accessibilityIdentifier("\(identifierPrefix).continue")
                    if !session.wasLastAnswerCorrect {
                        Button("Try with a Hint") {
                            if session.continueQuestionFeedback(interaction: interaction) {
                                session.requestHint()
                            }
                        }.buttonStyle(.bordered)
                            .disabled(isPaused)
                            .accessibilityIdentifier("\(identifierPrefix).hint")
                        if let onStory {
                            Button("Discovery Story", action: onStory).buttonStyle(.bordered)
                                .accessibilityIdentifier("\(identifierPrefix).story")
                        }
                        if let onReplay {
                            Button("Replay the clue", action: onReplay).buttonStyle(.bordered)
                                .accessibilityIdentifier("\(identifierPrefix).replay")
                        }
                    }
                    if !voiceOverEnabled {
                        Button("Read the Clue") { speakFeedback(manual: true) }
                            .buttonStyle(.bordered)
                            .disabled(!narrationEnabled || isPaused || scenePhase != .active)
                            .accessibilityIdentifier("\(identifierPrefix).read")
                    }
                }
                .frame(maxWidth: 1100).frame(maxWidth: .infinity)
                .padding(.horizontal, compact ? 24 : 52).padding(.vertical, compact ? 16 : 44)
            }.accessibilityIdentifier("\(identifierPrefix).scroll")
        }
        .background(Color(red: 0.025, green: 0.05, blue: 0.1).opacity(0.97))
        .onAppear {
            continueFocused = true
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { appeared = true }
            speakFeedback()
        }
        .onChange(of: isPaused) { speakFeedback() }
        .onChange(of: scenePhase) { speakFeedback() }
        .onChange(of: narrationEnabled) { speakFeedback() }
        .onChange(of: voiceOverEnabled) { speakFeedback() }
        .onDisappear { narrator.stop() }
    }

    private func speakFeedback(manual: Bool = false) {
        narrator.stop()
        guard narrationEnabled, !voiceOverEnabled, !isPaused, scenePhase == .active,
            (session.activeRoundAgeBand ?? session.activeMissionAgeBand) == .ages4To6 || manual
        else { return }
        let interaction = session.questionInteraction
        let text =
            session.lastFeedback
            + (session.wasLastAnswerCorrect ? "" : ". " + (session.currentQuiz?.hint ?? ""))
        narrator.speak(text, interaction: interaction) { speaking, token in
            session.setQuestionPaused(.narration, isPaused: speaking, interaction: token)
        }
    }

    private var feedbackChoice: QuizChoice? {
        guard let quiz = session.currentQuiz else { return nil }
        return quiz.choices.first {
            $0.id
                == (session.wasLastAnswerCorrect
                    ? quiz.correctChoiceID : session.selectedQuizChoiceID)
        }
    }
}
