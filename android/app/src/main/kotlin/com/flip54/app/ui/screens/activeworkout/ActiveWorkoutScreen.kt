package com.flip54.app.ui.screens.activeworkout

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.components.CardBackView
import com.flip54.app.ui.components.CardFaceView
import com.flip54.app.ui.components.MidasCardBack
import com.flip54.app.ui.components.StandardCardBack
import com.flip54.app.ui.theme.DS
import com.flip54.engine.WorkoutCoordinator
import com.flip54.engine.WorkoutEvent
import com.flip54.engine.WorkoutState
import com.flip54.core.Card
import com.flip54.core.Prescription
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun ActiveWorkoutScreen(
    coordinator: WorkoutCoordinator,
    deckId: String,
    onWorkoutComplete: () -> Unit,
    onEndEarly: () -> Unit
) {
    val workoutState by coordinator.state.collectAsState()
    val session by coordinator.session.collectAsState()
    val holdSeconds by coordinator.holdTimerSeconds.collectAsState()
    val scope = rememberCoroutineScope()

    var flipDegrees by remember { mutableFloatStateOf(0f) }
    var cardVisible by remember { mutableStateOf(true) }
    var showPrescription by remember { mutableStateOf(false) }
    var isPaused by remember { mutableStateOf(false) }

    val flipAnim by animateFloatAsState(
        targetValue = flipDegrees,
        animationSpec = tween(durationMillis = 400, easing = FastOutSlowInEasing),
        label = "flip"
    )

    LaunchedEffect(workoutState) {
        when (val s = workoutState) {
            is WorkoutState.CardFaceDown -> {
                flipDegrees = 0f
                showPrescription = false
                cardVisible = true
            }
            is WorkoutState.CardFaceUp -> {
                flipDegrees = 180f
                HapticHelper.cardFlip()
                delay(200)
                showPrescription = true
            }
            is WorkoutState.CardCompleting -> {
                cardVisible = false
                delay(300)
                coordinator.send(WorkoutEvent.AdvanceComplete)
                cardVisible = true
            }
            is WorkoutState.CardSkipping -> {
                HapticHelper.skip()
                cardVisible = false
                delay(300)
                coordinator.send(WorkoutEvent.AdvanceComplete)
                cardVisible = true
            }
            is WorkoutState.WorkoutComplete -> onWorkoutComplete()
            is WorkoutState.Paused -> isPaused = true
            else -> if (workoutState !is WorkoutState.Paused) isPaused = false
        }
    }

    val isFaceUp = workoutState is WorkoutState.CardFaceUp ||
            workoutState is WorkoutState.HoldStarting ||
            workoutState is WorkoutState.Holding ||
            workoutState is WorkoutState.HoldComplete

    val currentCard = when (val s = workoutState) {
        is WorkoutState.CardFaceUp   -> s.card
        is WorkoutState.HoldStarting -> s.card
        is WorkoutState.Holding      -> s.card
        is WorkoutState.HoldComplete -> s.card
        is WorkoutState.CardCompleting -> s.card
        is WorkoutState.CardSkipping  -> s.card
        else -> null
    }
    val currentPrescription = (workoutState as? WorkoutState.CardFaceUp)?.prescription

    Box(modifier = Modifier.fillMaxSize().background(DS.Colors.bg)) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top bar
            WorkoutTopBar(
                cardsCompleted = session?.cardsCompleted ?: 0,
                deckSize = session?.deckSize ?: 54,
                onPause = { HapticHelper.tap(); coordinator.send(WorkoutEvent.Pause) },
                onEndEarly = {
                    HapticHelper.warning()
                    onEndEarly()
                    coordinator.endEarly()
                }
            )

            // Card area
            Box(
                modifier = Modifier.weight(1f).fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                AnimatedVisibility(
                    visible = cardVisible,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Box(modifier = Modifier.graphicsLayer {
                        rotationY = if (flipAnim <= 90f) 0f else 180f
                        cameraDistance = 12f * density
                    }) {
                        if (flipAnim <= 90f) {
                            // Back of card
                            if (deckId == "midas") MidasCardBack() else StandardCardBack()
                        } else {
                            // Face of card
                            if (currentCard != null) {
                                CardFaceView(
                                    card = currentCard,
                                    prescription = if (showPrescription) currentPrescription else null
                                )
                            }
                        }
                    }
                }
            }

            // Action area
            ActionArea(
                state = workoutState,
                holdSecondsRemaining = holdSeconds,
                onFlipCard = {
                    if (workoutState is WorkoutState.CardFaceDown) {
                        HapticHelper.cardFlip()
                        coordinator.send(WorkoutEvent.FlipCard)
                    }
                },
                onDone = { reps ->
                    HapticHelper.done()
                    coordinator.send(WorkoutEvent.MarkDone(reps, null))
                },
                onStartHold = {
                    HapticHelper.holdStart()
                    coordinator.send(WorkoutEvent.StartHold)
                },
                onMarkHoldDone = { secs ->
                    HapticHelper.done()
                    coordinator.send(WorkoutEvent.MarkDone(null, secs))
                },
                onHoldAdvance = { coordinator.send(WorkoutEvent.AdvanceComplete) },
                onSkip = { coordinator.send(WorkoutEvent.Skip) }
            )
        }

        // Pause overlay
        if (isPaused) {
            PauseOverlay(
                onResume = {
                    HapticHelper.tap()
                    isPaused = false
                    coordinator.send(WorkoutEvent.Resume)
                },
                onEndEarly = {
                    HapticHelper.warning()
                    onEndEarly()
                    coordinator.endEarly()
                }
            )
        }
    }
}

