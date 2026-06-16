import AVFAudio
import Atoms
import Combine
import Foundation
import Testing

@testable import ExampleVoiceMemo

struct ExampleVoiceMemoTests {
    @MainActor
    @Test
    func testIsRecordingAtom() {
        let context = AtomTestContext()
        let atom = IsRecordingAtom()

        context.override(RecordingDataAtom()) { _ in nil }
        #expect(!context.read(atom))

        context.override(RecordingDataAtom()) { _ in .stub() }
        #expect(context.read(atom))
    }

    @MainActor
    @Test
    func testRecordingDataAtom() {
        let context = AtomTestContext()
        let atom = RecordingDataAtom()
        let audioSession = MockAudioSession()
        let audioRecorder = MockAudioRecorder()
        let recordingData = RecordingData.stub()

        context.override(AudioSessionAtom()) { _ in audioSession }
        context.override(AudioRecorderAtom()) { _ in audioRecorder }

        #expect(context.watch(atom) == nil)
        #expect(context.watch(VoiceMemosAtom()).isEmpty)
        #expect(!context.watch(IsRecordingFailedAtom()))

        context[atom] = recordingData

        #expect(audioSession.currentCategory == .playAndRecord)
        #expect(audioSession.currentMode == .default)
        #expect(audioSession.currentOptions == .defaultToSpeaker)
        #expect(audioSession.isActive)
        #expect(audioRecorder.isRecording)

        context[atom] = nil

        #expect(
            context.watch(VoiceMemosAtom())
                == [VoiceMemo(url: recordingData.url, date: recordingData.date, duration: audioRecorder.currentTime)]
        )
        #expect(!audioSession.isActive)
        #expect(!audioRecorder.isRecording)

        audioRecorder.recordingError = URLError(.unknown)
        context[atom] = recordingData

        #expect(context.watch(IsRecordingFailedAtom()))
    }

    @MainActor
    @Test
    func testRecordingElapsedTimeAtom() async {
        let context = AtomTestContext()
        let atom = RecordingElapsedTimeAtom()

        context.override(IsRecordingAtom()) { _ in false }
        context.override(ValueGeneratorAtom()) { _ in .stub() }
        context.override(TimerAtom.self) { _ in Just(10).eraseToAnyPublisher() }

        #expect(context.watch(atom) == .suspending)

        await context.waitForUpdate()

        #expect(context.watch(atom) == .success(.zero))

        context.override(IsRecordingAtom()) { _ in true }
        context.reset(IsRecordingAtom())

        #expect(context.watch(atom) == .suspending)

        await context.waitForUpdate()

        #expect(context.watch(atom) == .success(10))
    }

    @MainActor
    @Test
    func testToggleRecording() {
        let context = AtomTestContext()
        let actions = VoiceMemoActions(context: context)
        let audioSession = MockAudioSession()
        let generator = ValueGenerator.stub()

        context.override(IsRecordingAtom()) { _ in false }
        context.override(ValueGeneratorAtom()) { _ in generator }
        context.override(AudioSessionAtom()) { _ in audioSession }
        context.override(AudioRecorderAtom()) { _ in MockAudioRecorder() }

        audioSession.recordPermission = .undetermined

        #expect(context.watch(AudioRecordPermissionAtom()) == .undetermined)
        #expect(!context.watch(IsRecordingFailedAtom()))
        #expect(context.watch(RecordingDataAtom()) == nil)

        actions.toggleRecording()
        audioSession.recordPermission = .denied
        audioSession.requestRecordPermissionResponse!(true)

        #expect(context.watch(AudioRecordPermissionAtom()) == .denied)

        actions.toggleRecording()

        #expect(context.watch(IsRecordingFailedAtom()))

        audioSession.recordPermission = .granted
        context.reset(AudioRecordPermissionAtom())
        actions.toggleRecording()

        #expect(
            context.watch(RecordingDataAtom())
                == RecordingData(
                    url: URL(fileURLWithPath: generator.temporaryDirectory())
                        .appendingPathComponent(generator.uuid().uuidString)
                        .appendingPathExtension("m4a"),
                    date: generator.date()
                )
        )

        context.override(IsRecordingAtom()) { _ in true }
        actions.toggleRecording()

        #expect(context.watch(RecordingDataAtom()) == nil)
    }

    @MainActor
    @Test
    func testDelete() {
        let context = AtomTestContext()
        let actions = VoiceMemoActions(context: context)
        let voiceMemo = VoiceMemo.stub()

        context.override(VoiceMemosAtom()) { _ in [voiceMemo] }
        context.override(IsPlayingAtom.self) { _ in true }

        #expect(context.watch(VoiceMemosAtom()) == [voiceMemo])
        #expect(context.watch(IsPlayingAtom(voiceMemo: voiceMemo)))

        actions.delete(at: [0])

        #expect(context.watch(VoiceMemosAtom()).isEmpty)
        #expect(!context.watch(IsPlayingAtom(voiceMemo: voiceMemo)))
    }

    @MainActor
    @Test
    func testIsPlayingAtom() {
        let context = AtomTestContext()
        let audioPlayer = MockAudioPlayer()
        let voiceMemo = VoiceMemo.stub()
        let atom = IsPlayingAtom(voiceMemo: voiceMemo)

        context.override(AudioPlayerAtom.self) { _ in audioPlayer }

        #expect(!context.watch(atom))
        #expect(!context.watch(IsPlaybackFailedAtom()))

        context[atom] = true

        #expect(audioPlayer.isPlaying)

        context[atom] = false

        #expect(!audioPlayer.isPlaying)

        audioPlayer.playingError = URLError(.unknown)
        context[atom] = true

        #expect(context.watch(IsPlaybackFailedAtom()))
    }

    @MainActor
    @Test
    func testPlayingElapsedTimeAtom() async {
        let context = AtomTestContext()
        let voiceMemo = VoiceMemo.stub()
        let atom = PlayingElapsedTimeAtom(voiceMemo: voiceMemo)

        context.override(IsPlayingAtom.self) { _ in false }
        context.override(ValueGeneratorAtom()) { _ in .stub() }
        context.override(TimerAtom.self) { _ in Just(10).eraseToAnyPublisher() }

        #expect(context.watch(atom) == .suspending)

        await context.waitForUpdate()

        #expect(context.watch(atom) == .success(.zero))

        context.override(IsPlayingAtom.self) { _ in true }
        context.reset(IsPlayingAtom(voiceMemo: voiceMemo))

        #expect(context.watch(atom) == .suspending)

        await context.waitForUpdate()

        #expect(context.watch(atom) == .success(10))
    }
}

private extension ValueGenerator {
    static func stub() -> Self {
        ValueGenerator(
            date: { Date(timeIntervalSince1970: 0) },
            uuid: { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! },
            temporaryDirectory: { "/tmp" }
        )
    }
}

private extension RecordingData {
    static func stub() -> Self {
        RecordingData(url: URL(string: NSTemporaryDirectory())!, date: Date(timeIntervalSince1970: .zero))
    }
}

private extension VoiceMemo {
    static func stub() -> Self {
        VoiceMemo(
            url: URL(fileURLWithPath: "/tmp"),
            date: Date(timeIntervalSince1970: 0),
            duration: 0
        )
    }
}
