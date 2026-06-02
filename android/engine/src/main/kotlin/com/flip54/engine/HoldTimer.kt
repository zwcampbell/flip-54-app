package com.flip54.engine

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class HoldTimer(private val scope: CoroutineScope) {
    private val _remainingSeconds = MutableStateFlow(0)
    val remainingSeconds: StateFlow<Int> = _remainingSeconds

    var onExpired: (() -> Unit)? = null
    var onTick: ((Int) -> Unit)? = null

    private var expiryJob: Job? = null
    private var tickJob: Job? = null
    private var expiryTimeMs: Long? = null

    fun start(durationSeconds: Int, alreadyElapsedMs: Long = 0L) {
        cancel()
        val remainingMs = maxOf(0L, durationSeconds * 1000L - alreadyElapsedMs)
        _remainingSeconds.value = (remainingMs / 1000.0).let { kotlin.math.ceil(it).toInt() }
        expiryTimeMs = System.currentTimeMillis() + remainingMs

        expiryJob = scope.launch {
            delay(remainingMs)
            _remainingSeconds.value = 0
            onExpired?.invoke()
        }

        tickJob = scope.launch {
            while (isActive) {
                delay(1_000L)
                val expiry = expiryTimeMs ?: break
                val remaining = maxOf(0, ((expiry - System.currentTimeMillis()) / 1000.0).let {
                    kotlin.math.ceil(it).toInt()
                })
                _remainingSeconds.value = remaining
                onTick?.invoke(remaining)
            }
        }
    }

    fun cancel() {
        expiryJob?.cancel()
        tickJob?.cancel()
        expiryJob = null
        tickJob = null
        expiryTimeMs = null
    }

    fun remainingAtCancel(): Long {
        val expiry = expiryTimeMs ?: return 0L
        cancel()
        return maxOf(0L, expiry - System.currentTimeMillis())
    }
}