@Composable
private fun WorkoutTopBar(
    cardsCompleted: Int,
    deckSize: Int,
    onPause: () -> Unit,
    onEndEarly: () -> Unit
) {
    var showEndConfirm by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextButton(onClick = { showEndConfirm = true }) {
            Text("END", color = DS.Colors.red, style = DS.Type.sub(14f))
        }
        Text(
            "$cardsCompleted / $deckSize",
            style = DS.Type.mono(14f),
            color = DS.Colors.textTertiary
        )
        IconButton(onClick = onPause) {
            Text("⏸", fontSize = 20.sp, color = DS.Colors.textSecondary)
        }
    }
    if (showEndConfirm) {
        AlertDialog(
            onDismissRequest = { showEndConfirm = false },
            containerColor = DS.Colors.bgRaised,
            title = { Text("End workout?", style = DS.Type.display(22f)) },
            text = { Text("Progress will be saved to history.", color = DS.Colors.textSecondary) },
            confirmButton = {
                TextButton(onClick = { showEndConfirm = false; onEndEarly() }) {
                    Text("End Early", color = DS.Colors.red)
                }
            },
            dismissButton = {
                TextButton(onClick = { showEndConfirm = false }) { Text("Cancel", color = DS.Colors.gold) }
            }
        )
    }
}

@Composable
private fun ActionArea(
    state: WorkoutState,
    holdSecondsRemaining: Int,
    onFlipCard: () -> Unit,
    onDone: (Int) -> Unit,
    onStartHold: () -> Unit,
    onMarkHoldDone: (Int) -> Unit,
    onHoldAdvance: () -> Unit,
    onSkip: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 52.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        when (state) {
            is WorkoutState.CardFaceDown -> {
                Button(
                    onClick = onFlipCard,
                    modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                    colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                    shape = RoundedCornerShape(50)
                ) {
                    Text("FLIP CARD", style = DS.Type.display(24f), color = DS.Colors.bg)
                }
            }
            is WorkoutState.CardFaceUp -> {
                val p = state.prescription
                if (p is Prescription.Reps) {
                    Button(
                        onClick = { onDone(p.count) },
                        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                        colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                        shape = RoundedCornerShape(50)
                    ) {
                        Text("DONE — ${p.count} REPS", style = DS.Type.display(22f), color = DS.Colors.bg)
                    }
                } else if (p is Prescription.Hold) {
                    Button(
                        onClick = onStartHold,
                        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                        colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                        shape = RoundedCornerShape(50)
                    ) {
                        Text("START HOLD", style = DS.Type.display(22f), color = DS.Colors.bg)
                    }
                }
                OutlinedButton(
                    onClick = onSkip,
                    modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = DS.Colors.textTertiary),
                    border = BorderStroke(1.dp, DS.Colors.border),
                    shape = RoundedCornerShape(50)
                ) {
                    Text("SKIP", style = DS.Type.display(22f), color = DS.Colors.textTertiary)
                }
            }
            is WorkoutState.HoldStarting -> {
                HoldStartingArea(onStartHold = onStartHold, onSkip = onSkip)
            }
            is WorkoutState.Holding -> {
                HoldActiveArea(
                    remainingSeconds = holdSecondsRemaining,
                    durationSeconds = state.durationSeconds,
                    onMarkDone = { onMarkHoldDone(state.durationSeconds - holdSecondsRemaining) },
                    onSkip = onSkip
                )
            }
            is WorkoutState.HoldComplete -> {
                HoldCompleteArea(
                    secondsHeld = state.secondsHeld,
                    completedFully = state.completedFully,
                    onAdvance = onHoldAdvance
                )
            }
            else -> {}
        }
    }
}

