package com.flip54.app.ui

sealed class Screen(val route: String) {
    data object Onboarding    : Screen("onboarding")
    data object Main          : Screen("main")
    data object ActiveWorkout : Screen("active_workout")
    data object Completion    : Screen("completion")
}

sealed class Tab(val route: String) {
    data object Workout : Tab("workout")
    data object History : Tab("history")
    data object Profile : Tab("profile")
}
