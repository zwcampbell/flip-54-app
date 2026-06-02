package com.flip54.core

import kotlinx.serialization.Serializable

@Serializable
enum class Exercise {
    // Lower body
    BODYWEIGHT_SQUAT, LUNGE, JUMPING_SQUAT, GOBLET_SQUAT,
    // Upper body
    PUSH_UP, HINDU_PUSH_UP, PULL_UP, BICEP_CURL, SHOULDER_PRESS, TRICEP_EXTENSION,
    // Total body
    BURPEE, MOUNTAIN_CLIMBER, THRUSTER,
    // Core
    SIT_UP, RUSSIAN_TWIST, WEIGHTED_SIT_UP,
    // Conditioning
    JUMPING_JACKS,
    // Holds (Aces)
    PUSH_UP_HOLD, DEAD_HANG, HOLLOW_BODY_HOLD, WALL_SIT, PLANK;

    val isHold: Boolean get() = when (this) {
        PUSH_UP_HOLD, DEAD_HANG, HOLLOW_BODY_HOLD, WALL_SIT, PLANK -> true
        else -> false
    }

    val displayName: String get() = when (this) {
        BODYWEIGHT_SQUAT  -> "Body-weight Squats"
        LUNGE             -> "Lunges"
        JUMPING_SQUAT     -> "Jumping Squats"
        GOBLET_SQUAT      -> "Goblet Squats"
        PUSH_UP           -> "Push-ups"
        HINDU_PUSH_UP     -> "Hindu Push-ups"
        PULL_UP           -> "Pull-ups"
        BICEP_CURL        -> "Bicep Curls"
        SHOULDER_PRESS    -> "Shoulder Press"
        TRICEP_EXTENSION  -> "Tricep Extensions"
        BURPEE            -> "Burpees"
        MOUNTAIN_CLIMBER  -> "Mountain Climbers"
        THRUSTER          -> "Thrusters"
        SIT_UP            -> "Sit-ups"
        RUSSIAN_TWIST     -> "Russian Twists"
        WEIGHTED_SIT_UP   -> "Weighted Sit-ups"
        JUMPING_JACKS     -> "Jumping Jacks"
        PUSH_UP_HOLD      -> "Push-up Hold"
        DEAD_HANG         -> "Dead Hang"
        HOLLOW_BODY_HOLD  -> "Hollow Body Hold"
        WALL_SIT          -> "Wall Sit"
        PLANK             -> "Plank"
    }
}
