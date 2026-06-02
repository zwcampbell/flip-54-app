package com.flip54.storage.models

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "onboarding_state")
data class OnboardingStateEntity(
    @PrimaryKey val id: Int = 1,
    val hasSeenWelcome: Boolean = false,
    val hasSetEquipmentAndDifficulty: Boolean = false,
    val hasCompletedTutorialFlip: Boolean = false,
    val seenAceTooltip: Boolean = false,
    val seenJokerTooltip: Boolean = false,
    val seenFaceCardTooltip: Boolean = false,
    val seenSkipTooltip: Boolean = false,
    val seenSubstitutionTooltip: Boolean = false,
    val seenFirstCompletionTooltip: Boolean = false
)
