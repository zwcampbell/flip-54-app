package com.flip54.app.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.R

object DS {

    object Colors {
        val bg            = Color(0xFF111111)
        val bgRaised      = Color(0xFF191919)
        val bgCard        = Color(0xFF1A1A1A)
        val surface       = Color(0xFF101010)
        val border        = Color(0xFF2A2A2A)
        val borderSub     = Color(0xFF1E1E1E)
        val textPrimary   = Color(0xFFFEFEFE)
        val textSecondary = Color(0xFFD1CDC9)
        val textTertiary  = Color(0xFF666460)
        val cardFace      = Color(0xFFFEFEFE)
        val red           = Color(0xFFC8262C)
        val redSoft       = Color(0xFF2A1214)
        val gold          = Color(0xFFD1C4B1)
        val goldSoft      = Color(0xFF1E1B16)
        val goldLight     = Color(0xFFF0EAE0)
        val neutral       = Color(0xFFD1CDC9)
        val success       = Color(0xFF4CAF6E)
        val urgent        = Color(0xFFE8543C)
        val white         = Color(0xFFFEFEFE)
    }

    object Fonts {
        val barlow    = FontFamily(Font(R.font.barlow_condensed_extrabold, FontWeight.ExtraBold))
        val oswald    = FontFamily(Font(R.font.oswald_semibold, FontWeight.SemiBold))
        val ibmMono   = FontFamily(Font(R.font.ibm_plex_mono_medium, FontWeight.Medium))
    }

    object Type {
        fun display(size: Float = 50f) = TextStyle(
            fontFamily = Fonts.barlow,
            fontWeight = FontWeight.ExtraBold,
            fontSize = size.sp,
            color = Colors.textPrimary
        )
        fun sub(size: Float = 34f) = TextStyle(
            fontFamily = Fonts.oswald,
            fontWeight = FontWeight.SemiBold,
            fontSize = size.sp,
            color = Colors.textPrimary
        )
        fun mono(size: Float = 14f) = TextStyle(
            fontFamily = Fonts.ibmMono,
            fontWeight = FontWeight.Medium,
            fontSize = size.sp,
            color = Colors.textPrimary
        )
    }

    object Layout {
        val horizontalMargin: Dp = 24.dp
        val cornerRadius: Dp = 14.dp
        val buttonHeight: Dp = 56.dp
        val cardWidth: Dp = 280.dp
        val cardHeight: Dp = 392.dp
        val cardCornerRadius: Dp = 14.dp
    }
}
