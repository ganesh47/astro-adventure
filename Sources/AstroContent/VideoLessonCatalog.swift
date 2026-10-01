import AstroGameCore
import Foundation

public enum VideoLessonCatalogError: Error, Equatable {
    case missingBundledCatalog
    case invalidLesson(String)
    case duplicateID(String)
    case invalidCheckpoint(String)
    case invalidQuestion(String, AgeBand)
}

/// Offline lessons are authored independently of the required mission activities.
public enum VideoLessonCatalog {
    public static func bundled() throws -> [VideoLesson] {
        guard let url = Bundle.module.url(forResource: "video-lessons", withExtension: "json")
        else {
            throw VideoLessonCatalogError.missingBundledCatalog
        }
        return try decode(Data(contentsOf: url))
    }

    public static func decode(_ data: Data) throws -> [VideoLesson] {
        let lessons = try JSONDecoder().decode([VideoLesson].self, from: data)
        try validate(lessons)
        return lessons
    }

    public static func validate(_ lessons: [VideoLesson]) throws {
        var ids = Set<String>()
        var destinations = Set<String>()
        for lesson in lessons {
            guard ids.insert(lesson.id).inserted, destinations.insert(lesson.destinationID).inserted
            else {
                throw VideoLessonCatalogError.duplicateID(lesson.id)
            }
            guard lesson.revision > 0, lesson.duration.isFinite, lesson.duration > 0,
                !lesson.resourceName.isEmpty, !lesson.credit.isEmpty,
                lesson.source.reviewStatus == "reviewed", lesson.source.url.scheme == "https",
                !lesson.segments.isEmpty, lesson.fallbackCards.count == lesson.segments.count,
                lesson.segments.first?.startTime == 0,
                lesson.segments.last?.endTime == lesson.duration
            else { throw VideoLessonCatalogError.invalidLesson(lesson.id) }
            var lastEnd = 0.0
            var segmentIDs = Set<String>()
            for segment in lesson.segments {
                guard segmentIDs.insert(segment.id).inserted,
                    segment.startTime == lastEnd, segment.endTime.isFinite,
                    segment.endTime > segment.startTime, segment.endTime <= lesson.duration,
                    !segment.imageName.isEmpty,
                    AgeBand.allCases.allSatisfy({ !segment.narration[$0].isEmpty })
                else { throw VideoLessonCatalogError.invalidLesson(lesson.id) }
                lastEnd = segment.endTime
            }
            var checkpointIDs = Set<String>()
            var lastTime = 0.0
            for checkpoint in lesson.checkpoints {
                guard checkpointIDs.insert(checkpoint.id).inserted,
                    checkpoint.time.isFinite, checkpoint.time > lastTime,
                    checkpoint.time < lesson.duration, checkpoint.replayStartTime.isFinite,
                    checkpoint.replayStartTime >= 0,
                    checkpoint.replayStartTime < checkpoint.time,
                    lesson.segments.contains(where: {
                        $0.startTime == checkpoint.replayStartTime && $0.endTime == checkpoint.time
                    }), checkpoint.question.source.reviewStatus == "reviewed"
                else { throw VideoLessonCatalogError.invalidCheckpoint(checkpoint.id) }
                for band in AgeBand.allCases {
                    for quiz in [
                        checkpoint.question.content[band], checkpoint.question.reviewContent[band],
                    ] {
                        let expected = band == .ages4To6 ? 2 : 3
                        guard quiz.choices.count == expected,
                            Set(quiz.choices.map(\.id)).count == expected,
                            quiz.choices.contains(where: { $0.id == quiz.correctChoiceID }),
                            !quiz.prompt.isEmpty, !quiz.correctFeedback.isEmpty,
                            !quiz.retryFeedback.isEmpty, !quiz.hint.isEmpty
                        else { throw VideoLessonCatalogError.invalidQuestion(checkpoint.id, band) }
                    }
                }
                lastTime = checkpoint.time
            }
            guard !lesson.checkpoints.isEmpty else {
                throw VideoLessonCatalogError.invalidLesson(lesson.id)
            }
        }
    }
}
