import Atoms
import SwiftUI

struct VoiceMemoListScreen: View {
    @WatchState(VoiceMemosAtom())
    var voiceMemos

    @Watch(VoiceMemoActionsAtom())
    var actions

    @Watch(AudioRecordPermissionAtom())
    var audioRecorderPermission

    @Watch(RecordingElapsedTimeAtom())
    var elapsedTimePhase

    @Watch(IsRecordingAtom())
    var isRecording

    @WatchState(IsRecordingFailedAtom())
    var isRecordingFailed

    @WatchState(IsPlaybackFailedAtom())
    var isPlaybackFailed

    var body: some View {
        VStack {
            List {
                ForEach($voiceMemos, id: \.url) { $voiceMemo in
                    VoiceMemoRow(voiceMemo: $voiceMemo)
                }
                .onDelete { IndexSet in
                    actions.delete(at: IndexSet)
                }
            }

            VStack {
                ZStack {
                    switch audioRecorderPermission {
                    case .undetermined, .granted:
                        Circle()
                            .foregroundColor(Color(.label))
                            .frame(width: 74, height: 74)

                        Button {
                            withAnimation(.spring()) {
                                actions.toggleRecording()
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: isRecording ? 4 : 35)
                                .foregroundColor(Color(.systemRed))
                                .padding(isRecording ? 18 : 2)
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

                let elapsedTime = elapsedTimePhase.value ?? .zero

                if isRecording, let formattedDuration = dateComponentsFormatter.string(from: elapsedTime) {
                    Text(formattedDuration)
                        .font(.body.monospacedDigit().bold())
                        .foregroundColor(.white)
                        .colorMultiply(Color(Int(elapsedTime).isMultiple(of: 2) ? .systemRed : .label))
                        .animation(.easeInOut(duration: 0.5), value: elapsedTime)
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
