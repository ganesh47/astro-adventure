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
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.9), .black, .cyan.opacity(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Label("ROUND COMPLETE", systemImage: "trophy.fill")
                    .font(.headline.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.yellow)

                Text("\(destinationName) Star Score")
                    .font(.system(size: 48, weight: .black, design: .rounded))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < stars ? "star.fill" : "star")
                            .font(.system(size: 54))
                            .foregroundStyle(index < stars ? .yellow : .white.opacity(0.24))
                            .rotationEffect(.degrees(index == 1 ? 0 : index == 0 ? -9 : 9))
                    }
                }

                HStack(spacing: 16) {
                    scoreChip(value: "\(score)", label: "POINTS", color: .yellow)
                    scoreChip(
                        value: "\(correctAnswers)/\(totalQuestions)",
                        label: "CARDS MASTERED",
                        color: .cyan
                    )
                    scoreChip(value: "🔥 \(bestStreak)", label: "BEST STREAK", color: .orange)
                }

                leaderboardPanel

                Button(action: onContinue) {
                    Label("Continue Exploring", systemImage: "rocket.fill")
                        .font(.title3.weight(.bold))
                        .frame(minWidth: 290)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.large)
                .focused($continueFocused)
            }
            .padding(.horizontal, 70)
            .padding(.vertical, 36)
        }
        .onAppear { continueFocused = true }
        .preferredColorScheme(.dark)
    }

    private func scoreChip(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(minWidth: 190)
        .padding(.vertical, 13)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay { Capsule().stroke(color.opacity(0.42), lineWidth: 2) }
    }

    private var leaderboardPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Label("EXPLORER LEADERBOARD", systemImage: "medal.star.fill")
                    .font(.headline.weight(.black))
                    .tracking(1.3)
                Spacer()
                Text("Saved on this Apple TV")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }

            ForEach(Array(leaderboard.prefix(3).enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: 16) {
                    Text(["🥇", "🥈", "🥉"][index])
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.explorerName)
                            .font(.headline.weight(.bold))
                        Text("\(entry.destinationName) · \(entry.correctAnswers)/\(entry.totalQuestions) cards")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    Text("\(entry.score)")
                        .font(.title2.monospacedDigit().weight(.black))
                        .foregroundStyle(.yellow)
                    Text("PTS")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    index == 0 ? Color.yellow.opacity(0.14) : Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
        .frame(maxWidth: 900)
        .padding(20)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.16)) }
    }
}
