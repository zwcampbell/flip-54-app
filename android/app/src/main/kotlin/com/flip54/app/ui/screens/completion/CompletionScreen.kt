package com.flip54.app.ui.screens.completion

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.formatDuration
import com.flip54.app.ui.theme.DS
import com.flip54.core.Suit
import com.flip54.storage.ActiveSession

data class CompletedWorkoutData(
    val durationMs: Long,
    val deckId: String,
    val difficultyName: String,
    val totalReps: Int,
    val holdSecondsCompleted: Int,
    val cardCount: Int,
    val skipCount: Int,
    val repsBySuit: Map<Suit, Int>,
    val jumpingJacks: Int
) {
    companion object {
        fun from(session: ActiveSession, completedAtMs: Long): CompletedWorkoutData {
            val elapsed = completedAtMs - session.startedAtMs - session.totalPausedDurationMs
            val suitReps = session.repsBySuit.values.sum()
            return CompletedWorkoutData(
                durationMs = maxOf(0, elapsed),
                deckId = session.deckId,
                difficultyName = session.difficulty.displayName,
                totalReps = session.totalRepsCompleted,
                holdSecondsCompleted = session.holdSecondsCompleted,
                cardCount = session.cardsCompleted,
                skipCount = session.skipCount,
                repsBySuit = session.repsBySuit,
                jumpingJacks = session.totalRepsCompleted - suitReps
            )
        }
    }
}

@Composable
fun CompletionScreen(data: CompletedWorkoutData, onDone: () -> Unit) {
    var show by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        HapticHelper.completion()
        show = true
    }

    Box(modifier = Modifier.fillMaxSize().background(DS.Colors.bg)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(60.dp))

            // Header
            Text("WORKOUT", style = DS.Type.sub(13f), color = DS.Colors.textTertiary)
            Text("COMPLETE", style = DS.Type.display(64f), color = DS.Colors.gold)
            Spacer(Modifier.height(8.dp))
            Text(
                "${data.difficultyName} · ${data.deckId.replaceFirstChar { it.uppercase() }} Deck",
                fontSize = 13.sp, color = DS.Colors.textTertiary
            )

            Spacer(Modifier.height(32.dp))

            // Stats card
            AnimatedVisibility(
                visible = show,
                enter = fadeIn() + slideInVertically(initialOffsetY = { it / 3 })
            ) {
                StatsCard(data)
            }

            Spacer(Modifier.height(32.dp))

            // Done button
            Button(
                onClick = { HapticHelper.primary(); onDone() },
                modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                shape = RoundedCornerShape(50)
            ) {
                Text("DONE", style = DS.Type.display(24f), color = DS.Colors.bg)
            }

            Spacer(Modifier.height(52.dp))
        }
    }
}

@Composable
private fun StatsCard(data: CompletedWorkoutData) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.border, RoundedCornerShape(20.dp))
    ) {
        // Top summary row
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            StatCell("${data.totalReps}", "TOTAL REPS")
            VerticalDivider(modifier = Modifier.height(44.dp), color = DS.Colors.border)
            StatCell("${data.cardCount}", "CARDS")
            VerticalDivider(modifier = Modifier.height(44.dp), color = DS.Colors.border)
            StatCell(formatDuration(data.durationMs), "TIME")
        }

        HorizontalDivider(color = DS.Colors.border)

        // By-suit breakdown
        SuitRow("♥", "Lower Body", data.repsBySuit[Suit.HEARTS] ?: 0, isRed = true)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitRow("♠", "Upper Body", data.repsBySuit[Suit.SPADES] ?: 0, isRed = false)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitRow("♣", "Total Body", data.repsBySuit[Suit.CLUBS] ?: 0, isRed = false)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitRow("♦", "Core", data.repsBySuit[Suit.DIAMONDS] ?: 0, isRed = true)

        if (data.jumpingJacks > 0) {
            HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
            SuitRow("★", "Jumping Jacks", data.jumpingJacks, isRed = false, glyphColor = DS.Colors.gold)
        }

        if (data.holdSecondsCompleted > 0) {
            HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 13.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Hold Time", fontSize = 13.sp, color = DS.Colors.textSecondary)
                Text("${data.holdSecondsCompleted}s", style = DS.Type.mono(14f), color = DS.Colors.textPrimary)
            }
        }

        if (data.skipCount > 0) {
            HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 13.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Skipped", fontSize = 13.sp, color = DS.Colors.textTertiary)
                Text("${data.skipCount}", style = DS.Type.mono(14f), color = DS.Colors.textTertiary)
            }
        }
    }
}

@Composable
private fun StatCell(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(value, style = DS.Type.display(32f), color = DS.Colors.textPrimary)
        Text(label, style = DS.Type.sub(10f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun SuitRow(glyph: String, label: String, reps: Int, isRed: Boolean, glyphColor: Color? = null) {
    val color = glyphColor ?: (if (isRed) DS.Colors.red else DS.Colors.textPrimary)
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 13.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(glyph, fontSize = 16.sp, color = color, modifier = Modifier.width(20.dp))
        Text(label, fontSize = 13.sp, color = DS.Colors.textSecondary, modifier = Modifier.weight(1f))
        Text("$reps", style = DS.Type.mono(14f), color = DS.Colors.textPrimary)
    }
}
