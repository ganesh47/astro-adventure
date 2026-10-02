import AstroGameCore
import Foundation
import XCTest

@testable import AstroContent

/// Exercise authored copy and answer IDs through the same state machine used by both apps.
final class ExpeditionIntegrationTests: XCTestCase {
    private let encounterDate = Date(timeIntervalSince1970: 1_000_000)

    func testFullExpeditionAndNativeVideosAcrossAllModesFitTheTelevisionSaveBudget() throws {
        let lessons = try LessonCatalog.bundled()
        let missions = try PlanetMissionCatalog.bundled()
        let videos = try VideoLessonCatalog.bundled()
        let session = MissionSession(
            lessons: lessons, planetMissions: missions, videoLessons: videos)
        XCTAssertEqual(missions.count, 24)
        XCTAssertEqual(
            Set(missions.map { $0.activity.family }), Set(ScienceActivityFamily.allCases))
        XCTAssertTrue(missions.allSatisfy { $0.activity.tasks.count == 2 })
        var completedActivityTasks = 0

        for band in AgeBand.allCases {
            session.returnToWorlds()
            session.ageBand = band
            for mission in missions {
                session.returnToWorlds()
                let alreadyEarned = session.progress.completedMissionIDs.contains(mission.id)
                let before = session.progress.totalScore
                session.selectPlanetMission(id: mission.id)
                XCTAssertEqual(session.activeMissionAgeBand, band)
                XCTAssertEqual(session.phase, .missionBriefing)
                for _ in 0..<40 {
                    if session.phase == .planetMissionComplete { break }
                    switch session.phase {
                    case .missionQuestion:
                        let quiz = try XCTUnwrap(session.currentQuiz)
                        XCTAssertEqual(quiz.choices.count, band == .ages4To6 ? 2 : 3)
                        let answer = try correctAnswer(in: quiz)
                        session.submitAnswer(at: answer, now: encounterDate)
                        if session.activeQuestionIndex == 2 {
                            XCTAssertTrue(session.progress.completedMissionIDs.contains(mission.id))
                            let earned = session.progress
                            session.submitAnswer(at: answer, now: encounterDate)
                            XCTAssertEqual(
                                session.progress, earned,
                                "A repeated Select cannot duplicate a mission reward")
                        }
                    case .missionActivity:
                        let task = try XCTUnwrap(session.activeActivityTask)
                        let answer = try XCTUnwrap(
                            task.options.firstIndex { $0.id == task.correctOptionID })
                        session.selectActivityOption(at: answer)
                        XCTAssertEqual(session.phase, .missionActivity)
                        XCTAssertEqual(
                            session.selectedActivityOutcome, task.options[answer].outcome[band])
                        session.submitActivityAnswer(at: answer)
                        completedActivityTasks += 1
                    default:
                        session.confirm(now: encounterDate)
                    }
                }
                XCTAssertEqual(session.phase, .planetMissionComplete, "\(mission.id) in \(band)")
                XCTAssertEqual(session.progress.totalScore - before, alreadyEarned ? 0 : 300)
                XCTAssertTrue(
                    session.progress.destinations[mission.destinationID]?.isQuizCompleted == true)
            }
        }
        XCTAssertEqual(completedActivityTasks, 24 * 2 * 3)
        XCTAssertEqual(session.completedPlanetMissionCount, 24)
        XCTAssertTrue(session.isPlanetExpeditionComplete)
        XCTAssertEqual(session.progress.totalScore, 7_200)
        XCTAssertEqual(session.progress.concepts.count, 216)
        XCTAssertTrue(session.progress.concepts.values.allSatisfy { $0.reviewBox == 1 })

        // The optional films have two questions and a third concluding segment.
        for band in AgeBand.allCases {
            session.returnToWorlds()
            session.ageBand = band
            for video in videos {
                session.returnToWorlds()
                let alreadyEarned = session.progress.videoCompletions[video.id] != nil
                let before = session.progress.totalScore
                session.startVideoLesson(id: video.id)
                XCTAssertFalse(session.isVideoPlaying)
                for checkpoint in video.checkpoints {
                    session.videoSeekCompleted()
                    session.playVideo()
                    session.playbackTimeChanged(seconds: checkpoint.time + 0.1)
                    XCTAssertEqual(session.phase, .videoCheckpoint)
                    XCTAssertEqual(session.activeVideoCheckpoint?.id, checkpoint.id)
                    XCTAssertEqual(session.videoPlaybackSeconds, checkpoint.time)
                    XCTAssertFalse(session.isVideoPlaying)
                    let quiz = try XCTUnwrap(session.currentQuiz)
                    XCTAssertEqual(quiz.choices.count, band == .ages4To6 ? 2 : 3)
                    session.submitAnswer(at: try correctAnswer(in: quiz), now: encounterDate)
                    XCTAssertEqual(session.phase, .videoFeedback)
                    session.confirm(now: encounterDate)
                    XCTAssertEqual(session.phase, .videoPlayback)
                    XCTAssertFalse(session.isVideoPlaying)
                }
                XCTAssertEqual(
                    session.progress.totalScore, before,
                    "The final segment must be seen before completion")
                session.videoSeekCompleted()
                session.playVideo()
                session.playbackTimeChanged(seconds: video.duration - 0.1)
                XCTAssertEqual(session.phase, .videoPlayback)
                session.videoDidEnd(now: encounterDate)
                XCTAssertEqual(session.phase, .videoComplete)
                XCTAssertEqual(session.progress.totalScore - before, alreadyEarned ? 0 : 200)
                let earned = session.progress
                session.videoDidEnd(now: encounterDate)
                session.playbackTimeChanged(seconds: video.duration)
                XCTAssertEqual(session.progress, earned)
            }
        }
        XCTAssertEqual(session.progress.videoCompletions.count, 8)
        XCTAssertEqual(session.progress.concepts.count, 264)
        XCTAssertEqual(session.progress.totalScore, 8_800)

        // Fill the remaining bounded legacy history and retain a real, assisted checkpoint cursor.
        session.returnToWorlds()
        session.startVideoLesson(id: try XCTUnwrap(videos.last?.id))
        session.videoFailed()
        session.continueVideoFallback(now: encounterDate)
        session.requestHint()
        let quiz = try XCTUnwrap(session.currentQuiz)
        let wrong = try XCTUnwrap(quiz.choices.firstIndex { $0.id != quiz.correctChoiceID })
        session.submitAnswer(at: wrong, now: encounterDate)
        var fullLog = session.progress
        fullLog.leaderboard = (0..<20).map { index in
            LeaderboardEntry(
                explorerName: AgeBand.ages10To12.modeName,
                destinationName: "Space Technology Lab", score: 1_000,
                correctAnswers: 10, totalQuestions: 10, bestStreak: 0,
                achievedAt: encounterDate.addingTimeInterval(Double(index))
            )
        }
        let encoder = JSONEncoder()
        let compactData = try encoder.encode(fullLog)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let readableData = try encoder.encode(fullLog)
        XCTAssertLessThan(compactData.count, 256 * 1024)
        XCTAssertLessThan(readableData.count, 256 * 1024)
        XCTAssertEqual(try JSONDecoder().decode(GameProgress.self, from: compactData), fullLog)
    }

