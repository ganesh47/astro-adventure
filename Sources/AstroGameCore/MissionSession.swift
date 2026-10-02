import Foundation
import Observation

public enum MissionPhase: String, Codable, Sendable {
    case missionPrompt
    case navigation
    case discoveryCard
    case quiz
    case quizFeedback
    case quizRoundComplete
    case missionComplete
    case missionSelection
    case missionBriefing
    case missionClue
    case missionQuestion
    case missionActivity
    case missionStepFeedback
    case planetMissionComplete
    case videoPlayback
    case videoCheckpoint
    case videoFeedback
    case videoComplete
    case reviewQuestion
    case reviewFeedback
    case reviewComplete
    case deepDive
}

@Observable
public final class MissionSession {
    public let missionID: String
    public let lessons: [DestinationLesson]
    public let planetMissions: [PlanetMission]
    public let videoLessons: [VideoLesson]

    public private(set) var phase: MissionPhase
    public private(set) var focusedDestinationIndex: Int
    public private(set) var focusedQuizChoiceIndex: Int
    public private(set) var isShowingHint: Bool
    public private(set) var wasLastAnswerCorrect: Bool
    public private(set) var lastFeedback: String
    public private(set) var progress: GameProgress
    public private(set) var quizQuestionIndex: Int
    public private(set) var roundScore: Int
    public private(set) var roundCorrectAnswers: Int
    public private(set) var currentStreak: Int
    public private(set) var roundBestStreak: Int
    public private(set) var questionAttemptCount: Int

    public private(set) var activeRoundAgeBand: AgeBand?
    public private(set) var activeReviewQuestions: [LearningQuestion] = []
    public private(set) var selectedActivityOptionIndex: Int?
    public private(set) var videoPlaybackSeconds: Double = 0
    public private(set) var videoSeekTarget: Double?
    public private(set) var isVideoPlaying = false
    public private(set) var isVideoFallback = false
    private var deepDiveReturnPhase: MissionPhase?
    private var selectedDeepDiveCard: MissionCard?
    private var activeRoundQuestions: [QuizContent] = []
    private var hasFinishedRound = false

    private let quizProvider: (String, AgeBand) -> [QuizContent]

    public var ageBand: AgeBand {
        get { progress.selectedAgeBand }
        set {
            guard !isRoundInProgress else { return }
            progress.selectedAgeBand = newValue
            focusedQuizChoiceIndex = 0
            isShowingHint = false
        }
    }

    public var isRoundInProgress: Bool {
        phase == .quiz || phase == .quizFeedback || phase == .quizRoundComplete || isNewRunPhase
    }

    public var suggestedDestinationIndex: Int? {
        guard !lessons.isEmpty else { return nil }
        return (1...lessons.count).map {
            (focusedDestinationIndex + $0) % lessons.count
        }.first { progress.destinations[lessons[$0].id]?.isQuizCompleted != true }
    }

    public func exploreNextDestination() {
        guard phase == .navigation || phase == .quizRoundComplete else { return }
        if let next = suggestedDestinationIndex {
            focusedDestinationIndex = next
        }
        phase = isMissionComplete ? .missionComplete : .navigation
        resetTransientState()
    }

    public var focusedLesson: DestinationLesson? {
        guard lessons.indices.contains(focusedDestinationIndex) else { return nil }
        return lessons[focusedDestinationIndex]
    }

    public var focusedContent: AgeBandLessonContent? {
        focusedLesson?.content[ageBand]
    }

    public var quizQuestions: [QuizContent] {
        if isNewRunPhase {
            if let mission = activePlanetMission {
                return mission.questions.map { $0.content[activeMissionAgeBand] }
            }
            if let video = activeVideoLesson {
                return video.checkpoints.map { $0.question.content[activeMissionAgeBand] }
            }
            return activeReviewQuestions.map { $0.reviewContent[activeMissionAgeBand] }
        }
        if isRoundInProgress { return activeRoundQuestions }
        guard let lesson = focusedLesson else { return [] }
        let provided = quizProvider(lesson.id, ageBand)
        return provided.isEmpty ? [lesson.content[ageBand].quiz] : provided
    }

    public var currentQuiz: QuizContent? {
        if let question = activeLearningQuestion, isNewRunPhase {
            return phase == .reviewQuestion || phase == .reviewFeedback || phase == .reviewComplete
                ? question.reviewContent[activeMissionAgeBand]
                : question.content[activeMissionAgeBand]
        }
        let questions = quizQuestions
        guard questions.indices.contains(quizQuestionIndex) else { return nil }
        return questions[quizQuestionIndex]
    }

    public var quizProgressText: String {
        "Question \(min(quizQuestionIndex + 1, quizQuestions.count)) of \(quizQuestions.count)"
    }

    public var roundStars: Int {
        // Every completed discovery earns the same celebration, with unlimited help.
        hasFinishedRound ? 3 : 0
    }

    public var completedDestinationCount: Int {
        lessons.count { progress.destinations[$0.id]?.isQuizCompleted == true }
    }

    public var isMissionComplete: Bool {
        !lessons.isEmpty && completedDestinationCount == lessons.count
    }

