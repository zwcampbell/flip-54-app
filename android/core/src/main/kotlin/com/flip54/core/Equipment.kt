package com.flip54.core

import kotlinx.serialization.Serializable

@Serializable
data class Equipment(
    val hasWeights: Boolean,
    val hasPullUpBar: Boolean,
    val hasYogaMat: Boolean
) {
    companion object {
        val bodyWeightOnly = Equipment(hasWeights = false, hasPullUpBar = false, hasYogaMat = false)
        val fullKit        = Equipment(hasWeights = true,  hasPullUpBar = true,  hasYogaMat = true)
        val barOnly        = Equipment(hasWeights = false, hasPullUpBar = true,  hasYogaMat = false)
        val weightsOnly    = Equipment(hasWeights = true,  hasPullUpBar = false, hasYogaMat = false)
    }
}
