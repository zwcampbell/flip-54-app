package com.flip54.app.ui.screens.preworkout

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.components.MidasCardBack
import com.flip54.app.ui.components.StandardCardBack
import com.flip54.app.ui.theme.DS
import com.flip54.engine.WorkoutCoordinator
import com.flip54.engine.WorkoutEvent
import com.flip54.engine.WorkoutState
import com.flip54.storage.models.OnboardingStateEntity
import com.flip54.storage.models.UserSettingsEntity
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val FAN_OFFSETS = listOf(
    Triple(-32f, -8f, -14f),
    Triple(-22f, -5f, -10f),
    Triple(-12f, -2f, -6f),
    Triple(-4f,  0f,  -2f),
    Triple(0f,   0f,   0f),
    Triple(4f,   0f,   2f),
    Triple(12f, -2f,   6f),
    Triple(22f, -5f,  10f),
    Triple(32f, -8f,  14f)
)

@Composable
fun PreWorkoutScreen(
    coordinator: WorkoutCoordinator,
    settings: UserSettingsEntity,
    onboardingState: OnboardingStateEntity,
    showResumeBanner: Boolean,
    onResume: () -> Unit,
    onDismissResume: () -> Unit,
    onUpdateSettings: (UserSettingsEntity.() -> UserSettingsEntity) -> Unit,
    onStartTutorial: () -> Unit
) {
    val workoutState by coordinator.state.collectAsState()
    val scope = rememberCoroutineScope()
    var shufflePhase by remember { mutableStateOf(0) } // 0=idle 1=spread 2=scatter 3=collapse
    var scatterOffsets by remember { mutableStateOf(FAN_OFFSETS.map { Triple(it.first, it.second, it.third) }) }
    var tutorialDismissed by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }

    val isShuffling = workoutState is WorkoutState.Shuffling

    LaunchedEffect(workoutState) {
        if (workoutState is WorkoutState.Shuffling) {
            shufflePhase = 1
            delay(150)
            scatterOffsets = makeScatterOffsets()
            shufflePhase = 2
            HapticHelper.shuffle()
            delay(280)
            scatterOffsets = makeScatterOffsets()
            shufflePhase = 1
            delay(80)
            shufflePhase = 2
            delay(220)
            shufflePhase = 3
            delay(220)
            coordinator.send(WorkoutEvent.ShuffleComplete)
            delay(400)
            shufflePhase = 0
        }
    }

    Column(
        modifier = Modifier.fillMaxSize().background(DS.Colors.bg)
    ) {
        // Top bar
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            DeckChip(settings.equippedDeckId)
            IconButton(
                onClick = { HapticHelper.tap(); showSettings = true },
                modifier = Modifier.size(36.dp)
                    .background(DS.Colors.bgCard, CircleShape)
                    .border(1.dp, DS.Colors.border, CircleShape)
            ) {
                Text("?", color = DS.Colors.textSecondary, fontSize = 16.sp)
            }
        }

        // Banners
        if (showResumeBanner) {
            ResumeBanner(onResume = onResume, onDismiss = onDismissResume)
        }
        val showTutorialBanner = !onboardingState.hasCompletedTutorialFlip && !tutorialDismissed
        if (showTutorialBanner) {
            TutorialBanner(
                onStart = { tutorialDismissed = true; onStartTutorial() },
                onDismiss = { tutorialDismissed = true }
            )
        }

        Spacer(Modifier.weight(1f))

        // Deck fan
        DeckFan(
            deckId = settings.equippedDeckId,
            shufflePhase = shufflePhase,
            scatterOffsets = scatterOffsets
        )

        Spacer(Modifier.weight(1f))

        // Difficulty / equipment badge
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            val diffLabel = "${settings.difficulty.displayName.uppercase()} + " +
                    if (settings.useHalfDeck) "HALF DECK" else "FULL DECK"
            val eqParts = buildList {
                if (settings.hasWeights) add("Weights")
                if (settings.hasPullUpBar) add("Pull-up bar")
                if (isEmpty()) add("Bodyweight")
            }.joinToString(" + ").uppercase()

            SettingColumn("DIFFICULTY", diffLabel, onClick = { showSettings = true }, Modifier.weight(1f))
            SettingColumn("EQUIPMENT", eqParts, onClick = { showSettings = true }, Modifier.weight(1f))
        }

        // Start button
        Column(
            modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 52.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = {
                    if (!isShuffling) {
                        HapticHelper.primary()
                        coordinator.configure(
                            equipment = settings.equipment,
                            difficulty = settings.difficulty,
                            deckId = settings.equippedDeckId,
                            useHalfDeck = settings.useHalfDeck
                        )
                        coordinator.send(WorkoutEvent.Shuffle)
                    }
                },
                enabled = !isShuffling,
                modifier = Modifier.fillMaxWidth().height(58.dp),
                colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                shape = RoundedCornerShape(50)
            ) {
                Text(
                    if (isShuffling) "SHUFFLING…" else "START",
                    style = DS.Type.display(26f),
                    color = DS.Colors.bg
                )
            }
        }
    }

    if (showSettings) {
        SettingsSheet(settings, onUpdateSettings) { showSettings = false }
    }
}

