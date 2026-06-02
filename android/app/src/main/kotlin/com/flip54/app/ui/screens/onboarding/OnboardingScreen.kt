package com.flip54.app.ui.screens.onboarding

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.theme.DS
import com.flip54.core.Difficulty
import com.flip54.core.Equipment
import com.flip54.storage.models.UserSettingsEntity
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun OnboardingScreen(
    settings: UserSettingsEntity,
    onUpdateSettings: (UserSettingsEntity.() -> UserSettingsEntity) -> Unit,
    onComplete: (startTutorial: Boolean) -> Unit
) {
    val totalPages = 7
    val pagerState = rememberPagerState(pageCount = { totalPages })
    val scope = rememberCoroutineScope()

    fun skip() { onComplete(false) }
    fun advance() {
        scope.launch {
            if (pagerState.currentPage < totalPages - 1) {
                pagerState.animateScrollToPage(pagerState.currentPage + 1)
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.Colors.bg)
    ) {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "GET STARTED", onCTA = ::advance) {
                    WelcomePage()
                }
                1 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "NEXT", onCTA = ::advance) {
                    HowItWorksPage()
                }
                2 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "GOT IT", onCTA = ::advance) {
                    SpecialCardsPage()
                }
                3 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "NEXT", onCTA = ::advance) {
                    SkippingPage()
                }
                4 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "NEXT", onCTA = ::advance) {
                    EquipmentPage(
                        hasWeights = settings.hasWeights,
                        hasPullUpBar = settings.hasPullUpBar,
                        hasYogaMat = settings.hasYogaMat,
                        onToggleWeights = { onUpdateSettings { copy(hasWeights = !hasWeights) } },
                        onToggleBar    = { onUpdateSettings { copy(hasPullUpBar = !hasPullUpBar) } },
                        onToggleYogaMat = { onUpdateSettings { copy(hasYogaMat = !hasYogaMat) } }
                    )
                }
                5 -> OnboardingPageWrapper(page, totalPages, onSkip = ::skip, cta = "NEXT", onCTA = ::advance) {
                    DifficultyPage(
                        selected = settings.difficulty,
                        onSelect = { diff -> onUpdateSettings { copy(difficultyRaw = diff.name) } }
                    )
                }
                6 -> OnboardingPageWrapper(page, totalPages, onSkip = null, cta = "START TUTORIAL", onCTA = { onComplete(true) },
                    secondaryCta = "SKIP TUTORIAL", onSecondaryCta = { onComplete(false) }) {
                    ReadyPage()
                }
            }
        }

        // Dot indicator
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 140.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            repeat(totalPages) { i ->
                Box(
                    modifier = Modifier
                        .size(if (i == pagerState.currentPage) 8.dp else 5.dp)
                        .clip(CircleShape)
                        .background(
                            if (i == pagerState.currentPage) DS.Colors.gold
                            else DS.Colors.textTertiary.copy(alpha = 0.4f)
                        )
                )
            }
        }
    }
}

@Composable
private fun OnboardingPageWrapper(
    page: Int,
    total: Int,
    onSkip: (() -> Unit)?,
    cta: String,
    onCTA: () -> Unit,
    secondaryCta: String? = null,
    onSecondaryCta: (() -> Unit)? = null,
    content: @Composable () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize().background(DS.Colors.bg)) {
        if (onSkip != null) {
            TextButton(
                onClick = { HapticHelper.tap(); onSkip() },
                modifier = Modifier.align(Alignment.TopEnd).padding(top = 16.dp, end = 16.dp)
            ) {
                Text("Skip", color = DS.Colors.textTertiary, fontSize = 14.sp)
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(72.dp))
            content()
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.height(24.dp))
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 24.dp)
                .padding(bottom = 52.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = { HapticHelper.primary(); onCTA() },
                modifier = Modifier.fillMaxWidth().height(DS.Layout.buttonHeight),
                colors = ButtonDefaults.buttonColors(containerColor = DS.Colors.gold),
                shape = RoundedCornerShape(50)
            ) {
                Text(cta, style = DS.Type.display(22f), color = DS.Colors.bg)
            }
            if (secondaryCta != null && onSecondaryCta != null) {
                TextButton(
                    onClick = { HapticHelper.tap(); onSecondaryCta() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(secondaryCta, style = DS.Type.sub(14f), color = DS.Colors.textTertiary)
                }
            }
        }
    }
}

