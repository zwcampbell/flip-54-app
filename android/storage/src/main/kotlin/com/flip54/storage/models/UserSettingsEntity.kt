package com.flip54.storage.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.flip54.core.Difficulty
import com.flip54.core.Equipment

@Entity(tableName = "user_settings")
data class UserSettingsEntity(
    @PrimaryKey val id: Int = 1,
    val hasWeights: Boolean = false,
    val hasPullUpBar: Boolean = false,
    val hasYogaMat: Boolean = false,
    val difficultyRaw: String = Difficulty.STANDARD.name,
    val equippedDeckId: String = "standard",
    val useHalfDeck: Boolean = false,
    val soundEnabled: Boolean = true,
    val hapticsEnabled: Boolean = true,
    val reduceMotion: Boolean = false,
    val highContrastCardFaces: Boolean = false
) {
    val equipment: Equipment
        get() = Equipment(hasWeights, hasPullUpBar, hasYogaMat)

    val difficulty: Difficulty
        get() = Difficulty.entries.firstOrNull { it.name == difficultyRaw } ?: Difficulty.STANDARD
}
