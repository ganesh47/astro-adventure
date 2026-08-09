import AVFoundation
import AstroContent
import AstroGameCore
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct DiscoveryStoryView: View {
    let destinationName: String
    let ageBand: AgeBand
    let slides: [DiscoverySlide]
    let quizQuestionCount: Int
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var selectedIndex = 0
    @State private var narrationEnabled = true
    @State private var narrator = AVSpeechSynthesizer()
    @FocusState private var focusedControl: StoryControl?

    private enum StoryControl: Hashable {
        case worlds
        case previous
        case narration
        case next
    }

    private var selectedSlide: DiscoverySlide? {
        guard slides.indices.contains(selectedIndex) else { return nil }
        return slides[selectedIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            if let slide = selectedSlide {
                let compact = proxy.size.height < 520

                ZStack {
                    if let image = bundledImage(named: slide.imageName) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .id(slide.id)
                            .transition(.opacity.combined(with: .scale(scale: 1.025)))
                            .accessibilityHidden(true)
                    } else {
                        Color.black
                    }

                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.14), location: 0),
                            .init(color: .black.opacity(0.18), location: 0.38),
                            .init(color: .black.opacity(0.92), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .leading,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: compact ? 6 : 0) {
                        storyHeader(slide: slide, compact: compact)
                        Spacer(minLength: compact ? 4 : 8)
                        storyCopy(slide: slide, compact: compact)
                        storyControls(compact: compact)
                    }
                    .padding(.horizontal, compact ? 44 : 64)
                    .padding(.vertical, compact ? 12 : 46)
                }
                .animation(.easeInOut(duration: 0.45), value: selectedIndex)
                .onAppear {
                    focusedControl = .next
                    speakCurrentSlide()
                }
                .onChange(of: selectedIndex) {
                    speakCurrentSlide()
                }
                .onChange(of: narrationEnabled) {
                    if narrationEnabled {
                        speakCurrentSlide()
                    } else {
                        narrator.stopSpeaking(at: .immediate)
                    }
                }
                .onDisappear {
                    narrator.stopSpeaking(at: .immediate)
                }
            } else {
                ContentUnavailableView(
                    "Discovery story unavailable",
                    systemImage: "photo.on.rectangle.angled"
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func storyHeader(slide: DiscoverySlide, compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: compact ? 2 : 8) {
                Label(
                    "SPACE FLASHCARD · \(destinationName.uppercased())",
                    systemImage: "rectangle.stack.fill"
                )
                .font((compact ? Font.caption : Font.headline).weight(.black))
                .tracking(compact ? 1.2 : 1.8)
                Text("\(ageBand.modeName) · \(ageBand.displayName)")
                    .font((compact ? Font.caption2 : Font.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .padding(.horizontal, compact ? 10 : 18)
            .padding(.vertical, compact ? 7 : 14)
            .background(
                .black.opacity(0.5),
                in: RoundedRectangle(cornerRadius: compact ? 12 : 18, style: .continuous)
            )

            Spacer()

            HStack(spacing: compact ? 5 : 10) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? Color.cyan : Color.white.opacity(0.35))
                        .frame(
                            width: index == selectedIndex
                                ? (compact ? 24 : 42) : (compact ? 12 : 20),
                            height: compact ? 5 : 8
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Flashcard progress")
            .accessibilityValue("Card \(selectedIndex + 1) of \(slides.count)")
        }
    }

    private func storyCopy(slide: DiscoverySlide, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 14) {
            Text(slide.title)
                .font(.system(size: compact ? 30 : 52, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(slide.body)
                .font(.system(size: compact ? 17 : 30, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .lineSpacing(compact ? 1 : 5)
                .lineLimit(compact ? 2 : nil)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: 1120, alignment: .leading)

            HStack(spacing: compact ? 8 : 14) {
                ForEach(Array(slide.facts.enumerated()), id: \.offset) { _, fact in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fact.value)
                            .font(
                                .system(
                                    size: compact ? 17 : 26,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(fact.label.uppercased())
                            .font((compact ? Font.caption2 : Font.caption).weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .padding(.horizontal, compact ? 10 : 18)
                    .padding(.vertical, compact ? 5 : 10)
                    .background(.black.opacity(0.58), in: Capsule())
                    .overlay { Capsule().stroke(.yellow.opacity(0.48), lineWidth: 2) }
                }
            }

            Text("\(slide.credit) · \(slide.sourceID)")
                .font((compact ? Font.caption2 : Font.footnote).weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, compact ? 0 : 4)
        }
        .shadow(color: .black.opacity(0.8), radius: 12, y: 4)
        .padding(.bottom, compact ? 4 : 28)
        .accessibilityElement(children: .combine)
    }

    private func storyControls(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 18) {
            Button {
                narrator.stopSpeaking(at: .immediate)
                onBack()
            } label: {
                Label("Worlds", systemImage: "globe.americas.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .large)
            .focused($focusedControl, equals: .worlds)

            Button {
                showPreviousSlide()
            } label: {
                Label(compact ? "Back" : "Previous", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .large)
            .disabled(selectedIndex == 0)
            .focused($focusedControl, equals: .previous)

            Button {
                narrationEnabled.toggle()
            } label: {
                Label(
                    compact
                        ? (narrationEnabled ? "Sound On" : "Sound Off")
                        : (narrationEnabled ? "Narration On" : "Narration Off"),
                    systemImage: narrationEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .large)
            .focused($focusedControl, equals: .narration)
            .accessibilityHint("Turns automatic spoken descriptions on or off")

            Spacer()

            Text(
                compact
                    ? "\(selectedIndex + 1)/\(slides.count)"
                    : "CARD \(selectedIndex + 1) OF \(slides.count)"
            )
            .font((compact ? Font.caption : Font.headline).monospacedDigit())
            .foregroundStyle(.white.opacity(0.78))

            Button {
                showNextSlideOrComplete()
            } label: {
                Label(
                    selectedIndex == slides.count - 1
                        ? (compact ? "Start Quiz" : "Start \(quizQuestionCount)-Question Quiz")
                        : (compact ? "Next" : "Next Card"),
                    systemImage: selectedIndex == slides.count - 1
                        ? "gamecontroller.fill"
                        : "chevron.right"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .large)
            .focused($focusedControl, equals: .next)
        }
    }

    private func showPreviousSlide() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
        focusedControl = .previous
    }

    private func showNextSlideOrComplete() {
        guard selectedIndex < slides.count - 1 else {
            narrator.stopSpeaking(at: .immediate)
            onComplete()
            return
        }
        selectedIndex += 1
        focusedControl = .next
    }

    private func speakCurrentSlide() {
        guard narrationEnabled, let slide = selectedSlide else { return }
        narrator.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: slide.narration)
        utterance.rate = ageBand == .ages4To6 ? 0.43 : 0.48
        utterance.pitchMultiplier = 1.03
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        narrator.speak(utterance)
    }

    private func bundledImage(named name: String) -> Image? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "jpg") else {
            return nil
        }

        #if canImport(UIKit)
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            return Image(uiImage: image)
        #elseif canImport(AppKit)
            guard let image = NSImage(contentsOf: url) else { return nil }
            return Image(nsImage: image)
        #else
            return nil
        #endif
    }
}
