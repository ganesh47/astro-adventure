import AVFoundation
import AstroGameCore
import SwiftUI

@MainActor
struct QuizChallengeView: View {
    let session: MissionSession
    let destinationName: String
    let ageBand: AgeBand
    let questionIndex: Int
    let questionCount: Int
    let onBack: () -> Void
    var backTitle = "Discovery Story"
    var identifierPrefix = "quiz"
    var onReplay: (() -> Void)?
    var isPaused = false

    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var narrator = QuestionNarrator()
    @State private var appeared = false
    @FocusState private var focusedControl: Control?

    private enum Control: Hashable {
        case answer(String), check, hint, back, mode, sound, read, moreTime, practice, resume
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 520
            let wide = !dynamicTypeSize.isAccessibilitySize && proxy.size.width > 700
            ScrollView {
                if let quiz = session.currentQuiz {
                    let interaction = session.questionInteraction
                    VStack(spacing: compact ? 10 : 24) {
                        header(compact: compact, interaction: interaction)
                        Text(quiz.prompt)
                            .font(compact ? .headline : .largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("\(identifierPrefix).question")
                        answerCards(quiz, interaction: interaction, wide: wide, compact: compact)
                        if session.isShowingHint {
                            VStack(spacing: 12) {
                                Label(quiz.hint, systemImage: "lightbulb.fill")
                                    .font(.body).fixedSize(horizontal: false, vertical: true)
                                Button("Ready to choose") {
                                    narrator.stop()
                                    session.dismissQuestionHint()
                                    focusAnswer()
                                }.buttonStyle(.bordered)
                                    .accessibilityIdentifier("\(identifierPrefix).hint.close")
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                .yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 18)
                            )
                            .transition(.opacity)
                        }
                        challengeControls(interaction: interaction)
                        Button {
                            narrator.stop()
                            session.confirmSelectedQuizAnswer(interaction: interaction)
                        } label: {
                            Label("Check Answer", systemImage: "checkmark.circle")
                                .font(.headline)
                                .padding(.horizontal, 16).padding(.vertical, compact ? 3 : 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .focused($focusedControl, equals: .check)
                        .disabled(
                            session.selectedQuizChoiceID == nil || session.isQuestionInputBlocked
                                || isPaused || scenePhase != .active
                        )
                        .accessibilityIdentifier("\(identifierPrefix).check")
                        utilities(interaction: interaction, compact: compact)
                    }
                    .frame(maxWidth: 1280)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, compact ? 24 : 52)
                    .padding(.vertical, compact ? 10 : 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 12)
                }
            }
            .accessibilityIdentifier("\(identifierPrefix).scroll")
        }
        .background(Color(red: 0.02, green: 0.035, blue: 0.08).opacity(0.97))
        .preferredColorScheme(.dark)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.22), value: session.selectedQuizChoiceID
        )
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: session.isShowingHint)
        .onAppear {
            session.prepareQuestion()
            focusAnswer()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) { appeared = true }
            synchronizePauses()
            speakQuestion()
        }
        .onChange(of: session.questionInteraction) {
            focusAnswer()
            speakQuestion()
        }
        .onChange(of: session.questionClock.isExpired) {
            if session.questionClock.isExpired {
                narrator.stop()
                focusedControl = .moreTime
            } else {
                focusAnswer()
            }
        }
        .onChange(of: isPaused) {
            synchronizePauses()
            speakQuestion()
        }
        .onChange(of: scenePhase) {
            synchronizePauses()
            speakQuestion()
        }
        .onChange(of: narrationEnabled) { speakQuestion() }
        .onChange(of: voiceOverEnabled) { speakQuestion() }
        .onChange(of: session.isShowingHint) {
            if session.isShowingHint { speak(session.currentQuiz?.hint) }
        }
        .onDisappear { narrator.stop() }
        .task(id: session.questionInteraction) {
            let interaction = session.questionInteraction
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                session.sampleQuestionTime(interaction: interaction)
            }
        }
    }

    private func header(compact: Bool, interaction: QuestionChallengeInteraction) -> some View {
        VStack(spacing: compact ? 5 : 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("PICTURE EXPLORER", systemImage: "sparkles")
                        .font(.caption.bold()).foregroundStyle(.yellow)
                    Text("\(destinationName) · \(ageBand.modeName)")
                        .font(compact ? .caption : .headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Text("\(questionIndex + 1) / \(max(1, questionCount))")
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("Question \(questionIndex + 1) of \(max(1, questionCount))")
                    .accessibilityIdentifier("\(identifierPrefix).progress")
            }
            ProgressView(value: Double(questionIndex), total: Double(max(1, questionCount)))
                .tint(.cyan).accessibilityHidden(true)
            if !compact {
                Text("Choose a picture, then check your answer. Take all the time you need.")
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func answerCards(
        _ quiz: QuizContent, interaction: QuestionChallengeInteraction, wide: Bool, compact: Bool
    ) -> some View {
        let layout =
            wide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: compact ? 12 : 24))
            : AnyLayout(VStackLayout(spacing: 16))
        return layout {
            ForEach(Array(quiz.choices.enumerated()), id: \.element.id) { index, choice in
                let selected = choice.id == session.selectedQuizChoiceID
                let focused = focusedControl == .answer(choice.id)
                Button {
                    narrator.stop()
                    session.selectQuizAnswer(at: index, interaction: interaction)
                    if !session.isQuestionInputBlocked { focusedControl = .check }
                } label: {
                    VStack(alignment: .leading, spacing: compact ? 8 : 16) {
                        HStack {
                            Text(String(UnicodeScalar(65 + index)!)).font(.headline)
                            Spacer()
                            if selected {
                                Label("Selected", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold()).foregroundStyle(.cyan)
                            }
                        }
                        if let picture = choice.picture {
                            QuizPictureView(picture: picture, compact: compact)
                        }
                        Text(choice.text)
                            .font(compact ? .subheadline.bold() : .title3.bold())
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(compact ? 12 : 22)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .foregroundStyle(.white)
                    .background(
                        Color(red: 0.07, green: 0.11, blue: 0.2),
                        in: RoundedRectangle(cornerRadius: 24)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                focused ? .white : selected ? .cyan : .white.opacity(0.3),
                                lineWidth: focused ? 4 : selected ? 3 : 1)
                    }
                    .scaleEffect(focused && !reduceMotion ? 1.025 : 1)
                }
                .buttonStyle(.plain)
                .focused($focusedControl, equals: .answer(choice.id))
                .disabled(
                    isPaused || scenePhase != .active
                        || !session.questionClock.pauseReasons.isDisjoint(with: [
                            .manual, .appInactive, .awaitingResume, .story, .feedback,
                        ])
                )
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Answer \(index + 1): \(choice.text)")
                .accessibilityValue(selected ? "Selected" : "Not selected")
                .accessibilityHint(
                    "Picture idea: \(choice.picture?.detail ?? choice.text). Select, then use Check Answer."
                )
                .accessibilityIdentifier("\(identifierPrefix).answer.\(index)")
            }
        }
        .padding(6)
        .questionFocusSection()
    }

    @ViewBuilder private func challengeControls(interaction: QuestionChallengeInteraction)
        -> some View
    {
        if session.questionClock.mode == .challenge {
            VStack(spacing: 10) {
                if session.questionClock.isExpired {
                    Text("Time for a breather! Your answer and discoveries are safe.")
                        .font(.headline).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("More Time") {
                            session.giveQuestionMoreTime(interaction: interaction)
                        }
                        .focused($focusedControl, equals: .moreTime)
                        .accessibilityIdentifier("\(identifierPrefix).time.more")
                        Button("Continue in Practice") {
                            session.chooseQuestionMode(.practice, interaction: interaction)
                        }
                        .focused($focusedControl, equals: .practice)
                        .accessibilityIdentifier("\(identifierPrefix).time.practice")
                    }.buttonStyle(.borderedProminent).questionFocusSection()
                } else if session.questionClock.pauseReasons.contains(.awaitingResume) {
                    Button("Resume Challenge") {
                        session.resumeQuestionChallenge(interaction: interaction)
                    }
                    .buttonStyle(.borderedProminent).focused($focusedControl, equals: .resume)
                    .accessibilityIdentifier("\(identifierPrefix).time.resume")
                } else {
                    HStack {
                        Image(systemName: "timer")
                        Text(
                            "\(Int(ceil(session.questionClock.remaining))) seconds\(session.questionClock.isRunning ? "" : " · paused")"
                        )
                        .monospacedDigit()
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Optional challenge time")
                    .accessibilityValue(
                        "\(Int(ceil(session.questionClock.remaining))) seconds remaining\(session.questionClock.isRunning ? "" : ", paused")"
                    )
                    .accessibilityIdentifier("\(identifierPrefix).time.remaining")
                    ProgressView(value: session.questionClock.fractionRemaining)
                        .tint(.cyan).accessibilityHidden(true)
                }
            }.padding(12)
                .frame(maxWidth: .infinity)
                .background(.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func utilities(interaction: QuestionChallengeInteraction, compact: Bool) -> some View {
        let layout =
            compact && !dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 12))
        return layout {
            HStack {
                Button {
                    narrator.stop()
                    onBack()
                } label: {
                    Label(backTitle, systemImage: "book")
                }
                .focused($focusedControl, equals: .back)
                .accessibilityIdentifier("\(identifierPrefix).back")
                if let onReplay {
                    Button("Replay the clue") {
                        narrator.stop()
                        onReplay()
                    }
                    .accessibilityIdentifier("\(identifierPrefix).replay")
                }
                Button {
                    session.requestHint()
                    focusAnswer()
                } label: {
                    Label(
                        session.isShowingHint ? "Hint Revealed" : "Show a Hint",
                        systemImage: "lightbulb")
                }.focused($focusedControl, equals: .hint)
                    .accessibilityIdentifier("\(identifierPrefix).hint")
            }
            HStack {
                Button {
                    session.chooseQuestionMode(
                        session.questionClock.mode == .practice ? .challenge : .practice,
                        interaction: interaction)
                } label: {
                    Label(
                        session.questionClock.mode == .practice
                            ? "Try \(Int(session.questionClock.allowance))s Challenge"
                            : "Calm Practice", systemImage: "timer")
                }.focused($focusedControl, equals: .mode)
                    .accessibilityHint(
                        "Optional. Time never changes points, and you can always ask for more."
                    )
                    .accessibilityIdentifier("\(identifierPrefix).time.mode")
                Button {
                    narrationEnabled.toggle()
                } label: {
                    Image(
                        systemName: narrationEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }.focused($focusedControl, equals: .sound)
                    .accessibilityLabel(narrationEnabled ? "Sound On" : "Sound Off")
                    .accessibilityIdentifier("\(identifierPrefix).narration")
                if !voiceOverEnabled {
                    Button("Read Question") { speakQuestion(manual: true) }
                        .focused($focusedControl, equals: .read)
                        .disabled(!narrationEnabled || isPaused || scenePhase != .active)
                        .accessibilityIdentifier("\(identifierPrefix).read")
                }
            }
        }.font(.subheadline).buttonStyle(.bordered).questionFocusSection()
    }

    private func focusAnswer() {
        if session.questionClock.pauseReasons.contains(.awaitingResume) {
            focusedControl = .resume
        } else {
            focusedControl = .answer(
                session.selectedQuizChoiceID ?? session.currentQuiz?.choices.first?.id ?? "")
        }
    }

    private func synchronizePauses() {
        session.setQuestionPaused(.manual, isPaused: isPaused)
        session.setQuestionPaused(.appInactive, isPaused: scenePhase != .active)
    }

    private func speakQuestion(manual: Bool = false) {
        guard let quiz = session.currentQuiz else { return }
        speak(([quiz.prompt] + quiz.choices.map(\.text)).joined(separator: ". "), manual: manual)
    }

    private func speak(_ text: String?, manual: Bool = false) {
        narrator.stop()
        guard narrationEnabled, !voiceOverEnabled, !isPaused, scenePhase == .active,
            ageBand == .ages4To6 || manual, let text
        else { return }
        let interaction = session.questionInteraction
        narrator.speak(text, interaction: interaction) { speaking, token in
            session.setQuestionPaused(.narration, isPaused: speaking, interaction: token)
        }
    }
}

@MainActor
final class QuestionNarrator: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceID: ObjectIdentifier?
    private var interaction: QuestionChallengeInteraction?
    private var onSpeaking: ((Bool, QuestionChallengeInteraction) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(
        _ text: String, interaction: QuestionChallengeInteraction,
        onSpeaking: @escaping (Bool, QuestionChallengeInteraction) -> Void
    ) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.43
        utteranceID = ObjectIdentifier(utterance)
        self.interaction = interaction
        self.onSpeaking = onSpeaking
        onSpeaking(true, interaction)
        synthesizer.speak(utterance)
    }

    func stop() {
        if let interaction { onSpeaking?(false, interaction) }
        utteranceID = nil
        interaction = nil
        onSpeaking = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func finished(_ id: ObjectIdentifier) {
        guard id == utteranceID else { return }
        if let interaction { onSpeaking?(false, interaction) }
        utteranceID = nil
        interaction = nil
        onSpeaking = nil
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finished(id) }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
    ) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finished(id) }
    }
}

extension View {
    @ViewBuilder fileprivate func questionFocusSection() -> some View {
        #if os(tvOS)
            focusSection()
        #else
            self
        #endif
    }
}
