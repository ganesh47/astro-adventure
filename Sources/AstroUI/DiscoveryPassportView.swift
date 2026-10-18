import AstroGameCore
import AstroWorld
import SwiftUI

struct DiscoveryPassportView: View {
    let progress: GameProgress
    let adventures: [ExplorationAdventure]
    let safaris: [PhotoSafari]
    let lessons: [DestinationLesson]
    let onClose: () -> Void
    @State private var selectedPhoto: PhotoSafariStop?

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
        .background(Color(red: 0.035, green: 0.055, blue: 0.095).ignoresSafeArea())
        .preferredColorScheme(.dark)
        #if os(tvOS)
            .fullScreenCover(item: $selectedPhoto) { photoDetail($0) }
        #else
            .sheet(item: $selectedPhoto) { photoDetail($0) }
        #endif
    }

    private func photoDetail(_ stop: PhotoSafariStop) -> some View {
        VStack(spacing: 20) {
            if let photo = stop.discoveryPhoto {
                SpacePhotoImage(photo: photo).frame(maxHeight: .infinity)
                Text(stop.title).font(.title.bold())
                Text(stop.fact.text(for: progress.selectedAgeBand)).font(.title3)
                Text(photo.caption).font(.body)
                Text(photo.credit).font(.caption)
            }
            Button("Back to passport") { selectedPhoto = nil }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("passport.photo.close")
        }
        .multilineTextAlignment(.center).padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.035, green: 0.055, blue: 0.095).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func discoveries(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 16 : 28) {
            Text("Keep your space photos and discoveries here.")
                .font(compact ? .body : .title3).foregroundStyle(.secondary)
            ForEach(safaris) { safari in
                if progress.explorationCompletions[safari.id] != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("My \(safari.destinationID.capitalized) space photos").font(
                            .title2.bold()
                        )
                        .accessibilityIdentifier("passport.collection.\(safari.destinationID)")
                        HStack(spacing: 20) {
                            ForEach(safari.stops) { stop in
                                if let photo = stop.discoveryPhoto {
                                    Button {
                                        selectedPhoto = stop
                                    } label: {
                                        VStack {
                                            SpacePhotoImage(photo: photo)
                                                .frame(height: compact ? 100 : 170)
                                            Text(stop.title).font(.headline)
                                                .lineLimit(2).multilineTextAlignment(.center)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .accessibilityIdentifier("passport.photo.\(stop.id)")
                                }
                            }
                        }
                    }
                }
            }
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
                    "Your first space-photo collection is waiting to be discovered.",
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
