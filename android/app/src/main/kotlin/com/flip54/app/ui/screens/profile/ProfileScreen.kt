package com.flip54.app.ui.screens.profile

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.theme.DS
import com.flip54.storage.models.UserSettingsEntity
import com.flip54.storage.models.WorkoutHistoryEntity
import com.flip54.core.Difficulty
import java.util.*

data class LifetimeStats(
    val totalWorkouts: Int,
    val totalReps: Int,
    val totalCards: Int,
    val totalTimeMs: Long,
    val currentStreak: Int,
    val longestStreak: Int,
    val repsByHeart: Int,
    val repsBySpade: Int,
    val repsByClub: Int,
    val repsByDiamond: Int,
    val jumpingJacks: Int
) {
    val totalTimeString: String get() {
        val hrs = (totalTimeMs / 1000 / 3600).toInt()
        val mins = ((totalTimeMs / 1000 % 3600) / 60).toInt()
        return if (hrs > 0) "${hrs}h ${mins}m" else "${mins}m"
    }

    companion object {
        fun from(history: List<WorkoutHistoryEntity>): LifetimeStats {
            val totalWorkouts = history.size
            val totalReps = history.sumOf { it.totalReps }
            val totalCards = history.sumOf { it.cardCount }
            val totalTimeMs = history.sumOf { it.durationMs }
            val repsByHeart = history.sumOf { it.heartsReps }
            val repsBySpade = history.sumOf { it.spadesReps }
            val repsByClub = history.sumOf { it.clubsReps }
            val repsByDiamond = history.sumOf { it.diamondsReps }
            val jumpingJacks = history.sumOf { it.jumpingJacks }

            // Streak calculation
            val cal = Calendar.getInstance()
            fun startOfDay(ms: Long): Long {
                cal.timeInMillis = ms
                cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
                return cal.timeInMillis
            }
            val workoutDaySorted = history.map { startOfDay(it.completedAt) }.toSortedSet().reversed()
            var cur = 0
            var check = startOfDay(System.currentTimeMillis())
            for (day in workoutDaySorted) {
                if (day == check) {
                    cur++
                    cal.timeInMillis = check; cal.add(Calendar.DAY_OF_YEAR, -1)
                    check = cal.timeInMillis
                } else if (day < check) break
            }
            var longestPass = 0; var streak = 0; var prev: Long? = null
            for (day in workoutDaySorted.sorted()) {
                val p = prev
                if (p != null) {
                    cal.timeInMillis = p; cal.add(Calendar.DAY_OF_YEAR, 1)
                    streak = if (cal.timeInMillis == day) streak + 1 else 1
                } else streak = 1
                longestPass = maxOf(longestPass, streak)
                prev = day
            }

            return LifetimeStats(totalWorkouts, totalReps, totalCards, totalTimeMs,
                cur, maxOf(longestPass, cur), repsByHeart, repsBySpade, repsByClub, repsByDiamond, jumpingJacks)
        }
    }
}

@Composable
fun ProfileScreen(
    history: List<WorkoutHistoryEntity>,
    settings: UserSettingsEntity,
    onUpdateSettings: (UserSettingsEntity.() -> UserSettingsEntity) -> Unit
) {
    val stats = remember(history) { LifetimeStats.from(history) }
    var showSettings by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().background(DS.Colors.bg)) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 20.dp, bottom = 16.dp)) {
            Text("PROFILE", style = DS.Type.display(32f), color = DS.Colors.textPrimary)
        }
        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
            StatsSection(stats)
            SuitsSection(stats)
            SettingsButton { showSettings = true }
            Spacer(Modifier.height(60.dp))
        }
    }

    if (showSettings) {
        FullSettingsSheet(settings, onUpdateSettings) { showSettings = false }
    }
}

@Composable
private fun StatsSection(stats: LifetimeStats) {
    SectionHeader("LIFETIME STATS")
    Column(modifier = Modifier.padding(horizontal = 20.dp).clip(RoundedCornerShape(16.dp))
        .background(DS.Colors.bgCard).border(1.dp, DS.Colors.border, RoundedCornerShape(16.dp))) {
        Row(modifier = Modifier.fillMaxWidth()) {
            StatTile("${stats.totalWorkouts}", "Workouts", Modifier.weight(1f))
            VerticalDivider(modifier = Modifier.height(80.dp), color = DS.Colors.border)
            StatTile("${stats.totalReps}", "Total Reps", Modifier.weight(1f))
        }
        HorizontalDivider(color = DS.Colors.border)
        Row(modifier = Modifier.fillMaxWidth()) {
            StatTile("${stats.totalCards}", "Cards Flipped", Modifier.weight(1f))
            VerticalDivider(modifier = Modifier.height(80.dp), color = DS.Colors.border)
            StatTile(stats.totalTimeString, "Total Time", Modifier.weight(1f))
        }
        HorizontalDivider(color = DS.Colors.border)
        Row(modifier = Modifier.fillMaxWidth()) {
            StatTile("${stats.currentStreak}", "Current Streak", Modifier.weight(1f))
            VerticalDivider(modifier = Modifier.height(80.dp), color = DS.Colors.border)
            StatTile("${stats.longestStreak}", "Best Streak", Modifier.weight(1f))
        }
    }
}

