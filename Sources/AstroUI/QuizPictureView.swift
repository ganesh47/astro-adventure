import AstroGameCore
import SwiftUI

/// Offline answer proposals. This view has no access to answer correctness or position.
struct QuizPictureView: View {
    let picture: QuizPicture
    var compact = false

    var body: some View {
        VStack(spacing: 8) {
            QuizScientificIllustration(picture: picture, compact: compact)
                .frame(height: compact ? 76 : 170)
                .accessibilityHidden(true)
            if showsQuantityLabel {
                Text(picture.label)
                    .font(.headline.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            Color(red: 0.045, green: 0.075, blue: 0.15), in: RoundedRectangle(cornerRadius: 18)
        )
        .accessibilityLabel("Answer idea: \(picture.label). \(picture.detail ?? "")")
    }

    private var showsQuantityLabel: Bool {
        switch picture.scene {
        case .distance, .duration, .temperature, .measurement, .sizeComparison, .waterCoverage,
            .craterWidth, .canyonLength, .volcanoWidth, .flybyDistance, .planetDiameter,
            .spacecraftSize, .classroomDistance, .earthWorldDistance, .changingOrbitDistance:
            true
        default:
            false
        }
    }
}