@Composable
private fun HoldStartingArea(onStartHold: () -> Unit, onSkip: () -> Unit) {
    Button(
        onClick = onStartHold,
        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
        colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
        shape = RoundedCornerShape(50)
    ) {
        Text("BEGIN HOLD", style = DS.Type.display(22f), color = DS.Colors.bg)
    }
    OutlinedButton(
        onClick = onSkip,
        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
        border = BorderStroke(1.dp, DS.Colors.border),
        shape = RoundedCornerShape(50)
    ) {
        Text("SKIP", style = DS.Type.display(22f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun HoldActiveArea(
    remainingSeconds: Int,
    durationSeconds: Int,
    onMarkDone: () -> Unit,
    onSkip: () -> Unit
) {
    val progress = if (durationSeconds > 0) 1f - (remainingSeconds.toFloat() / durationSeconds) else 1f
    val timerColor = lerp(DS.Colors.red, DS.Colors.success, progress)

    Text(
        text = formatHoldTime(remainingSeconds),
        style = DS.Type.mono(48f),
        color = timerColor,
        textAlign = TextAlign.Center
    )
    LinearProgressIndicator(
        progress = { progress },
        modifier = Modifier.fillMaxWidth().height(4.dp),
        color = timerColor,
        trackColor = DS.Colors.bgCard
    )
    OutlinedButton(
        onClick = onMarkDone,
        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
        border = BorderStroke(1.dp, DS.Colors.border),
        shape = RoundedCornerShape(50)
    ) {
        Text("STOP HOLD", style = DS.Type.display(22f), color = DS.Colors.textTertiary)
    }
    OutlinedButton(
        onClick = onSkip,
        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
        border = BorderStroke(1.dp, DS.Colors.border),
        shape = RoundedCornerShape(50)
    ) {
        Text("SKIP", style = DS.Type.display(22f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun HoldCompleteArea(secondsHeld: Int, completedFully: Boolean, onAdvance: () -> Unit) {
    Text(
        text = if (completedFully) "HOLD COMPLETE" else "HOLD STOPPED",
        style = DS.Type.display(28f),
        color = if (completedFully) DS.Colors.success else DS.Colors.textTertiary
    )
    Text("${secondsHeld}s held", style = DS.Type.mono(16f), color = DS.Colors.textSecondary)
    Button(
        onClick = onAdvance,
        modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
        colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
        shape = RoundedCornerShape(50)
    ) {
        Text("NEXT CARD", style = DS.Type.display(22f), color = DS.Colors.bg)
    }
}

@Composable
private fun PauseOverlay(onResume: () -> Unit, onEndEarly: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.85f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(horizontal = 40.dp)
        ) {
            Text("PAUSED", style = DS.Type.display(48f), color = DS.Colors.textPrimary)
            Spacer(Modifier.height(8.dp))
            Button(
                onClick = onResume,
                modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                shape = RoundedCornerShape(50)
            ) {
                Text("RESUME", style = DS.Type.display(24f), color = DS.Colors.bg)
            }
            OutlinedButton(
                onClick = onEndEarly,
                modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                border = BorderStroke(1.dp, DS.Colors.red),
                shape = RoundedCornerShape(50)
            ) {
                Text("END WORKOUT", style = DS.Type.display(22f), color = DS.Colors.red)
            }
        }
    }
}

private fun formatHoldTime(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return if (m > 0) "$m:${s.toString().padStart(2, '0')}" else "${s}s"
}

private fun lerp(a: Color, b: Color, t: Float): Color {
    val clamped = t.coerceIn(0f, 1f)
    return Color(
        red   = a.red   + (b.red   - a.red)   * clamped,
        green = a.green + (b.green - a.green) * clamped,
        blue  = a.blue  + (b.blue  - a.blue)  * clamped
    )
}
