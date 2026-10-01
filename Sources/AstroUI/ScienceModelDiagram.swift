import SwiftUI

/// Deliberately qualitative diagrams accompany authored outcomes, rather than inventing numeric physics.
struct ScienceModelDiagram: View {
    let optionID: String
    let destinationID: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if optionID.hasSuffix("thick-air") || optionID.hasSuffix("thin-air") {
                atmosphere
            } else if optionID.hasSuffix("sideways") || optionID.hasSuffix("upright")
                || optionID.hasSuffix("north-toward") || optionID.hasSuffix("north-away")
            {
                tilt
            } else if optionID.hasSuffix("near") || optionID.hasSuffix("far") {
                distance
            } else if optionID.hasSuffix("sunlight-route") || optionID.hasSuffix("radio-route") {
                lightRoute
            } else if optionID.hasSuffix("methane") || optionID.hasSuffix("no-methane") {
                atmosphereColor
            } else if optionID.hasSuffix("rotate") || optionID.hasSuffix("orbit")
                || optionID.hasSuffix("retrograde") || optionID.hasSuffix("prograde")
                || optionID.hasSuffix("solar-cycle") || optionID.hasSuffix("axial-turn")
            {
                motion
            } else {
                comparison
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: optionID)
        .padding(14)
        .frame(maxWidth: 700)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }

    private var globeColor: Color {
        switch destinationID {
        case "venus": .orange
        case "uranus", "neptune": .cyan
        case "mercury": .gray
        default: .blue
        }
    }

    private var atmosphere: some View {
        HStack(spacing: 35) {
            sun
            Image(systemName: "arrow.right").font(.largeTitle).foregroundStyle(.yellow)
            ZStack {
                ForEach(0..<(optionID.hasSuffix("thick-air") ? 4 : 1), id: \.self) { index in
                    Circle().stroke(.orange.opacity(0.65), lineWidth: 5)
                        .frame(width: CGFloat(88 + index * 14), height: CGFloat(88 + index * 14))
                }
                Circle().fill(globeColor).frame(width: 76, height: 76)
                Image(systemName: "arrow.uturn.down").font(.largeTitle).foregroundStyle(.white)
            }
            Text(optionID.hasSuffix("thick-air") ? "Thicker atmosphere" : "Thinner atmosphere")
                .font(.headline).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tilt: some View {
        let sideways = optionID.hasSuffix("sideways")
        let upright = optionID.hasSuffix("upright")
        let angle =
            sideways ? 98.0 : upright ? 0 : optionID.hasSuffix("north-toward") ? -23.5 : 23.5
        return HStack(spacing: 36) {
            sun
            Image(systemName: "arrow.right").font(.largeTitle).foregroundStyle(.yellow)
            ZStack {
                Circle().fill(globeColor.gradient).frame(width: 94, height: 94)
                Ellipse().stroke(.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 94, height: 28).rotationEffect(.degrees(angle))
                VStack(spacing: 0) {
                    Text("N").font(.caption.bold())
                    Rectangle().fill(.white).frame(width: 4, height: 108)
                    Text("S").font(.caption.bold())
                }
                .rotationEffect(.degrees(angle))
            }
            Text("Change the axis\nObserve the sunlight")
                .font(.headline).multilineTextAlignment(.center)
        }
    }

    private var distance: some View {
        HStack(spacing: 8) {
            sun
            Rectangle().fill(.yellow.opacity(0.6)).frame(
                maxWidth: optionID.hasSuffix("far") ? 350 : 90, maxHeight: 3)
            Circle().fill(globeColor).frame(width: 65, height: 65)
            Text(optionID.hasSuffix("far") ? "Farther" : "Closer").font(.headline)
        }
    }

    private var lightRoute: some View {
        HStack(spacing: 25) {
            if optionID.hasSuffix("sunlight-route") {
                sun
                Text("Sunlight").font(.headline)
            } else {
                Image(systemName: "globe.americas.fill").font(.system(size: 60)).foregroundStyle(
                    .blue)
                Text("Radio signal").font(.headline)
            }
            Image(systemName: "arrow.right").font(.largeTitle).foregroundStyle(.yellow)
            Circle().fill(globeColor).frame(width: 70, height: 70)
        }
    }

    private var atmosphereColor: some View {
        let methane = !optionID.hasSuffix("no-methane")
        return HStack(spacing: 24) {
            VStack(spacing: 10) {
                Label("Red light", systemImage: "arrow.right").foregroundStyle(.red)
                Label("Blue light", systemImage: "arrow.right").foregroundStyle(.cyan)
            }
            Rectangle().fill(.white.opacity(0.2)).frame(width: 12, height: 90)
            ZStack {
                Circle().fill(methane ? Color.cyan.gradient : Color.gray.gradient).frame(
                    width: 90, height: 90)
                Text(methane ? "CH₄" : "Air").font(.headline.bold()).foregroundStyle(.black)
            }
            Text(methane ? "Some red light\nis absorbed" : "Compare with\nno methane")
                .font(.headline).multilineTextAlignment(.center)
        }
    }

    private var motion: some View {
        let orbit = optionID.hasSuffix("orbit") || optionID.hasSuffix("solar-cycle")
        return HStack(spacing: 32) {
            if orbit {
                ZStack {
                    Ellipse().stroke(.white.opacity(0.5), lineWidth: 3).frame(
                        width: 190, height: 110)
                    sun
                    Circle().fill(globeColor).frame(width: 30, height: 30).offset(x: 95)
                }
                Text("Around the Sun").font(.headline)
            } else {
                ZStack {
                    Circle().fill(globeColor.gradient).frame(width: 94, height: 94)
                    Image(
                        systemName: optionID.hasSuffix("retrograde")
                            ? "arrow.counterclockwise" : "arrow.clockwise"
                    )
                    .font(.system(size: 115, weight: .light)).foregroundStyle(.white)
                }
                Text("Around an axis").font(.headline)
            }
        }
    }

    private var comparison: some View {
        HStack(spacing: 30) {
            Image(systemName: "slider.horizontal.3").font(.system(size: 50)).foregroundStyle(.cyan)
            Image(systemName: "arrow.right").font(.largeTitle).foregroundStyle(.yellow)
            Image(systemName: "eye.fill").font(.system(size: 50)).foregroundStyle(.white)
            Text("Change one setting\nCompare the outcome").font(.headline).multilineTextAlignment(
                .center)
        }
    }

    private var sun: some View {
        Image(systemName: "sun.max.fill").font(.system(size: 62)).foregroundStyle(.yellow)
    }
}
