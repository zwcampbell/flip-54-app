package com.flip54.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.flip54.core.Difficulty
import com.flip54.core.Equipment
import com.flip54.core.Suit
import com.flip54.storage.ActiveSessionStore
import com.flip54.storage.models.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AppViewModel @Inject constructor(
    private val userSettingsDao: UserSettingsDao,
    private val workoutHistoryDao: WorkoutHistoryDao,
    private val onboardingStateDao: OnboardingStateDao,
    private val sessionStore: ActiveSessionStore
) : ViewModel() {

    val settings: StateFlow<UserSettingsEntity> = userSettingsDao.observe()
        .map { it ?: UserSettingsEntity() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, UserSettingsEntity())

    val history: StateFlow<List<WorkoutHistoryEntity>> = workoutHistoryDao.observeAll()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val onboarding: StateFlow<OnboardingStateEntity> = onboardingStateDao.observe()
        .map { it ?: OnboardingStateEntity() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, OnboardingStateEntity())

    val hasResumableSession: StateFlow<Boolean> = MutableStateFlow(false).also { flow ->
        viewModelScope.launch {
            val saved = sessionStore.load()
            val nowMs = System.currentTimeMillis()
            (flow as MutableStateFlow).value =
                saved != null && !saved.isComplete && (nowMs - saved.startedAtMs) < 86_400_000L
        }
    }.asStateFlow()

    fun ensureSettingsExist() = viewModelScope.launch {
        if (userSettingsDao.get() == null) userSettingsDao.upsert(UserSettingsEntity())
    }

    fun ensureOnboardingExists() = viewModelScope.launch {
        if (onboardingStateDao.get() == null) onboardingStateDao.upsert(OnboardingStateEntity())
    }

    fun markOnboardingWelcomeSeen() = viewModelScope.launch {
        val current = onboardingStateDao.get() ?: OnboardingStateEntity()
        onboardingStateDao.upsert(current.copy(hasSeenWelcome = true, hasSetEquipmentAndDifficulty = true))
    }

    fun markTutorialComplete() = viewModelScope.launch {
        val current = onboardingStateDao.get() ?: OnboardingStateEntity()
        onboardingStateDao.upsert(current.copy(hasCompletedTutorialFlip = true))
    }

    fun updateSettings(block: UserSettingsEntity.() -> UserSettingsEntity) = viewModelScope.launch {
        val current = userSettingsDao.get() ?: UserSettingsEntity()
        userSettingsDao.upsert(current.block())
    }

    fun saveWorkoutHistory(
        durationMs: Long,
        deckId: String,
        difficulty: Difficulty,
        totalReps: Int,
        holdSecondsCompleted: Int,
        cardCount: Int,
        skipCount: Int,
        repsBySuit: Map<Suit, Int>,
        jumpingJacks: Int
    ) = viewModelScope.launch {
        workoutHistoryDao.insert(
            WorkoutHistoryEntity(
                id = UUID.randomUUID().toString(),
                completedAt = System.currentTimeMillis(),
                durationMs = durationMs,
                deckId = deckId,
                difficultyRaw = difficulty.name,
                totalReps = totalReps,
                holdSecondsCompleted = holdSecondsCompleted,
                cardCount = cardCount,
                skipCount = skipCount,
                heartsReps = repsBySuit[Suit.HEARTS] ?: 0,
                spadesReps = repsBySuit[Suit.SPADES] ?: 0,
                clubsReps  = repsBySuit[Suit.CLUBS]  ?: 0,
                diamondsReps = repsBySuit[Suit.DIAMONDS] ?: 0,
                jumpingJacks = jumpingJacks
            )
        )
    }

    fun dismissResumeBanner() {
        sessionStore.clear()
        (hasResumableSession as MutableStateFlow).value = false
    }

    fun refreshResumeBanner() {
        viewModelScope.launch {
            val saved = sessionStore.load()
            val nowMs = System.currentTimeMillis()
            (hasResumableSession as MutableStateFlow).value =
                saved != null && !saved.isComplete && (nowMs - saved.startedAtMs) < 86_400_000L
        }
    }
}
