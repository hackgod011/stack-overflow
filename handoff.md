# Handoff — Stack Overflow (Godot 4.4 Roguelike Deckbuilder)

## Goal we are working toward

Build "Stack Overflow" — a roguelike deckbuilder in Godot 4.4 where cards are stack operations (PUSH, POP, DUP, etc.). Implementation follows `implementation_plan.md` phase by phase, one task at a time, with a subagent-driven workflow: implementer subagent → spec reviewer → quality reviewer per task.

**Do NOT auto-start the next phase.** The plan says STOP and wait for Dharm's approval at each phase boundary.

---

## Current state of the project

### Branch
`feat/phase-2-graybox` — Phase 3 committed and pushed

### Phase status
| Phase | Status |
|-------|--------|
| Phase 0 — Setup & web export | ✅ COMPLETE, committed to main (SHA `df96ea1`) |
| Phase 1 — Data layer & autoloads | ✅ COMPLETE, committed (SHA `697ea01`) |
| Phase 2 — Graybox core loop | ✅ COMPLETE — browser verified + committed + pushed (SHA `96956fd`) |
| Phase 3 — First juice pass | ✅ **COMPLETE — browser verified + committed + pushed** |
| Phase 4 — Content depth | ⏳ **WAITING for Dharm approval** |

### Phase 3 task status
| Task | Description | Status |
|------|-------------|--------|
| 3.1 | `tween_presets.gd` utility | ✅ Done |
| 3.2 | Card hover animation | ✅ Done |
| 3.3 | Card movement tweens (deal, land, discard) | ✅ Done |
| 3.4 | HP and block bars tween | ✅ Done |
| 3.5 | Floating number popups | ✅ Done |
| 3.6 | Sound effects wired | ✅ Done (hover SFX removed — see deviations) |
| 3.7 | Background music | ✅ Done |
| 3.8 | Particle bursts on card execution | ✅ Done |
| 3.9 | Web export check | ✅ Browser-verified |
| 3.10 | Commit Phase 3 | ✅ Done |

### What the game does right now
- All Phase 2 features still work
- Card hover: lifts 32px, scales to 1.08 — uses lazy position capture to avoid overlap bug
- Card deal: animates from 0.8 scale to 1.0 on draw; audio plays per card
- Card play: scale-down land animation on arrival in stack zone; energy deducted immediately
- Stack zone: compact overlapping pile (0.62 scale, 14px diagonal offset, newest card on top at lower-right)
- **Clear button** on stack zone: returns all stacked cards to hand and refunds energy
- Execute Stack: guarded against empty stack (no sound/action)
- Discard: cards fade out over 0.3s at end of turn
- HP bars: both player and enemy tween smoothly over 0.4s on change
- Block label: pops/scales on gain
- Floating numbers: `-N` (red) on damage, `+N` (cyan) on block gain — drift up 60px, fade over 0.8s
- Particle bursts: 16 particles per card execution, tinted by card type
- SFX: card_play, card_draw, card_discard, block_gain, enemy_hurt, player_hurt, execute_stack, button_click, victory, defeat — all at -8 dB
- BGM: looping ambient music at -10 dB, starts on combat load, does not restart between turns
- Victory/defeat overlays unchanged from Phase 2

---

## Files changed in Phase 3

| File | Purpose |
|------|---------|
| `scripts/utils/tween_presets.gd` | NEW — shared easing constants + factory |
| `scripts/autoloads/audio_manager.gd` | REWRITTEN — fire-and-forget SFX, BGM loop, -8 dB SFX volume |
| `scripts/card/card_view.gd` | Hover animation, deal/land tweens, disable() method, lazy position capture |
| `scripts/card/hand.gd` | animate_deal flag, discard_all_animated(), DISCARD_DURATION const |
| `scripts/combat/stack_zone.gd` | Scaled stacked display (0.62), Clear button, empty-execute guard, clear_requested signal |
| `scripts/combat/combat_scene.gd` | FloatingNumber + CardBurst spawning, clear signal handler, all SFX wiring, BGM call, HP bar tween |
| `scripts/combat/enemy.gd` | HP bar tween on take_damage |
| `scripts/ui/floating_number.gd` | NEW — floating label popup |
| `scripts/ui/card_burst.gd` | NEW — GPUParticles2D burst, color by card type |
| `scenes/combat/combat_scene.tscn` | HPBar added to PlayerPanel |
| `scenes/combat/enemy.tscn` | HPBar added |
| `scenes/combat/stack_zone.tscn` | CardSlots → Control (clip_contents=true), ButtonRow with Clear + Execute |
| `scenes/ui/floating_number.tscn` | NEW — Label scene, z_index=100 |
| `scenes/ui/card_burst.tscn` | NEW — GPUParticles2D scene, z_index=50 |
| `assets/audio/sfx/*.ogg/.mp3` | 11 SFX files |
| `assets/audio/music/bgm_loop.wav` | BGM loop |
| `assets/fonts/*.ttf` | JetBrainsMono, PressStart2P (available for Phase 5) |

---

## Deviations from spec (Phase 3)

