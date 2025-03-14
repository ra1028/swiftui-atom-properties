import Atoms
import SwiftUI

struct VoiceMemoListScreen: View {
    @WatchState(VoiceMemosAtom())
    var voiceMemos

    @Watch(VoiceMemoActionsAtom())
    var actions

    @Watch(AudioRecordPermissionAtom())
    var audioRecorderPermission

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
                .onDelete { indexSet in
                    actions.delete(at: indexSet)
                }
            }

            VStack {
                switch audioRecorderPermission {
                case .undetermined, .granted:
                    RecordingButton()

                case .denied:
                    PermissionDeniedContent()

                @unknown default:
                    PermissionDeniedContent()
                }

                if isRecording {
                    ElapsedTimeDisplay()
                }
            }
            .padding()
        }
        .navigationTitle("Voice Memo")
        .background(Color(.tertiarySystemBackground))
        .ignoresSafeArea(.keyboard)
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
}

private struct RecordingButton: View {
    @Watch(IsRecordingAtom())
    var isRecording

    @Watch(VoiceMemoActionsAtom())
    var actions

    var body: some View {
        ZStack {
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
        }
    }
}

private struct PermissionDeniedContent: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Recording requires microphone access.")
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 74)
    }
}

private struct ElapsedTimeDisplay: View {
    @Watch(RecordingElapsedTimeAtom())
    var elapsedTimePhase

    var body: some View {
        let elapsedTime = elapsedTimePhase.value ?? .zero

        if let formattedDuration = dateComponentsFormatter.string(from: elapsedTime) {
            Text(formattedDuration)
                .font(.body.monospacedDigit().bold())
                .foregroundColor(.white)
                .colorMultiply(Color(Int(elapsedTime).isMultiple(of: 2) ? .systemRed : .label))
                .animation(.easeInOut(duration: 0.5), value: elapsedTime)
        }
    }
}

#Preview {
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
