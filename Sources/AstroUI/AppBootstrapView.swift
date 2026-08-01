import AstroContent
import AstroGameCore
import AstroServices
import SwiftUI

public struct AppBootstrapView: View {
    private let catalogResult: Result<[DestinationLesson], Error>
    private let progressStore: JSONProgressStore?
    @State private var savedProgress: GameProgress?
    @State private var hasLoadedProgress = false

    public init() {
        catalogResult = Result { try LessonCatalog.bundled() }
        progressStore = try? JSONProgressStore.applicationSupport()
    }

    public var body: some View {
        switch catalogResult {
        case .success(let lessons):
            if hasLoadedProgress {
                GameRootView(
                    lessons: lessons,
                    progress: savedProgress,
                    onProgressChanged: saveProgress
                )
            } else {
                ProgressView("Loading your space log…")
                    .task { await loadProgress() }
            }
        case .failure:
            ContentUnavailableView(
                "Mission data unavailable",
                systemImage: "sparkles",
                description: Text("Astro Adventure could not load its bundled lessons.")
            )
        }
    }

    private func loadProgress() async {
        if let progressStore {
            savedProgress = try? await progressStore.load()
        }
        hasLoadedProgress = true
    }

    private func saveProgress(_ progress: GameProgress) {
        guard let progressStore else { return }
        Task {
            try? await progressStore.save(progress)
        }
    }
}
