import Atoms
import Combine
import XCTest

@testable import ExampleVoiceMemo

@MainActor
final class ExampleVoiceMemoTests: XCTestCase {
    func testVoiceMemoListViewModelAtom() {
        let audioSession = MockAudioSession()
        let audioRecorder = MockAudioRecorder()
        let audioPlayer = MockAudioPlayer()
        let generator = Generator.stub()
        let fileURL = URL(fileURLWithPath: generator.temporaryDirectory())
            .appendingPathComponent(generator.uuid().uuidString)
            .appendingPathExtension("m4a")
        let timer = PassthroughSubject<TimeInterval, Never>()

        audioSession.recordPermission = .undetermined
        audioRecorder.currentTime = 100

        let context = AtomTestContext()

        context.override(AudioSessionAtom()) { _ in audioSession }
        context.override(AudioRecorderAtom()) { _ in audioRecorder }
        context.override(AudioPlayerAtom.self) { _ in audioPlayer }
        context.override(GeneratorAtom()) { _ in generator }
        context.override(TimerAtom.self) { _ in timer.eraseToAnyPublisher() }

        let viewModel = context.watch(VoiceMemoListViewModelAtom())

        XCTAssertEqual(viewModel.voiceMemos, [])
        XCTAssertEqual(viewModel.audioRecorderPermission, .undetermined)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(context.watch(IsRecordingFailedAtom()))

        viewModel.toggleRecording()

        XCTAssertNotNil(audioSession.requestRecordPermissionResponse)

        audioSession.recordPermission = .denied
        viewModel.toggleRecording()

        XCTAssertTrue(context.watch(IsRecordingFailedAtom()))

        context[IsRecordingFailedAtom()] = false
        audioSession.recordPermission = .granted
        audioSession.requestRecordPermissionResponse?(true)
        viewModel.toggleRecording()
        timer.send(10)

        XCTAssertTrue(viewModel.isRecording)
        XCTAssertEqual(viewModel.audioRecorderPermission, .granted)
        XCTAssertEqual(viewModel.elapsedTime, 10)
        XCTAssertEqual(audioSession.currentCategory, .playAndRecord)
        XCTAssertEqual(audioSession.currentMode, .default)
        XCTAssertEqual(audioSession.currentOptions, .defaultToSpeaker)
        XCTAssertTrue(audioSession.isActive)
        XCTAssertTrue(audioRecorder.isRecording)
        XCTAssertEqual(
            viewModel.currentRecording,
            Recording(url: fileURL, date: generator.date())
        )

        viewModel.toggleRecording()

        let voiceMemo = VoiceMemo(
            url: fileURL,
            date: generator.date(),
            duration: audioRecorder.currentTime
        )

        XCTAssertNil(viewModel.currentRecording)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(audioRecorder.isRecording)
        XCTAssertFalse(audioSession.isActive)
        XCTAssertEqual(viewModel.voiceMemos, [voiceMemo])

        let rowViewModel = context.watch(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemo))

        rowViewModel.togglePaying()

        XCTAssertTrue(rowViewModel.isPlaying)

        viewModel.delete([0])

        XCTAssertFalse(rowViewModel.isPlaying)
        XCTAssertEqual(viewModel.voiceMemos, [])
    }

    func testVoiceMemoRowViewModelAtom() {
        let audioPlayer = MockAudioPlayer()
        let generator = Generator.stub()
        let timer = PassthroughSubject<TimeInterval, Never>()
        let voiceMemo = VoiceMemo(
            url: URL(fileURLWithPath: "/tmp"),
            date: Date(timeIntervalSince1970: 0),
            duration: 0
        )

        let context = AtomTestContext()

        context.override(AudioPlayerAtom.self) { _ in audioPlayer }
        context.override(GeneratorAtom()) { _ in generator }
        context.override(TimerAtom.self) { _ in timer.eraseToAnyPublisher() }

        let viewModel = context.watch(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemo))

        XCTAssertFalse(audioPlayer.isPlaying)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(context.watch(IsPlaybackFailedAtom()))

        viewModel.togglePaying()
        timer.send(10)

        XCTAssertTrue(audioPlayer.isPlaying)
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertEqual(viewModel.elapsedTime, 10)

        viewModel.stopPlaying()

        XCTAssertFalse(audioPlayer.isPlaying)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.elapsedTime, 0)

        audioPlayer.playingError = URLError(.badURL)
        viewModel.togglePaying()

        XCTAssertFalse(audioPlayer.isPlaying)
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertTrue(context.watch(IsPlaybackFailedAtom()))

        viewModel.togglePaying()

        XCTAssertFalse(audioPlayer.isPlaying)
        XCTAssertFalse(viewModel.isPlaying)
    }
}

private extension Generator {
    static func stub() -> Self {
        Generator(
            date: { Date(timeIntervalSince1970: 0) },
            uuid: { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! },
            temporaryDirectory: { "/tmp" }
        )
    }
}