@Composable
private fun DeckFan(deckId: String, shufflePhase: Int, scatterOffsets: List<Triple<Float, Float, Float>>) {
    Box(modifier = Modifier.fillMaxWidth().height(260.dp), contentAlignment = Alignment.Center) {
        FAN_OFFSETS.indices.forEach { i ->
            val (dx, dy, rot) = when (shufflePhase) {
                0 -> FAN_OFFSETS[i]
                1 -> Triple(FAN_OFFSETS[i].first * 2.4f, FAN_OFFSETS[i].second * 2f, FAN_OFFSETS[i].third * 1.8f)
                2 -> if (i < scatterOffsets.size) scatterOffsets[i] else FAN_OFFSETS[i]
                3 -> Triple(0f, 0f, 0f)
                else -> FAN_OFFSETS[i]
            }
            Box(
                modifier = Modifier
                    .graphicsLayer {
                        translationX = dx.dp.toPx()
                        translationY = dy.dp.toPx()
                        rotationZ = rot
                    }
            ) {
                if (deckId == "midas") MidasCardBack(140.dp, 196.dp)
                else StandardCardBack(140.dp, 196.dp)
            }
        }
    }
}

@Composable
private fun SettingColumn(label: String, value: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label, style = DS.Type.sub(10f), color = DS.Colors.textTertiary)
        Button(
            onClick = { HapticHelper.tap(); onClick() },
            modifier = Modifier.fillMaxWidth().height(48.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.bgCard),
            shape = RoundedCornerShape(50),
            border = BorderStroke(1.dp, DS.Colors.border)
        ) {
            Text(value, style = DS.Type.display(18f), color = DS.Colors.textPrimary, maxLines = 1)
        }
    }
}

@Composable
private fun DeckChip(deckId: String) {
    val name = when (deckId) { "midas" -> "Midas" else -> "Standard" }
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.border, RoundedCornerShape(50))
            .padding(horizontal = 12.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(name, fontSize = 12.sp, color = DS.Colors.textSecondary)
        Text("▾", fontSize = 9.sp, color = DS.Colors.textTertiary)
    }
}

@Composable
private fun ResumeBanner(onResume: () -> Unit, onDismiss: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.gold.copy(alpha = 0.4f), RoundedCornerShape(10.dp))
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("↻", color = DS.Colors.gold, fontSize = 16.sp)
        Text("Resume your unfinished workout?", fontSize = 13.sp, color = DS.Colors.textSecondary, modifier = Modifier.weight(1f))
        TextButton(onClick = { HapticHelper.tap(); onResume() }, contentPadding = PaddingValues(horizontal = 8.dp)) {
            Text("Resume", color = DS.Colors.gold, fontSize = 13.sp)
        }
        IconButton(onClick = { HapticHelper.tap(); onDismiss() }, modifier = Modifier.size(24.dp)) {
            Text("✕", color = DS.Colors.textTertiary, fontSize = 12.sp)
        }
    }
}

@Composable
private fun TutorialBanner(onStart: () -> Unit, onDismiss: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.gold.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("🎓", fontSize = 16.sp)
        Text("New? Try a tutorial flip first.", fontSize = 13.sp, color = DS.Colors.textSecondary, modifier = Modifier.weight(1f))
        TextButton(onClick = { HapticHelper.primary(); onStart() }, contentPadding = PaddingValues(horizontal = 8.dp)) {
            Text("Start", color = DS.Colors.gold, fontSize = 13.sp)
        }
        IconButton(onClick = { HapticHelper.tap(); onDismiss() }, modifier = Modifier.size(24.dp)) {
            Text("✕", color = DS.Colors.textTertiary, fontSize = 12.sp)
        }
    }
}

@Composable
private fun SettingsSheet(
    settings: UserSettingsEntity,
    onUpdate: (UserSettingsEntity.() -> UserSettingsEntity) -> Unit,
    onDismiss: () -> Unit
) {
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DS.Colors.bgRaised,
        title = { Text("Settings", style = DS.Type.display(24f)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("EQUIPMENT", style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
                SettingsToggle("Weights / Dumbbells", settings.hasWeights) { onUpdate { copy(hasWeights = !hasWeights) } }
                SettingsToggle("Pull-up Bar", settings.hasPullUpBar) { onUpdate { copy(hasPullUpBar = !hasPullUpBar) } }
                SettingsToggle("Yoga Mat", settings.hasYogaMat) { onUpdate { copy(hasYogaMat = !hasYogaMat) } }
                HorizontalDivider(color = DS.Colors.border)
                Text("OPTIONS", style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
                SettingsToggle("Use Half Deck (27 cards)", settings.useHalfDeck) { onUpdate { copy(useHalfDeck = !useHalfDeck) } }
                SettingsToggle("Sound Effects", settings.soundEnabled) { onUpdate { copy(soundEnabled = !soundEnabled) } }
                SettingsToggle("Haptic Feedback", settings.hapticsEnabled) { onUpdate { copy(hapticsEnabled = !hapticsEnabled) } }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Done", color = DS.Colors.gold) }
        }
    )
}

@Composable
private fun SettingsToggle(label: String, checked: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 14.sp, color = DS.Colors.textPrimary)
        Switch(
            checked = checked,
            onCheckedChange = { HapticHelper.selection(); onToggle() },
            colors = SwitchDefaults.colors(checkedThumbColor = DS.Colors.bg, checkedTrackColor = DS.Colors.gold)
        )
    }
}

private fun makeScatterOffsets(): List<Triple<Float, Float, Float>> =
    (0 until FAN_OFFSETS.size).map {
        Triple(
            (-200..200).random().toFloat(),
            (-180..180).random().toFloat(),
            (-540..540).random().toFloat()
        )
    }
