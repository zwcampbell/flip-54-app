package com.flip54.storage

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.flip54.storage.models.*

@Database(
    entities = [UserSettingsEntity::class, WorkoutHistoryEntity::class, OnboardingStateEntity::class],
    version = 1,
    exportSchema = false
)
abstract class Flip54Database : RoomDatabase() {
    abstract fun userSettingsDao(): UserSettingsDao
    abstract fun workoutHistoryDao(): WorkoutHistoryDao
    abstract fun onboardingStateDao(): OnboardingStateDao

    companion object {
        fun create(context: Context): Flip54Database =
            Room.databaseBuilder(context, Flip54Database::class.java, "flip54.db")
                .fallbackToDestructiveMigration()
                .build()
    }
}