    func testEveryActualVideoFallbackHasEquivalentQuestionsAndNoPlanetStampInAllModes() throws {
        let missions = try PlanetMissionCatalog.bundled()
        let videos = try VideoLessonCatalog.bundled()
        let session = MissionSession(
            lessons: try LessonCatalog.bundled(), planetMissions: missions, videoLessons: videos
        )
        for band in AgeBand.allCases {
            session.returnToWorlds()
            session.ageBand = band
            for video in videos {
                session.returnToWorlds()
                session.startVideoLesson(id: video.id)
                session.videoFailed()
                XCTAssertTrue(session.isVideoFallback)
                XCTAssertFalse(session.isVideoPlaying)
                for (index, checkpoint) in video.checkpoints.enumerated() {
                    XCTAssertEqual(session.videoFallbackCardIndex, index)
                    session.continueVideoFallback(now: encounterDate)
                    XCTAssertEqual(session.phase, .videoCheckpoint)
                    XCTAssertEqual(session.activeLearningQuestion?.id, checkpoint.question.id)
                    if index == 0 {
                        session.replayVideoClue()
                        XCTAssertEqual(session.phase, .videoPlayback)
                        XCTAssertEqual(session.videoFallbackCardIndex, index)
                        session.continueVideoFallback(now: encounterDate)
                        XCTAssertEqual(session.activeLearningQuestion?.id, checkpoint.question.id)
                    }
                    let quiz = try XCTUnwrap(session.currentQuiz)
                    session.submitAnswer(at: try correctAnswer(in: quiz), now: encounterDate)
                    session.confirm(now: encounterDate)
                    XCTAssertEqual(session.phase, .videoPlayback)
                }
                XCTAssertEqual(session.videoFallbackCardIndex, video.fallbackCards.count - 1)
                session.continueVideoFallback(now: encounterDate)
                XCTAssertEqual(session.phase, .videoComplete)
                XCTAssertNotNil(session.progress.videoCompletions[video.id])
                XCTAssertFalse(
                    session.progress.destinations[video.destinationID]?.isQuizCompleted == true)
            }
        }
        XCTAssertEqual(session.progress.videoCompletions.count, 8)
        XCTAssertEqual(session.progress.concepts.count, 48)
        XCTAssertEqual(session.progress.totalScore, 1_600)
        XCTAssertTrue(session.progress.completedMissionIDs.isEmpty)
        XCTAssertFalse(session.isPlanetExpeditionComplete)
    }