| Spec item | Deviation | Reason |
|-----------|-----------|--------|
| Task 3.6: card_hover SFX triggers on mouse_entered | Removed — hover sound NOT triggered | Dharm found it annoying and distracting during card selection |
| Stack zone visual | Added Clear button + stacked card pile view | User-requested; spec left visual design open |

---

## All bugs found and fixed (all sessions)

| Bug | Root cause | Fix applied |
|-----|-----------|-------------|
| Cards showing TITLE/0/Description in browser | `set_card_data()` called before `add_child()` → @onready labels null | Swapped order: add_child first, then set_card_data |
| Clicking cards did nothing | Background ColorRect default `mouse_filter=STOP` intercepts clicks | Added `mouse_filter = 2` (IGNORE) to Background in card_view.tscn |
| Browser serving stale export | Browser caching old .pck | Open in incognito; or hard-refresh Ctrl+Shift+R |
| `emit_signal("enemy_died")` in enemy.gd | Godot 3 API | Changed to `enemy_died.emit()` |
| `for i in 5` unused var warning | GDScript 4 convention | Renamed to `_i` |
| `seed` param shadowing built-in | Shadows `seed()` global | Renamed to `run_seed` |
| `get_next_attack()` no bounds check | Crashes if attack_pattern empty | Added guard |
| Python server via Bash fails | Bash can't find python on this machine | Use PowerShell to start Python server |
| `Co-Authored-By: Claude` in commits | Default commit template | Always omit; git history clean |
| Card hover overlap bug | `_original_position = position` captured in `_ready()` before HBoxContainer finishes layout → all cards got position (0,0) → hovered to same spot | Lazy capture on first `mouse_entered` (guaranteed post-layout) |
| `to_local()` parse error on Control | `to_local()` is Node2D only; CombatScene extends Control | Use `global_pos` directly (viewport origin = control origin since scene fills viewport) |
| Stack cards going out of bounds | `view.size` doesn't shrink a Control below its scene-defined dimensions | Use `view.scale = Vector2(0.62, 0.62)` instead; add `clip_contents = true` on CardSlots |
| Stack direction inverted | Depth formula `n-1-i` put newest card at top-left; spec+user wants newest at bottom-right | Changed to `depth = i` so newest child has largest offset and highest z_index |
| Execute Stack fires SFX with empty stack | No guard in `_on_execute_pressed()` | Added `if _stack.is_empty(): return` |

---

## Next step to take

### Phase 4 — Content depth (WAITING FOR DHARM APPROVAL)
Tasks per implementation_plan.md:
- **4.1** Expand CardEffect library: swap, add, multiply, loop, if_positive, damage_per_stack_value, apply_vulnerable
- **4.2** Status effects system: VulnerableStatus, WeakStatus (tick down at end of turn)
- **4.3** Card library — **ASK DHARM to review 20-card list before creating .tres files**
- **4.4** Enemy library — **ASK DHARM to confirm enemy designs before building**
- **4.5** Run map (Slay-the-Spire style, 15 floors, seeded)
- **4.6** Reward screen (3 random cards after fight, pick one)
- **4.7** Shop screen (3 cards + 2 tools for gold)
- **4.8** Main menu & game over screen
- **4.9** Web export check
- **4.10** Commit Phase 4

**Critical design gates before coding 4.3 and 4.4:** Dharm must approve the card list and enemy designs. Do not invent balance values.

Do NOT start Phase 4 without explicit "go ahead" from Dharm.

---

## Important workflow rules to remember

- **One task at a time.** Never combine tasks.
- **Subagent-driven:** implementer → spec reviewer → quality reviewer per task. Fix issues between reviews. Only mark complete when quality reviewer says APPROVED.
- **Do NOT modify:** `guide.md`, `implementation_plan.md`, `do_not_do.md`, `setup.md`
- **No direct randi()/randf() calls** — always use `RNG` autoload
- **No gameplay logic in view scenes** — CardView, Hand, StackZone are display/input only
- **After every headless Godot run**, check `project.godot` — it sometimes drops `window/stretch/aspect="keep"`
- **Godot executable:** `C:\Users\DHARM\Godot\Godot_v4.4-stable_win64.exe`
- **Headless export:** `cd` to project root first, then `& "godot.exe" --headless --export-release "Web" "exports/web/index.html"`
- **Thread support:** must be OFF in export_presets.cfg (`variant/thread_support=false`)
- **Python server:** start via PowerShell (`python -m http.server 8000` from `exports/web/`), NOT Bash
- **Browser verify:** always test in incognito to avoid cache issues
- **No Co-Authored-By: Claude** in any commit message — keep git history clean

## Autoloads registered in project.godot
- `RNG` → `scripts/autoloads/rng.gd`
- `GameManager` → `scripts/autoloads/game_manager.gd`
- `AudioManager` → `scripts/autoloads/audio_manager.gd`

## GitHub
- Repo: https://github.com/hackgod011/stack-overflow
- Main branch: `main` (always shippable)
- Active branch: `feat/phase-2-graybox` (contains Phase 2 + Phase 3)
- Git history: clean — no Co-Authored-By in any commit
