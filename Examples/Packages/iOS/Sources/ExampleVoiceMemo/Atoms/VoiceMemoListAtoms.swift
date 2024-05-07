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

struct RecordingData: Equatable {
    var url: URL
    var date: Date
}

@MainActor
struct VoiceMemoActions {
    let context: AtomContext

    func toggleRecording() {
        let isRecording = context.read(IsRecordingAtom())
        let recordPermission = context.read(AudioRecordPermissionAtom())

        guard !isRecording else {
            context[RecordingDataAtom()] = nil
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
            context[RecordingDataAtom()] = RecordingData(url: url, date: date)

        @unknown default:
            break
        }
    }

    func delete(at indexSet: IndexSet) {
        for index in indexSet {
            let voiceMemos = context.read(VoiceMemosAtom())
            context[IsPlayingAtom(voiceMemo: voiceMemos[index])] = false
        }

        context[VoiceMemosAtom()].remove(atOffsets: indexSet)
    }
}

struct VoiceMemoActionsAtom: ValueAtom, Hashable {
    func value(context: Context) -> VoiceMemoActions {
        VoiceMemoActions(context: context)
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
            context[RecordingDataAtom()] = nil
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
        context.watch(RecordingDataAtom()) != nil
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

struct RecordingDataAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> RecordingData? {
        // Add the recorder atom as a depedency.
        context.watch(AudioRecorderAtom())
        return nil
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        RecordingEffect()
    }
}

struct RecordingElapsedTimeAtom: PublisherAtom, Hashable {
    func publisher(context: Context) -> AnyPublisher<TimeInterval, Never> {
        let isRecording = context.watch(IsRecordingAtom().changes)

        guard isRecording else {
            return Just(.zero).eraseToAnyPublisher()
        }

        let startDate = context.watch(ValueGeneratorAtom()).date()
        return context.read(TimerAtom(startDate: startDate, timeInterval: 1))
    }
}
