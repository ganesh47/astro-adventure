import AstroContent
import AstroGameCore
import AstroServices
import Foundation
import SwiftUI

public struct AppBootstrapView: View {
    private let catalogResult: Result<[DestinationLesson], Error>
    @State private var progressStore: (any ProgressStoring)?
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var retryFocused: Bool
    @State private var savedProgress: GameProgress?
    @State private var hasLoadedProgress = false
    @State private var loadError: String?
    @State private var saveQueue: ProgressSaveQueue?

    public init() {
        catalogResult = Result { try LessonCatalog.bundled() }
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
        case .success(let lessons):
            if hasLoadedProgress {
                GameRootView(
                    lessons: lessons,
                    progress: savedProgress,
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
                    Text("Retry to recover your rewards, or begin a new space log.")
                    Button("Retry") { Task { await loadProgress() } }
                        .focused($retryFocused)
                        .onAppear { retryFocused = true }
                    if let store = progressStore {
                        Button("Begin a new space log") {
                            let freshProgress = GameProgress()
                            savedProgress = freshProgress
                            saveQueue = ProgressSaveQueue(store: store)
                            saveQueue?.enqueue(freshProgress)
                            hasLoadedProgress = true
                        }
                    }
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
