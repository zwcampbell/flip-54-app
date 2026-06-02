package com.flip54.storage.models

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface UserSettingsDao {
    @Query("SELECT * FROM user_settings WHERE id = 1")
    fun observe(): Flow<UserSettingsEntity?>

    @Query("SELECT * FROM user_settings WHERE id = 1")
    suspend fun get(): UserSettingsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(settings: UserSettingsEntity)
}

@Dao
interface WorkoutHistoryDao {
    @Query("SELECT * FROM workout_history ORDER BY completedAt DESC")
    fun observeAll(): Flow<List<WorkoutHistoryEntity>>

    @Query("SELECT * FROM workout_history ORDER BY completedAt DESC")
    suspend fun getAll(): List<WorkoutHistoryEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(history: WorkoutHistoryEntity)
}

@Dao
interface OnboardingStateDao {
    @Query("SELECT * FROM onboarding_state WHERE id = 1")
    fun observe(): Flow<OnboardingStateEntity?>

    @Query("SELECT * FROM onboarding_state WHERE id = 1")
    suspend fun get(): OnboardingStateEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(state: OnboardingStateEntity)
}
