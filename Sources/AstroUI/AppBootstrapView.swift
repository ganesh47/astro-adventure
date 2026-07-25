import AstroContent
import AstroGameCore
import SwiftUI

public struct AppBootstrapView: View {
    private let catalogResult: Result<[DestinationLesson], Error>

    public init() {
        catalogResult = Result { try LessonCatalog.bundled() }
    }

    public var body: some View {
        switch catalogResult {
        case .success(let lessons):
            GameRootView(lessons: lessons)
        case .failure:
            ContentUnavailableView(
                "Mission data unavailable",
                systemImage: "sparkles",
                description: Text("Astro Adventure could not load its bundled lessons.")
            )
        }
    }
}
