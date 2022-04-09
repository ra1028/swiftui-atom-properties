import Atoms
import SwiftUI

struct VoiceMemoListScreen: View {
    @WatchStateObject(VoiceMemoListViewModelAtom())
    var viewModel

    @WatchState(IsRecordingFailedAtom())
    var isRecordingFailed

    @WatchState(IsPlaybackFailedAtom())
    var isPlaybackFailed

    var body: some View {
        VStack {
            List {
                ForEach($viewModel.voiceMemos, id: \.url) { $voiceMemo in
                    VoiceMemoRow(voiceMemo: $voiceMemo)
                }
                .onDelete { viewModel.delete($0) }
            }

            VStack {
                ZStack {
                    switch viewModel.audioRecorderPermission {
                    case .undetermined, .granted:
                        Circle()
                            .foregroundColor(Color(.label))
                            .frame(width: 74, height: 74)

                        Button {
                            withAnimation(.spring()) {
                                viewModel.toggleRecording()
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: viewModel.isRecording ? 4 : 35)
                                .foregroundColor(Color(.systemRed))
                                .padding(viewModel.isRecording ? 18 : 2)
                        }
                        .frame(width: 70, height: 70)

                    case .denied:
                        VStack(spacing: 10) {
                            Text("Recording requires microphone access.")
                                .multilineTextAlignment(.center)

                            Button("Open Settings") {
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 74)

                    @unknown default:
                        EmptyView()
                    }
                }

                if viewModel.isRecording, let formattedDuration = dateComponentsFormatter.string(from: viewModel.elapsedTime) {
                    Text(formattedDuration)
                        .font(.body.monospacedDigit().bold())
                        .foregroundColor(.white)
                        .colorMultiply(Color(Int(viewModel.elapsedTime).isMultiple(of: 2) ? .systemRed : .label))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.elapsedTime)
                }
            }
            .padding()
            .alert(
                "Voice memo recording failed.",
                isPresented: $isRecordingFailed,
                actions: {}
            )
            .alert(
                "Voice memo playback failed.",
                isPresented: $isPlaybackFailed,
                actions: {}
            )
        }
        .navigationTitle("Voice Memo")
        .background(Color(.tertiarySystemBackground))
    }
}

struct VoiceMemoListScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            VoiceMemoListScreen()
        }
        .override(AudioSessionAtom()) { _ in
            MockAudioSession()
        }
        .override(AudioRecorderAtom()) { _ in
            MockAudioRecorder()
        }
        .override(AudioPlayerAtom.self) { _ in
            MockAudioPlayer()
        }
    }
}
