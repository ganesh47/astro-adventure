import AstroContent
import AstroGameCore
import AstroServices
import Foundation
import SwiftUI

public struct AppBootstrapView: View {
    private struct BundledGameContent {
        let lessons: [DestinationLesson]
        let missions: [PlanetMission]
        let videos: [VideoLesson]
    }

    private let catalogResult: Result<BundledGameContent, Error>
    @State private var progressStore: (any ProgressStoring)?
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var retryFocused: Bool
    @State private var savedProgress: GameProgress?
    @State private var hasLoadedProgress = false
    @State private var loadError: String?
    @State private var saveQueue: ProgressSaveQueue?

    public init() {
        catalogResult = Result {
            try BundledGameContent(
                lessons: LessonCatalog.bundled(),
                missions: PlanetMissionCatalog.bundled(),
                videos: VideoLessonCatalog.bundled()
            )
        }
    }

    #if DEBUG
        private static let uiTestSuiteName = "AstroAdventure.UITests"
        // Static initialization runs once per process, including retries and view reconstruction.
        // Both switches are absent from Release builds and never clear production preferences.
        private static let prepareUITestStorage: Void = {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--ui-testing"),
                arguments.contains("--reset-ui-testing-progress")
            {
                UserDefaults(suiteName: uiTestSuiteName)?
                    .removePersistentDomain(forName: uiTestSuiteName)
            }
        }()
    #endif

    private static func makeStore() throws -> any ProgressStoring {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                _ = prepareUITestStorage
                return try PreferencesProgressStore(suiteName: uiTestSuiteName)
            }
        #endif
        #if os(tvOS)
            return try PreferencesProgressStore.television()
        #else
            return try JSONProgressStore.applicationSupport()
        #endif
    }

    public var body: some View {
        switch catalogResult {
        case .success(let content):
            if hasLoadedProgress {
                GameRootView(
                    lessons: content.lessons,
                    progress: savedProgress,
                    planetMissions: content.missions,
                    videoLessons: content.videos,
                    onProgressChanged: saveProgress
                )
                .overlay(alignment: .bottom) {
                    if saveQueue?.errorMessage != nil {
                        Button("Space log could not be saved. Retry") {
                            saveQueue?.retry()
                        }
                        .focused($retryFocused)
                        .onAppear { retryFocused = true }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding()
                        .accessibilityHint("Your rewards are still available in this game session.")
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        Task { await saveQueue?.flush() }
                    }
                }
            } else if loadError != nil {
                VStack(spacing: 24) {
                    Text("Your space log could not be opened")
                        .font(.title)
                    Text(
                        "Your existing space log is preserved. Retry after restoring a compatible log or updating the app."
                    )
                    .multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadProgress() } }
                        .accessibilityIdentifier("progress.load.retry")
                        .focused($retryFocused)
                        .onAppear { retryFocused = true }
                }
                .padding()
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
        do {
            let store = try Self.makeStore()
            progressStore = store
            savedProgress = try await store.load()
            #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                    let fixture = ProcessInfo.processInfo.environment["ASTRO_UI_TEST_PROGRESS_JSON"]
                {
                    savedProgress = try JSONDecoder().decode(
                        GameProgress.self, from: Data(fixture.utf8))
                }
            #endif
            saveQueue = ProgressSaveQueue(store: store)
            loadError = nil
            hasLoadedProgress = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveProgress(_ progress: GameProgress) {
        saveQueue?.enqueue(progress)
    }
}