    public init(
        missionID: String = "signal-sweep",
        lessons: [DestinationLesson],
        progress: GameProgress? = nil,
        quizProvider: @escaping (String, AgeBand) -> [QuizContent] = { _, _ in [] },
        planetMissions: [PlanetMission] = [],
        videoLessons: [VideoLesson] = []
    ) {
        self.missionID = missionID
        self.lessons = lessons
        self.planetMissions = planetMissions
        self.videoLessons = videoLessons
        self.quizProvider = quizProvider
        self.progress =
            progress
            ?? GameProgress(
                missionID: missionID,
                destinations: Dictionary(
                    uniqueKeysWithValues: lessons.map { ($0.id, DestinationProgress()) }
                )
            )
        self.phase = .missionPrompt
        self.focusedDestinationIndex = 0
        self.focusedQuizChoiceIndex = 0
        self.isShowingHint = false
        self.wasLastAnswerCorrect = false
        self.lastFeedback = ""
        self.quizQuestionIndex = 0
        self.roundScore = 0
        self.roundCorrectAnswers = 0
        self.currentStreak = 0
        self.roundBestStreak = 0
        self.questionAttemptCount = 0

        for lesson in lessons where self.progress.destinations[lesson.id] == nil {
            self.progress.destinations[lesson.id] = DestinationProgress()
        }
    }

    public func selectDestination(at index: Int) {
        guard phase == .navigation || phase == .missionPrompt,
            lessons.indices.contains(index)
        else { return }
        focusedDestinationIndex = index
        resetTransientState()
    }

    /// Exploration publishes a complete save snapshot through the existing persistence owner.
    public func applyExplorationProgress(_ updated: GameProgress) {
        progress = updated
    }

    public func focusNext() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz || phase == .missionQuestion || phase == .videoCheckpoint
            || phase == .reviewQuestion
        {
            moveQuizFocus(by: 1)
            return
        }
        guard phase == .navigation || phase == .missionPrompt else { return }
        focusedDestinationIndex = (focusedDestinationIndex + 1) % lessons.count
        resetTransientState()
    }

    public func focusPrevious() {
        guard !lessons.isEmpty else { return }
        if phase == .quiz || phase == .missionQuestion || phase == .videoCheckpoint
            || phase == .reviewQuestion
        {
            moveQuizFocus(by: -1)
            return
        }
        guard phase == .navigation || phase == .missionPrompt else { return }
        focusedDestinationIndex =
            (focusedDestinationIndex - 1 + lessons.count) % lessons.count
        resetTransientState()
    }

    public func confirm(now: Date = Date()) {
        if confirmAdventure(now: now) { return }
        guard let lesson = focusedLesson else { return }
        isShowingHint = false

        switch phase {
        case .missionPrompt:
            phase = .navigation
        case .navigation:
            markScanned(destinationID: lesson.id)
            if availableMissions.isEmpty {
                // Bonus discoveries keep their existing restart behavior and replace an older run.
                progress.activeRun = nil
                phase = .discoveryCard
            } else {
                phase = .missionSelection
            }
        case .discoveryCard:
            beginQuizRound()
            phase = .quiz
        case .quiz:
            submitAnswer(at: focusedQuizChoiceIndex, now: now)
        case .quizFeedback:
            if wasLastAnswerCorrect {
                if quizQuestionIndex + 1 < quizQuestions.count {
                    quizQuestionIndex += 1
                    focusedQuizChoiceIndex = 0
                    questionAttemptCount = 0
                    phase = .quiz
                } else {
                    phase = .quizRoundComplete
                }
            } else {
                phase = .quiz
            }
        case .quizRoundComplete:
            exploreNextDestination()
        case .missionComplete:
            phase = .navigation
        default:
            break
        }
    }

    public func back() {
        if phase == .deepDive {
            closeDeepDive()
            return
        }
        if isNewRunPhase {
            returnToWorlds()
            return
        }
        isShowingHint = false
        switch phase {
        case .navigation:
            phase = .missionPrompt
        case .quiz:
            phase = .discoveryCard
        case .discoveryCard, .quizFeedback, .quizRoundComplete, .missionComplete:
            phase = .navigation
        case .missionSelection:
            phase = .navigation
        default:
            break
        }
    }

    public func returnToWorlds() {
        if isNewRunPhase, phase != .deepDive { persistRun() }
        isVideoPlaying = false
        videoSeekTarget = nil
        phase = .navigation
        resetTransientState()
    }

    public func requestHint() {
        guard
            phase == .quiz || phase == .missionQuestion || phase == .missionActivity
                || phase == .videoCheckpoint || phase == .reviewQuestion
        else { return }
        isShowingHint = true
        if isNewRunPhase {
            let conceptID =
                phase == .missionActivity
                ? activeActivity?.conceptID : activeLearningQuestion?.conceptID
            if let conceptID {
                progress.activeRun?.assistedConceptIDs.insert(conceptID)
            }
            persistRun()
        }
    }

    public func moveQuizFocus(by direction: Int) {
        guard
            phase == .quiz || phase == .missionQuestion || phase == .videoCheckpoint
                || phase == .reviewQuestion,
            let choices = currentQuiz?.choices, !choices.isEmpty
        else {
            return
        }

        focusedQuizChoiceIndex =
            (focusedQuizChoiceIndex + direction + choices.count) % choices.count
    }

    public func submitAnswer(at choiceIndex: Int, now: Date = Date()) {
        if phase == .missionQuestion || phase == .videoCheckpoint || phase == .reviewQuestion {
            submitLearningAnswer(at: choiceIndex, now: now)
            return
        }
        guard
            phase == .quiz,
            let lesson = focusedLesson,
            let quiz = currentQuiz,
            quiz.choices.indices.contains(choiceIndex)
        else {
            return
        }

        var destinationProgress = progress.destinations[lesson.id] ?? DestinationProgress()
        destinationProgress.attempts += 1
        questionAttemptCount += 1

        let isCorrect = quiz.choices[choiceIndex].id == quiz.correctChoiceID
        wasLastAnswerCorrect = isCorrect
        lastFeedback = isCorrect ? quiz.correctFeedback : quiz.retryFeedback
        phase = .quizFeedback

        if isCorrect {
            roundCorrectAnswers += 1
            roundScore += 100
        }

        destinationProgress.isQuizCompleted =
            destinationProgress.isQuizCompleted
            || (isCorrect && quizQuestionIndex == quizQuestions.count - 1)
        destinationProgress.correctAnswers += isCorrect ? 1 : 0
        destinationProgress.masteryScore = min(
            max(
                destinationProgress.masteryScore
                    + LearningEngine.masteryDelta(
                        answeredCorrectly: isCorrect,
                        attempts: destinationProgress.attempts
                    ),
                0
            ),
            100
        )
        destinationProgress.reviewBox = LearningEngine.nextReviewBox(
            current: destinationProgress.reviewBox,
            answeredCorrectly: isCorrect
        )
        let delay = LearningEngine.reviewDelayDays(for: destinationProgress.reviewBox)
        destinationProgress.nextReviewAt = now.addingTimeInterval(
            TimeInterval(delay * 24 * 60 * 60)
        )
        progress.destinations[lesson.id] = destinationProgress
        if isCorrect && quizQuestionIndex == activeRoundQuestions.count - 1 {
            finishQuizRound(now: now)
        }
    }

    private func markScanned(destinationID: String) {
        var destinationProgress =
            progress.destinations[destinationID] ?? DestinationProgress()
        destinationProgress.isScanned = true
        progress.destinations[destinationID] = destinationProgress
    }

    private func resetTransientState() {
        focusedQuizChoiceIndex = 0
        isShowingHint = false
    }

    private func beginQuizRound() {
        activeRoundAgeBand = ageBand
        activeRoundQuestions = quizQuestions
        hasFinishedRound = false
        quizQuestionIndex = 0
        focusedQuizChoiceIndex = 0
        roundScore = 0
        roundCorrectAnswers = 0
        currentStreak = 0
        roundBestStreak = 0
        questionAttemptCount = 0
        isShowingHint = false
    }

    private func finishQuizRound(now: Date) {
        guard !hasFinishedRound, let lesson = focusedLesson else { return }
        hasFinishedRound = true
        var destinationProgress = progress.destinations[lesson.id] ?? DestinationProgress()
        destinationProgress.bestRoundScore = max(destinationProgress.bestRoundScore, roundScore)
        destinationProgress.bestRoundStars = max(destinationProgress.bestRoundStars, roundStars)
        progress.destinations[lesson.id] = destinationProgress
        progress.totalScore += roundScore
        progress.bestStreak = max(progress.bestStreak, roundBestStreak)
        progress.leaderboard.append(
            LeaderboardEntry(
                explorerName: (activeRoundAgeBand ?? ageBand).modeName,
                destinationName: lesson.displayName,
                score: roundScore,
                correctAnswers: roundCorrectAnswers,
                totalQuestions: quizQuestions.count,
                bestStreak: roundBestStreak,
                achievedAt: now
            )
        )
        progress.leaderboard = Array(
            progress.leaderboard.sorted { $0.achievedAt > $1.achievedAt }.prefix(20)
        )
    }
}

