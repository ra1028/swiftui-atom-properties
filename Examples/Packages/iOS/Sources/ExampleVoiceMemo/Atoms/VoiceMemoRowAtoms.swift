import AVFoundation
import Atoms
import Combine
import Foundation
import SwiftUI

struct IsPlayingAtom: StateAtom {
    let voiceMemo: VoiceMemo

    var key: some Hashable {
        voiceMemo.url
    }

    func defaultValue(context: Context) -> Bool {
        // Add the player atom as a depedency.
        context.watch(AudioPlayerAtom(voiceMemo: voiceMemo))
        return false
    }

    func effect(context: CurrentContext) -> some AtomEffect {
        UpdateEffect {
            let audioPlayer = context.read(AudioPlayerAtom(voiceMemo: voiceMemo))
            let isPlaying = context.read(self)

            guard isPlaying else {
                return audioPlayer.stop()
            }

            do {
                try audioPlayer.play(url: voiceMemo.url)
            }
            catch {
                context[IsPlaybackFailedAtom()] = true
            }
        }
    }
}

struct PlayingElapsedTimeAtom: PublisherAtom {
    let voiceMemo: VoiceMemo

    var key: some Hashable {
        voiceMemo.url
    }

    func publisher(context: Context) -> AnyPublisher<TimeInterval, Never> {
        let isPlaying = context.watch(IsPlayingAtom(voiceMemo: voiceMemo).changes)

        guard isPlaying else {
            return Just(.zero).eraseToAnyPublisher()
        }

        let startDate = context.watch(ValueGeneratorAtom()).date()
        return context.read(TimerAtom(startDate: startDate, timeInterval: 0.5))
    }
}

struct AudioPlayerAtom: ValueAtom {
    let voiceMemo: VoiceMemo

    var key: some Hashable {
        voiceMemo.url
    }

    func value(context: Context) -> AudioPlayerProtocol {
        AudioPlayer(
            onFinish: {
                context[IsPlayingAtom(voiceMemo: voiceMemo)] = false
            },
            onFail: {
                context[IsPlaybackFailedAtom()] = false
                context[IsPlayingAtom(voiceMemo: voiceMemo)] = false
            }
        )
    }
}
