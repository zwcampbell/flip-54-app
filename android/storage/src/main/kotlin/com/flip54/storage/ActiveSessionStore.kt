package com.flip54.storage

import android.content.Context
import kotlinx.serialization.json.Json
import java.io.File

class ActiveSessionStore(context: Context) {
    private val file = File(context.filesDir, "active_session.json")
    private val json = Json { ignoreUnknownKeys = true }

    fun save(session: ActiveSession) {
        try {
            file.writeText(json.encodeToString(ActiveSession.serializer(), session))
        } catch (_: Exception) {}
    }

    fun load(): ActiveSession? = try {
        if (!file.exists()) null
        else json.decodeFromString(ActiveSession.serializer(), file.readText())
    } catch (_: Exception) { null }

    fun clear() {
        file.delete()
    }
}