extension MissionSession {
    public var availableMissions: [PlanetMission] {
        planetMissions.filter { $0.destinationID == focusedLesson?.id }
    }

    public var availableVideoLessons: [VideoLesson] {
        videoLessons.filter { $0.destinationID == focusedLesson?.id }
    }

    public var dueReviewQuestions: [LearningQuestion] { reviewQuestionsDue(now: Date()) }

    public var activePlanetMission: PlanetMission? {
        guard let cursor = progress.activeRun, cursor.kind == .planetMission else { return nil }
        return planetMissions.first { $0.id == cursor.contentID }
    }

    public var activeVideoLesson: VideoLesson? {
        guard let cursor = progress.activeRun, cursor.kind == .video else { return nil }
        return videoLessons.first { $0.id == cursor.contentID }
    }

    public var activeMissionAgeBand: AgeBand {
        isNewRunPhase ? progress.activeRun?.ageBand ?? ageBand : ageBand
    }
    public var activeCardIndex: Int { progress.activeRun?.cardIndex ?? 0 }
    public var activeQuestionIndex: Int { progress.activeRun?.questionIndex ?? 0 }
    public var currentActivityTaskIndex: Int { progress.activeRun?.activityTaskIndex ?? 0 }
    public var currentReviewQuestionIndex: Int { activeQuestionIndex }
    public var hasSavedAdventure: Bool {
        guard let savedPhase = progress.activeRun?.phase else { return false }
        return savedPhase != .planetMissionComplete && savedPhase != .videoComplete
            && savedPhase != .reviewComplete
    }

