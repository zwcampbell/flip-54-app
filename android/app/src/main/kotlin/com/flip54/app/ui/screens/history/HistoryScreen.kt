package com.flip54.app.ui.screens.history

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.formatDuration
import com.flip54.app.ui.theme.DS
import com.flip54.storage.models.WorkoutHistoryEntity
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun HistoryScreen(history: List<WorkoutHistoryEntity>) {
    var displayMonth by remember { mutableLongStateOf(startOfMonth(System.currentTimeMillis())) }
    var selectedWorkout by remember { mutableStateOf<WorkoutHistoryEntity?>(null) }
    var page by remember { mutableIntStateOf(0) }
    val pageSize = 5

    val isCurrentMonth = isSameMonth(displayMonth, System.currentTimeMillis())

    Column(modifier = Modifier.fillMaxSize().background(DS.Colors.bg)) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 20.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("HISTORY", style = DS.Type.display(32f), color = DS.Colors.textPrimary)
            OutlinedButton(
                onClick = { HapticHelper.tap(); displayMonth = startOfMonth(System.currentTimeMillis()) },
                enabled = !isCurrentMonth,
                border = BorderStroke(1.dp, if (isCurrentMonth) DS.Colors.border else DS.Colors.gold.copy(alpha = 0.6f)),
                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp),
                shape = RoundedCornerShape(50),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = if (isCurrentMonth) DS.Colors.textTertiary else DS.Colors.gold
                )
            ) {
                Text("TODAY", style = DS.Type.sub(12f))
            }
        }

        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
            // Calendar
            CalendarCard(
                displayMonth = displayMonth,
                history = history,
                onPrevMonth = { displayMonth = addMonths(displayMonth, -1) },
                onNextMonth = {
                    val next = addMonths(displayMonth, 1)
                    if (next <= System.currentTimeMillis()) displayMonth = next
                },
                onDayClick = { workout -> HapticHelper.tap(); selectedWorkout = workout }
            )

            Spacer(Modifier.height(16.dp))

            // Recent workouts
            if (history.isEmpty()) {
                EmptyState()
            } else {
                SectionHeader("RECENT")
                val pageWorkouts = history.drop(page * pageSize).take(pageSize)
                Column(
                    modifier = Modifier.padding(horizontal = 20.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(DS.Colors.bgCard)
                        .border(1.dp, DS.Colors.border, RoundedCornerShape(16.dp))
                ) {
                    pageWorkouts.forEachIndexed { i, workout ->
                        WorkoutRow(workout) { HapticHelper.tap(); selectedWorkout = workout }
                        if (i < pageWorkouts.lastIndex) {
                            HorizontalDivider(modifier = Modifier.padding(start = 56.dp), color = DS.Colors.borderSub)
                        }
                    }
                }
                val pageCount = maxOf(1, (history.size + pageSize - 1) / pageSize)
                if (pageCount > 1) {
                    PaginationBar(page, pageCount, onPrev = { page-- }, onNext = { page++ })
                }
            }
            Spacer(Modifier.height(60.dp))
        }
    }

    selectedWorkout?.let { workout ->
        WorkoutDetailSheet(workout, onDismiss = { selectedWorkout = null })
    }
}

