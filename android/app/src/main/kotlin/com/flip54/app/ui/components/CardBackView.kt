package com.flip54.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.theme.DS

@Composable
fun StandardCardBack(
    width: Dp = 140.dp,
    height: Dp = 196.dp,
    modifier: Modifier = Modifier
) {
    val shape = RoundedCornerShape(14.dp)
    Box(
        modifier = modifier
            .size(width, height)
            .clip(shape)
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFF1A1A22), Color(0xFF0E0E16))
                )
            )
            .border(1.5.dp, DS.Colors.border, shape),
        contentAlignment = Alignment.Center
    ) {
        // Inner border
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .border(1.dp, DS.Colors.border.copy(alpha = 0.5f), RoundedCornerShape(10.dp))
        )
        // Gold circle
        Box(
            modifier = Modifier
                .size(56.dp)
                .border(1.5.dp, DS.Colors.gold.copy(alpha = 0.4f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "54",
                style = DS.Type.display(32f),
                color = DS.Colors.gold
            )
        }
        // Corner dots
        CornerDots(width, height)
    }
}

@Composable
fun MidasCardBack(
    width: Dp = 140.dp,
    height: Dp = 196.dp,
    modifier: Modifier = Modifier
) {
    val shape = RoundedCornerShape(14.dp)
    Box(
        modifier = modifier
            .size(width, height)
            .clip(shape)
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFF2A2010), Color(0xFF1A1408), Color(0xFF2C1E08))
                )
            )
            .border(1.5.dp, DS.Colors.gold.copy(alpha = 0.6f), shape),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .border(1.dp, DS.Colors.gold.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
        )
        Box(
            modifier = Modifier
                .size(56.dp)
                .border(1.5.dp, DS.Colors.gold.copy(alpha = 0.7f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "54",
                style = DS.Type.display(32f),
                color = DS.Colors.gold
            )
        }
        CornerDots(width, height, tint = DS.Colors.gold.copy(alpha = 0.6f))
    }
}

@Composable
private fun CornerDots(width: Dp, height: Dp, tint: Color = DS.Colors.gold.copy(alpha = 0.35f)) {
    val dotSize = 4.dp
    val inset = 11.dp
    Box(modifier = Modifier.size(width, height)) {
        Box(
            Modifier.size(dotSize).background(tint, CircleShape)
                .align(Alignment.TopStart).offset(inset, inset)
        )
        Box(
            Modifier.size(dotSize).background(tint, CircleShape)
                .align(Alignment.TopEnd).offset(-inset, inset)
        )
        Box(
            Modifier.size(dotSize).background(tint, CircleShape)
                .align(Alignment.BottomStart).offset(inset, -inset)
        )
        Box(
            Modifier.size(dotSize).background(tint, CircleShape)
                .align(Alignment.BottomEnd).offset(-inset, -inset)
        )
    }
}