    public var savedAdventureTitle: String? {
        switch progress.activeRun?.kind {
        case .planetMission: activePlanetMission?.title
        case .video: activeVideoLesson?.title
        case .review: "A quick clue adventure"
        case nil: nil
        }
    }

    public var activeCard: MissionCard? {
        guard let mission = activePlanetMission else { return nil }
        if phase == .deepDive { return mission.deepDive }
        return mission.cards.indices.contains(activeCardIndex)
            ? mission.cards[activeCardIndex] : nil
    }

    public var deepDiveCard: MissionCard? {
        if phase == .deepDive { return selectedDeepDiveCard }
        return (phase == .missionSelection ? suggestedMission : activePlanetMission)?.deepDive
    }

    public var activeActivity: ScienceActivity? { activePlanetMission?.activity }

    public var activeActivityTask: ActivityTask? {
        guard let activity = activeActivity,
            activity.tasks.indices.contains(currentActivityTaskIndex)
        else { return nil }
        return activity.tasks[currentActivityTaskIndex]
    }

    public var activityOptions: [ActivityOption] { activeActivityTask?.options ?? [] }

    public var selectedActivityOutcome: String? {
        guard let index = selectedActivityOptionIndex, activityOptions.indices.contains(index)
        else { return nil }
        return activityOptions[index].outcome[activeMissionAgeBand]
    }

    public var activeLearningQuestion: LearningQuestion? {
        guard let cursor = progress.activeRun else { return nil }
        switch cursor.kind {
        case .planetMission:
            guard let mission = activePlanetMission,
                mission.questions.indices.contains(cursor.questionIndex)
            else { return nil }
            return mission.questions[cursor.questionIndex]
        case .video:
            return activeVideoCheckpoint?.question
        case .review:
            guard activeReviewQuestions.indices.contains(cursor.questionIndex) else { return nil }
            return activeReviewQuestions[cursor.questionIndex]
        }
    }

    public var activeVideoCheckpoint: VideoCheckpoint? {
        guard let video = activeVideoLesson,
            video.checkpoints.indices.contains(activeQuestionIndex)
        else { return nil }
        return video.checkpoints[activeQuestionIndex]
    }

    public var videoFallbackCardIndex: Int {
        guard let video = activeVideoLesson else { return 0 }
        let index = nextPendingCheckpointIndex ?? max(video.fallbackCards.count - 1, 0)
        return min(index, max(video.fallbackCards.count - 1, 0))
    }

    public var completedPlanetMissionCount: Int {
        planetMissions.count { progress.missionCompletions[$0.id] != nil }
    }

    public var isPlanetExpeditionComplete: Bool {
        !planetMissions.isEmpty && completedPlanetMissionCount == planetMissions.count
    }

    public var suggestedMission: PlanetMission? {
        availableMissions.first { progress.missionCompletions[$0.id] == nil }
            ?? availableMissions.first
    }

    public func selectPlanetMission(id: String) {
        guard phase == .missionSelection || phase == .navigation || phase == .missionPrompt,
            let mission = planetMissions.first(where: { $0.id == id }),
            !mission.cards.isEmpty, mission.cards.count == mission.questions.count,
            !mission.activity.tasks.isEmpty
        else { return }
        focusDestination(id: mission.destinationID)
        markScanned(destinationID: mission.destinationID)
        progress.activeRun = AdventureRunCursor(
            kind: .planetMission, contentID: id, destinationID: mission.destinationID,
            revision: mission.revision, ageBand: ageBand, phase: .missionBriefing
        )
        resetAdventureQuestion()
        selectedActivityOptionIndex = nil
        isVideoPlaying = false
        videoPlaybackSeconds = 0
        isVideoFallback = false
        videoSeekTarget = nil
        phase = .missionBriefing
        persistRun()
    }

    public func selectActivityOption(at index: Int) {
        guard phase == .missionActivity, activityOptions.indices.contains(index) else { return }
        let optionID = activityOptions[index].id
        selectedActivityOptionIndex = index
        progress.activeRun?.selectedActivityOptionID = optionID
        persistRun()
    }

    public func submitActivityAnswer(at index: Int) {
        guard phase == .missionActivity, let task = activeActivityTask,
            task.options.indices.contains(index)
        else { return }
        selectActivityOption(at: index)
        questionAttemptCount += 1
        wasLastAnswerCorrect = task.options[index].id == task.correctOptionID
        lastFeedback =
            wasLastAnswerCorrect
            ? task.explanation[activeMissionAgeBand]
            : "\(task.options[index].outcome[activeMissionAgeBand]) \(task.hint[activeMissionAgeBand])"
        if wasLastAnswerCorrect {
            progress.activeRun?.completedActivityTaskIDs.insert(task.id)
        } else if let conceptID = activeActivity?.conceptID {
            progress.activeRun?.assistedConceptIDs.insert(conceptID)
        }
        progress.activeRun?.stepID = task.id
        phase = .missionStepFeedback
        persistRun()
    }

    public func showDeepDive() {
        guard
            phase == .missionSelection || phase == .missionBriefing
                || phase == .planetMissionComplete,
            deepDiveCard != nil
        else { return }
        selectedDeepDiveCard = deepDiveCard
        deepDiveReturnPhase = phase
        phase = .deepDive
    }

