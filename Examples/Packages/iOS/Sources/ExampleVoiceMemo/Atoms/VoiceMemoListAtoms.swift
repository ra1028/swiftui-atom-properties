import AVFoundation
import Atoms
import Combine
import Foundation

struct VoiceMemo: Equatable {
    var url: URL
    var date: Date
    var duration: TimeInterval
    var title = ""
}

struct Recording: Equatable {
    var url: URL
    var date: Date
}

@MainActor
final class VoiceMemoListViewModel: ObservableObject {
    @Published
    var voiceMemos = [VoiceMemo]()

    @Published
    private(set) var audioRecorderPermission = AVAudioSession.RecordPermission.undetermined

    @Published
    private(set) var elapsedTime: TimeInterval = 0

    @Published
    private(set) var currentRecording: Recording? {
        willSet { stopRecording() }
        didSet { startRecording() }
    }

    private let context: AtomContext
    private let audioSession: AudioSessionProtocol
    private let audioRecorder: AudioRecorderProtocol
    private var timerCancellable: Cancellable?

    init(
        context: AtomContext,
        audioSession: AudioSessionProtocol,
        audioRecorder: AudioRecorderProtocol
    ) {
        self.context = context
        self.audioSession = audioSession
        self.audioRecorder = audioRecorder

        updateAudioRecorderPermission()
    }

    var isRecording: Bool {
        currentRecording != nil
    }

    func cancelRecording() {
        currentRecording = nil
    }

    func toggleRecording() {
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermissionOnMain { [weak self] _ in
                self?.updateAudioRecorderPermission()
            }

        case .denied:
            context[IsRecordingFailedAtom()] = true

        case .granted:
            guard currentRecording == nil else {
                return currentRecording = nil
            }

            let generator = context.read(GeneratorAtom())
            let date = generator.date()
            let url = URL(fileURLWithPath: generator.temporaryDirectory())
                .appendingPathComponent(generator.uuid().uuidString)
                .appendingPathExtension("m4a")

            currentRecording = Recording(url: url, date: date)

        @unknown default:
            return
        }
    }

    func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            let viewModel = context.read(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemos[index]))
            viewModel.stopPlaying()
        }

        voiceMemos.remove(atOffsets: indexSet)
    }

    private func updateAudioRecorderPermission() {
        audioRecorderPermission = audioSession.recordPermission
    }

    private func startRecording() {
        guard let recording = currentRecording else {
            timerCancellable = nil
            return elapsedTime = 0
        }

        let startDate = context.read(GeneratorAtom()).date()
        let timer = context.read(TimerAtom(startDate: startDate, timeInterval: 1))

        timerCancellable = timer.sink { [weak self] elapsedTime in
            self?.elapsedTime = elapsedTime
        }

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: [])
            try audioRecorder.record(url: recording.url)
        }
        catch {
            context[IsRecordingFailedAtom()] = true
        }
    }

    private func stopRecording() {
        guard let recording = currentRecording else {
            return
        }

        let voiceMemo = VoiceMemo(
            url: recording.url,
            date: recording.date,
            duration: audioRecorder.currentTime
        )

        voiceMemos.insert(voiceMemo, at: 0)
        audioRecorder.stop()
        try? audioSession.setActive(false, options: [])
    }
}

struct VoiceMemoListViewModelAtom: ObservableObjectAtom, Hashable {
    func object(context: Context) -> VoiceMemoListViewModel {
        VoiceMemoListViewModel(
            context: context,
            audioSession: context.watch(AudioSessionAtom()),
            audioRecorder: context.watch(AudioRecorderAtom())
        )
    }
}

struct IsPlaybackFailedAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Bool {
        false
    }
}

struct IsRecordingFailedAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Bool {
        false
    }
}

struct AudioRecorderAtom: ValueAtom, Hashable {
    func value(context: Context) -> AudioRecorderProtocol {
        AudioRecorder {
            context[IsRecordingFailedAtom()] = true
            context.read(VoiceMemoListViewModelAtom()).cancelRecording()
        }
    }
}

struct AudioSessionAtom: ValueAtom, Hashable {
    func value(context: Context) -> AudioSessionProtocol {
        AVAudioSession.sharedInstance()
    }
}
