package com.flip54.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flip54.app.ui.theme.DS
import com.flip54.core.Card
import com.flip54.core.JokerVariant
import com.flip54.core.Prescription
import com.flip54.core.Suit
import com.flip54.core.SuitColor

@Composable
fun CardFaceView(
    card: Card,
    prescription: Prescription?,
    modifier: Modifier = Modifier
) {
    val shape = RoundedCornerShape(DS.Layout.cardCornerRadius)
    Box(
        modifier = modifier
            .size(DS.Layout.cardWidth, DS.Layout.cardHeight)
            .clip(shape)
            .background(DS.Colors.cardFace)
            .border(1.dp, DS.Colors.border, shape),
        contentAlignment = Alignment.Center
    ) {
        when (card) {
            is Card.Standard -> StandardCardFace(card, prescription)
            is Card.Joker    -> JokerCardFace(card)
        }
    }
}

@Composable
private fun StandardCardFace(card: Card.Standard, prescription: Prescription?) {
    val suitSymbol = card.suit.symbol
    val rankSymbol = card.rank.displaySymbol
    val suitColor  = if (card.suit.color == SuitColor.RED) Color(0xFFD32F2F) else Color(0xFF1A1A1A)

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Top-left corner
        Column {
            Text(rankSymbol, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = suitColor)
            Text(suitSymbol, fontSize = 18.sp, color = suitColor)
        }

        // Center content
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = suitSymbol,
                fontSize = 48.sp,
                color = suitColor
            )
            if (prescription != null) {
                Text(
                    text = when (prescription) {
                        is Prescription.Reps -> "${prescription.count}"
                        is Prescription.Hold -> {
                            val s = prescription.seconds
                            if (s >= 60) "${s / 60}:${(s % 60).toString().padStart(2, '0')}"
                            else "${s}s"
                        }
                    },
                    style = DS.Type.display(56f),
                    color = DS.Colors.bg
                )
                Text(
                    text = prescription.exercise.displayName.uppercase(),
                    style = DS.Type.sub(14f),
                    color = DS.Colors.bg.copy(alpha = 0.7f),
                    textAlign = TextAlign.Center
                )
            }
        }

        // Bottom-right corner (rotated)
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.End
        ) {
            Text(suitSymbol, fontSize = 18.sp, color = suitColor)
            Text(rankSymbol, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = suitColor)
        }
    }
}

@Composable
private fun JokerCardFace(card: Card.Joker) {
    val color = if (card.variant == JokerVariant.RED) Color(0xFFD32F2F) else Color(0xFF1A1A1A)
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("🃏", fontSize = 64.sp)
        Spacer(Modifier.height(8.dp))
        Text(
            text = "JOKER",
            style = DS.Type.display(28f),
            color = color
        )
    }
}

private val Suit.symbol: String get() = when (this) {
    Suit.HEARTS   -> "♥"
    Suit.SPADES   -> "♠"
    Suit.CLUBS    -> "♣"
    Suit.DIAMONDS -> "♦"
}
