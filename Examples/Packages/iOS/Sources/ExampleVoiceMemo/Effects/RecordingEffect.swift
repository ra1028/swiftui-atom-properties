import AVFoundation
import Atoms

final class RecordingEffect: AtomEffect {
    private var currentData: RecordingData?

    func updated(context: Context) {
        let audioSession = context.read(AudioSessionAtom())
        let audioRecorder = context.read(AudioRecorderAtom())
        let data = context.read(RecordingDataAtom())

        if let currentData {
            let voiceMemo = VoiceMemo(
                url: currentData.url,
                date: currentData.date,
                duration: audioRecorder.currentTime
            )

            context[VoiceMemosAtom()].insert(voiceMemo, at: 0)
            audioRecorder.stop()
            try? audioSession.setActive(false, options: [])
        }

        currentData = data

        if let data {
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                try audioSession.setActive(true, options: [])
                try audioRecorder.record(url: data.url)
            }
            catch {
                context[IsRecordingFailedAtom()] = true
            }
        }
    }
}
