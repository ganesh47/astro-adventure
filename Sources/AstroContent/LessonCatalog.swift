import AstroGameCore
import Foundation

public enum LessonCatalogError: Error, Equatable {
    case missingBundledCatalog
    case duplicateLessonID(String)
    case invalidChoiceCount(lessonID: String, ageBand: AgeBand)
    case missingCorrectChoice(lessonID: String, ageBand: AgeBand)
    case unreviewedSource(lessonID: String)
}

public enum LessonCatalog {
    public static func bundled() throws -> [DestinationLesson] {
        guard let url = Bundle.module.url(forResource: "lessons", withExtension: "json") else {
            throw LessonCatalogError.missingBundledCatalog
        }

        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    public static func decode(_ data: Data) throws -> [DestinationLesson] {
        let lessons = try JSONDecoder().decode([DestinationLesson].self, from: data)
        try validate(lessons)
        return lessons
    }

    public static func validate(_ lessons: [DestinationLesson]) throws {
        var lessonIDs = Set<String>()

        for lesson in lessons {
            guard lessonIDs.insert(lesson.id).inserted else {
                throw LessonCatalogError.duplicateLessonID(lesson.id)
            }
            guard lesson.source.reviewStatus == "reviewed" else {
                throw LessonCatalogError.unreviewedSource(lessonID: lesson.id)
            }

            for ageBand in AgeBand.allCases {
                let quiz = lesson.content[ageBand].quiz
                let expectedChoiceCount = ageBand == .ages4To6 ? 2 : 3
                guard quiz.choices.count == expectedChoiceCount else {
                    throw LessonCatalogError.invalidChoiceCount(
                        lessonID: lesson.id,
                        ageBand: ageBand
                    )
                }
                guard quiz.choices.contains(where: { $0.id == quiz.correctChoiceID }) else {
                    throw LessonCatalogError.missingCorrectChoice(
                        lessonID: lesson.id,
                        ageBand: ageBand
                    )
                }
            }
        }
    }
}