    public func closeDeepDive() {
        guard phase == .deepDive else { return }
        phase = deepDiveReturnPhase ?? .missionSelection
        deepDiveReturnPhase = nil
        selectedDeepDiveCard = nil
    }

    public func startVideoLesson(id: String) {
        guard
            phase == .missionSelection || phase == .navigation || phase == .missionPrompt
                || phase == .planetMissionComplete,
            let video = videoLessons.first(where: { $0.id == id }),
            video.duration.isFinite, video.duration > 0, !video.checkpoints.isEmpty
        else { return }
        focusDestination(id: video.destinationID)
        markScanned(destinationID: video.destinationID)
        progress.activeRun = AdventureRunCursor(
            kind: .video, contentID: id, destinationID: video.destinationID,
            revision: video.revision, ageBand: ageBand, phase: .videoPlayback
        )
        resetAdventureQuestion()
        videoPlaybackSeconds = 0
        videoSeekTarget = 0
        isVideoPlaying = false
        isVideoFallback = false
        phase = .videoPlayback
        persistRun()
    }

    public func playVideo() {
        guard phase == .videoPlayback, !isVideoFallback else { return }
        isVideoPlaying = true
    }

    public func pauseVideo() {
        isVideoPlaying = false
        if phase == .videoPlayback { persistRun() }
    }

    public func videoSeekCompleted() { videoSeekTarget = nil }

    public func playbackTimeChanged(seconds: Double) {
        guard phase == .videoPlayback, isVideoPlaying, !isVideoFallback,
            videoSeekTarget == nil, seconds.isFinite, let video = activeVideoLesson
        else { return }
        videoPlaybackSeconds = min(max(seconds, 0), video.duration)
        if let index = nextPendingCheckpointIndex,
            videoPlaybackSeconds >= video.checkpoints[index].time
        {
            presentVideoCheckpoint(at: index)
        } else {
            // Persist whole seconds rather than generating a save on every player tick.
            if Int(progress.activeRun?.videoSeconds ?? 0) != Int(videoPlaybackSeconds) {
                persistRun()
            }
        }
    }

    public func videoSeek(to seconds: Double) {
        guard phase == .videoPlayback, seconds.isFinite, let video = activeVideoLesson else {
            return
        }
        let bounded = min(max(seconds, 0), video.duration)
        if let index = nextPendingCheckpointIndex, bounded >= video.checkpoints[index].time {
            presentVideoCheckpoint(at: index)
        } else {
            videoPlaybackSeconds = bounded
            videoSeekTarget = bounded
            persistRun()
        }
    }

    public func replayVideoClue() {
        guard phase == .videoCheckpoint || (phase == .videoFeedback && !wasLastAnswerCorrect),
            let checkpoint = activeVideoCheckpoint
        else { return }
        progress.activeRun?.assistedConceptIDs.insert(checkpoint.question.conceptID)
        videoPlaybackSeconds = max(0, checkpoint.replayStartTime)
        videoSeekTarget = videoPlaybackSeconds
        isVideoPlaying = !isVideoFallback
        isShowingHint = false
        phase = .videoPlayback
        persistRun()
    }

    public func videoFailed() {
        guard progress.activeRun?.kind == .video,
            phase == .videoPlayback || phase == .videoCheckpoint || phase == .videoFeedback
        else { return }
        isVideoPlaying = false
        isVideoFallback = true
        videoSeekTarget = nil
        persistRun()
    }

    public func continueVideoFallback(now: Date = Date()) {
        guard phase == .videoPlayback, isVideoFallback else { return }
        if let index = nextPendingCheckpointIndex {
            presentVideoCheckpoint(at: index)
        } else {
            if let video = activeVideoLesson { finishVideoLesson(video, now: now) }
            phase = .videoComplete
            persistRun()
        }
    }

    public func videoDidEnd(now: Date = Date()) {
        guard phase == .videoPlayback, isVideoPlaying, !isVideoFallback else { return }
        if let index = nextPendingCheckpointIndex {
            presentVideoCheckpoint(at: index)
        } else {
            if let video = activeVideoLesson { finishVideoLesson(video, now: now) }
            isVideoPlaying = false
            phase = .videoComplete
            persistRun()
        }
    }

    public func dueReviewConceptCount(now: Date = Date()) -> Int {
        reviewQuestionsDue(now: now).count
    }

    public func startReview(now: Date = Date()) {
        guard
            phase == .navigation || phase == .missionPrompt || phase == .missionSelection
                || phase == .planetMissionComplete || phase == .videoComplete
        else { return }
        let questions = Array(reviewQuestionsDue(now: now).prefix(2))
        guard let first = questions.first else { return }
        activeReviewQuestions = questions
        progress.activeRun = AdventureRunCursor(
            kind: .review, contentID: "quick-clue-review", destinationID: focusedLesson?.id ?? "",
            revision: 1, ageBand: ageBand, phase: .reviewQuestion, stepID: first.id
        )
        progress.activeRun?.reviewQuestionIDs = questions.map(\.id)
        resetAdventureQuestion()
        isVideoPlaying = false
        videoPlaybackSeconds = 0
        isVideoFallback = false
        videoSeekTarget = nil
        phase = .reviewQuestion
        persistRun()
    }

