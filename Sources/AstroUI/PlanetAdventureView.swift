import AVFoundation
import AstroGameCore
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// The expedition screens send semantic actions to the core; focus never submits an answer.
struct PlanetAdventureView: View {
    let session: MissionSession
    var isPaused = false

    @AppStorage("astro.narrationEnabled") private var narrationEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @FocusState private var focusedAction: String?
    @State private var narrator = AVSpeechSynthesizer()

    private var ageBand: AgeBand { session.activeMissionAgeBand }
    private var planetName: String { session.focusedLesson?.displayName ?? "Space" }
    private var stepIdentity: String {
        "\(session.phase.rawValue)-\(session.activeCard?.id ?? "")-\(session.activeLearningQuestion?.id ?? "")-\(session.activeActivityTask?.id ?? "")"
    }

    var body: some View {
        Group {
            if session.phase == .missionQuestion || session.phase == .reviewQuestion,
                session.currentQuiz != nil
            {
                QuizChallengeView(
                    session: session,
                    destinationName: session.phase == .reviewQuestion
                        ? "Memory Mission" : session.activePlanetMission?.title ?? "Planet mission",
                    ageBand: session.activeMissionAgeBand,
                    questionIndex: session.activeQuestionIndex,
                    questionCount: session.quizQuestions.count,
                    onBack: { session.returnToWorlds() }, backTitle: "Worlds", isPaused: isPaused
                )
                .id(session.activeLearningQuestion?.id ?? stepIdentity)
            } else if usesSharedQuestionFeedback {
                QuestionFeedbackView(session: session, isPaused: isPaused)
            } else {
                expeditionScreens
            }
        }
        .onAppear { focusAndNarrate() }
        .onChange(of: stepIdentity) { focusAndNarrate() }
        .onChange(of: isPaused) { speakCurrentStep() }
        .onChange(of: scenePhase) { speakCurrentStep() }
        .onChange(of: narrationEnabled) { speakCurrentStep() }
        .onChange(of: voiceOverEnabled) { speakCurrentStep() }
        .onChange(of: session.isShowingHint) {
            if session.phase == .missionActivity, session.isShowingHint,
                let task = session.activeActivityTask
            {
                speak(task.hint[ageBand])
                focusedAction = "activity.0"
            }
        }
        .onChange(of: session.selectedActivityOptionIndex) {
            if let outcome = session.selectedActivityOutcome { speak(outcome) }
        }
        .onDisappear { narrator.stopSpeaking(at: .immediate) }
        .preferredColorScheme(.dark)
    }

