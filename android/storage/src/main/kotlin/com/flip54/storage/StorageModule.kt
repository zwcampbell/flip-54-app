package com.flip54.storage

import android.content.Context
import com.flip54.storage.models.OnboardingStateDao
import com.flip54.storage.models.UserSettingsDao
import com.flip54.storage.models.WorkoutHistoryDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object StorageModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): Flip54Database =
        Flip54Database.create(context)

    @Provides
    fun provideUserSettingsDao(db: Flip54Database): UserSettingsDao = db.userSettingsDao()

    @Provides
    fun provideWorkoutHistoryDao(db: Flip54Database): WorkoutHistoryDao = db.workoutHistoryDao()

    @Provides
    fun provideOnboardingStateDao(db: Flip54Database): OnboardingStateDao = db.onboardingStateDao()

    @Provides
    @Singleton
    fun provideActiveSessionStore(@ApplicationContext context: Context): ActiveSessionStore =
        ActiveSessionStore(context)
}