    /// Loading the app never starts media. Resume is an explicit player action.
    public func resumeSavedAdventure() {
        guard phase == .missionPrompt || phase == .navigation || phase == .missionSelection,
            var cursor = progress.activeRun
        else { return }
        switch cursor.kind {
        case .planetMission:
            guard let mission = planetMissions.first(where: { $0.id == cursor.contentID }) else {
                discardUnavailableCursor()
                return
            }
            let validPhase: Set<MissionPhase> = [
                .missionBriefing, .missionClue, .missionQuestion, .missionActivity,
                .missionStepFeedback, .planetMissionComplete,
            ]
            let indicesAreValid =
                mission.cards.indices.contains(cursor.cardIndex)
                && mission.questions.indices.contains(cursor.questionIndex)
                && mission.activity.tasks.indices.contains(cursor.activityTaskIndex)
            var expectedStepIDs = Set<String>()
            if indicesAreValid {
                switch cursor.phase {
                case .missionBriefing: expectedStepIDs = [mission.id]
                case .missionClue: expectedStepIDs = [mission.cards[cursor.cardIndex].id]
                case .missionQuestion:
                    expectedStepIDs = [mission.questions[cursor.questionIndex].id]
                case .missionActivity:
                    expectedStepIDs = [mission.activity.tasks[cursor.activityTaskIndex].id]
                case .missionStepFeedback:
                    expectedStepIDs = [
                        mission.questions[cursor.questionIndex].id,
                        mission.activity.tasks[cursor.activityTaskIndex].id,
                    ]
                case .planetMissionComplete: expectedStepIDs = ["complete"]
                default: break
                }
            }
            if cursor.revision != mission.revision || !validPhase.contains(cursor.phase)
                || !indicesAreValid || !expectedStepIDs.contains(cursor.stepID)
            {
                cursor = AdventureRunCursor(
                    kind: .planetMission, contentID: mission.id,
                    destinationID: mission.destinationID, revision: mission.revision,
                    ageBand: cursor.ageBand, phase: .missionBriefing, stepID: mission.id
                )
            }
            cursor.completedQuestionIDs.formIntersection(mission.questions.map(\.id))
            cursor.completedActivityTaskIDs.formIntersection(mission.activity.tasks.map(\.id))
        case .video:
            guard let video = videoLessons.first(where: { $0.id == cursor.contentID }) else {
                discardUnavailableCursor()
                return
            }
            let validPhase: Set<MissionPhase> = [
                .videoPlayback, .videoCheckpoint, .videoFeedback, .videoComplete,
            ]
            let expectedStepID =
                cursor.phase == .videoComplete
                ? "complete"
                : video.checkpoints.indices.contains(cursor.questionIndex)
                    ? video.checkpoints[cursor.questionIndex].id : nil
            if cursor.revision != video.revision || !validPhase.contains(cursor.phase)
                || !video.checkpoints.indices.contains(cursor.questionIndex)
                || cursor.stepID != expectedStepID
            {
                cursor = AdventureRunCursor(
                    kind: .video, contentID: video.id, destinationID: video.destinationID,
                    revision: video.revision, ageBand: cursor.ageBand, phase: .videoPlayback
                )
            }
            cursor.completedCheckpointIDs.formIntersection(video.checkpoints.map(\.id))
            cursor.videoSeconds =
                cursor.videoSeconds.isFinite
                ? min(max(cursor.videoSeconds, 0), video.duration) : 0
        case .review:
            let questionsByID = allLearningQuestions.reduce(into: [String: LearningQuestion]()) {
                $0[$1.id] = $1
            }
            activeReviewQuestions = cursor.reviewQuestionIDs.compactMap { questionsByID[$0] }
            guard !activeReviewQuestions.isEmpty,
                activeReviewQuestions.count == cursor.reviewQuestionIDs.count,
                activeReviewQuestions.count <= 2,
                activeReviewQuestions.indices.contains(cursor.questionIndex),
                [.reviewQuestion, .reviewFeedback, .reviewComplete].contains(cursor.phase),
                cursor.stepID
                    == (cursor.phase == .reviewComplete
                        ? "complete" : activeReviewQuestions[cursor.questionIndex].id)
            else {
                discardUnavailableCursor()
                return
            }
        }
        progress.activeRun = cursor
        progress.selectedAgeBand = cursor.ageBand
        focusDestination(id: cursor.destinationID)
        phase = cursor.phase
        quizQuestionIndex = cursor.questionIndex
        questionAttemptCount = cursor.questionAttemptCount
        isShowingHint = cursor.isShowingHint
        wasLastAnswerCorrect = cursor.feedbackWasCorrect
        lastFeedback = cursor.feedbackText
        videoPlaybackSeconds = cursor.videoSeconds
        isVideoFallback = cursor.isVideoFallback
        isVideoPlaying = false
        videoSeekTarget = cursor.kind == .video ? cursor.videoSeconds : nil
        selectedActivityOptionIndex = activeActivityTask?.options.firstIndex {
            $0.id == cursor.selectedActivityOptionID
        }
        focusedQuizChoiceIndex = 0
        persistRun()
    }

    private var isNewRunPhase: Bool {
        switch phase {
        case .missionBriefing, .missionClue, .missionQuestion, .missionActivity,
            .missionStepFeedback, .planetMissionComplete, .videoPlayback, .videoCheckpoint,
            .videoFeedback, .videoComplete, .reviewQuestion, .reviewFeedback, .reviewComplete,
            .deepDive:
            true
        default:
            false
        }
    }

