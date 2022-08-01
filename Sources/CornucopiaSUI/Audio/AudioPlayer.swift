//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation
import AVFoundation

public actor AudioPlayer: NSObject {

    public static let `default`: AudioPlayer = .init()
    var players: [URL: AVAudioPlayer] = [:]

    override private init() { }

    public func startPlaying(_ string: String) {

        guard let url = Bundle.main.url(forResource: string, withExtension: nil) else { return }
        self.startPlaying(url)
    }

    public func startPlaying(_ url: URL) {

        guard !self.players.keys.contains(url) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        self.players[url] = player
        player.play()
    }

    func didFinishPlaying(_ url: URL) {
        self.players[url] = nil
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {

    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let url = player.url else { return }
        Task { await self.didFinishPlaying(url) }
    }
}
