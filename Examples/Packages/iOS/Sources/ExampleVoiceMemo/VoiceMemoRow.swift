import Atoms
import SwiftUI

struct VoiceMemoRow: View {
    @Binding
    var voiceMemo: VoiceMemo

    @ViewContext
    var context

    var viewModel: VoiceMemoRowViewModel {
        context.watch(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemo))
    }

    var progress: Double {
        max(0, min(1, viewModel.elapsedTime / voiceMemo.duration))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                if viewModel.isPlaying {
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

                    if let time = dateComponentsFormatter.string(from: viewModel.isPlaying ? viewModel.elapsedTime : voiceMemo.duration) {
                        Text(time)
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(Color(.systemGray))
                    }

                    Button {
                        viewModel.togglePaying()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "stop.circle" : "play.circle")
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