    func testAuthoredActivityFamiliesResumeAtTheSecondTaskWithoutSkippingTheFinalQuestion() throws {
        let lessons = try LessonCatalog.bundled()
        let missions = try PlanetMissionCatalog.bundled()
        for family in ScienceActivityFamily.allCases {
            let mission = try XCTUnwrap(missions.first { $0.activity.family == family })
            let session = MissionSession(lessons: lessons, planetMissions: missions)
            session.selectPlanetMission(id: mission.id)
            for _ in 0..<25 {
                if session.phase == .missionActivity { break }
                if session.phase == .missionQuestion {
                    let quiz = try XCTUnwrap(session.currentQuiz)
                    session.submitAnswer(at: try correctAnswer(in: quiz), now: encounterDate)
                } else {
                    session.confirm(now: encounterDate)
                }
            }
            XCTAssertEqual(session.phase, .missionActivity)
            let firstTask = try XCTUnwrap(session.activeActivityTask)
            session.submitActivityAnswer(
                at: try XCTUnwrap(
                    firstTask.options.firstIndex { $0.id == firstTask.correctOptionID }))
            session.confirm(now: encounterDate)
            XCTAssertEqual(session.currentActivityTaskIndex, 1)
            let secondTask = try XCTUnwrap(session.activeActivityTask)
            session.selectActivityOption(at: 1)
            session.returnToWorlds()
            let bytes = try JSONEncoder().encode(session.progress)
            let restored = MissionSession(
                lessons: lessons,
                progress: try JSONDecoder().decode(GameProgress.self, from: bytes),
                planetMissions: missions
            )
            restored.resumeSavedAdventure()
            XCTAssertEqual(restored.phase, .missionActivity)
            XCTAssertEqual(restored.activeActivityTask?.id, secondTask.id)
            XCTAssertEqual(restored.selectedActivityOptionIndex, 1)
            XCTAssertTrue(restored.progress.completedMissionIDs.isEmpty)
            restored.submitActivityAnswer(
                at: try XCTUnwrap(
                    secondTask.options.firstIndex { $0.id == secondTask.correctOptionID }))
            restored.confirm(now: encounterDate)
            XCTAssertEqual(restored.phase, .missionQuestion)
            XCTAssertEqual(restored.activeLearningQuestion?.id, mission.questions[2].id)
            XCTAssertTrue(restored.progress.completedMissionIDs.isEmpty)
        }
    }

    private func correctAnswer(in quiz: QuizContent) throws -> Int {
        try XCTUnwrap(quiz.choices.firstIndex { $0.id == quiz.correctChoiceID })
    }
}
