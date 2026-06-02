package com.flip54.app.ui

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import com.flip54.app.ui.screens.activeworkout.ActiveWorkoutScreen
import com.flip54.app.ui.screens.completion.CompletedWorkoutData
import com.flip54.app.ui.screens.completion.CompletionScreen
import com.flip54.app.ui.screens.history.HistoryScreen
import com.flip54.app.ui.screens.onboarding.OnboardingScreen
import com.flip54.app.ui.screens.preworkout.PreWorkoutScreen
import com.flip54.app.ui.screens.profile.ProfileScreen
import com.flip54.app.ui.theme.DS
import com.flip54.engine.WorkoutCoordinator
import com.flip54.engine.WorkoutState

@Composable
fun Flip54App(
    appViewModel: AppViewModel = hiltViewModel(),
    coordinator: WorkoutCoordinator = hiltViewModel()
) {
    LaunchedEffect(Unit) {
        appViewModel.ensureSettingsExist()
        appViewModel.ensureOnboardingExists()
    }

    val settings by appViewModel.settings.collectAsState()
    val history by appViewModel.history.collectAsState()
    val onboarding by appViewModel.onboarding.collectAsState()
    val hasResume by appViewModel.hasResumableSession.collectAsState()
    val workoutState by coordinator.state.collectAsState()

    var completedData by remember { mutableStateOf<CompletedWorkoutData?>(null) }
    var selectedTab by remember { mutableIntStateOf(0) }

    val showOnboarding = !onboarding.hasSeenWelcome
    val isActiveWorkout = workoutState !is WorkoutState.Idle && workoutState !is WorkoutState.Shuffling
    val showCompletion = completedData != null

    Box(modifier = Modifier.fillMaxSize()) {
        when {
            showOnboarding -> {
                OnboardingScreen(
                    settings = settings,
                    onUpdateSettings = { appViewModel.updateSettings(it) },
                    onComplete = { startTutorial ->
                        appViewModel.markOnboardingWelcomeSeen()
                        if (startTutorial) {
                            coordinator.configureTutorial(settings.equipment, settings.difficulty)
                            coordinator.send(com.flip54.engine.WorkoutEvent.Shuffle)
                        }
                    }
                )
            }
            showCompletion -> {
                val data = completedData!!
                CompletionScreen(data = data, onDone = {
                    completedData = null
                    coordinator.reset()
                    appViewModel.refreshResumeBanner()
                })
            }
            isActiveWorkout -> {
                ActiveWorkoutScreen(
                    coordinator = coordinator,
                    deckId = settings.equippedDeckId,
                    onWorkoutComplete = {
                        val session = coordinator.session.value
                        if (session != null) {
                            val nowMs = System.currentTimeMillis()
                            val data = CompletedWorkoutData.from(session, nowMs)
                            completedData = data
                            if (!coordinator.isTutorial.value) {
                                appViewModel.saveWorkoutHistory(
                                    durationMs = data.durationMs,
                                    deckId = data.deckId,
                                    difficulty = session.difficulty,
                                    totalReps = data.totalReps,
                                    holdSecondsCompleted = data.holdSecondsCompleted,
                                    cardCount = data.cardCount,
                                    skipCount = data.skipCount,
                                    repsBySuit = data.repsBySuit,
                                    jumpingJacks = data.jumpingJacks
                                )
                            } else {
                                appViewModel.markTutorialComplete()
                            }
                        }
                    },
                    onEndEarly = {
                        val session = coordinator.session.value
                        if (session != null && !coordinator.isTutorial.value && session.cardsCompleted > 0) {
                            val nowMs = System.currentTimeMillis()
                            val data = CompletedWorkoutData.from(session, nowMs)
                            appViewModel.saveWorkoutHistory(
                                durationMs = data.durationMs,
                                deckId = data.deckId,
                                difficulty = session.difficulty,
                                totalReps = data.totalReps,
                                holdSecondsCompleted = data.holdSecondsCompleted,
                                cardCount = data.cardCount,
                                skipCount = data.skipCount,
                                repsBySuit = data.repsBySuit,
                                jumpingJacks = data.jumpingJacks
                            )
                        }
                        appViewModel.refreshResumeBanner()
                    }
                )
            }
            else -> {
                MainTabs(
                    selectedTab = selectedTab,
                    onTabSelected = { selectedTab = it },
                    content = { tab ->
                        when (tab) {
                            0 -> PreWorkoutScreen(
                                coordinator = coordinator,
                                settings = settings,
                                onboardingState = onboarding,
                                showResumeBanner = hasResume,
                                onResume = {
                                    coordinator.restoreIfNeeded(settings.equipment, settings.difficulty, settings.equippedDeckId)
                                    (appViewModel.hasResumableSession as? kotlinx.coroutines.flow.MutableStateFlow)?.value = false
                                },
                                onDismissResume = { appViewModel.dismissResumeBanner() },
                                onUpdateSettings = { appViewModel.updateSettings(it) },
                                onStartTutorial = {
                                    coordinator.configureTutorial(settings.equipment, settings.difficulty)
                                    coordinator.send(com.flip54.engine.WorkoutEvent.Shuffle)
                                }
                            )
                            1 -> HistoryScreen(history = history)
                            2 -> ProfileScreen(
                                history = history,
                                settings = settings,
                                onUpdateSettings = { appViewModel.updateSettings(it) }
                            )
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun MainTabs(
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    content: @Composable (Int) -> Unit
) {
    val tabs = listOf(
        TabItem("Workout", Icons.Filled.PlayArrow),
        TabItem("History", Icons.Filled.DateRange),
        TabItem("Profile",  Icons.Filled.Person)
    )

    Scaffold(
        containerColor = DS.Colors.bg,
        bottomBar = {
            NavigationBar(containerColor = DS.Colors.bgRaised, tonalElevation = 0.dp) {
                tabs.forEachIndexed { i, tab ->
                    NavigationBarItem(
                        selected = selectedTab == i,
                        onClick = { onTabSelected(i) },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label, style = DS.Type.sub(10f)) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = DS.Colors.gold,
                            selectedTextColor = DS.Colors.gold,
                            unselectedIconColor = DS.Colors.textTertiary,
                            unselectedTextColor = DS.Colors.textTertiary,
                            indicatorColor = DS.Colors.bgRaised
                        )
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            content(selectedTab)
        }
    }
}

private data class TabItem(val label: String, val icon: ImageVector)
