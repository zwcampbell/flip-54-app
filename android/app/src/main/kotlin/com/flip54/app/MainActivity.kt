package com.flip54.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.flip54.app.ui.Flip54App
import com.flip54.app.ui.HapticHelper
import com.flip54.app.ui.theme.Flip54Theme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        HapticHelper.init(this)
        setContent {
            Flip54Theme {
                Flip54App()
            }
        }
    }
}
