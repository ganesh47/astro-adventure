import AstroGameCore
import AstroWorld
import SwiftUI

struct DiscoveryPassportView: View {
    let progress: GameProgress
    let adventures: [ExplorationAdventure]
    let lessons: [DestinationLesson]
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 550
            VStack(alignment: .leading, spacing: compact ? 12 : 24) {
                HStack {
                    Text("Your Discovery Passport")
                        .font(compact ? .title2.bold() : .largeTitle.bold())
                    Spacer()
                    Button("Back to worlds", systemImage: "arrow.backward", action: onClose)
                        .accessibilityIdentifier("passport.close")
                }
                ScrollView {
                    discoveries(compact: compact)
                }
                .accessibilityIdentifier("passport.scroll")
            }
            .padding(compact ? 18 : 36)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .preferredColorScheme(.dark)
    }

    private func discoveries(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 16 : 28) {
            Text("Your crew keeps the things you made and noticed.")
                .font(compact ? .body : .title3).foregroundStyle(.secondary)
            ForEach(adventures) { adventure in
                if let completion = progress.explorationCompletions[adventure.id] {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(adventure.postcardTitle).font(.title2.bold())
                        DiscoveryPostcardView(adventure: adventure, cursor: completion.postcard)
                            .frame(height: compact ? 180 : 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        ForEach(adventure.goals) { goal in
                            Label(goal.title, systemImage: "sparkles")
                                .font(.headline)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("passport.postcard.\(adventure.destinationID)")
                }
            }
            if progress.explorationCompletions.isEmpty {
                Label(
                    "Your first playground postcard is waiting to be made.",
                    systemImage: "camera.fill"
                )
                .font(.headline)
            }
            Text("World stamps").font(.title2.bold())
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200))], alignment: .leading, spacing: 20
            ) {
                ForEach(lessons) { lesson in
                    if progress.destinations[lesson.id]?.isQuizCompleted == true {
                        Label(lesson.displayName, systemImage: "checkmark.seal.fill")
                            .font(.headline).foregroundStyle(.yellow)
                    }
                }
            }
            Text(
                "All earlier mission badges and discoveries are kept in More missions and films."
            )
            .font(.body).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
