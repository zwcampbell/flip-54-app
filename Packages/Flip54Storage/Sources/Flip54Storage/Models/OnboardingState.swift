import Foundation
import SwiftData

@Model
public final class OnboardingState {
    public var hasSeenWelcome: Bool
    public var hasSetEquipmentAndDifficulty: Bool
    public var hasCompletedTutorialFlip: Bool

    // First-time tooltip flags
    public var seenAceTooltip: Bool
    public var seenJokerTooltip: Bool
    public var seenFaceCardTooltip: Bool
    public var seenSkipTooltip: Bool
    public var seenSubstitutionTooltip: Bool
    public var seenFirstCompletionTooltip: Bool

    public init(
        hasSeenWelcome: Bool = false,
        hasSetEquipmentAndDifficulty: Bool = false,
        hasCompletedTutorialFlip: Bool = false,
        seenAceTooltip: Bool = false,
        seenJokerTooltip: Bool = false,
        seenFaceCardTooltip: Bool = false,
        seenSkipTooltip: Bool = false,
        seenSubstitutionTooltip: Bool = false,
        seenFirstCompletionTooltip: Bool = false
    ) {
        self.hasSeenWelcome = hasSeenWelcome
        self.hasSetEquipmentAndDifficulty = hasSetEquipmentAndDifficulty
        self.hasCompletedTutorialFlip = hasCompletedTutorialFlip
        self.seenAceTooltip = seenAceTooltip
        self.seenJokerTooltip = seenJokerTooltip
        self.seenFaceCardTooltip = seenFaceCardTooltip
        self.seenSkipTooltip = seenSkipTooltip
        self.seenSubstitutionTooltip = seenSubstitutionTooltip
        self.seenFirstCompletionTooltip = seenFirstCompletionTooltip
    }

    public func resetTooltips() {
        seenAceTooltip = false
        seenJokerTooltip = false
        seenFaceCardTooltip = false
        seenSkipTooltip = false
        seenSubstitutionTooltip = false
        seenFirstCompletionTooltip = false
    }
}
