import AVFAudio
import Atoms
import Combine
import XCTest

@testable import ExampleVoiceMemo

final class ExampleVoiceMemoTests: XCTestCase {
    @MainActor
    func testIsRecordingAtom() {
        let context = AtomTestContext()
        let atom = IsRecordingAtom()

        context.override(RecordingDataAtom()) { _ in nil }
        XCTAssertFalse(context.read(atom))

        context.override(RecordingDataAtom()) { _ in .stub() }
        XCTAssertTrue(context.read(atom))
    }

    @MainActor
    func testRecordingDataAtom() {
        let context = AtomTestContext()
        let atom = RecordingDataAtom()
        let audioSession = MockAudioSession()
        let audioRecorder = MockAudioRecorder()
        let recordingData = RecordingData.stub()

        context.override(AudioSessionAtom()) { _ in audioSession }
        context.override(AudioRecorderAtom()) { _ in audioRecorder }

        XCTAssertNil(context.watch(atom))
        XCTAssertTrue(context.watch(VoiceMemosAtom()).isEmpty)
        XCTAssertFalse(context.watch(IsRecordingFailedAtom()))

        context[atom] = recordingData

        XCTAssertEqual(audioSession.currentCategory, .playAndRecord)
        XCTAssertEqual(audioSession.currentMode, .default)
        XCTAssertEqual(audioSession.currentOptions, .defaultToSpeaker)
        XCTAssertTrue(audioSession.isActive)
        XCTAssertTrue(audioRecorder.isRecording)

        context[atom] = nil

        XCTAssertEqual(
            context.watch(VoiceMemosAtom()),
            [VoiceMemo(url: recordingData.url, date: recordingData.date, duration: audioRecorder.currentTime)]
        )
        XCTAssertFalse(audioSession.isActive)
        XCTAssertFalse(audioRecorder.isRecording)

        audioRecorder.recordingError = URLError(.unknown)
        context[atom] = recordingData

        XCTAssertTrue(context.watch(IsRecordingFailedAtom()))
    }

    @MainActor
    func testRecordingElapsedTimeAtom() async {
        let context = AtomTestContext()
        let atom = RecordingElapsedTimeAtom()

        context.override(IsRecordingAtom()) { _ in false }
        context.override(ValueGeneratorAtom()) { _ in .stub() }
        context.override(TimerAtom.self) { _ in Just(10).eraseToAnyPublisher() }

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.waitForUpdate()

        XCTAssertEqual(context.watch(atom), .success(.zero))

        context.override(IsRecordingAtom()) { _ in true }
        context.reset(IsRecordingAtom())

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.waitForUpdate()

        XCTAssertEqual(context.watch(atom), .success(10))
    }

    @MainActor
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

        XCTAssertEqual(context.watch(AudioRecordPermissionAtom()), .undetermined)
        XCTAssertFalse(context.watch(IsRecordingFailedAtom()))
        XCTAssertNil(context.watch(RecordingDataAtom()))

        actions.toggleRecording()
        audioSession.recordPermission = .denied
        audioSession.requestRecordPermissionResponse!(true)

        XCTAssertEqual(context.watch(AudioRecordPermissionAtom()), .denied)

        actions.toggleRecording()

        XCTAssertTrue(context.watch(IsRecordingFailedAtom()))

        audioSession.recordPermission = .granted
        context.reset(AudioRecordPermissionAtom())
        actions.toggleRecording()

        XCTAssertEqual(
            context.watch(RecordingDataAtom()),
            RecordingData(
                url: URL(fileURLWithPath: generator.temporaryDirectory())
                    .appendingPathComponent(generator.uuid().uuidString)
                    .appendingPathExtension("m4a"),
                date: generator.date()
            )
        )

        context.override(IsRecordingAtom()) { _ in true }
        actions.toggleRecording()

        XCTAssertNil(context.watch(RecordingDataAtom()))
    }

    @MainActor
    func testDelete() {
        let context = AtomTestContext()
        let actions = VoiceMemoActions(context: context)
        let voiceMemo = VoiceMemo.stub()

        context.override(VoiceMemosAtom()) { _ in [voiceMemo] }
        context.override(IsPlayingAtom.self) { _ in true }

        XCTAssertEqual(context.watch(VoiceMemosAtom()), [voiceMemo])
        XCTAssertTrue(context.watch(IsPlayingAtom(voiceMemo: voiceMemo)))

        actions.delete(at: [0])

        XCTAssertTrue(context.watch(VoiceMemosAtom()).isEmpty)
        XCTAssertFalse(context.watch(IsPlayingAtom(voiceMemo: voiceMemo)))
    }

    @MainActor
    func testIsPlayingAtom() {
        let context = AtomTestContext()
        let audioPlayer = MockAudioPlayer()
        let voiceMemo = VoiceMemo.stub()
        let atom = IsPlayingAtom(voiceMemo: voiceMemo)

        context.override(AudioPlayerAtom.self) { _ in audioPlayer }

        XCTAssertFalse(context.watch(atom))
        XCTAssertFalse(context.watch(IsPlaybackFailedAtom()))

        context[atom] = true

        XCTAssertTrue(audioPlayer.isPlaying)

        context[atom] = false

        XCTAssertFalse(audioPlayer.isPlaying)

        audioPlayer.playingError = URLError(.unknown)
        context[atom] = true

        XCTAssertTrue(context.watch(IsPlaybackFailedAtom()))
    }

    @MainActor
    func testPlayingElapsedTimeAtom() async {
        let context = AtomTestContext()
        let voiceMemo = VoiceMemo.stub()
        let atom = PlayingElapsedTimeAtom(voiceMemo: voiceMemo)

        context.override(IsPlayingAtom.self) { _ in false }
        context.override(ValueGeneratorAtom()) { _ in .stub() }
        context.override(TimerAtom.self) { _ in Just(10).eraseToAnyPublisher() }

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.waitForUpdate()

        XCTAssertEqual(context.watch(atom), .success(.zero))

        context.override(IsPlayingAtom.self) { _ in true }
        context.reset(IsPlayingAtom(voiceMemo: voiceMemo))

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.waitForUpdate()

        XCTAssertEqual(context.watch(atom), .success(10))
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