    private var nextPendingCheckpointIndex: Int? {
        guard let video = activeVideoLesson, let cursor = progress.activeRun else { return nil }
        return video.checkpoints.indices.first {
            !cursor.completedCheckpointIDs.contains(video.checkpoints[$0].id)
        }
    }

    private var allLearningQuestions: [LearningQuestion] {
        planetMissions.flatMap(\.questions)
            + videoLessons.flatMap { $0.checkpoints.map(\.question) }
    }

    private func reviewQuestionsDue(now: Date) -> [LearningQuestion] {
        let questionsByConcept = allLearningQuestions.reduce(into: [String: LearningQuestion]()) {
            if $0[$1.conceptID] == nil { $0[$1.conceptID] = $1 }
        }
        return progress.concepts.values.filter {
            $0.ageBand == ageBand && $0.nextReviewAt <= now
        }.sorted {
            if $0.nextReviewAt == $1.nextReviewAt { return $0.conceptID < $1.conceptID }
            return $0.nextReviewAt < $1.nextReviewAt
        }.compactMap { questionsByConcept[$0.conceptID] }
    }

    private func confirmAdventure(now: Date) -> Bool {
        switch phase {
        case .missionSelection:
            if let mission = suggestedMission { selectPlanetMission(id: mission.id) }
        case .missionBriefing:
            phase = .missionClue
            persistRun()
        case .missionClue:
            guard let mission = activePlanetMission else { return true }
            let isLastCard = activeCardIndex == mission.cards.count - 1
            let hasActivity = mission.activity.tasks.allSatisfy {
                progress.activeRun?.completedActivityTaskIDs.contains($0.id) == true
            }
            phase = isLastCard && !hasActivity ? .missionActivity : .missionQuestion
            persistRun()
        case .missionQuestion, .videoCheckpoint, .reviewQuestion:
            submitAnswer(at: focusedQuizChoiceIndex, now: now)
        case .missionActivity:
            if let index = selectedActivityOptionIndex { submitActivityAnswer(at: index) }
        case .missionStepFeedback:
            continueMissionFeedback()
        case .planetMissionComplete:
            phase = .missionSelection
        case .videoPlayback:
            if isVideoFallback { continueVideoFallback(now: now) } else { playVideo() }
        case .videoFeedback:
            if !wasLastAnswerCorrect {
                phase = .videoCheckpoint
            } else if let index = nextPendingCheckpointIndex {
                progress.activeRun?.questionIndex = index
                quizQuestionIndex = index
                resetAdventureQuestion()
                phase = .videoPlayback
                // The answer pauses the story; another explicit Play resumes it.
                isVideoPlaying = false
            } else {
                resetAdventureQuestion()
                phase = .videoPlayback
                isVideoPlaying = false
            }
            persistRun()
        case .videoComplete, .reviewComplete:
            phase = availableMissions.isEmpty ? .navigation : .missionSelection
        case .reviewFeedback:
            if !wasLastAnswerCorrect {
                phase = .reviewQuestion
            } else if activeQuestionIndex + 1 < activeReviewQuestions.count {
                progress.activeRun?.questionIndex += 1
                quizQuestionIndex = activeQuestionIndex
                resetAdventureQuestion()
                phase = .reviewQuestion
            } else {
                phase = .reviewComplete
            }
            persistRun()
        case .deepDive:
            closeDeepDive()
        default:
            return false
        }
        return true
    }

    private func continueMissionFeedback() {
        guard let mission = activePlanetMission, let cursor = progress.activeRun else { return }
        let fromActivity = activeActivityTask?.id == cursor.stepID
        if !wasLastAnswerCorrect {
            phase = fromActivity ? .missionActivity : .missionQuestion
        } else if fromActivity {
            if currentActivityTaskIndex + 1 < mission.activity.tasks.count {
                progress.activeRun?.activityTaskIndex += 1
                selectedActivityOptionIndex = nil
                progress.activeRun?.selectedActivityOptionID = nil
                resetAdventureQuestion()
                phase = .missionActivity
            } else {
                resetAdventureQuestion()
                phase = .missionQuestion
            }
        } else if activeQuestionIndex + 1 < mission.questions.count {
            progress.activeRun?.questionIndex += 1
            progress.activeRun?.cardIndex += 1
            quizQuestionIndex = activeQuestionIndex
            resetAdventureQuestion()
            phase = .missionClue
        } else {
            phase = .planetMissionComplete
        }
        persistRun()
    }

    private func submitLearningAnswer(at index: Int, now: Date) {
        guard let question = activeLearningQuestion, let quiz = currentQuiz,
            quiz.choices.indices.contains(index)
        else { return }
        questionAttemptCount += 1
        let correct = quiz.choices[index].id == quiz.correctChoiceID
        wasLastAnswerCorrect = correct
        lastFeedback = correct ? quiz.correctFeedback : quiz.retryFeedback
        if !correct { progress.activeRun?.assistedConceptIDs.insert(question.conceptID) }
        if correct {
            progress.activeRun?.completedQuestionIDs.insert(question.id)
            if phase == .reviewQuestion { recordConceptEncounter(question.conceptID, now: now) }
        }
        switch phase {
        case .missionQuestion:
            progress.activeRun?.stepID = question.id
            if correct, let mission = activePlanetMission,
                mission.questions.allSatisfy({
                    progress.activeRun?.completedQuestionIDs.contains($0.id) == true
                }),
                mission.activity.tasks.allSatisfy({
                    progress.activeRun?.completedActivityTaskIDs.contains($0.id) == true
                })
            {
                finishPlanetMission(mission, now: now)
            }
            phase = .missionStepFeedback
        case .videoCheckpoint:
            if correct, let checkpoint = activeVideoCheckpoint {
                progress.activeRun?.completedCheckpointIDs.insert(checkpoint.id)
            }
            phase = .videoFeedback
        case .reviewQuestion:
            phase = .reviewFeedback
        default:
            return
        }
        persistRun()
    }

