package com.flip54.engine

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.flip54.core.*
import com.flip54.storage.ActiveSession
import com.flip54.storage.ActiveSessionStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class WorkoutCoordinator @Inject constructor(
    private val store: ActiveSessionStore
) : ViewModel() {

    private val _state = MutableStateFlow<WorkoutState>(WorkoutState.Idle)
    val state: StateFlow<WorkoutState> = _state.asStateFlow()

    private val _session = MutableStateFlow<ActiveSession?>(null)
    val session: StateFlow<ActiveSession?> = _session.asStateFlow()

    private val _isTutorial = MutableStateFlow(false)
    val isTutorial: StateFlow<Boolean> = _isTutorial.asStateFlow()

    private var useHalfDeck: Boolean = false

    private val holdTimer = HoldTimer(viewModelScope).also { timer ->
        timer.onExpired = { send(WorkoutEvent.HoldTimerExpired) }
    }

    val holdTimerSeconds: StateFlow<Int> = holdTimer.remainingSeconds

    // MARK: - Public API

    fun send(event: WorkoutEvent) {
        val current = _state.value
        var next = transition(current, event)
        if (next == current) return

        // On resume from pause into holding: rebuild startTime accounting for elapsed hold
        if (current is WorkoutState.Paused && next is WorkoutState.Holding) {
            val elapsedMs = _session.value?.holdElapsedMs ?: 0L
            next = WorkoutState.Holding(
                card = next.card,
                startTimeMs = System.currentTimeMillis() - elapsedMs,
                durationSeconds = next.durationSeconds
            )
        }

        applyTransition(from = current, to = next, event = event)
        _state.value = next
    }

    // MARK: - State machine

    private fun transition(state: WorkoutState, event: WorkoutEvent): WorkoutState {
        return when {
            state is WorkoutState.Idle && event is WorkoutEvent.Shuffle ->
                WorkoutState.Shuffling

            state is WorkoutState.Shuffling && event is WorkoutEvent.ShuffleComplete ->
                WorkoutState.CardFaceDown

            state is WorkoutState.CardFaceDown && event is WorkoutEvent.FlipCard -> {
                val s = _session.value ?: return state
                if (s.drawPile.isEmpty()) return state
                val flipped = s.flipNextCard()
                _session.value = flipped
                val card = flipped.currentCard ?: return state
                val p = prescription(card, s.equipment, s.difficulty)
                WorkoutState.CardFaceUp(card, p)
            }

            state is WorkoutState.CardFaceUp && state.card.isAce && event is WorkoutEvent.StartHold ->
                WorkoutState.HoldStarting(state.card)

            state is WorkoutState.HoldStarting && event is WorkoutEvent.StartHold -> {
                val s = _session.value ?: return state
                val p = prescription(state.card, s.equipment, s.difficulty)
                val secs = (p as? Prescription.Hold)?.seconds ?: return state
                WorkoutState.Holding(state.card, System.currentTimeMillis(), secs)
            }

            state is WorkoutState.CardFaceUp && event is WorkoutEvent.MarkDone ->
                WorkoutState.CardCompleting(state.card)

            state is WorkoutState.Holding && event is WorkoutEvent.MarkDone ->
                WorkoutState.HoldComplete(state.card, event.holdSeconds ?: 0, false)

            state is WorkoutState.Holding && event is WorkoutEvent.HoldTimerExpired -> {
                val held = ((System.currentTimeMillis() - state.startTimeMs) / 1000).toInt()
                WorkoutState.HoldComplete(state.card, minOf(held, state.durationSeconds), true)
            }

            state is WorkoutState.HoldComplete && event is WorkoutEvent.AdvanceComplete ->
                WorkoutState.CardCompleting(state.card)

            (state is WorkoutState.CardFaceUp || state is WorkoutState.HoldStarting ||
                    state is WorkoutState.Holding) && event is WorkoutEvent.Skip -> {
                val card = when (state) {
                    is WorkoutState.CardFaceUp   -> state.card
                    is WorkoutState.HoldStarting -> state.card
                    is WorkoutState.Holding      -> state.card
                    else -> return state
                }
                WorkoutState.CardSkipping(card)
            }

            state is WorkoutState.CardCompleting && event is WorkoutEvent.AdvanceComplete -> {
                val s = _session.value ?: return WorkoutState.WorkoutComplete
                if (s.isComplete) WorkoutState.WorkoutComplete else WorkoutState.CardFaceDown
            }

            state is WorkoutState.CardSkipping && event is WorkoutEvent.AdvanceComplete ->
                WorkoutState.CardFaceDown

            !state.isPaused && event is WorkoutEvent.Pause ->
                WorkoutState.Paused(state)

            state is WorkoutState.Paused && event is WorkoutEvent.Resume ->
                state.previous

            else -> state
        }
    }

    // MARK: - Side effects

    private fun applyTransition(from: WorkoutState, to: WorkoutState, event: WorkoutEvent) {
        when (to) {
            is WorkoutState.Shuffling -> startNewSession()

            is WorkoutState.Holding -> {
                val elapsedMs = _session.value?.holdElapsedMs ?: 0L
                holdTimer.start(to.durationSeconds, elapsedMs)
                if (from is WorkoutState.Paused) {
                    _session.value = _session.value?.resume(System.currentTimeMillis())
                }
                _session.value = _session.value?.startHold(System.currentTimeMillis())
            }

            is WorkoutState.HoldComplete -> {
                holdTimer.cancel()
                if (to.card.isAce) {
                    _session.value = _session.value?.completeCurrentCard(
                        reps = null,
                        holdSeconds = to.secondsHeld,
                        nowMs = System.currentTimeMillis()
                    )
                }
            }

            is WorkoutState.CardCompleting -> {
                if (from is WorkoutState.CardFaceUp) {
                    val count = (from.prescription as? Prescription.Reps)?.count
                    if (count != null) {
                        _session.value = _session.value?.completeCurrentCard(
                            reps = count,
                            holdSeconds = null,
                            nowMs = System.currentTimeMillis()
                        )
                    }
                }
                persistSession()
            }

            is WorkoutState.CardSkipping -> {
                holdTimer.cancel()
                _session.value = _session.value?.skipCurrentCard()
                persistSession()
            }

            is WorkoutState.WorkoutComplete -> store.clear()

            is WorkoutState.Paused -> {
                _session.value = _session.value?.pause(System.currentTimeMillis())
                holdTimer.cancel()
                persistSession()
            }

            is WorkoutState.CardFaceDown -> {
                if (from is WorkoutState.Paused) {
                    _session.value = _session.value?.resume(System.currentTimeMillis())
                }
            }

            else -> Unit
        }
    }

    // MARK: - Session management

    private fun startNewSession() {
        if (_isTutorial.value) return
        val current = _session.value
        val equipment = current?.equipment ?: Equipment.bodyWeightOnly
        val difficulty = current?.difficulty ?: Difficulty.STANDARD
        val deckId = current?.deckId ?: "standard"
        val deck = if (useHalfDeck) Card.halfDeck() else Card.standardDeck()
        val session = ActiveSession.start(deck, deckId, equipment, difficulty)
        _session.value = session
        persistSession()
    }

    private fun persistSession() {
        if (_isTutorial.value) return
        _session.value?.let { store.save(it) }
    }

    // MARK: - Configuration

    fun configure(equipment: Equipment, difficulty: Difficulty, deckId: String, useHalfDeck: Boolean = false) {
        _isTutorial.value = false
        this.useHalfDeck = useHalfDeck
        val deck = if (useHalfDeck) Card.halfDeck() else Card.standardDeck()
        _session.value = ActiveSession.start(deck, deckId, equipment, difficulty)
    }

    fun configureTutorial(equipment: Equipment, difficulty: Difficulty) {
        _isTutorial.value = true
        val tutorialCards = listOf(
            Card.Standard(Suit.HEARTS,   Rank.SEVEN),
            Card.Standard(Suit.SPADES,   Rank.KING),
            Card.Standard(Suit.CLUBS,    Rank.ACE),
            Card.Standard(Suit.DIAMONDS, Rank.FIVE),
            Card.Joker(JokerVariant.RED)
        )
        val session = ActiveSession.start(tutorialCards, "tutorial", equipment, Difficulty.BEGINNER)
        _session.value = session.copy(drawPile = tutorialCards, currentCard = null)
    }

    fun restoreIfNeeded(equipment: Equipment, difficulty: Difficulty, deckId: String) {
        val saved = store.load()
        val nowMs = System.currentTimeMillis()
        if (saved != null && !saved.isComplete && (nowMs - saved.startedAtMs) < 86_400_000L) {
            _isTutorial.value = false
            _session.value = saved
            _state.value = WorkoutState.CardFaceDown
        } else {
            store.clear()
            _session.value = null
        }
    }

    fun endEarly() {
        holdTimer.cancel()
        if (!_isTutorial.value) {
            _session.value?.let { store.save(it) }
        }
        _session.value = null
        _isTutorial.value = false
        _state.value = WorkoutState.Idle
    }

    fun reset() {
        holdTimer.cancel()
        store.clear()
        _session.value = null
        _isTutorial.value = false
        _state.value = WorkoutState.Idle
    }
}
