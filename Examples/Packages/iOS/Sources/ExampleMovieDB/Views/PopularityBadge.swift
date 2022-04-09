import SwiftUI

struct PopularityBadge: View {
    let voteAverage: Float

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.primary)
                .overlay(overlay)

            Text(Int(score * 100).description + "%")
                .font(.caption2.bold())
                .foregroundColor(.primary)
                .colorInvert()
        }
        .frame(width: 36, height: 36)
    }

    var overlay: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(score))
                .stroke(style: StrokeStyle(lineWidth: 2))
                .foregroundColor(scoreColor)
        }
        .rotationEffect(.degrees(-90))
        .padding(2)
    }
}

private extension PopularityBadge {
    var score: Float {
        voteAverage / 10
    }

    var scoreColor: Color {
        switch voteAverage {
        case ..<4:
            return .red

        case 4..<6:
            return .orange

        case 6..<7.5:
            return .yellow

        default:
            return .green
        }
    }
}
