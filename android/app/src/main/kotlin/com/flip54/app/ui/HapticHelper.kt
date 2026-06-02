package com.flip54.app.ui

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.content.getSystemService

object HapticHelper {
    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService<VibratorManager>()?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService<Vibrator>()
        }
    }

    fun tap()       = vibrate(VibrationEffect.EFFECT_CLICK)
    fun primary()   = vibrate(VibrationEffect.EFFECT_HEAVY_CLICK)
    fun cardFlip()  = vibrate(VibrationEffect.EFFECT_CLICK)
    fun done()      = vibrate(VibrationEffect.EFFECT_DOUBLE_CLICK)
    fun skip()      = vibrate(VibrationEffect.EFFECT_TICK)
    fun shuffle()   = vibrate(50L)
    fun holdStart() = vibrate(VibrationEffect.EFFECT_HEAVY_CLICK)
    fun holdTick()  = vibrate(VibrationEffect.EFFECT_TICK)
    fun completion() = vibrate(100L)
    fun warning()   = vibrate(VibrationEffect.EFFECT_HEAVY_CLICK)
    fun selection() = vibrate(VibrationEffect.EFFECT_TICK)

    private fun vibrate(effectId: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator?.vibrate(VibrationEffect.createPredefined(effectId))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(30L)
        }
    }

    private fun vibrate(ms: Long) {
        vibrator?.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
    }
}
