import Flip54Core

// MAINTENANCE: Whenever an Exercise case is added or removed from
// Flip54Core/Exercise.swift, a corresponding entry MUST be added or removed
// here. The compiler will warn if any switch cases are missing.

struct FormGuide {
    let category: String
    let tempoLabel: String
    let cues: [String]
    let watch: [String]
}

enum FormGuideData {
    static func guide(for exercise: Exercise) -> FormGuide {
        switch exercise {

        // MARK: - Lower Body (Hearts ♥)

        case .bodyweightSquat:
            return FormGuide(
                category: "Hearts · Quads, Glutes, Hamstrings",
                tempoLabel: "3s DOWN  ·  1s HOLD  ·  1s UP",
                cues: [
                    "Feet shoulder-width apart, toes 5–15° outward. Arms forward or at chest.",
                    "Hinge hips back and down, keeping your chest tall and knees tracking over your toes.",
                    "Lower until thighs are parallel to the floor — or as deep as your mobility allows.",
                    "Drive through your heels to stand. Fully extend your hips at the top before the next rep.",
                ],
                watch: [
                    "Knees caving inward — push them out actively, following your second toe.",
                    "Forward trunk lean — keep your gaze forward and chest up throughout the descent.",
                ]
            )

        case .lunge:
            return FormGuide(
                category: "Hearts · Quads, Glutes, Hip Flexors",
                tempoLabel: "2s DOWN  ·  0s HOLD  ·  1s UP",
                cues: [
                    "Stand tall, feet hip-width apart. Step one foot forward 2–3 feet, keeping the torso upright.",
                    "Lower your back knee toward the floor, stopping 1–2 inches above it.",
                    "Front shin stays vertical; front knee tracks over the ankle, not past the toes.",
                    "Drive through the front heel to return. Alternate legs each rep.",
                ],
                watch: [
                    "Torso lurching forward — keep your chest proud and shoulders back throughout.",
                    "Front knee diving inward — brace the hip and actively push the knee out over the foot.",
                ]
            )

        case .jumpingSquat:
            return FormGuide(
                category: "Hearts · Quads, Glutes, Power",
                tempoLabel: "2s DOWN  ·  EXPLODE  ·  LAND SOFT",
                cues: [
                    "Feet shoulder-width, toes slightly out. Load into a squat through your heels.",
                    "Explode upward with maximum effort — swing your arms overhead to aid lift.",
                    "At peak height, pull toes up to engage the shin — this prepares the landing.",
                    "Land toe-to-heel, immediately absorbing with bent knees back into the squat position.",
                ],
                watch: [
                    "Stiff-knee landings — absorb with ankles, knees, and hips to protect your joints.",
                    "Caving knees on landing — drive knees out to match your squat stance on every touchdown.",
                ]
            )

        case .gobletSquat:
            return FormGuide(
                category: "Hearts · Quads, Glutes, Core",
                tempoLabel: "3s DOWN  ·  1s HOLD  ·  1s UP",
                cues: [
                    "Hold a dumbbell or kettlebell vertically at your chest, elbows pointing down.",
                    "Feet slightly wider than shoulder-width, toes 15–25° outward.",
                    "Sit down and back into the squat, using the weight as a counterbalance. Elbows brush inner thighs at the bottom.",
                    "Drive through the heels to stand, squeezing glutes at the top.",
                ],
                watch: [
                    "Arms dropping the weight away from the chest — keep it close throughout.",
                    "Heels rising off the floor — push through the full foot; widen your stance if needed.",
                ]
            )

        case .wallSit:
            return FormGuide(
                category: "Hearts · Quads, Glutes",
                tempoLabel: "HOLD STILL  ·  BREATHE  ·  ENDURE",
                cues: [
                    "Back flat against the wall, feet 2 feet out, shoulder-width apart.",
                    "Lower until thighs are parallel to the floor — 90° at both hips and knees.",
                    "Arms at sides or resting on thighs. Hands off your knees.",
                    "Breathe steadily. Maintain the position until the timer ends.",
                ],
                watch: [
                    "Hips higher than knees — this takes load off the quads; drop to true parallel.",
                    "Pushing through the wall with your back — the wall is for posture only; drive through your legs.",
                ]
            )

        // MARK: - Upper Body (Spades ♠)

        case .pushUp:
            return FormGuide(
                category: "Spades · Chest, Triceps, Core",
                tempoLabel: "2s DOWN  ·  1s HOLD  ·  1s UP",
                cues: [
                    "Hands shoulder-width apart, fingers spread, weight stacked over your palms.",
                    "Brace your core, squeeze glutes — body is one straight line from heels to crown.",
                    "Lower chest to within a fist of the floor; elbows track ~45° from the ribcage.",
                    "Drive through the palms. Full extension at the top, no shrugging the shoulders.",
                ],
                watch: [
                    "Hips sagging or piking — kills the line and robs the core of its work.",
                    "Elbows flared at 90° — strains the shoulders and produces a weak press.",
                ]
            )

        case .hinduPushUp:
            return FormGuide(
                category: "Spades · Chest, Shoulders, Triceps, Spine",
                tempoLabel: "FLOW  ·  PRESS  ·  EXTEND",
                cues: [
                    "Start in a downward dog: hips high, arms long, heels pressing back.",
                    "Sweep your nose toward the floor in a forward arc, leading with your chest.",
                    "Swoop upward into an upward dog at the top — hips near the floor, chest open.",
                    "Push back into downward dog by driving the hips skyward. That's one rep.",
                ],
                watch: [
                    "Nose grazing the floor instead of arcing forward — lead with the chest, not the head.",
                    "Collapsing the core at the bottom — maintain shoulder stability throughout the swoop.",
                ]
            )

        case .pullUp:
            return FormGuide(
                category: "Spades · Lats, Biceps, Rear Deltoids",
                tempoLabel: "1s UP  ·  1s HOLD  ·  2s LOWER",
                cues: [
                    "Grip the bar slightly wider than shoulder-width, palms facing away.",
                    "Brace your core and squeeze shoulder blades down and back before you pull.",
                    "Pull your chest toward the bar — lead with your elbows, not your hands.",
                    "Lower with control until arms are fully extended. Never drop from the top.",
                ],
                watch: [
                    "Kipping or swinging — momentum cheats the lats; keep every rep strict.",
                    "Chin barely clearing the bar — the chin must clear; chest-to-bar is the gold standard.",
                ]
            )

        case .bicepCurl:
            return FormGuide(
                category: "Spades · Biceps, Forearms",
                tempoLabel: "1s UP  ·  1s HOLD  ·  2s LOWER",
                cues: [
                    "Stand tall, dumbbells at sides, palms facing forward. Pin your elbows to your ribs.",
                    "Curl both weights upward by rotating your forearms — stop when biceps are fully contracted.",
                    "Hold the peak contraction for one count. Forearms vertical, wrists neutral.",
                    "Lower slowly under control for the full 2 seconds. Never drop the weight.",
                ],
                watch: [
                    "Swinging the torso — that momentum cheats the biceps; keep your trunk locked.",
                    "Elbows drifting forward at the top — the elbow stays pinned; only the forearm moves.",
                ]
            )

        case .shoulderPress:
            return FormGuide(
                category: "Spades · Deltoids, Triceps, Traps",
                tempoLabel: "1s UP  ·  1s HOLD  ·  2s LOWER",
                cues: [
                    "Stand or sit tall. Dumbbells at shoulder height, palms facing forward, elbows at 90°.",
                    "Press straight overhead until arms are fully extended. Don't flare the ribs.",
                    "Hold briefly at the top — biceps near your ears, core braced.",
                    "Lower in 2 seconds back to shoulder height. Maintain upright posture throughout.",
                ],
                watch: [
                    "Arching the lower back — brace the core before each rep; tuck the pelvis slightly.",
                    "Partial range of motion — full lockout overhead is the goal on every rep.",
                ]
            )

        case .tricepExtension:
            return FormGuide(
                category: "Spades · Triceps",
                tempoLabel: "1s UP  ·  1s HOLD  ·  2s LOWER",
                cues: [
                    "Stand or sit tall. Hold one dumbbell with both hands overhead, elbows framing your face.",
                    "Keep your upper arms vertical and still — only the forearms move.",
                    "Lower the dumbbell behind your head until forearms are horizontal.",
                    "Drive the weight back to full extension. Pause at the top before the next rep.",
                ],
                watch: [
                    "Elbows flaring wide — keep them close to your head throughout the entire rep.",
                    "Upper arms drifting forward — your elbows are the hinge; lock the upper arm vertical.",
                ]
            )

        case .pushUpHold:
            return FormGuide(
                category: "Spades · Chest, Triceps, Core, Shoulders",
                tempoLabel: "LOCK IN  ·  BREATHE  ·  ENDURE",
                cues: [
                    "Set up as for a push-up: hands under shoulders, body in a straight line.",
                    "Lower halfway down — elbows at ~90°. This is the hold position.",
                    "Brace your core, squeeze glutes, and drive your hands into the floor.",
                    "Breathe steadily. Maintain the half-down position until the timer ends.",
                ],
                watch: [
                    "Hips rising into a pike — your body must stay as one rigid plank throughout.",
                    "Arms shaking inward — actively drive the elbows toward each other to stabilize.",
                ]
            )

        case .deadHang:
            return FormGuide(
                category: "Spades · Lats, Grip, Shoulder Stability",
                tempoLabel: "BREATHE  ·  PACK SHOULDERS  ·  ENDURE",
                cues: [
                    "Grip the bar shoulder-width, palms facing away or neutral.",
                    "Hang fully extended — don't let the shoulders shrug up to your ears.",
                    "Pack your shoulder blades: pull them down slightly, away from your neck.",
                    "Breathe steadily. Let your spine decompress. Hold until the timer ends.",
                ],
                watch: [
                    "Passive shoulders — actively pack the shoulder blades; shrugging strains the joint.",
                    "Grip failing early — mentally shift focus from hand to hand; maintain even pressure.",
                ]
            )

        // MARK: - Total Body (Clubs ♣)

        case .burpee:
            return FormGuide(
                category: "Clubs · Full Body, Conditioning",
                tempoLabel: "FAST AND SMOOTH",
                cues: [
                    "Stand, then hinge and plant hands on the floor — jump or step feet back to push-up position.",
                    "Perform one push-up: lower your chest to the floor, then press back up.",
                    "Jump or step feet toward your hands, loading into a squat position.",
                    "Explode upward, reaching arms overhead. Land softly and flow immediately into the next rep.",
                ],
                watch: [
                    "Skipping the push-up — the chest must touch the floor for a full rep.",
                    "Landing stiff — absorb with bent knees on every jump to protect your joints.",
                ]
            )

        case .mountainClimber:
            return FormGuide(
                category: "Clubs · Core, Hip Flexors, Shoulders",
                tempoLabel: "LEFT + RIGHT = 1 REP",
                cues: [
                    "High plank: hands under shoulders, body straight from head to heels. Brace the core.",
                    "Drive one knee toward your chest — keep your hips level with your spine.",
                    "Return that foot, then immediately drive the other knee forward.",
                    "Alternate at a controlled pace. One left + one right counts as one rep.",
                ],
                watch: [
                    "Hips bouncing upward — stay in plank; your hips should never peak during the drive.",
                    "Weight falling back toward the feet — keep your shoulders stacked over your wrists.",
                ]
            )

        case .thruster:
            return FormGuide(
                category: "Clubs · Quads, Glutes, Deltoids, Triceps",
                tempoLabel: "SQUAT  ·  EXPLODE  ·  PRESS",
                cues: [
                    "Hold dumbbells at shoulder height, feet shoulder-width apart.",
                    "Squat down, keeping weights at your shoulders — thighs parallel or below.",
                    "Drive upward out of the squat with full power, using the momentum to initiate the press.",
                    "Press the dumbbells overhead to full lockout. Lower them as you descend into the next squat.",
                ],
                watch: [
                    "Pausing between the squat and press — it should be one fluid, continuous movement.",
                    "Elbows dropping during the squat — keep them high to protect wrists and shoulders.",
                ]
            )

        case .plank:
            return FormGuide(
                category: "Clubs · Core, Shoulders, Glutes",
                tempoLabel: "HOLD STILL  ·  BREATHE  ·  ENDURE",
                cues: [
                    "Forearms flat on the floor, elbows directly under shoulders. Feet hip-width apart.",
                    "Body forms a straight line from heels to crown — no sagging, no piking.",
                    "Brace your core as if bracing for a punch. Squeeze glutes and quads.",
                    "Breathe steadily. Push the floor away through your forearms. Hold for the full timer.",
                ],
                watch: [
                    "Hips sagging toward the floor — re-brace the core and drive hips up to the line.",
                    "Holding your breath — controlled, steady breathing is the secret to endurance.",
                ]
            )

        // MARK: - Core (Diamonds ♦)

        case .sitUp:
            return FormGuide(
                category: "Diamonds · Abs, Hip Flexors",
                tempoLabel: "1s UP  ·  0s HOLD  ·  2s DOWN",
                cues: [
                    "Lie on your back, knees bent, feet flat. Hands behind your head or crossed on your chest.",
                    "Curl your upper body upward by contracting the abs — avoid pulling on your neck.",
                    "Reach the top when your chest is upright or elbows near your knees.",
                    "Lower slowly under control for the full 2 seconds. Don't slam your back down.",
                ],
                watch: [
                    "Pulling the neck with your hands — let your abs do the lifting; hands just guide.",
                    "Feet lifting off the floor — anchor your heels or hook them under something if needed.",
                ]
            )

        case .russianTwist:
            return FormGuide(
                category: "Diamonds · Obliques, Abs",
                tempoLabel: "LEFT + RIGHT = 1 REP",
                cues: [
                    "Sit on the floor, knees bent, feet hovering or lightly planted. Lean back to ~45°.",
                    "Clasp your hands together or hold a light weight. Keep your chest tall.",
                    "Rotate your torso fully to one side — touch the floor beside your hip if mobile.",
                    "Rotate to the other side with control. One left + one right = one rep.",
                ],
                watch: [
                    "Rotating only your arms — the twist must come from the torso, not just the hands.",
                    "Rounding the spine — maintain the 45° lean and a tall chest throughout.",
                ]
            )

        case .weightedSitUp:
            return FormGuide(
                category: "Diamonds · Abs, Hip Flexors",
                tempoLabel: "1s UP  ·  0s HOLD  ·  2s DOWN",
                cues: [
                    "Lie on your back, knees bent, feet flat. Hold a dumbbell or plate at your chest.",
                    "Brace your abs and curl upward, holding the weight close to your body throughout.",
                    "Reach the top position — chest upright, weight still held at the chest.",
                    "Lower with full control for 2 seconds, letting the abs resist gravity the whole way.",
                ],
                watch: [
                    "Tossing the weight forward — the dumbbell stays at the chest; no throwing.",
                    "Dropping back fast — fight gravity on the way down; that eccentric work is half the rep.",
                ]
            )

        case .vSit:
            return FormGuide(
                category: "Diamonds · Abs, Hip Flexors",
                tempoLabel: "1s UP  ·  2s HOLD  ·  2s DOWN",
                cues: [
                    "Sit on the floor, knees bent, feet flat. Place hands beside your hips.",
                    "Lean back slightly and lift both feet — keep a tall spine, not a rounded one.",
                    "Straighten your legs to form a V with your torso. Arms reach forward for balance.",
                    "Hold the top for 2 seconds, then lower both legs slowly back to the floor.",
                ],
                watch: [
                    "Rounding the lower back — the V comes from your hip flexors, not a collapsed spine.",
                    "Collapsing your chest to reach the hold — keep the torso upright and long.",
                ]
            )

        case .bicycleCrunch:
            return FormGuide(
                category: "Diamonds · Obliques, Abs",
                tempoLabel: "LEFT + RIGHT = 1 REP",
                cues: [
                    "Lie on your back, hands lightly behind your head, knees bent and feet lifted.",
                    "Bring your right elbow toward your left knee while extending the right leg straight.",
                    "Rotate smoothly to the other side — left elbow to right knee, left leg extends.",
                    "Keep each rotation deliberate. One full cycle (both sides) = one rep.",
                ],
                watch: [
                    "Pulling your neck with your hands — keep elbows wide and let the torso do the rotating.",
                    "Rushing through reps — slow, controlled rotation targets the obliques; speed kills it.",
                ]
            )

        case .hollowBodyHold:
            return FormGuide(
                category: "Diamonds · Abs, Hip Flexors, Lower Back",
                tempoLabel: "BREATHE SHALLOW  ·  HOLD TIGHT  ·  ENDURE",
                cues: [
                    "Lie on your back. Press your lower back firmly into the floor — no gap.",
                    "Extend arms overhead and straighten legs. Lift shoulders and feet a few inches off the floor.",
                    "The shape is a shallow bowl — a gentle curve, not a flat plank.",
                    "Hold and breathe. If your lower back rises, bend your knees or raise your legs slightly.",
                ],
                watch: [
                    "Lower back arching off the floor — re-press it down before adding any height.",
                    "Holding your breath — stay with shallow, steady breaths; oxygen keeps the hold alive.",
                ]
            )

        // MARK: - Conditioning (Joker)

        case .jumpingJacks:
            return FormGuide(
                category: "Joker · Full Body, Conditioning",
                tempoLabel: "OUT → IN = 1 REP",
                cues: [
                    "Stand with feet together, arms at your sides.",
                    "Jump outward, simultaneously raising your arms overhead.",
                    "At the peak: feet are shoulder-width apart, hands nearly meeting overhead.",
                    "Jump feet back together, lowering arms. Keep knees soft on every landing.",
                ],
                watch: [
                    "Locking your knees on landing — stay light on your feet and absorb each touchdown.",
                    "Rushing without full range — arms should reach overhead and feet fully together each rep.",
                ]
            )
        }
    }
}
