import AstroGameCore
import SwiftUI

struct QuizRoundResultsView: View {
    let destinationName: String
    let score: Int
    let stars: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let bestStreak: Int
    let leaderboard: [LeaderboardEntry]
    let onContinue: () -> Void

    @FocusState private var continueFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 520

            ZStack {
                LinearGradient(
                    colors: [.indigo.opacity(0.9), .black, .cyan.opacity(0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: compact ? 8 : 24) {
                    Label("ROUND COMPLETE", systemImage: "trophy.fill")
                        .font((compact ? Font.caption : Font.headline).weight(.black))
                        .tracking(compact ? 1.4 : 2)
                        .foregroundStyle(.yellow)

                    Text("\(destinationName) Star Score")
                        .font(
                            .system(
                                size: compact ? 28 : 48,
                                weight: .black,
                                design: .rounded
                            )
                        )

                    HStack(spacing: compact ? 5 : 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < stars ? "star.fill" : "star")
                                .font(.system(size: compact ? 30 : 54))
                                .foregroundStyle(index < stars ? .yellow : .white.opacity(0.24))
                                .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -9 : 9))
                        }
                    }

                    HStack(spacing: compact ? 8 : 16) {
                        scoreChip(
                            value: "\(score)", label: "POINTS", color: .yellow, compact: compact)
                        scoreChip(
                            value: "\(correctAnswers)/\(totalQuestions)",
                            label: "CARDS MASTERED",
                            color: .cyan,
                            compact: compact
                        )
                        scoreChip(
                            value: "🔥 \(bestStreak)",
                            label: "BEST STREAK",
                            color: .orange,
                            compact: compact
                        )
                    }

                    leaderboardPanel(compact: compact)

                    Button(action: onContinue) {
                        Label("Continue Exploring", systemImage: "rocket.fill")
                            .font((compact ? Font.subheadline : Font.title3).weight(.bold))
                            .frame(minWidth: compact ? 210 : 290)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .controlSize(compact ? .regular : .large)
                    .focused($continueFocused)
                }
                .padding(.horizontal, compact ? 44 : 70)
                .padding(.vertical, compact ? 8 : 36)
            }
        }
        .onAppear { continueFocused = true }
        .preferredColorScheme(.dark)
    }

    private func scoreChip(
        value: String,
        label: String,
        color: Color,
        compact: Bool
    ) -> some View {
        VStack(spacing: compact ? 1 : 3) {
            Text(value)
                .font(.system(size: compact ? 20 : 30, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font((compact ? Font.caption2 : Font.caption).weight(.black))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(minWidth: compact ? 120 : 190)
        .padding(.vertical, compact ? 6 : 13)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay { Capsule().stroke(color.opacity(0.42), lineWidth: 2) }
    }

    private func leaderboardPanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 5 : 12) {
            HStack {
                Label("EXPLORER LEADERBOARD", systemImage: "medal.star.fill")
                    .font((compact ? Font.caption : Font.headline).weight(.black))
                    .tracking(compact ? 0.8 : 1.3)
                Spacer()
                Text(savedLocationLabel)
                    .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }

            ForEach(
                Array(leaderboard.prefix(compact ? 2 : 3).enumerated()),
                id: \.element.id
            ) { index, entry in
                HStack(spacing: 16) {
                    Text(["🥇", "🥈", "🥉"][index])
                        .font(compact ? .body : .title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.explorerName)
                            .font((compact ? Font.subheadline : Font.headline).weight(.bold))
                        Text(
                            "\(entry.destinationName) · \(entry.correctAnswers)/\(entry.totalQuestions) cards"
                        )
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    Text("\(entry.score)")
                        .font(
                            (compact ? Font.subheadline : Font.title2)
                                .monospacedDigit().weight(.black)
                        )
                        .foregroundStyle(.yellow)
                    Text("PTS")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, compact ? 10 : 18)
                .padding(.vertical, compact ? 5 : 10)
                .background(
                    index == 0 ? Color.yellow.opacity(0.14) : Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
        .frame(maxWidth: 900)
        .padding(compact ? 10 : 20)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.16)) }
    }

    private var savedLocationLabel: String {
        #if os(tvOS)
            "Saved on this Apple TV"
        #else
            "Saved on this device"
        #endif
    }
}
