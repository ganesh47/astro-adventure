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

                    VStack(alignment: .leading, spacing: 0) {
                        storyHeader(slide: slide)
                        Spacer()
                        storyCopy(slide: slide)
                        storyControls
                    }
                    .padding(.horizontal, 64)
                    .padding(.vertical, 46)
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

    private func storyHeader(slide: DiscoverySlide) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "SPACE FLASHCARD · \(destinationName.uppercased())",
                    systemImage: "rectangle.stack.fill"
                )
                .font(.headline.weight(.black))
                .tracking(1.8)
                Text("\(ageBand.modeName) · \(ageBand.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                .black.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )

            Spacer()

            HStack(spacing: 10) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? Color.cyan : Color.white.opacity(0.35))
                        .frame(width: index == selectedIndex ? 42 : 20, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Flashcard progress")
            .accessibilityValue("Card \(selectedIndex + 1) of \(slides.count)")
        }
    }

    private func storyCopy(slide: DiscoverySlide) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(slide.title)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .lineLimit(2)

            Text(slide.body)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .lineSpacing(5)
                .frame(maxWidth: 1120, alignment: .leading)

            HStack(spacing: 14) {
                ForEach(Array(slide.facts.enumerated()), id: \.offset) { _, fact in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fact.value)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                        Text(fact.label.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.58), in: Capsule())
                    .overlay { Capsule().stroke(.yellow.opacity(0.48), lineWidth: 2) }
                }
            }

            Text("\(slide.credit) · \(slide.sourceID)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
                .padding(.top, 4)
        }
        .shadow(color: .black.opacity(0.8), radius: 12, y: 4)
        .padding(.bottom, 28)
        .accessibilityElement(children: .combine)
    }

    private var storyControls: some View {
        HStack(spacing: 18) {
            Button {
                narrator.stopSpeaking(at: .immediate)
                onBack()
            } label: {
                Label("Worlds", systemImage: "globe.americas.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .focused($focusedControl, equals: .worlds)

            Button {
                showPreviousSlide()
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(selectedIndex == 0)
            .focused($focusedControl, equals: .previous)

            Button {
                narrationEnabled.toggle()
            } label: {
                Label(
                    narrationEnabled ? "Narration On" : "Narration Off",
                    systemImage: narrationEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .focused($focusedControl, equals: .narration)
            .accessibilityHint("Turns automatic spoken descriptions on or off")

            Spacer()

            Text("CARD \(selectedIndex + 1) OF \(slides.count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.78))

            Button {
                showNextSlideOrComplete()
            } label: {
                Label(
                    selectedIndex == slides.count - 1
                        ? "Start \(quizQuestionCount)-Question Quiz"
                        : "Next Card",
                    systemImage: selectedIndex == slides.count - 1
                        ? "gamecontroller.fill"
                        : "chevron.right"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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
