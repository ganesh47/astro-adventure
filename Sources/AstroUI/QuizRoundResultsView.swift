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
                    Label("DISCOVERY SAVED", systemImage: "sparkles")
                        .font((compact ? Font.caption : Font.headline).weight(.black))
                        .tracking(compact ? 1.4 : 2)
                        .foregroundStyle(.yellow)

                    Text("\(destinationName) discovered!")
                        .font(.system(size: compact ? 28 : 48, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: compact ? 50 : 90))
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)

                    Text("A new stamp for your Discovery Passport")
                        .font((compact ? Font.headline : Font.title2).bold())
                        .multilineTextAlignment(.center)
                    Text(
                        "You explored \(correctAnswers) of \(totalQuestions) clues.\nHints and retries help explorers learn!"
                    )
                    .font(compact ? .subheadline : .title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))

                    Button(action: onContinue) {
                        Label("Continue Exploring", systemImage: "rocket.fill")
                            .font((compact ? Font.subheadline : Font.title3).weight(.bold))
                            .frame(minWidth: compact ? 210 : 290)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .controlSize(compact ? .regular : .large)
                    .focused($continueFocused)
                    .accessibilityIdentifier("results.continue")
                }
                .padding(.horizontal, compact ? 44 : 70)
                .padding(.vertical, compact ? 8 : 36)
            }
        }
        .onAppear { continueFocused = true }
        .preferredColorScheme(.dark)
    }

}
