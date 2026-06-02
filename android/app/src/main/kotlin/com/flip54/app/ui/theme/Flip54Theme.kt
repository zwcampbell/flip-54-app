package com.flip54.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val Flip54ColorScheme = darkColorScheme(
    primary   = DS.Colors.gold,
    background = DS.Colors.bg,
    surface   = DS.Colors.bgRaised,
    onPrimary = DS.Colors.bg,
    onBackground = DS.Colors.textPrimary,
    onSurface = DS.Colors.textPrimary
)

@Composable
fun Flip54Theme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = Flip54ColorScheme,
        content = content
    )
}
