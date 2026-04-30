import AVFoundation
import SwiftUI

// MARK: - Sound identifiers

enum SoundEffect: String, CaseIterable {
    case cardFlip    = "card-flip"
    case deckRiffle  = "deck-riffle"
    case cardSkip    = "card-skip"
    case holdStart   = "hold-start"
    case holdTick    = "hold-tick"
    case holdEnd     = "hold-end"
    case completion  = "completion"

    var fileName: String { rawValue }
    var fileExtension: String { "mp3" }
}

// MARK: - Sound player

/// Singleton audio player. Preloads bundled sound assets on first use.
/// Gracefully no-ops when assets are absent — no crash if not yet delivered.
@MainActor
final class SoundPlayer: @unchecked Sendable {
    static let shared = SoundPlayer()
    private init() {}

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var loaded = false

    // MARK: - Playback

    func play(_ sound: SoundEffect, volume: Float = 1.0) {
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.sfxEnabled) else { return }
        if !loaded { preload() }
        guard let player = players[sound] else { return }
        let masterVol = UserDefaults.standard.float(forKey: UserDefaultsKeys.sfxVolume)
        player.volume = volume * max(0, min(1, masterVol > 0 ? masterVol : 1))
        player.currentTime = 0
        player.play()
    }

    // MARK: - Preload

    func preload() {
        guard !loaded else { return }
        loaded = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
        for sound in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) else {
                continue  // asset not yet bundled — skip silently
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[sound] = player
            }
        }
    }
}

// MARK: - UserDefaults keys for sound settings

enum UserDefaultsKeys {
    static let sfxEnabled = "sfxEnabled"
    static let sfxVolume  = "sfxVolume"    // 0.0 – 1.0
    static let hapticsEnabled = "hapticsEnabled"
}

// MARK: - Settings extension for sound toggles

extension UserDefaults {
    var sfxEnabled: Bool {
        get { object(forKey: UserDefaultsKeys.sfxEnabled) as? Bool ?? true }
        set { set(newValue, forKey: UserDefaultsKeys.sfxEnabled) }
    }
    var sfxVolume: Float {
        get { object(forKey: UserDefaultsKeys.sfxVolume) as? Float ?? 1.0 }
        set { set(newValue, forKey: UserDefaultsKeys.sfxVolume) }
    }
    var hapticsEnabled: Bool {
        get { object(forKey: UserDefaultsKeys.hapticsEnabled) as? Bool ?? true }
        set { set(newValue, forKey: UserDefaultsKeys.hapticsEnabled) }
    }
}
