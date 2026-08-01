import AstroGameCore
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct QuizChallengeView: View {
    let destinationName: String
    let ageBand: AgeBand
    let quiz: QuizContent
    let isShowingHint: Bool
    let completedCount: Int
    let totalCount: Int
    let questionIndex: Int
    let questionCount: Int
    let score: Int
    let streak: Int
    let onSelectAnswer: (Int) -> Void
    let onHint: () -> Void
    let onBack: () -> Void

    @FocusState private var focusedChoiceID: String?
    @FocusState private var focusedUtility: UtilityControl?

    private enum UtilityControl: Hashable {
        case back
        case hint
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        visual(for: quiz.choices.first?.id ?? "").color.opacity(0.2),
                        .clear,
                        .black.opacity(0.78),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 22) {
                    challengeHeader
                    question
                    answerCards(availableWidth: proxy.size.width - 128)

                    if isShowingHint {
                        hintBanner
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    utilityControls
                }
                .padding(.horizontal, 64)
                .padding(.vertical, 42)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isShowingHint)
        .onAppear {
            focusedChoiceID = quiz.choices.first?.id
        }
    }

    private var challengeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Label("CLUE CHALLENGE", systemImage: "sparkles")
                    .font(.headline.weight(.black))
                    .tracking(1.8)
                    .foregroundStyle(.yellow)
                Text("\(destinationName) · \(ageBand.modeName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            HStack(spacing: 14) {
                statusPill(
                    "\(questionIndex + 1)/\(questionCount)",
                    icon: "rectangle.stack.fill",
                    color: .cyan
                )
                statusPill("\(score)", icon: "star.fill", color: .yellow)
                statusPill("\(streak)", icon: "flame.fill", color: .orange)
            }
        }
    }

    private func statusPill(_ value: String, icon: String, color: Color) -> some View {
        Label(value, systemImage: icon)
            .font(.headline.monospacedDigit().weight(.black))
            .foregroundStyle(color)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay { Capsule().stroke(color.opacity(0.4), lineWidth: 1.5) }
    }

    private var question: some View {
        VStack(spacing: 8) {
            Text("Choose your best clue")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.66))
                .textCase(.uppercase)
                .tracking(1.4)

            Text(quiz.prompt)
                .font(.system(size: 45, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: 1280)
        .accessibilityElement(children: .combine)
    }

    private func answerCards(availableWidth: CGFloat) -> some View {
        let spacing: CGFloat = 24
        let count = max(CGFloat(quiz.choices.count), 1)
        let cardWidth = min(
            (availableWidth - spacing * (count - 1)) / count,
            quiz.choices.count == 2 ? 650 : 500
        )

        return HStack(spacing: spacing) {
            ForEach(Array(quiz.choices.enumerated()), id: \.element.id) { index, choice in
                let optionVisual = visual(for: choice.id)
                let isFocused = focusedChoiceID == choice.id

                Button {
                    onSelectAnswer(index)
                } label: {
                    QuizAnswerCard(
                        letter: String(UnicodeScalar(65 + index)!),
                        text: choice.text,
                        visual: optionVisual,
                        isFocused: isFocused
                    )
                }
                .buttonStyle(.plain)
                .frame(width: cardWidth)
                .focused($focusedChoiceID, equals: choice.id)
                .accessibilityLabel("Answer \(index + 1), \(choice.text)")
                .accessibilityHint("Selects this clue")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var hintBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text(quiz.hint)
                .font(.title3.weight(.semibold))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            .yellow.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.yellow.opacity(0.58), lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hint, \(quiz.hint)")
    }

    private var utilityControls: some View {
        HStack(spacing: 18) {
            Button(action: onBack) {
                Label("Discovery Story", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .focused($focusedUtility, equals: .back)

            Spacer()

            Text("Move, focus, and press to answer")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            Button(action: onHint) {
                Label(
                    isShowingHint ? "Hint Revealed" : "Show a Hint",
                    systemImage: "lightbulb.fill"
                )
                .foregroundStyle(.yellow)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isShowingHint)
            .focused($focusedUtility, equals: .hint)
        }
    }

    private func visual(for choiceID: String) -> QuizOptionVisual {
        switch choiceID {
        case "sun", "short_orbit":
            QuizOptionVisual(
                imageName: "mercury-color",
                symbol: "sun.max.fill",
                color: .orange
            )
        case "rust", "red", "oxidation", "oxidized_dust", "oxidized_planet",
            "red_planet":
            QuizOptionVisual(
                imageName: "mars-canyons",
                symbol: "circle.hexagongrid.fill",
                color: .red
            )
        case "ice", "icy", "icy_moon", "ocean_moon", "jupiter_moon":
            QuizOptionVisual(
                imageName: "europa-global",
                symbol: "snowflake",
                color: .cyan
            )
        case "plants", "vegetation":
            QuizOptionVisual(
                imageName: "mars-landscape",
                symbol: "leaf.fill",
                color: .green
            )
        case "jupiter", "reflected_light":
            QuizOptionVisual(
                imageName: "europa-ocean-concept",
                symbol: "sparkles",
                color: .purple
            )
        case "small_planet", "inner_planet":
            QuizOptionVisual(
                imageName: "mercury-horizon",
                symbol: "smallcircle.filled.circle.fill",
                color: .yellow
            )
        case "caloris_1550", "caloris_155", "caloris_15500":
            QuizOptionVisual(
                imageName: "mercury-caloris",
                symbol: "circle.dotted.circle.fill",
                color: choiceID == "caloris_1550" ? .orange : .indigo
            )
        case "thin_air":
            QuizOptionVisual(imageName: "mercury-horizon", symbol: "wind", color: .orange)
        case "red_dust":
            QuizOptionVisual(imageName: "mars-landscape", symbol: "aqi.medium", color: .red)
        case "deep_ocean":
            QuizOptionVisual(imageName: "europa-ocean-concept", symbol: "water.waves", color: .cyan)
        case "half_earth", "same_earth", "double_earth":
            QuizOptionVisual(
                imageName: "mars-comparison",
                symbol: "arrow.left.and.right.circle.fill",
                color: choiceID == "half_earth" ? .orange : .purple
            )
        case "canyon_4000", "canyon_400", "canyon_40":
            QuizOptionVisual(
                imageName: "mars-canyons",
                symbol: "mountain.2.fill",
                color: choiceID == "canyon_4000" ? .red : .brown
            )
        case "cracked_ice":
            QuizOptionVisual(imageName: "europa-closeup", symbol: "snowflake", color: .cyan)
        case "green_clouds":
            QuizOptionVisual(imageName: "europa-global", symbol: "cloud.fill", color: .green)
        case "lava_desert", "iron_core":
            QuizOptionVisual(imageName: "mars-canyons", symbol: "flame.fill", color: .red)
        case "bright_hollows":
            QuizOptionVisual(
                imageName: "mercury-hollows", symbol: "circle.grid.cross.fill", color: .yellow)
        case "storm_clouds", "thick_cloud":
            QuizOptionVisual(imageName: "mars-polar-cap", symbol: "cloud.bolt.fill", color: .purple)
        case "ice_mountains", "polar_shadow":
            QuizOptionVisual(imageName: "mercury-polar-ice", symbol: "snowflake", color: .cyan)
        case "sunny_plain":
            QuizOptionVisual(imageName: "mercury-color", symbol: "sun.max.fill", color: .orange)
        case "olympus_600", "olympus_60", "olympus_6":
            QuizOptionVisual(
                imageName: "mars-olympus",
                symbol: "mountain.2.fill",
                color: choiceID == "olympus_600" ? .orange : .red
            )
        case "seasonal_ice":
            QuizOptionVisual(imageName: "mars-polar-cap", symbol: "snowflake", color: .cyan)
        case "never_change":
            QuizOptionVisual(
                imageName: "mars-comparison", symbol: "pause.circle.fill", color: .gray)
        case "fly_away":
            QuizOptionVisual(imageName: "mars-landscape", symbol: "paperplane.fill", color: .purple)
        case "chaos_blocks":
            QuizOptionVisual(imageName: "europa-chaos", symbol: "square.3.layers.3d", color: .pink)
        case "sand_dunes":
            QuizOptionVisual(imageName: "mars-landscape", symbol: "wind", color: .orange)
        case "green_forest":
            QuizOptionVisual(imageName: "europa-global", symbol: "tree.fill", color: .green)
        case "juno_1521", "juno_15210", "juno_152100":
            QuizOptionVisual(
                imageName: "europa-juno",
                symbol: "scope",
                color: choiceID == "juno_1521" ? .cyan : .indigo
            )
        default:
            QuizOptionVisual(
                imageName: "mercury-horizon",
                symbol: "questionmark.circle.fill",
                color: .indigo
            )
        }
    }
}

private struct QuizOptionVisual {
    let imageName: String
    let symbol: String
    let color: Color
}

private struct QuizAnswerCard: View {
    let letter: String
    let text: String
    let visual: QuizOptionVisual
    let isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let image = bundledImage(named: visual.imageName) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipped()
                } else {
                    visual.color.opacity(0.32)
                }

                LinearGradient(
                    colors: [.clear, visual.color.opacity(0.84)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack {
                    Text(letter)
                        .font(.title2.weight(.black))
                        .frame(width: 52, height: 52)
                        .background(.white, in: Circle())
                        .foregroundStyle(visual.color)

                    Spacer()

                    Image(systemName: visual.symbol)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                }
                .padding(18)
            }
            .frame(height: 230)
            .clipped()

            Text(text)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .padding(20)
                .foregroundStyle(.white)
                .background(visual.color.opacity(0.42))
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    isFocused ? Color.white : visual.color.opacity(0.72),
                    lineWidth: isFocused ? 6 : 2
                )
        }
        .shadow(
            color: isFocused ? visual.color.opacity(0.75) : .black.opacity(0.4),
            radius: isFocused ? 30 : 10,
            y: isFocused ? 8 : 4
        )
        .scaleEffect(isFocused ? 1.055 : 0.96)
        .opacity(isFocused ? 1 : 0.78)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isFocused)
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
