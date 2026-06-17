//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation
import AVFoundation

public actor AudioPlayer: NSObject {

    public static let `default`: AudioPlayer = .init()
    var players: [URL: AVAudioPlayer] = [:]
    private var delegates: [URL: AudioPlayerDelegate] = [:]

    override private init() { }

    public func startPlaying(_ string: String) {

        guard let url = Bundle.main.url(forResource: string, withExtension: nil) else { return }
        self.startPlaying(url)
    }

    public func startPlaying(_ url: URL) {

        guard !self.players.keys.contains(url) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        let delegate = AudioPlayerDelegate { [weak self] url in
            Task { await self?.didFinishPlaying(url) }
        }
        player.delegate = delegate
        self.delegates[url] = delegate
        self.players[url] = player
        player.play()
    }

    func didFinishPlaying(_ url: URL) {
        self.players[url] = nil
        self.delegates[url] = nil
    }
}

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    private let didFinishPlaying: @Sendable (URL) -> Void

    nonisolated init(didFinishPlaying: @escaping @Sendable (URL) -> Void) {
        self.didFinishPlaying = didFinishPlaying
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let url = player.url else { return }
        self.didFinishPlaying(url)
    }
}
