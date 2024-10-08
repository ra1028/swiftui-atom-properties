import AVFoundation

protocol AudioPlayerProtocol {
    func play(url: URL) throws
    func stop()
}

final class AudioPlayer: NSObject, AVAudioPlayerDelegate, AudioPlayerProtocol {
    private let onFinish: () -> Void
    private let onFail: () -> Void
    private var player: AVAudioPlayer?

    init(onFinish: @escaping () -> Void, onFail: @escaping () -> Void) {
        self.onFinish = onFinish
        self.onFail = onFail
        super.init()
    }

    func play(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            onFinish()
        }
        else {
            onFail()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        onFail()
    }
}

final class MockAudioPlayer: AudioPlayerProtocol, @unchecked Sendable {
    private(set) var isPlaying = false
    var playingError: (any Error)?

    func play(url: URL) throws {
        if let playingError = playingError {
            throw playingError
        }

        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }
}