    private func recordConceptEncounter(_ conceptID: String, now: Date) {
        let band = activeMissionAgeBand
        let key = ConceptProgress.key(conceptID: conceptID, ageBand: band)
        let previous = progress.concepts[key]
        // Replays before the scheduled revisit are not additional spaced encounters.
        if let previous, previous.nextReviewAt > now {
            return
        }
        let usedHelp = progress.activeRun?.assistedConceptIDs.contains(conceptID) == true
        let box =
            usedHelp
            ? 1
            : LearningEngine.nextReviewBox(
                current: previous?.reviewBox ?? 0, answeredCorrectly: true
            )
        progress.concepts[key] = ConceptProgress(
            conceptID: conceptID, ageBand: band, reviewBox: box, lastPracticedAt: now,
            nextReviewAt: now.addingTimeInterval(
                TimeInterval(LearningEngine.reviewDelayDays(for: box) * 24 * 60 * 60)
            )
        )
    }

    private func finishPlanetMission(_ mission: PlanetMission, now: Date) {
        for conceptID in Set(mission.requiredConceptIDs) {
            recordConceptEncounter(conceptID, now: now)
        }
        guard progress.missionCompletions[mission.id] == nil else { return }
        let band = activeMissionAgeBand
        progress.missionCompletions[mission.id] = MissionCompletion(
            completedAt: now, ageBand: band
        )
        progress.totalScore += mission.questions.count * 100
        stampDestination(id: mission.destinationID)
    }

    private func finishVideoLesson(_ video: VideoLesson, now: Date) {
        for conceptID in Set(video.checkpoints.map { $0.question.conceptID }) {
            recordConceptEncounter(conceptID, now: now)
        }
        guard progress.videoCompletions[video.id] == nil else { return }
        let band = activeMissionAgeBand
        progress.videoCompletions[video.id] = MissionCompletion(
            completedAt: now, ageBand: band
        )
        progress.totalScore += video.checkpoints.count * 100
    }

    private func stampDestination(id: String) {
        var destination = progress.destinations[id] ?? DestinationProgress()
        destination.isScanned = true
        destination.isQuizCompleted = true
        destination.bestRoundStars = 3
        progress.destinations[id] = destination
    }

    private func presentVideoCheckpoint(at index: Int) {
        guard let video = activeVideoLesson, video.checkpoints.indices.contains(index) else {
            return
        }
        let sameQuestion = activeQuestionIndex == index
        progress.activeRun?.questionIndex = index
        quizQuestionIndex = index
        if !sameQuestion { resetAdventureQuestion() }
        videoPlaybackSeconds = video.checkpoints[index].time
        videoSeekTarget = isVideoFallback ? nil : videoPlaybackSeconds
        isVideoPlaying = false
        phase = .videoCheckpoint
        persistRun()
    }

    private func resetAdventureQuestion() {
        questionAttemptCount = 0
        isShowingHint = false
        wasLastAnswerCorrect = false
        lastFeedback = ""
        focusedQuizChoiceIndex = 0
        quizQuestionIndex = activeQuestionIndex
    }

    private func persistRun() {
        guard var cursor = progress.activeRun else { return }
        if phase == .deepDive { return }
        cursor.phase = phase
        cursor.questionAttemptCount = questionAttemptCount
        cursor.isShowingHint = isShowingHint
        cursor.feedbackWasCorrect = wasLastAnswerCorrect
        cursor.feedbackText = lastFeedback
        cursor.videoSeconds = videoPlaybackSeconds
        cursor.isVideoFallback = isVideoFallback
        switch phase {
        case .missionBriefing:
            cursor.stepID = cursor.contentID
        case .missionClue:
            cursor.stepID = activeCard?.id ?? ""
        case .missionQuestion, .reviewQuestion:
            cursor.stepID = activeLearningQuestion?.id ?? ""
        case .missionActivity:
            cursor.stepID = activeActivityTask?.id ?? ""
        case .videoPlayback, .videoCheckpoint:
            cursor.stepID = activeVideoCheckpoint?.id ?? ""
        case .planetMissionComplete, .videoComplete, .reviewComplete:
            cursor.stepID = "complete"
        default:
            break
        }
        progress.activeRun = cursor
    }

    private func focusDestination(id: String) {
        if let index = lessons.firstIndex(where: { $0.id == id }) {
            focusedDestinationIndex = index
        }
    }

    private func discardUnavailableCursor() {
        progress.activeRun = nil
        activeReviewQuestions = []
        isVideoPlaying = false
        videoSeekTarget = nil
        phase = .navigation
    }
}
