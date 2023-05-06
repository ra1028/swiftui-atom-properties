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
        // Add recorder instance as a depedency.
        context.watch(AudioPlayerAtom(voiceMemo: voiceMemo))
        return false
    }

    func updated(newValue: Bool, oldValue: Bool, context: UpdatedContext) {
        let audioPlayer = context.read(AudioPlayerAtom(voiceMemo: voiceMemo))

        guard newValue else {
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

struct PlayingElapsedTimeAtom: PublisherAtom {
    let voiceMemo: VoiceMemo

    var key: some Hashable {
        voiceMemo.url
    }

    func publisher(context: Context) -> AnyPublisher<TimeInterval, Never> {
        let isPlaying = context.watch(IsPlayingAtom(voiceMemo: voiceMemo))
        let startDate = context.watch(ValueGeneratorAtom()).date()

        guard isPlaying else {
            return Just(.zero).eraseToAnyPublisher()
        }

        return Timer.publish(
            every: 0.5,
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
