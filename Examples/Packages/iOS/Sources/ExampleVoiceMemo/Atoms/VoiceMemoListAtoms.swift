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

struct Record: Equatable {
    var url: URL
    var date: Date
}

@MainActor
struct VoiceMemoAction {
    let context: AtomContext

    func toggleRecording() {
        let isRecording = context.read(IsRecordingAtom())
        let recordPermission = context.read(AudioRecordPermissionAtom())

        guard !isRecording else {
            context[RecordAtom()] = nil
            return
        }

        switch recordPermission {
        case .undetermined:
            let audioSession = context.read(AudioSessionAtom())
            audioSession.requestRecordPermissionOnMain { _ in
                context.reset(AudioRecordPermissionAtom())
            }

        case .denied:
            context[IsRecordingFailedAtom()] = true

        case .granted:
            let generator = context.read(ValueGeneratorAtom())
            let date = generator.date()
            let url = URL(fileURLWithPath: generator.temporaryDirectory())
                .appendingPathComponent(generator.uuid().uuidString)
                .appendingPathExtension("m4a")
            context[RecordAtom()] = Record(url: url, date: date)

        @unknown default:
            break
        }
    }

    func delete(at indexSet: IndexSet) {
        for index in indexSet {
            let voiceMemos = context.read(VoiceMemosAtom())
            let viewModel = context.read(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemos[index]))
            viewModel.stopPlaying()
        }

        context[VoiceMemosAtom()].remove(atOffsets: indexSet)
    }
}

struct VoiceMemoActionsAtom: ValueAtom, Hashable {
    func value(context: Context) -> VoiceMemoAction {
        VoiceMemoAction(context: context)
    }
}

struct AudioSessionAtom: ValueAtom, Hashable {
    func value(context: Context) -> AudioSessionProtocol {
        AVAudioSession.sharedInstance()
    }
}

struct AudioRecorderAtom: ValueAtom, Hashable {
    func value(context: Context) -> AudioRecorderProtocol {
        AudioRecorder {
            context[IsRecordingFailedAtom()] = true
            context[RecordAtom()] = nil
        }
    }
}

struct VoiceMemosAtom: StateAtom, KeepAlive, Hashable {
    func defaultValue(context: Context) -> [VoiceMemo] {
        []
    }
}

struct IsRecordingAtom: ValueAtom, Hashable {
    func value(context: Context) -> Bool {
        context.watch(RecordAtom()) != nil
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

struct AudioRecordPermissionAtom: ValueAtom, Hashable {
    func value(context: Context) -> AVAudioSession.RecordPermission {
        let audioSession = context.watch(AudioSessionAtom())
        return audioSession.recordPermission
    }
}

struct RecordAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Record? {
        // Add recorder instance as a depedency.
        context.watch(AudioRecorderAtom())
        return nil
    }

    func updated(newValue: Record?, oldValue: Record?, context: UpdatedContext) {
        let audioRecorder = context.read(AudioRecorderAtom())
        let audioSession = context.read(AudioSessionAtom())

        if let recording = oldValue {
            let voiceMemo = VoiceMemo(
                url: recording.url,
                date: recording.date,
                duration: audioRecorder.currentTime
            )

            context[VoiceMemosAtom()].insert(voiceMemo, at: 0)
            audioRecorder.stop()
            try? audioSession.setActive(false, options: [])
        }

        if let recording = newValue {
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                try audioSession.setActive(true, options: [])
                try audioRecorder.record(url: recording.url)
            }
            catch {
                context[IsRecordingFailedAtom()] = true
            }
        }
    }
}

struct RecordingElapsedTimeAtom: PublisherAtom, Hashable {
    func publisher(context: Context) -> AnyPublisher<TimeInterval, Never> {
        let isRecording = context.watch(IsRecordingAtom())
        let startDate = context.watch(ValueGeneratorAtom()).date()

        guard isRecording else {
            return Just(.zero).eraseToAnyPublisher()
        }

        return Timer.publish(
            every: 1,
            tolerance: 0,
            on: .main,
            in: .common
        )
        .autoconnect()
        .map { $0.timeIntervalSince(startDate) }
        .prepend(.zero)
        .eraseToAnyPublisher()
    }
}
