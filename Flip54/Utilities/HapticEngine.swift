import CoreHaptics
import UIKit

// MARK: - Haptic events

enum HapticEvent {
    // Gameplay-specific patterns (custom Core Haptics)
    case cardFlip    // sharp click at mid-flip
    case holdStart   // low rumble building to heavy
    case holdTick    // gentle tap each countdown second
    case skip        // double-tap (two transients 100ms apart)
    case done        // medium thud on card complete
    case shuffle     // notification-style success pulse
    case completion  // crescendo burst at workout end

    // UI-chrome events — standard system feedback per Apple HIG.
    case tap         // light impact: secondary buttons, banner CTAs, dismiss
    case primary     // medium impact: primary CTAs (START, FLIP CARD)
    case selection   // selection feedback: picker rows, choice list toggles
    case warning     // warning notification: potentially destructive (End Early)
}

// MARK: - Haptic engine

/// Core Haptics wrapper with UIKit fallback for devices that don't support CHHapticEngine.
/// All play() calls are no-ops when hapticsEnabled is false.
@MainActor
final class HapticEngine: @unchecked Sendable {
    static let shared = HapticEngine()
    private init() { startEngine() }

    private var engine: CHHapticEngine?
    private var engineReady = false

    private static let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    // UIKit fallbacks (also used directly for chrome events)
    private let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact  = UIImpactFeedbackGenerator(style: .heavy)
    private let notifyGen    = UINotificationFeedbackGenerator()
    private let selectionGen = UISelectionFeedbackGenerator()

    // MARK: - Public

    func play(_ event: HapticEvent) {
        guard UserDefaults.standard.hapticsEnabled else { return }
        // Chrome events always use UIKit generators — no custom pattern needed
        // and they auto-respect Reduce Motion / system haptics settings.
        switch event {
        case .tap, .primary, .selection, .warning:
            playFallback(for: event)
            return
        default:
            break
        }
        if Self.supported, engineReady {
            playPattern(for: event)
        } else {
            playFallback(for: event)
        }
    }

    // MARK: - Engine lifecycle

    private func startEngine() {
        guard Self.supported else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.stoppedHandler = { [weak self] _ in Task { @MainActor in self?.engineReady = false } }
            e.resetHandler  = { [weak self] in Task { @MainActor in self?.restartEngine() } }
            try e.start()
            engine = e
            engineReady = true
        } catch { }
    }

    private func restartEngine() {
        guard let e = engine else { return }
        do { try e.start(); engineReady = true } catch { engineReady = false }
    }

    // MARK: - Core Haptics playback

    private func playPattern(for event: HapticEvent) {
        guard let engine, engineReady else { playFallback(for: event); return }
        do {
            let pattern = try makePattern(for: event)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }

    private func makePattern(for event: HapticEvent) throws -> CHHapticPattern {
        switch event {

        case .cardFlip:
            // Sharp transient — feels like a physical card snap
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: 0)
            ], parameters: [])

        case .holdStart:
            // Continuous rumble with intensity rising over 0.55s
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ],
                    relativeTime: 0, duration: 0.55)
            ], parameterCurves: [
                CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [
                        .init(relativeTime: 0.00, value: 0.35),
                        .init(relativeTime: 0.45, value: 1.00)
                    ],
                    relativeTime: 0)
            ])

        case .holdTick:
            // Light transient — gentle clock tick during final countdown
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.30),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.50)
                    ],
                    relativeTime: 0)
            ], parameters: [])

        case .skip:
            // Double transient 100ms apart — feels like "skip past"
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                    ],
                    relativeTime: 0.00),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.50),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                    ],
                    relativeTime: 0.10)
            ], parameters: [])

        case .done:
            // Medium thud — satisfying "card completed" confirmation
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.80),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                    ],
                    relativeTime: 0)
            ], parameters: [])

        case .shuffle:
            // Two-pulse success beat — riffle animation feedback
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.70),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.60)
                    ],
                    relativeTime: 0.00),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.90),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.60)
                    ],
                    relativeTime: 0.08)
            ], parameters: [])

        case .completion:
            // Crescendo: continuous body that ramps to full intensity, capped by a final sharp burst
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.00),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.50)
                    ],
                    relativeTime: 0.00, duration: 0.90),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.00),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.90)
                    ],
                    relativeTime: 0.85)
            ], parameterCurves: [
                CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [
                        .init(relativeTime: 0.00, value: 0.20),
                        .init(relativeTime: 0.50, value: 0.70),
                        .init(relativeTime: 0.80, value: 1.00)
                    ],
                    relativeTime: 0)
            ])

        case .tap, .primary, .selection, .warning:
            // Chrome events are routed to UIKit generators upstream and
            // never reach makePattern. This branch keeps the switch
            // exhaustive.
            return try CHHapticPattern(events: [], parameters: [])
        }
    }

    // MARK: - UIKit fallback

    private func playFallback(for event: HapticEvent) {
        switch event {
        case .cardFlip:   mediumImpact.impactOccurred(intensity: 0.85)
        case .holdStart:  heavyImpact.impactOccurred()
        case .holdTick:   lightImpact.impactOccurred(intensity: 0.35)
        case .skip:       notifyGen.notificationOccurred(.warning)
        case .done:       mediumImpact.impactOccurred()
        case .shuffle:    notifyGen.notificationOccurred(.success)
        case .completion: notifyGen.notificationOccurred(.success)
        // Chrome events
        case .tap:        lightImpact.impactOccurred()
        case .primary:    mediumImpact.impactOccurred()
        case .selection:  selectionGen.selectionChanged()
        case .warning:    notifyGen.notificationOccurred(.warning)
        }
    }
}