    private var expeditionScreens: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 520
            let television = geometry.size.width > 1200
            ZStack {
                LinearGradient(
                    colors: [
                        .indigo.opacity(0.92), Color(red: 0.02, green: 0.05, blue: 0.12),
                        .cyan.opacity(0.2),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: compact ? 8 : 18) {
                    HStack {
                        Label(planetName.uppercased(), systemImage: "sparkles")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Button {
                            narrationEnabled.toggle()
                        } label: {
                            Label(
                                narrationEnabled ? "Sound On" : "Sound Off",
                                systemImage: narrationEnabled
                                    ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("mission.narration")
                    }
                    #if os(tvOS)
                        .focusSection()
                    #endif
                    ScrollView {
                        VStack(spacing: compact ? 12 : 24) {
                            screenContent(compact: compact, television: television)
                        }
                        .frame(maxWidth: television ? 1120 : 850)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                    HStack {
                        Button {
                            narrator.stopSpeaking(at: .immediate)
                            session.returnToWorlds()
                        } label: {
                            Label("Worlds", systemImage: "globe.americas.fill")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("mission.worlds")
                        Spacer()
                        primaryFooter
                        Spacer()
                        Text("\(session.completedPlanetMissionCount) / 24 mission badges")
                            .font(compact ? .caption : .headline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    #if os(tvOS)
                        .focusSection()
                    #endif
                }
                .padding(.horizontal, compact ? 36 : 48)
                .padding(.vertical, compact ? 10 : 28)
            }
        }
    }

    @ViewBuilder
    private func screenContent(compact: Bool, television: Bool) -> some View {
        switch session.phase {
        case .missionSelection:
            missionChooser(compact: compact, television: television)
        case .missionBriefing:
            if let mission = session.activePlanetMission {
                title(mission.title, compact: compact)
                copy(mission.invitation[ageBand], television: television)
                Label("3 clues · 1 science activity · Your pace", systemImage: "map.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                action("Explore More", id: "mission.more", icon: "book.fill", prominent: false) {
                    session.showDeepDive()
                }
            }
        case .missionClue:
            if let card = session.activeCard {
                Text("CLUE \(session.activeCardIndex + 1) OF 3")
                    .font(.headline.weight(.black)).foregroundStyle(.yellow)
                cardView(card, compact: compact, television: television)
            }
        case .missionActivity:
            activity(compact: compact, television: television)
        case .missionStepFeedback, .reviewFeedback:
            Image(systemName: session.wasLastAnswerCorrect ? "sparkles" : "lightbulb.fill")
                .font(.system(size: compact ? 35 : 65))
                .foregroundStyle(.yellow).accessibilityHidden(true)
            copy(session.lastFeedback, television: television)
        case .planetMissionComplete:
            title(
                session.isPlanetExpeditionComplete
                    ? "Planetary expedition complete!" : "Mission discovery saved!",
                compact: compact)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: compact ? 50 : 90)).foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text("Discovery saved in your Passport")
                .font(.title2.bold()).multilineTextAlignment(.center)
            copy(
                "You investigated three clues and played a science activity. Your mission badge is in your passport!",
                television: television)
            passportBadges
            action("Explore More", id: "mission.more", icon: "book.fill", prominent: false) {
                session.showDeepDive()
            }
        case .deepDive:
            if let card = session.deepDiveCard {
                Label("EXPLORE MORE", systemImage: "book.fill")
                    .font(.headline.weight(.black)).foregroundStyle(.yellow)
                cardView(card, compact: compact, television: television)
            }
        case .reviewComplete:
            title("Clues connected!", compact: compact)
            copy(
                "You used earlier discoveries in a new way. Your space knowledge is growing!",
                television: television)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var primaryFooter: some View {
        switch session.phase {
        case .missionBriefing:
            action("Start the Mission", id: "mission.start", icon: "rocket.fill") {
                session.confirm()
            }
        case .missionClue:
            action(
                session.activeCardIndex == 2 ? "Try the Science Activity" : "Check the Clue",
                id: "story.next", icon: "sparkles"
            ) { session.confirm() }
        case .missionStepFeedback, .reviewFeedback:
            action(
                session.wasLastAnswerCorrect ? "Continue" : "Try Again",
                id: "feedback.continue", icon: "arrow.right"
            ) { session.confirm() }
        case .planetMissionComplete:
            action("Continue Exploring", id: "results.continue", icon: "rocket.fill") {
                session.confirm()
            }
        case .deepDive:
            action("Back to My Mission", id: "mission.more.close", icon: "arrow.uturn.backward") {
                session.closeDeepDive()
            }
        case .reviewComplete:
            action("Choose an Adventure", id: "review.complete", icon: "globe.americas.fill") {
                session.returnToWorlds()
            }
        case .missionActivity:
            if session.activeActivity?.family == .experiment,
                let index = session.selectedActivityOptionIndex
            {
                action("Check My Model", id: "activity.check", icon: "checkmark.circle.fill") {
                    session.submitActivityAnswer(at: index)
                }
            }
        default:
            EmptyView()
        }
    }

    private func missionChooser(compact: Bool, television: Bool) -> some View {
        VStack(spacing: compact ? 12 : 22) {
            title("Choose a \(planetName) mission", compact: compact)
            Text("Every adventure is ready to explore")
                .font(.headline).foregroundStyle(.white.opacity(0.8))
            passportBadges
            if session.hasSavedAdventure {
                action(
                    "Resume: \(session.savedAdventureTitle ?? "My Adventure")",
                    id: "mission.resume", icon: "play.fill"
                ) {
                    session.resumeSavedAdventure()
                }
            }
            ForEach(session.availableMissions) { mission in
                let completed = session.progress.completedMissionIDs.contains(mission.id)
                let suggested = session.suggestedMission?.id == mission.id
                Button {
                    session.selectPlanetMission(id: mission.id)
                } label: {
                    HStack(spacing: 18) {
                        Image(
                            systemName: completed
                                ? "checkmark.seal.fill" : "sparkle.magnifyingglass"
                        )
                        .font(.title).foregroundStyle(completed ? .yellow : .cyan)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(mission.title).font(
                                (television ? Font.title2 : Font.headline).bold())
                            Text(
                                completed
                                    ? "Badge collected · Explore again"
                                    : suggested
                                        ? "Mission Control suggests this adventure"
                                        : "3 clues and a science activity"
                            )
                            .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .padding(compact ? 14 : 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.bordered)
                .focused($focusedAction, equals: mission.id)
                .accessibilityIdentifier("mission.select.\(mission.id)")
            }
            ForEach(session.availableVideoLessons) { video in
                action(
                    "Watch and Discover", id: "video.start.\(video.destinationID)",
                    icon: "play.rectangle.fill",
                    prominent: false
                ) { session.startVideoLesson(id: video.id) }
            }
        }
    }

    private var passportBadges: some View {
        HStack(spacing: 12) {
            ForEach(Array(session.availableMissions.enumerated()), id: \.element.id) {
                index, mission in
                let earned = session.progress.completedMissionIDs.contains(mission.id)
                Label("Mission \(index + 1)", systemImage: earned ? "checkmark.seal.fill" : "seal")
                    .font(.subheadline.bold())
                    .foregroundStyle(earned ? .yellow : .white.opacity(0.7))
                    .accessibilityLabel(
                        "\(mission.title), \(earned ? "badge collected" : "ready to explore")")
            }
        }
        .accessibilityIdentifier("mission.passport")
    }

    private func cardView(_ card: MissionCard, compact: Bool, television: Bool) -> some View {
        VStack(spacing: compact ? 12 : 22) {
            title(card.title, compact: compact)
            if let picture = discoveryImage(named: card.imageName) {
                picture.resizable().scaledToFit()
                    .frame(maxHeight: compact ? 135 : television ? 310 : 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
            }
            copy(card.body[ageBand], television: television)
            Text("\(card.imageCredit) · \(card.imageSourceID)")
                .font(.caption).foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func activity(compact: Bool, television: Bool) -> some View {
        if let mission = session.activePlanetMission, let task = session.activeActivityTask {
            Label(
                mission.activity.family == .experiment
                    ? "SCIENCE MODEL"
                    : mission.activity.family == .classify ? "SORT THE CLUES" : "EVIDENCE HUNT",
                systemImage: mission.activity.family == .experiment
                    ? "slider.horizontal.3" : "sparkle.magnifyingglass"
            )
            .font(.headline.weight(.black)).foregroundStyle(.yellow)
            title(mission.activity.title, compact: compact)
            if let picture = discoveryImage(named: task.imageName) {
                picture.resizable().scaledToFit()
                    .frame(maxHeight: compact ? 100 : 230)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
            }
            copy(task.prompt[ageBand], television: television)
            ForEach(Array(session.activityOptions.enumerated()), id: \.element.id) {
                index, option in
                Button {
                    if mission.activity.family == .experiment {
                        session.selectActivityOption(at: index)
                    } else {
                        session.submitActivityAnswer(at: index)
                    }
                } label: {
                    HStack {
                        Image(systemName: option.symbol).font(.title2).accessibilityHidden(true)
                        Text(option.label[ageBand]).font(
                            (television ? Font.title3 : Font.headline).bold())
                        Spacer()
                        if session.selectedActivityOptionIndex == index {
                            Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .focused($focusedAction, equals: "activity.\(index)")
                .accessibilityIdentifier("activity.option.\(index)")
            }
            if mission.activity.family == .experiment,
                let selection = session.selectedActivityOptionIndex,
                let outcome = session.selectedActivityOutcome
            {
                ScienceModelDiagram(
                    optionID: session.activityOptions[selection].id,
                    destinationID: mission.destinationID
                )
                .frame(height: compact ? 120 : 180)
                .accessibilityHidden(true)
                Text("Illustrative model · Sizes and distances simplified")
                    .font(.caption).foregroundStyle(.white.opacity(0.65))
                copy(outcome, television: television)
                    .padding(16).background(
                        .cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
            }
            if session.isShowingHint {
                copy(task.hint[ageBand], television: television).foregroundStyle(.yellow)
            }
            action(
                session.isShowingHint ? "Hint Revealed" : "Show a Hint", id: "activity.hint",
                icon: "lightbulb.fill", prominent: false
            ) { session.requestHint() }
        }
    }

    private func title(_ text: String, compact: Bool) -> some View {
        Text(text).font(.system(size: compact ? 26 : 38, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private func copy(_ text: String, television: Bool) -> some View {
        Text(text).font(.system(size: television ? 29 : 21, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 1000)
    }

    private func action(
        _ label: String, id: String, icon: String, prominent: Bool = true,
        perform: @escaping () -> Void
    ) -> some View {
        Group {
            if prominent {
                Button(action: perform) { Label(label, systemImage: icon).font(.headline.bold()) }
                    .buttonStyle(.borderedProminent).tint(.cyan)
            } else {
                Button(action: perform) { Label(label, systemImage: icon).font(.headline.bold()) }
                    .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
        .focused($focusedAction, equals: id)
        .accessibilityIdentifier(id)
    }

    private func focusAndNarrate() {
        if usesSharedQuestionFeedback {
            narrator.stopSpeaking(at: .immediate)
            return
        }
        switch session.phase {
        case .missionSelection:
            focusedAction =
                session.hasSavedAdventure
                ? "mission.resume"
                : session.suggestedMission?.id ?? session.availableMissions.first?.id
        case .missionBriefing: focusedAction = "mission.start"
        case .missionClue: focusedAction = "story.next"
        case .missionActivity: focusedAction = "activity.0"
        case .missionStepFeedback, .reviewFeedback: focusedAction = "feedback.continue"
        case .planetMissionComplete: focusedAction = "results.continue"
        case .deepDive: focusedAction = "mission.more.close"
        case .reviewComplete: focusedAction = "review.complete"
        default: break
        }
        speakCurrentStep()
    }

    private func speakCurrentStep() {
        if usesSharedQuestionFeedback {
            narrator.stopSpeaking(at: .immediate)
            return
        }
        switch session.phase {
        case .missionBriefing: speak(session.activePlanetMission?.invitation[ageBand] ?? "")
        case .missionClue: speak(session.activeCard?.body[ageBand] ?? "")
        case .deepDive: speak(session.deepDiveCard?.body[ageBand] ?? "")
        case .missionActivity:
            let choices = session.activityOptions.map { $0.label[ageBand] }.joined(separator: ". ")
            speak("\(session.activeActivityTask?.prompt[ageBand] ?? "") \(choices)")
        case .missionStepFeedback, .reviewFeedback: speak(session.lastFeedback)
        default: narrator.stopSpeaking(at: .immediate)
        }
    }

    private var usesSharedQuestionFeedback: Bool {
        session.phase == .reviewFeedback
            || (session.phase == .missionStepFeedback
                && session.progress.activeRun?.stepID == session.activeLearningQuestion?.id)
    }

    private func speak(_ text: String) {
        narrator.stopSpeaking(at: .immediate)
        guard narrationEnabled, !voiceOverEnabled, !isPaused, scenePhase == .active, !text.isEmpty
        else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = ageBand == .ages4To6 ? 0.43 : 0.48
        narrator.speak(utterance)
    }
}

func discoveryImage(named name: String) -> Image? {
    guard let url = Bundle.module.url(forResource: name, withExtension: "jpg") else { return nil }
    #if canImport(UIKit)
        guard let picture = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: picture)
    #elseif canImport(AppKit)
        guard let picture = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: picture)
    #else
        return nil
    #endif
}
