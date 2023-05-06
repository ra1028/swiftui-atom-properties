import AVFoundation
import Atoms
import Combine
import Foundation
import SwiftUI

@MainActor
final class VoiceMemoRowViewModel: ObservableObject {
    @Published
    private(set) var isPlaying = false {
        didSet { togglePlayback() }
    }

    @Published
    private(set) var elapsedTime: TimeInterval = 0

    private let context: AtomContext
    private let audioPlayer: AudioPlayerProtocol
    private let voiceMemo: VoiceMemo
    private var timerCancellable: Cancellable?

    init(
        context: AtomContext,
        audioPlayer: AudioPlayerProtocol,
        voiceMemo: VoiceMemo
    ) {
        self.context = context
        self.audioPlayer = audioPlayer
        self.voiceMemo = voiceMemo
    }

    func stopPlaying() {
        isPlaying = false
    }

    func togglePaying() {
        isPlaying.toggle()
    }

    private func togglePlayback() {
        guard isPlaying else {
            timerCancellable = nil
            elapsedTime = 0
            return audioPlayer.stop()
        }

        let startDate = context.read(ValueGeneratorAtom()).date()
        let timer = context.read(TimerAtom(startDate: startDate, timeInterval: 0.5))

        timerCancellable = timer.sink { [weak self] elapsedTime in
            self?.elapsedTime = elapsedTime
        }

        do {
            try audioPlayer.play(url: voiceMemo.url)
        }
        catch {
            context[IsPlaybackFailedAtom()] = true
        }
    }
}

struct VoiceMemoRowViewModelAtom: ObservableObjectAtom {
    let voiceMemo: VoiceMemo

    var key: URL {
        voiceMemo.url
    }

    func object(context: Context) -> VoiceMemoRowViewModel {
        VoiceMemoRowViewModel(
            context: context,
            audioPlayer: context.watch(AudioPlayerAtom(voiceMemo: voiceMemo)),
            voiceMemo: voiceMemo
        )
    }
}

struct AudioPlayerAtom: ValueAtom {
    let voiceMemo: VoiceMemo

    var key: URL {
        voiceMemo.url
    }

    func value(context: Context) -> AudioPlayerProtocol {
        AudioPlayer(
            onFinish: {
                context.read(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemo)).stopPlaying()
            },
            onFail: {
                context[IsPlaybackFailedAtom()] = false
                context.read(VoiceMemoRowViewModelAtom(voiceMemo: voiceMemo)).stopPlaying()
            }
        )
    }
}