@Composable
private fun CalendarCard(
    displayMonth: Long,
    history: List<WorkoutHistoryEntity>,
    onPrevMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onDayClick: (WorkoutHistoryEntity) -> Unit
) {
    val days = monthDays(displayMonth)
    val workoutDays = history.groupBy { startOfDay(it.completedAt) }

    Column(
        modifier = Modifier.padding(horizontal = 20.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.border, RoundedCornerShape(20.dp))
    ) {
        // Month nav
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { HapticHelper.tap(); onPrevMonth() }, modifier = Modifier.size(36.dp)
                .background(DS.Colors.bgRaised, CircleShape)) {
                Text("‹", color = DS.Colors.textSecondary, fontSize = 18.sp)
            }
            Text(monthYearString(displayMonth), style = DS.Type.sub(16f), color = DS.Colors.textPrimary)
            IconButton(onClick = { HapticHelper.tap(); onNextMonth() }, modifier = Modifier.size(36.dp)
                .background(DS.Colors.bgRaised, CircleShape)) {
                Text("›", color = DS.Colors.textSecondary, fontSize = 18.sp)
            }
        }

        // Day headers
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            listOf("Su","Mo","Tu","We","Th","Fr","Sa").forEach { d ->
                Text(d, style = DS.Type.sub(11f), color = DS.Colors.textTertiary,
                    modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            }
        }
        Spacer(Modifier.height(8.dp))

        // Grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.fillMaxWidth().height(((days.size / 7) * 40).dp).padding(horizontal = 16.dp),
            contentPadding = PaddingValues(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            userScrollEnabled = false
        ) {
            items(days.size) { i ->
                val dayMs = days[i]
                if (dayMs == null) {
                    Box(Modifier.height(36.dp))
                } else {
                    val isToday = isSameDay(dayMs, System.currentTimeMillis())
                    val workoutsOnDay = workoutDays[startOfDay(dayMs)] ?: emptyList()
                    val hasWorkout = workoutsOnDay.isNotEmpty()
                    val dayNum = dayOfMonth(dayMs)

                    Box(
                        modifier = Modifier.height(36.dp)
                            .clip(CircleShape)
                            .background(when {
                                hasWorkout -> DS.Colors.gold.copy(alpha = 0.9f)
                                isToday    -> DS.Colors.gold.copy(alpha = 0.15f)
                                else       -> Color.Transparent
                            })
                            .clickable(enabled = hasWorkout) { onDayClick(workoutsOnDay.first()) },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "$dayNum",
                            fontSize = 13.sp,
                            color = when {
                                hasWorkout -> DS.Colors.bg
                                isToday    -> DS.Colors.gold
                                else       -> DS.Colors.textSecondary
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkoutRow(workout: WorkoutHistoryEntity, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(36.dp)) {
            Text(dayOfWeekShort(workout.completedAt), style = DS.Type.sub(10f), color = DS.Colors.textTertiary)
            Text("${dayOfMonth(workout.completedAt)}", style = DS.Type.display(20f), color = DS.Colors.gold)
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("${workout.totalReps} reps · ${workout.cardCount} cards", fontSize = 14.sp, color = DS.Colors.textPrimary)
            Text("${formatDuration(workout.durationMs)} · ${workout.difficulty.displayName}", fontSize = 12.sp, color = DS.Colors.textTertiary)
        }
        Text("›", fontSize = 12.sp, color = DS.Colors.textTertiary)
    }
}

@Composable
private fun PaginationBar(page: Int, pageCount: Int, onPrev: () -> Unit, onNext: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = { HapticHelper.tap(); onPrev() }, enabled = page > 0,
            modifier = Modifier.size(36.dp).background(DS.Colors.bgCard, CircleShape)) {
            Text("‹", color = if (page > 0) DS.Colors.textSecondary else DS.Colors.textTertiary.copy(alpha = 0.4f), fontSize = 18.sp)
        }
        Text("PAGE ${page + 1} OF $pageCount", style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
        IconButton(onClick = { HapticHelper.tap(); onNext() }, enabled = page < pageCount - 1,
            modifier = Modifier.size(36.dp).background(DS.Colors.bgCard, CircleShape)) {
            Text("›", color = if (page < pageCount - 1) DS.Colors.textSecondary else DS.Colors.textTertiary.copy(alpha = 0.4f), fontSize = 18.sp)
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp, horizontal = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("♣", fontSize = 48.sp, color = DS.Colors.textTertiary)
        Text("No workouts yet", style = DS.Type.display(24f), color = DS.Colors.textSecondary)
        Text("Complete your first workout to see history here.", fontSize = 14.sp, color = DS.Colors.textTertiary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center)
    }
}

@Composable
private fun SectionHeader(text: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp)) {
        Text(text, style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun WorkoutDetailSheet(workout: WorkoutHistoryEntity, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DS.Colors.bgRaised,
        title = {
            Column {
                Text(dateString(workout.completedAt).uppercase(), style = DS.Type.display(22f))
                Text("${workout.difficulty.displayName} · ${workout.deckId.replaceFirstChar { it.uppercase() }} Deck",
                    fontSize = 13.sp, color = DS.Colors.textTertiary)
            }
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(horizontalArrangement = Arrangement.SpaceEvenly, modifier = Modifier.fillMaxWidth()) {
                    MiniStat("${workout.totalReps}", "REPS")
                    MiniStat("${workout.cardCount}", "CARDS")
                    MiniStat(formatDuration(workout.durationMs), "TIME")
                }
                HorizontalDivider(color = DS.Colors.border)
                SuitDetailRow("♥", "Lower Body", workout.heartsReps, isRed = true)
                SuitDetailRow("♠", "Upper Body", workout.spadesReps, isRed = false)
                SuitDetailRow("♣", "Total Body", workout.clubsReps, isRed = false)
                SuitDetailRow("♦", "Core", workout.diamondsReps, isRed = true)
                if (workout.jumpingJacks > 0) SuitDetailRow("★", "Jumping Jacks", workout.jumpingJacks, isRed = false)
                if (workout.skipCount > 0) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Skipped", fontSize = 13.sp, color = DS.Colors.textTertiary)
                        Text("${workout.skipCount}", style = DS.Type.mono(13f), color = DS.Colors.textTertiary)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Done", color = DS.Colors.gold) }
        }
    )
}

@Composable
private fun MiniStat(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = DS.Type.display(28f))
        Text(label, style = DS.Type.sub(10f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun SuitDetailRow(glyph: String, label: String, reps: Int, isRed: Boolean) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(glyph, fontSize = 14.sp, color = if (isRed) DS.Colors.red else DS.Colors.textPrimary, modifier = Modifier.width(16.dp))
        Text(label, fontSize = 13.sp, color = DS.Colors.textSecondary, modifier = Modifier.weight(1f))
        Text("$reps", style = DS.Type.mono(13f), color = DS.Colors.textPrimary)
    }
}

// ── Date helpers ────────────────────────────────────────────────────────────

private fun startOfMonth(ms: Long): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = ms
    cal.set(Calendar.DAY_OF_MONTH, 1)
    cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0); cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
    return cal.timeInMillis
}

private fun startOfDay(ms: Long): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = ms
    cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0); cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
    return cal.timeInMillis
}

