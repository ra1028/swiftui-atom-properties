import Atoms
import SwiftUI

struct VoiceMemoRow: View {
    @Binding
    var voiceMemo: VoiceMemo

    @ViewContext
    var context

    var isPlaying: Binding<Bool> {
        context.binding(IsPlayingAtom(voiceMemo: voiceMemo))
    }

    var elapsedTime: TimeInterval {
        context.watch(PlayingElapsedTimeAtom(voiceMemo: voiceMemo)).value ?? .zero
    }

    var progress: Double {
        max(0, min(1, elapsedTime / voiceMemo.duration))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                if isPlaying.wrappedValue {
                    Rectangle()
                        .foregroundColor(Color(.systemGray5))
                        .frame(width: proxy.size.width * CGFloat(progress))
                        .animation(.linear(duration: 0.5), value: progress)
                }

                HStack {
                    TextField(
                        "Untitled, \(voiceMemo.date.formatted(date: .numeric, time: .shortened))",
                        text: $voiceMemo.title
                    )

                    Spacer()

                    if let time = dateComponentsFormatter.string(from: isPlaying.wrappedValue ? elapsedTime : voiceMemo.duration) {
                        Text(time)
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(Color(.systemGray))
                    }

                    Button {
                        isPlaying.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isPlaying.wrappedValue ? "stop.circle" : "play.circle")
                            .font(Font.system(size: 22))
                    }
                }
                .frame(maxHeight: .infinity)
                .padding([.leading, .trailing])
            }
        }
        .buttonStyle(.borderless)
        .listRowInsets(EdgeInsets())
    }
}