@Composable
private fun WelcomePage() {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("FLIP 54", style = DS.Type.display(64f), color = DS.Colors.gold)
        Text("A workout powered\nby a deck of cards.", style = DS.Type.sub(22f),
            color = DS.Colors.textSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun HowItWorksPage() {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Text("HOW IT WORKS", style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Spacer(Modifier.height(8.dp))
        HowItWorksStep("1", "Shuffle the deck", "54 cards, shuffled fresh every workout.")
        HowItWorksStep("2", "Flip a card", "Each card prescribes an exercise and a rep count.")
        HowItWorksStep("3", "Do the reps", "Suit = body region. Number = how many reps.")
        HowItWorksStep("4", "Repeat until done", "Work through all 54 cards to complete the workout.")
    }
}

@Composable
private fun HowItWorksStep(num: String, title: String, body: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(
            modifier = Modifier.size(32.dp).clip(CircleShape).background(DS.Colors.bgCard)
                .border(1.dp, DS.Colors.border, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(num, style = DS.Type.mono(14f), color = DS.Colors.gold)
        }
        Column {
            Text(title, style = DS.Type.sub(16f), color = DS.Colors.textPrimary)
            Text(body, fontSize = 13.sp, color = DS.Colors.textTertiary)
        }
    }
}

@Composable
private fun SpecialCardsPage() {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("SPECIAL CARDS", style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Spacer(Modifier.height(8.dp))
        SpecialCardRow("A", "Ace = Hold exercise", "60 seconds of an isometric hold.")
        SpecialCardRow("J/Q/K", "Face cards = 10 reps", "Jack, Queen, King always prescribe 10 reps.")
        SpecialCardRow("🃏", "Joker = Jumping Jacks", "40 jumping jacks every time a joker appears.")
    }
}

@Composable
private fun SpecialCardRow(badge: String, title: String, body: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier.width(48.dp).height(48.dp)
                .clip(RoundedCornerShape(8.dp)).background(DS.Colors.bgCard)
                .border(1.dp, DS.Colors.border, RoundedCornerShape(8.dp)),
            contentAlignment = Alignment.Center
        ) {
            Text(badge, style = DS.Type.display(14f), color = DS.Colors.gold)
        }
        Column {
            Text(title, style = DS.Type.sub(15f), color = DS.Colors.textPrimary)
            Text(body, fontSize = 13.sp, color = DS.Colors.textTertiary)
        }
    }
}

@Composable
private fun SkippingPage() {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("SKIPPING", style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Text("Can't do an exercise? Skip it.", style = DS.Type.sub(18f),
            color = DS.Colors.textSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        Text("Skipped cards go to the bottom of the deck and will come back around. " +
                "Skipping is tracked in your workout summary.",
            fontSize = 15.sp, color = DS.Colors.textTertiary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun EquipmentPage(
    hasWeights: Boolean,
    hasPullUpBar: Boolean,
    hasYogaMat: Boolean,
    onToggleWeights: () -> Unit,
    onToggleBar: () -> Unit,
    onToggleYogaMat: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("YOUR EQUIPMENT", style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Text("Select what you have available. This unlocks additional exercises.",
            fontSize = 14.sp, color = DS.Colors.textTertiary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        EquipmentToggle("Weights / Dumbbells", hasWeights, onToggleWeights)
        EquipmentToggle("Pull-up Bar", hasPullUpBar, onToggleBar)
        EquipmentToggle("Yoga Mat", hasYogaMat, onToggleYogaMat)
    }
}

@Composable
private fun EquipmentToggle(label: String, checked: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(DS.Colors.bgCard)
            .border(1.dp, if (checked) DS.Colors.gold.copy(alpha = 0.4f) else DS.Colors.border, RoundedCornerShape(12.dp))
            .clickable { HapticHelper.selection(); onToggle() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 15.sp, color = DS.Colors.textPrimary)
        Switch(
            checked = checked,
            onCheckedChange = { HapticHelper.selection(); onToggle() },
            colors = SwitchDefaults.colors(
                checkedThumbColor = DS.Colors.bg,
                checkedTrackColor = DS.Colors.gold
            )
        )
    }
}

@Composable
private fun DifficultyPage(selected: Difficulty, onSelect: (Difficulty) -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("DIFFICULTY", style = DS.Type.display(36f), color = DS.Colors.textPrimary)
        Text("Sets the rep multiplier for every card.",
            fontSize = 14.sp, color = DS.Colors.textTertiary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        Difficulty.entries.forEach { diff ->
            DifficultyOption(diff, selected == diff) { onSelect(diff) }
        }
    }
}

@Composable
private fun DifficultyOption(diff: Difficulty, isSelected: Boolean, onClick: () -> Unit) {
    val description = when (diff) {
        Difficulty.BEGINNER -> "0.5× reps — great for beginners"
        Difficulty.STANDARD -> "1× reps — the classic workout"
        Difficulty.ADVANCED -> "2× reps — for serious athletes"
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (isSelected) DS.Colors.goldSoft else DS.Colors.bgCard)
            .border(1.dp, if (isSelected) DS.Colors.gold.copy(alpha = 0.5f) else DS.Colors.border, RoundedCornerShape(12.dp))
            .clickable { HapticHelper.selection(); onClick() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(diff.displayName.uppercase(), style = DS.Type.display(20f), color = if (isSelected) DS.Colors.gold else DS.Colors.textPrimary)
            Text(description, fontSize = 12.sp, color = DS.Colors.textTertiary)
        }
        if (isSelected) {
            Text("✓", color = DS.Colors.gold, fontSize = 18.sp)
        }
    }
}

@Composable
private fun ReadyPage() {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("YOU'RE READY", style = DS.Type.display(48f), color = DS.Colors.gold)
        Text("Start with a tutorial to see how the workout flows, or jump straight in.",
            fontSize = 15.sp, color = DS.Colors.textTertiary, textAlign = TextAlign.Center)
    }
}