private fun isSameMonth(a: Long, b: Long): Boolean {
    val ca = Calendar.getInstance().also { it.timeInMillis = a }
    val cb = Calendar.getInstance().also { it.timeInMillis = b }
    return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) && ca.get(Calendar.MONTH) == cb.get(Calendar.MONTH)
}

private fun isSameDay(a: Long, b: Long): Boolean {
    val ca = Calendar.getInstance().also { it.timeInMillis = a }
    val cb = Calendar.getInstance().also { it.timeInMillis = b }
    return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) &&
            ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
}

private fun addMonths(ms: Long, months: Int): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = ms
    cal.add(Calendar.MONTH, months)
    return cal.timeInMillis
}

private fun monthDays(monthStartMs: Long): List<Long?> {
    val cal = Calendar.getInstance()
    cal.timeInMillis = monthStartMs
    cal.set(Calendar.DAY_OF_MONTH, 1)
    val startWeekday = (cal.get(Calendar.DAY_OF_WEEK) - 1 + 7) % 7
    val daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)
    val result = mutableListOf<Long?>()
    repeat(startWeekday) { result.add(null) }
    for (d in 1..daysInMonth) {
        cal.set(Calendar.DAY_OF_MONTH, d)
        result.add(cal.timeInMillis)
    }
    while (result.size % 7 != 0) result.add(null)
    return result
}

private fun dayOfMonth(ms: Long): Int = Calendar.getInstance().also { it.timeInMillis = ms }.get(Calendar.DAY_OF_MONTH)
private fun dayOfWeekShort(ms: Long): String = SimpleDateFormat("EEE", Locale.getDefault()).format(Date(ms)).uppercase()
private fun monthYearString(ms: Long): String = SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(Date(ms)).uppercase()
private fun dateString(ms: Long): String = SimpleDateFormat("EEEE, MMM d", Locale.getDefault()).format(Date(ms))
private val Color.Companion.Transparent get() = Color(0x00000000)