@Composable
private fun StatTile(value: String, label: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.padding(vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(value, style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Text(label.uppercase(), style = DS.Type.sub(10f), color = DS.Colors.textTertiary)
    }
}

@Composable
private fun SuitsSection(stats: LifetimeStats) {
    SectionHeader("REPS BY BODY FOCUS")
    val maxReps = maxOf(1, stats.repsByHeart, stats.repsBySpade, stats.repsByClub, stats.repsByDiamond, stats.jumpingJacks)
    Column(modifier = Modifier.padding(horizontal = 20.dp).clip(RoundedCornerShape(16.dp))
        .background(DS.Colors.bgCard).border(1.dp, DS.Colors.border, RoundedCornerShape(16.dp))) {
        SuitBar("♥", "Lower Body", stats.repsByHeart, maxReps, DS.Colors.red)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitBar("♠", "Upper Body", stats.repsBySpade, maxReps, DS.Colors.textPrimary)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitBar("♣", "Total Body", stats.repsByClub, maxReps, DS.Colors.textPrimary)
        HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
        SuitBar("♦", "Core", stats.repsByDiamond, maxReps, DS.Colors.red)
        if (stats.jumpingJacks > 0) {
            HorizontalDivider(modifier = Modifier.padding(start = 50.dp), color = DS.Colors.borderSub)
            SuitBar("★", "Jumping Jacks", stats.jumpingJacks, maxReps, DS.Colors.gold)
        }
    }
}

@Composable
private fun SuitBar(glyph: String, label: String, reps: Int, maxReps: Int, color: androidx.compose.ui.graphics.Color) {
    val pct = reps.toFloat() / maxReps
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(glyph, fontSize = 16.sp, color = color, modifier = Modifier.width(20.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(label, fontSize = 13.sp, color = DS.Colors.textSecondary)
                Text("$reps", style = DS.Type.mono(13f), color = DS.Colors.textPrimary)
            }
            LinearProgressIndicator(
                progress = { pct },
                modifier = Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)),
                color = color.copy(alpha = 0.7f),
                trackColor = DS.Colors.bgRaised
            )
        }
    }
}

@Composable
private fun SettingsButton(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, DS.Colors.border, RoundedCornerShape(14.dp))
            .clickable { HapticHelper.tap(); onClick() }
            .padding(horizontal = 18.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("⚙", fontSize = 16.sp, color = DS.Colors.textSecondary)
            Text("Settings", fontSize = 15.sp, color = DS.Colors.textSecondary)
        }
        Text("›", fontSize = 14.sp, color = DS.Colors.textTertiary)
    }
}

@Composable
private fun FullSettingsSheet(
    settings: UserSettingsEntity,
    onUpdate: (UserSettingsEntity.() -> UserSettingsEntity) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DS.Colors.bgRaised,
        title = { Text("Settings", style = DS.Type.display(24f)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionLabel("EQUIPMENT")
                SettingRow("Weights / Dumbbells", settings.hasWeights) { onUpdate { copy(hasWeights = !hasWeights) } }
                SettingRow("Pull-up Bar", settings.hasPullUpBar) { onUpdate { copy(hasPullUpBar = !hasPullUpBar) } }
                SettingRow("Yoga Mat", settings.hasYogaMat) { onUpdate { copy(hasYogaMat = !hasYogaMat) } }
                HorizontalDivider(color = DS.Colors.border)
                SectionLabel("DIFFICULTY")
                Difficulty.entries.forEach { diff ->
                    Row(
                        modifier = Modifier.fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (settings.difficulty == diff) DS.Colors.goldSoft else DS.Colors.bgCard)
                            .border(1.dp, if (settings.difficulty == diff) DS.Colors.gold.copy(alpha = 0.4f) else DS.Colors.border, RoundedCornerShape(8.dp))
                            .clickable { HapticHelper.selection(); onUpdate { copy(difficultyRaw = diff.name) } }
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(diff.displayName, fontSize = 14.sp, color = if (settings.difficulty == diff) DS.Colors.gold else DS.Colors.textPrimary)
                        if (settings.difficulty == diff) Text("✓", color = DS.Colors.gold, fontSize = 14.sp)
                    }
                }
                HorizontalDivider(color = DS.Colors.border)
                SectionLabel("OPTIONS")
                SettingRow("Use Half Deck (27 cards)", settings.useHalfDeck) { onUpdate { copy(useHalfDeck = !useHalfDeck) } }
                SettingRow("Sound Effects", settings.soundEnabled) { onUpdate { copy(soundEnabled = !soundEnabled) } }
                SettingRow("Haptic Feedback", settings.hapticsEnabled) { onUpdate { copy(hapticsEnabled = !hapticsEnabled) } }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done", color = DS.Colors.gold) } }
    )
}

@Composable
private fun SectionLabel(text: String) {
    Text(text, style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
}

@Composable
private fun SettingRow(label: String, checked: Boolean, onToggle: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        Text(label, fontSize = 14.sp, color = DS.Colors.textPrimary)
        Switch(checked = checked, onCheckedChange = { HapticHelper.selection(); onToggle() },
            colors = SwitchDefaults.colors(checkedThumbColor = DS.Colors.bg, checkedTrackColor = DS.Colors.gold))
    }
}

@Composable
private fun SectionHeader(text: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 24.dp, bottom = 8.dp)) {
        Text(text, style = DS.Type.sub(11f), color = DS.Colors.textTertiary)
    }
}
