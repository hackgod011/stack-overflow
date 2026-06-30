# Handoff — Stack Overflow (Godot 4.4 Roguelike Deckbuilder)

## Goal we are working toward

Build "Stack Overflow" — a roguelike deckbuilder in Godot 4.4 where cards are stack operations (PUSH, POP, DUP, etc.). Implementation follows `implementation_plan.md` phase by phase, one task at a time, with a subagent-driven workflow: implementer subagent → spec reviewer → quality reviewer per task.

**Do NOT auto-start the next phase.** The plan says STOP and wait for Dharm's approval at each phase boundary.

---

## Current state of the project

### Branch
`feat/phase-2-graybox` — Phases 0–7 complete; **enemy visuals + persistence/resume session is UNCOMMITTED in the working tree** (see next section)

### Phase status
| Phase | Status |
|-------|--------|
| Phase 0 — Setup & web export | ✅ COMPLETE, committed to main (SHA `df96ea1`) |
| Phase 1 — Data layer & autoloads | ✅ COMPLETE, committed (SHA `697ea01`) |
| Phase 2 — Graybox core loop | ✅ COMPLETE — browser verified + committed + pushed (SHA `96956fd`) |
| Phase 3 — First juice pass | ✅ COMPLETE — browser verified + committed + pushed (SHA `0f4238c`) |
| Phase 4 — Content depth | ✅ COMPLETE — committed (SHA `a1b18eb`) |
| Phase 5 — Art & polish | ✅ COMPLETE — all tasks done + extended post-phase visual polish (SHA `2d7083f`) |
| Phase 6 — Web optimization | ✅ COMPLETE — committed (SHA `53b868b`) |
| Post-phase gameplay fixes | ✅ COMPLETE — committed (SHA `92c7db1`) |
| Phase 7 — Meta-features (optional) | ✅ COMPLETE — committed (SHA `84020dd`) |
| **Enemy visuals + persistence/resume** | ⚠️ **DONE but UNCOMMITTED** — headless-compiled + web-exported; needs browser verify + commit |
| **Themed enemy art + bigger sprites** | ⚠️ **DONE but UNCOMMITTED** (this session) — placeholder pack replaced with themed single-frame sprites, backgrounds removed, sizes bumped to medium-large. Browser-verified by Dharm (infinity holes + axis lines fixed). Needs commit. |

---

## ⚠️ LATEST SESSION (uncommitted) — Themed enemy art + bigger sprites

All in the working tree, **not committed**. Headless-compiled (exit 0) + web-exported (exit 0).
Browser-verified by Dharm. Builds on the prior uncommitted session below.

### 1. Themed enemy art (replaced the Fantasy Battle Pack placeholders)
- Dharm provided 9 themed sprite **sheets** (one per enemy) — these were **raw 4×2 grids of one
  character on a baked-in opaque checkerboard background** (NOT real transparency), irregular sizes
  (~327×137), and the_compiler's last cell held a "Scale/Size" annotation graphic. Earlier the wrong
  grid (`hframes=4,vframes=7`) made one "frame" capture a block of mini-characters → a **swarm of 4**.
- **Processing pipeline (Python/Pillow, run by hand this session — NOT saved as a repo script yet):**
  1. **Border flood-fill key** — treat background = any **neutral** pixel (max−min ≤ 24) with
     brightness ≥ 110, flood from the borders (8-connected). This crosses the white/gray checker tiles
     AND the darker ~127 grid lines between them, while colored/dark character pixels stop it and
     interior lights (kernel_panic "CPU" text, armor highlights) stay protected by connectivity.
  2. **Fill enclosed holes** — clear enclosed background-colored regions **only if large (≥18px)**
     → removes the white centers inside the infinity, keeps small enclosed lights like the CPU text.
  3. **Peripheral thin-line erosion** — the artist baked a dark navy **graph-axis** (right + bottom
     [+ left] lines, corner dots, motion arrows) into every cell. Erode **thin (≤2px) runs only in
     the outer 3px band** → strips axes/arrows even when they touch the artwork (boss, stack_overflow),
     while thick edge art (slime base, machine base) and central thin art (race_condition streaks,
     segfault shards) survive. Then drop tiny specks (≤4px) and autocrop + 4px pad.
- Output = **9 single-frame transparent PNGs** in `assets/sprites/enemies/<name>.png`. Raw sheets
  backed up to `assets/sprites/enemies/_raw/` (**excluded from export** via `export_presets.cfg`).
- `.tres` rewired: each `sprite_sheet` → new PNG (new uid + path), **`sheet_hframes=1`,
  `sheet_vframes=1`, `idle_frames=PackedInt32Array(0)`** (single frame → swarm now structurally
  impossible). The_compiler's `phase_tints` (white→orange→red) still modulate the new machine sprite.

### 2. Bigger, "medium-large / threatening" sizes
- Native frames came out ~55–88px after autocrop, so scales were tuned to land at medium-large:
  **standard `sprite_scale=3.0`, elite (kernel_panic, stack_overflow) `3.6`, boss (the_compiler) `4.4`.**
- On-screen heights roughly: standard ~180–200px, elite ~265px, **boss ~330px (~46% of 720)**.
  infinite_loop is wide-and-short (≈252×132) because the symbol is naturally wide — bump its scale
  if it ever feels small. Sprite still anchored at local y≈250 (renders behind the translucent
  StackZone); enemy labels draw on top so they stay readable.

### 3. Known / accepted
- Bosses are **single-frame** now (no idle frame-cycling) — but they still **lunge on attack,
  recoil on hit, and fade on death** (those are tweens in `enemy.gd`, not sheet frames).
  To add a breathing idle later: repack the multiple sheet frames into a clean uniform horizontal
  strip (exclude the_compiler's annotation cell) and set `hframes=N/idle_frames=[...]`.
- kernel_panic keeps small "error dialog" icons around the CPU — those are **intentional theme art**, kept.

---

## ⚠️ PRIOR SESSION (uncommitted) — Enemy visuals + persistence/resume

All of the below is in the working tree, **not yet committed**. Validated by clean headless
compile (`--headless --editor --quit`, exit 0) + successful web export (`exports/web/`).
Behavior NOT yet browser-verified by Dharm. Web build was rebuilt; test at
`http://localhost:8080` (use a **normal window** for persistence — incognito wipes `user://`).

### 1. Enemy/boss sprites (was: flat red ColorRect)
- Enemies now render an **animated sprite** in the center arena. Data-driven from each `.tres`
  so themed art swaps in later with **zero code change** ("hybrid" placeholder approach).
- ~~Placeholder art = **Fantasy Battle Pack** (medieval)~~ **SUPERSEDED** by themed art in the
  LATEST SESSION above — `.tres` now point at `assets/sprites/enemies/*.png`. The Fantasy pack under
  `Resources/UI Elements & Icons/Fantasy Battle Pack/` is no longer referenced.
- `EnemyData` gained: `sprite_sheet`, `sheet_hframes`/`sheet_vframes`, `idle_frames`,
  `idle_frame_time`, `sprite_scale`, `phase_tints`. All 9 enemy `.tres` configured.
  The Compiler = Wizard @ 2.8× with phase tints (white→orange→red across its 3 phases).
- `enemy.gd`: idle loop (Timer), `play_attack()` = awaitable **lunge toward player**
  (universal "enemy attacked" beat — NOT dependent on a hand-authored attack animation),
  hit recoil, death fade, `get_sprite_global_center()` so damage/heal numbers pop on the sprite.
- `combat_scene.gd`: `await _enemy.play_attack()` on the enemy turn + `_spawn_impact()` plays
  `CriticalHit.png` over the player HP bar. Sprite renders at y≈250 BEHIND the transparent
  StackZone (so STACK/DATA labels stay readable); EnemyArea kept at 140px (taller broke layout).
- **Scope:** visuals for the existing 9 enemies only (FIGHT pool stays random). NOT 15 unique.
  To swap to themed art: drop a PNG in `assets/sprites/enemies/`, point the enemy `.tres`
  `sprite_sheet` at it, set grid/idle/scale fields.

### 2. Combat fixes
- **End Turn was off-screen**: the taller enemy area + Hand(190) + StackZone(~318) overflowed
  720px. Fixed by keeping EnemyArea at 140 and rendering the sprite as a non-layout overlay.
- **Auto-end-turn**: when the player has no playable move (no affordable card + empty stack),
  the enemy turn fires automatically after `AUTO_END_DELAY = 8.0s`. Any action reschedules it
  (token-guarded `_maybe_schedule_auto_end()`).
- **Buttons only clickable on top half** (Flee, Quit, every screen): ROOT CAUSE = the
  AchievementManager toast `PanelContainer` (alpha 0, on a layer=128 CanvasLayer in every scene,
  anchored top-right) had default `mouse_filter = STOP` → invisible click-blocker over the bottom
  of top-right buttons. Fixed: `mouse_filter = IGNORE` on the toast panel + its children.

### 3. Persistence — card collection + run history + RESUME
- `CollectionManager` autoload (`scripts/autoloads/collection_manager.gd`, registered after
  GameManager) → `user://collection.json`. **Per-run "discovered" model** (user's choice):
  starters always discovered; reward-pick + shop-buy discover a card; **`reset_to_starters()`
  on every New Run** (collection reflects only the CURRENT run, not lifetime). Card library shows
  only discovered cards + `X / 22` count. Resume does NOT reset.
- **Run history** is permanent. Recording unified into `GameManager.record_current_run(won)`
  (guarded by `run_recorded`+`is_run_active`; also `clear_saved_run()`). Called on game-over
  (win/loss) and on main-menu **Abandon Run** (loss). The history screen also shows the
  in-progress run as a live cyan **ACTIVE** row via `GameManager.get_active_run_summary()`
  (in-memory if loaded, else peeks the save file) — converts to a recorded row on conclusion.
- **Resume run**: run state persists to `user://current_run.json` (survives reload).
  `save_run()` checkpoints on every map entry + on Quit; `load_saved_run()` restores deck
  (by card id via `get_card_by_id`) + scalars + seed; `has_saved_run()`/`clear_saved_run()`.
  Map **Quit to Menu** now = "save & exit, resumable" (NO longer records a loss). Main menu shows
  **Resume Run** + **Abandon Run** buttons only when `has_saved_run()`. New Run clears any saved
  run + resets collection. Resume drops you at the MAP (between floors), not mid-combat.

### Persistence decision (local-first; Supabase deferred)
- User wants eventual multi-user accounts. Verdict: **Supabase** is the only sane fit for a Godot
  WASM web client (Postgres + PostgREST + GoTrue auth + RLS over HTTP); **MongoDB ruled out**
  (needs a custom backend). Built local-first now; structured so `discovered`/history could sync
  to Supabase later. **Not started — deferred.**
- KEY GOTCHA the user hit: web `user://` = browser **IndexedDB** keyed to origin (`localhost:8080`)
  + profile. Survives **server restart** (python http.server stores nothing). Incognito wipes it
  on session end. So: test persistence in a NORMAL window; "reset for testing" = New Run / clear
  site data / incognito — NOT restarting the server.

---

## What the game does right now

**Full run loop works end-to-end:**
- Main menu → "New Run" → Run Map → Floor combat → Reward screen → Map → Shop (floors 6, 11) → Elite (floors 9, 12) → Boss (floor 15) → Game Over / Victory

**Visual state:**
- All 22 cards display marcus_darius pixel-art frames (color-coded by type: blue=VALUE, green=OPERATION, yellow=FLOW, red=damage EFFECT, purple=utility EFFECT)
- Each card has a relevant icon in the art area
- RARE cards have holographic rainbow shimmer overlay (HoloOverlay ColorRect)
- Terminal-green branded loading screen (custom HTML shell) with og:/Twitter meta tags
- Combat background: animated green dot-grid drifting upward against dark teal
- Victory/Defeat overlays, floating damage numbers, screen shake, card launch choreography all working

**Combat mechanics (fully working):**
- Stack mechanic: PUSH values → OPERATE → STRIKE deals 6 + sum(runtime_stack) damage
- **Runtime stack now visible**: `DATA: [5, 3]` label in StackZone updates live after each card animates
- Cards execute step-by-step: each card animates, runtime_stack display updates, then next card
- LOOP/IF/BREAK flow control works correctly (logic resolved before animation, snapshots drive display)
- 3 energy per turn, 5 card draw at turn start
- Status effects: Vulnerable (+50% damage taken), Weak (-25% damage dealt)
- **HP restored to full after each floor win** (on "Continue" press from Victory overlay)
- "Flee Floor" button top-right

**Run Map:**
- 15 floors: 8 FIGHT, 2 ELITE, 2 SHOP, 1 BOSS (The Compiler), 2 FIGHT
- `►` green arrow marks the one unlocked floor; all future floors locked, cleared floors dimmed
- Sequential unlock — must clear current floor to open next

**Boss — The Compiler (3-phase fight):**
| Phase | Trigger | Attack pattern | Status inflicted | Special |
|-------|---------|---------------|-----------------|---------|
| Phase 1 | Start | [8, 12, 8, 20] | +VUL | Ignores hits < 5 dmg |
| Phase 2 | ≤75% HP (90 HP) | [10, 15, 10, 24] | +VUL | Same armor |
| Phase 3 | ≤40% HP (48 HP) | [12, 18, 12, 28] | +VUL +WEAK 2 | Heals 5/turn, same armor |
- Phase transitions show "PHASE 2!" / "ENRAGED!" floating popup + screen shake
- EnemyData resource has full phase2/phase3 fields available for any enemy to use

**Enemy intent display:**
- 0-damage turns (e.g. Segfault's charge-up pattern [0,0,0,22]) now show `CHARGING...` instead of `Next: 0`
- +VUL / +WEAK suffixes shown in intent when enemy inflicts statuses

**Enemy library (9 enemies, all have distinct mechanics):**
| Enemy | HP | Pattern | Special |
|-------|-----|---------|---------|
| Null Pointer | 30 | [6, 8, 6] | — |
| Infinite Loop | 45 | [4,4,4,4,4] | Heals 3/turn |
| Segfault | 30 | [0, 0, 0, 22] | Charging mechanic |
| Race Condition | 28 | [3,11,3,11...] | Alternating light/heavy |
| Memory Leak | 40 | [2,4,6,8,10] | Escalating damage |
| Off-by-One | 22 | [5,7,5,7] | +VUL on player |
| Kernel Panic (elite) | 60 | [9,9,16] | +VUL 2 |
| Stack Overflow (elite) | 70 | [7,7,7,14] | +WEAK 2 |
| The Compiler (boss) | 120 | 3-phase (see above) | Armor + phase transitions |

**Reward screen:** 3 random cards (60% COMMON / 30% UNCOMMON / 10% RARE) shown as full CardViews, pick one or skip

**Shop screen:** 3 cards for sale, 2 "Remove a card" slots

**Card library (22 cards):** VALUE (7), OPERATION (5), FLOW (4), EFFECT (6)

**Phase 7 meta features (all working):**
- **Settings screen** — 3 volume sliders (Master/SFX/Music), Reduce Motion toggle, Show Seed Input toggle; Save navigates to main menu; Back reverts changes without saving; live audio preview on slider drag
- **Run history screen** — last 10 runs, green for wins / red for losses; shows floor, enemies defeated, total damage, seed, duration (m:ss), date
- **Card library screen** — all 22 cards displayed in 6-column grid (full-size CardViews), scrollable
- **Achievements (8 total):** `first_victory`, `compiler_slain`, `stack_of_10`, `perfect_floor`, `damage_dealer` (100 dmg single hit), `deck_collector` (20+ cards), `gold_hoarder` (200+ gold), `speedrun` (win in < 5 min); toast notification (top-right, 3s) via CanvasLayer layer=128 on AchievementManager autoload — visible in every scene

**Web build:**
- Total: 63.58 MB (WASM 50.88 MB fixed + PCK 13.56 MB)
- Baseline was 66.59 MB — saved 3 MB via OGG audio + unused sprite exclusion
- `perf_baseline.md` written with full audit results
- Browser testing (cross-browser) still requires **manual verification by Dharm**:
  - Start server: `Start-Process python -ArgumentList "-m","http.server","8080" -WorkingDirectory "exports/web" -WindowStyle Minimized`
  - Open `http://localhost:8080` in **incognito** tab (Chrome, Firefox, Chrome Android)

---

## Phase 7 — what was done (SHA `84020dd`)

| Task | What was implemented |
|------|---------------------|
| 7.1 Settings | `SettingsManager` autoload persists to `user://settings.cfg` via ConfigFile. `settings_screen.tscn/.gd` with 3 HSliders + 2 CheckButtons. Back reverts originals (no disk read). Live slider preview calls `AudioManager.update_music_volume()`. `AudioManager` now reads `SettingsManager.sfx_volume` / `music_volume` per play. |
| 7.2 Run history | `HistoryManager` autoload saves last 10 runs to `user://run_history.json`. `GameManager.run_start_time` set at `start_new_run()`; duration computed at game-over. `game_over_screen.gd` calls `HistoryManager.record_run(...)`. `run_history_screen.tscn/.gd` renders color-coded rows. |
| 7.3 Card library | `card_library_screen.tscn/.gd` — GridContainer (6 cols) inside ScrollContainer. `_build_grid()` instantiates full-size CardViews for all 22 cards (`add_child` first, then `set_card_data`, then `disable()`). |
| 7.4 Achievements | `AchievementManager` autoload with CanvasLayer layer=128 for toast. 8 achievements in dict. `combat_scene.gd` triggers: `stack_of_10`, `perfect_floor`, `damage_dealer`, `compiler_slain`, `gold_hoarder`. `game_over_screen.gd` triggers: `first_victory`, `speedrun`, `deck_collector`. `_shake_screen()` gates on `SettingsManager.reduce_motion`. |
| 7.5 Main menu wired | `GameManager` has `SETTINGS_SCENE`, `HISTORY_SCENE`, `CARD_LIBRARY_SCENE` consts. `main_menu.gd` has `_on_settings_pressed`, `_on_history_pressed`, `_on_library_pressed`. Seed input row shown/hidden via `SettingsManager.show_seed_input`. |

### New files (Phase 7)
| File | Description |
|------|-------------|
| `scripts/autoloads/settings_manager.gd` | Persists volumes + toggles to `user://settings.cfg`; `apply_audio()` sets AudioServer bus 0 |
| `scripts/autoloads/history_manager.gd` | Records/loads last 10 runs to `user://run_history.json` |
| `scripts/autoloads/achievement_manager.gd` | 8 achievements; CanvasLayer toast overlay; persists to `user://achievements.json` |
| `scripts/ui/settings_screen.gd` | Settings screen controller |
| `scripts/ui/run_history_screen.gd` | Run history list controller |
| `scripts/ui/card_library_screen.gd` | Card library grid controller |
| `scenes/ui/settings_screen.tscn` | uid: `uid://settings_screen_scene` |
| `scenes/ui/run_history_screen.tscn` | uid: `uid://run_history_screen_scene` |
| `scenes/ui/card_library_screen.tscn` | uid: `uid://card_library_screen_scene` |

### Modified files (Phase 7)
| File | Change |
|------|--------|
| `project.godot` | Added SettingsManager, HistoryManager, AchievementManager autoloads |
| `scripts/autoloads/game_manager.gd` | Added scene consts; `total_damage_dealt`, `run_start_time` vars; reset in `start_new_run()` |
| `scripts/autoloads/audio_manager.gd` | `play_sfx/music()` reads SettingsManager volumes; `update_music_volume()` for live preview |
| `scripts/combat/combat_scene.gd` | Achievement triggers; `_took_damage_this_floor` flag; `reduce_motion` gate on shake |
| `scripts/ui/game_over_screen.gd` | Calls `HistoryManager.record_run()`; triggers `first_victory`, `speedrun`, `deck_collector` |
| `scripts/core/main_menu.gd` | New button handlers; seed row toggle; `show_seed_input` support |
| `scenes/core/main_menu.tscn` | SeedRow (hidden VBox), SettingsButton, HistoryButton, LibraryButton added to MenuVBox |

---

## Phase 6 — what was done (SHA `53b868b`)

| Task | What was implemented |
|------|---------------------|
| 6.1 Baseline | `perf_baseline.md` written: 66.59 MB total, PCK 16.96 MB, WASM 50.88 MB |
| 6.2 Asset audit | `bgm_loop.wav` (20 MB) → OGG (2 MB); 3 MP3 SFX → OGG; export `exclude_filter` strips unused `sprites/ui/`, `sprites/icons/`, unused kerenel_Cards 22–83 |
| 6.3 Code opt | AudioStreamPlayer pool (6 slots); CardBurst static shared texture; FloatingNumber + CardBurst pools (8+6 slots) in CombatScene |
| 6.4 Mobile UI | Hover disabled via `DisplayServer.is_touchscreen_available()`; `InputEventScreenTouch` in card_view; all buttons ≥ 44px (EndTurn, Execute, Clear, Flee, map Enter) |
| 6.5 Cross-browser | No print() in hot paths; OGG audio; WebGL2; threads OFF |
| 6.6 HTML shell | Terminal-green branded loading screen in `assets/web_shell/custom_shell.html`; og:title/description/image + Twitter card meta tags |
| 6.7 Commit | SHA `53b868b` — `export_presets.cfg` now tracked in git (removed from .gitignore) |

## Post-phase gameplay fixes (SHA `92c7db1`)

| Fix | Details |
|-----|---------|
| Runtime stack visible | `DATA: [5, 3]` label in StackZone, updated live after each card animation. Resolver now records snapshots in `context["_snapshots"]`; logic runs first, animation plays with snapshots. LOOP/IF/BREAK still correct. |
| HP restored after floor win | `GameManager.player_hp = GameManager.player_max_hp` in `_on_vic_continue_pressed()` |
| Boss 3-phase | `EnemyData` has phase2/phase3 fields; `Enemy._check_phase_transition()` fires after each `take_damage()`; pattern/stats switch automatically; "PHASE 2!" / "ENRAGED!" popup shown |
| CHARGING display | `enemy.gd _update_labels()` shows `CHARGING...` when `get_next_attack() == 0` |
| Phase-aware enemy API | `enemy.get_heal_per_turn()`, `get_inflicts_vulnerable()`, `get_inflicts_weak()` return values for the active phase; combat_scene uses these instead of `data.*` directly |

---

## Files changed in Phase 6 + post-phase fixes

| File | Change |
|------|--------|
| `assets/audio/music/bgm_loop.ogg` | Converted from WAV (20 MB → 2 MB) |
| `assets/audio/sfx/button_click.ogg`, `defeat.ogg`, `victory.ogg` | Converted from MP3 |
| `assets/web_shell/custom_shell.html` | Branded loading screen + og/Twitter meta |
| `export_presets.cfg` | Added exclude_filter, custom_html_shell; now tracked in git |
| `perf_baseline.md` | Build size audit at Phase 6 start |
| `scripts/autoloads/audio_manager.gd` | OGG refs; SFX pool (6 AudioStreamPlayers) |
| `scripts/card/card_view.gd` | Hover disabled on touch; InputEventScreenTouch support |
| `scripts/ui/floating_number.gd` | Pool-aware: `show_popup()` + `popup_finished` signal instead of auto-free |
| `scripts/ui/card_burst.gd` | Static shared texture; `emit_burst()` + `burst_finished` signal instead of auto-free |
| `scripts/combat/combat_scene.gd` | Node pools (_popup_pool, _burst_pool); HP restore; phase-aware enemy API calls; `_on_enemy_phase_changed` handler |
| `scripts/combat/stack_zone.gd` | `update_runtime_stack_display()` + `clear_runtime_stack_display()` |
| `scenes/combat/stack_zone.tscn` | Added RuntimeStackLabel node |
| `scripts/systems/stack_resolver.gd` | `resolve()` now records `context["_snapshots"]` (runtime_stack state after each card) |
| `scripts/resources/enemy_data.gd` | Added phase2/phase3 fields (hp_fraction, attack_pattern, inflicts_*, heal_per_turn, min_damage_threshold) |
| `scripts/combat/enemy.gd` | `_check_phase_transition()`, `_get_active_attack_pattern()`, `_get_active_stat()`; phase-aware getters; `phase_changed` signal; CHARGING display; phase suffix in name label |
| `data/enemies/the_compiler.tres` | Added phase2 (≤75% HP) and phase3 (≤40% HP) data |
| `scenes/combat/combat_scene.tscn` | EndTurnButton min-height 44px; FleeButton enlarged to 44px |
| `scenes/combat/stack_zone.tscn` | Execute + Clear buttons min-height 44px |
| `scripts/map/run_map.gd` | Enter button min-size 100×44 |

---

## All bugs found and fixed (all sessions)

| Bug | Root cause | Fix applied |
|-----|-----------|-------------|
| Cards showing TITLE/0/Description in browser | `set_card_data()` called before `add_child()` → @onready labels null | Swapped order: add_child first, then set_card_data |
| Clicking cards did nothing | Background ColorRect default `mouse_filter=STOP` intercepts clicks | Added `mouse_filter = 2` (IGNORE) to Background in card_view.tscn |
| Browser serving stale export | Browser caching old .pck / .wasm | Open in incognito; or hard-refresh Ctrl+Shift+R |
| `emit_signal("enemy_died")` in enemy.gd | Godot 3 API | Changed to `enemy_died.emit()` |
| `for i in 5` unused var warning | GDScript 4 convention | Renamed to `_i` |
| `seed` param shadowing built-in | Shadows `seed()` global | Renamed to `run_seed` |
| `get_next_attack()` no bounds check | Crashes if attack_pattern empty | Added guard |
| Python server via Bash fails | Bash can't find python on this machine | Use PowerShell to start Python server |
| Card hover overlap bug | `_original_position` captured in `_ready()` before HBoxContainer finishes layout | Lazy capture on first `mouse_entered` |
| `to_local()` parse error on Control | `to_local()` is Node2D only | Use `global_pos` directly |
| Stack cards going out of bounds | `view.size` doesn't shrink Control below scene dimensions | Use `view.scale = Vector2(0.80, 0.80)` + `clip_contents = true` |
| Stack direction inverted | Depth formula put newest card at wrong corner | Changed to `depth = i` |
| Execute Stack fires SFX with empty stack | No guard | Added `if _stack.is_empty(): return` |
| `Array.filter()` crashes on typed Array[StatusEffect] | Godot 4 typed array limitation | Replaced with explicit `for` loop + typed `kept` array |
| `get_class()` returns "Resource" not class name | Godot's `get_class()` returns internal type | Added `get_status_name() -> String` virtual to StatusEffect base |
| Enemy outgoing damage multiplier not applied | Missing in attack calculation | Applied `_enemy.get_outgoing_damage_multiplier()` in `_on_end_turn_pressed()` |
| `combat_scene.tscn` load_steps mismatch | Removed null_pointer ext_resource but didn't decrement count | Reduced load_steps from 6 to 5 |
| `_loop_times` not always cleared from context | `context.erase()` inside `if extra_runs > 0` guard | Moved erase outside guard — always clears |
| Skip branch leaks `_loop_times` | `_skip_next` branch continued without erasing `_loop_times` | Added `context.erase("_loop_times")` before `continue` |
| QuitButton appearing in screen center | `anchor_top=0` with `offset_top=-52` places top edge at -52px | Set `anchor_top=1.0`; then switched to VBoxContainer layout |
| Locked floors visually indistinguishable | Future floors showed full color with no button | Added grey "locked" label + dim color for all floors above current+1 |
| Execute button white background in WebGL | ShaderMaterial on Button: TEXTURE is empty, samples white | Removed shader from Button; replaced with modulate-based green tween |
| Combat background invisible | CombatBg Control.size = 0 when instanced outside layout container | Use get_viewport_rect() in _draw(); set_anchors_preset(FULL_RECT) in _ready() |
| Cards oversized after frame integration | TextureRect stretch_mode=2 (KEEP) → min_size = texture native size (~550px) | Set expand_mode=1 (EXPAND_IGNORE_SIZE) + stretch_mode=0 (SCALE) |
| Cards invisible in HBoxContainer | SIZE_SHRINK_CENTER set after add_child() triggers layout cycle before _ready(); computed rect = 0×0 | Bake size_flags into tscn root so they apply at parse time |
| Holo RARE cards: no visible frame boundaries | holo_foil.gdshader output COLOR = vec4(opaque) ignoring TEXTURE | Refactored: Background keeps plain frame; HoloOverlay ColorRect runs alpha-based shimmer shader on top |
| Card symbols invisible under Background | _draw() on parent drawn behind children; Background TextureRect covers symbols | Replaced with ArtIcon TextureRect + ArtLabel Label as children |
| Reward screen cards look plain | _make_card_panel() built custom ColorRect panels, not using CardView | Rewritten to instantiate CardView; add wrapper to scene tree first so _ready() fires correctly |
| Operation cards (MUL, ADD etc.) appeared to do nothing | Runtime stack values were invisible — player had no feedback | Added `DATA: [...]` live display in StackZone; updated step-by-step via snapshots |
| Enemy showed "Next: 0" for Segfault charge turns | No special case for 0-damage attacks | Shows `CHARGING...` for 0-damage turns |
| Boss fight had no escalation | Single repeating pattern, no phase transitions | 3-phase The Compiler: phases at 75% and 40% HP with escalating patterns/statuses |
| Player HP not restored between floors | HP carried over unchanged, making later floors too hard | HP fully restored on Victory "Continue" press |

---

## Next step to take

### FIRST: finish this session's uncommitted work
1. **Browser-verify** the enemy-visuals + persistence/resume work at `http://localhost:8080`
   (normal window for persistence). Checklist:
   - Enemy sprite shows + idles in combat; lunges on its turn; impact FX over player HP; death fade.
   - The Compiler tints orange→red across phases 2/3.
   - End Turn button visible & on-screen; auto-end fires ~8s after you run out of moves.
   - Flee/Quit/menu buttons clickable across their FULL height (not just top).
   - Card Library shows `3 / 22` on a fresh New Run, grows as you pick/buy, resets on next New Run.
   - Run History shows a cyan ACTIVE row mid-run; Quit→Resume Run works; Abandon logs a loss.
2. **Commit** (no Co-Authored-By, per repo convention). Both uncommitted sessions can go in one
   commit or two. Suggested messages:
   - `feat: enemy sprites + combat fixes + per-run collection + resume` (prior session)
   - `feat: themed enemy art (bg-removed, single-frame) + larger boss sprites` (this session)
3. **Asset cleanup before shipping:** `assets/sprites/enemies/_raw/` (raw provider sheets) is
   excluded from the web build via `export_presets.cfg`. The `Resources/Fantasy Battle Pack/`
   medieval sheets are **no longer referenced** by any `.tres` — consider deleting them or adding
   to `exclude_filter` for a leaner build. `assets/sprites/enemies/_raw/` is still tracked by git
   (keeps the source sheets recoverable) — keep or remove per preference.

### THEN: Phase 8 — Ship and share — WAITING FOR DHARM APPROVAL

Per `implementation_plan.md`, Phase 8 tasks:
- 8.1 Final QA pass (5 full runs, verify all cards/enemies)
- 8.2 itch.io page (cover image, screenshots, description)
- 8.3 GitHub README
- 8.4 Resume/portfolio entry

**Do NOT start Phase 8 without explicit "go ahead" from Dharm.**

### Deferred / possible follow-ups
- ~~**Themed enemy art**~~ ✅ DONE this session (themed single-frame sprites, bg-removed, larger).
- **Animated idle for enemies** — currently single-frame. Repack the multi-frame provider sheets in
  `assets/sprites/enemies/_raw/` into clean uniform strips (exclude the_compiler annotation cell) and
  set `hframes=N` / `idle_frames=[...]` for a breathing idle. Offered to Dharm; not requested yet.
- **Save the bg-removal pipeline as `tools/clean_enemy_sprites.py`** — currently run ad-hoc; offered.
- **Supabase accounts** (deferred) — if multi-user/cross-device wanted later.
- **Reset Progress** button in Settings (wipe history too) — only collection resets today.
- **Mid-combat resume** — current resume returns to the map only.
- **New Run confirmation** when a saved run exists (currently overwrites silently).

---

## Important workflow rules to remember

- **One task at a time.** Never combine tasks.
- **Subagent-driven:** implementer → spec reviewer → quality reviewer per task. Fix issues between reviews. Only mark complete when quality reviewer says APPROVED.
- **Do NOT modify:** `guide.md`, `implementation_plan.md`, `do_not_do.md`, `setup.md`
- **No direct randi()/randf() calls** — always use `RNG` autoload
- **No gameplay logic in view scenes** — CardView, Hand, StackZone are display/input only
- **After every headless Godot run**, check `project.godot` — it sometimes drops `window/stretch/aspect="keep"`
- **Godot executable:** `C:\Users\DHARM\Godot\Godot_v4.4-stable_win64.exe`
- **Headless export:** `cd` to project root first, then `& "C:\Users\DHARM\Godot\Godot_v4.4-stable_win64.exe" --headless --export-debug "Web" "exports/web/index.html"`
- **Thread support:** must be OFF in export_presets.cfg (`variant/thread_support=false`)
- **Python server:** start via PowerShell (`Start-Process python -ArgumentList "-m","http.server","8080" -WorkingDirectory "exports/web" -WindowStyle Minimized`), NOT Bash
- **Browser verify:** incognito avoids `.pck`/`.wasm` cache — BUT incognito also wipes `user://` saves on session close, so use a NORMAL window when verifying persistence (collection / history / resume)
- **Godot .gd cache:** if external edits not reflected, close Godot fully and reopen — editor caches scripts in memory
- **VBoxContainer layouts** are more reliable than hand-coded anchor values in .tscn files — prefer them for UI scenes
- **CardView set_card_data():** always add to scene tree first (`add_child(view)`), THEN call `set_card_data()` — @onready vars require the node to be in the tree
- **TextureRect for card frames:** must have `expand_mode = 1` (EXPAND_IGNORE_SIZE) so the high-res frame PNG doesn't force the card size to match the texture's native resolution
- **SIZE_SHRINK_CENTER on cards:** set in the tscn root node, not at runtime after add_child — setting size_flags after add_child can cause 0×0 layout rect
- **EnemyData phase fields:** `phase2_hp_fraction` and `phase3_hp_fraction` default to 0.0 (disabled). Only The Compiler uses phases currently; the fields exist for any future enemy.
- **StackResolver snapshots:** `context["_snapshots"]` is an `Array` of `Array[int]` — one snapshot of `runtime_stack` after each card slot. Read by combat_scene for live DATA display.
- **FloatingNumber.show_popup() / CardBurst.emit_burst():** pool-aware versions; the old `init_popup()` is gone. Always call `show_popup()`.
- **SettingsManager.apply_audio():** sets AudioServer bus 0 db from `master_volume`. Call after any volume change.
- **AchievementManager toast:** built directly on the AchievementManager Node (autoload) via `add_child(CanvasLayer)` in `_ready()` — layer=128 puts it above all scenes. Do NOT add a separate toast scene to individual scenes. **Its toast PanelContainer + children MUST stay `mouse_filter = IGNORE`** — at alpha 0 it would otherwise be an invisible click-blocker over the top-right corner (this caused the "buttons only clickable on top half" bug).
- **CardLibraryScreen._build_grid():** must call `add_child(view)` BEFORE `set_card_data(card)` — @onready vars in CardView require the node to be in the tree. Iterates `CollectionManager.get_discovered_cards()` (NOT all 22).
- **Web `user://` persistence:** maps to browser **IndexedDB** keyed to origin + profile. Survives server restart; **incognito wipes it on session end.** Test persistence in a NORMAL window; use incognito only to dodge `.pck`/`.wasm` cache (hard-refresh Ctrl+Shift+R works too).
- **Card collection is PER-RUN** — `CollectionManager.reset_to_starters()` fires in `GameManager.start_new_run()`. Resume does NOT reset it. Run history is permanent.
- **Run lifecycle:** `start_new_run` (clears saved run + collection) → map checkpoints via `save_run()` → conclude via `record_current_run(won)` on game-over/abandon (clears saved run). Map "Quit to Menu" = save & resumable (does NOT record). Resume returns to the MAP, not mid-combat.
- **Enemy sprite is data-driven** from `EnemyData` (`sprite_sheet`/`sheet_hframes`/`sheet_vframes`/`idle_frames`/`sprite_scale`/`phase_tints`). Attack is a **lunge tween**, not sheet frames — so themed art swaps in with only a new PNG + `.tres` values.
- **Themed enemy art is now LIVE** (latest session): `.tres` reference `assets/sprites/enemies/<name>.png` — **single-frame** (`sheet_hframes=1`, `sheet_vframes=1`, `idle_frames=PackedInt32Array(0)`). Scales: standard `3.0`, elite `3.6`, boss `4.4`. Raw provider sheets kept in `assets/sprites/enemies/_raw/` (excluded from export). If a new sprite drop has a baked checkerboard/axis, re-run the background-removal pipeline documented in the LATEST SESSION section (flood-fill key → fill large holes → erode peripheral thin lines). **Frame size = native PNG size × scale** (frames are ~55–88px after autocrop, NOT 64px).
- **Web export WAS rebuilt this session** — `exports/web/` reflects the enemy-visuals + persistence work. Server runs on `http://localhost:8080`.

## Autoloads registered in project.godot (order matters)
- `RNG` → `scripts/autoloads/rng.gd`
- `SettingsManager` → `scripts/autoloads/settings_manager.gd`
- `GameManager` → `scripts/autoloads/game_manager.gd`
- `CollectionManager` → `scripts/autoloads/collection_manager.gd` *(after GameManager — references its card consts)*
- `AudioManager` → `scripts/autoloads/audio_manager.gd`
- `HistoryManager` → `scripts/autoloads/history_manager.gd`
- `AchievementManager` → `scripts/autoloads/achievement_manager.gd`

## GitHub
- Repo: https://github.com/hackgod011/stack-overflow
- Main branch: `main` (always shippable)
- Active branch: `feat/phase-2-graybox` (all phases on this branch)
- Latest SHA: `84020dd` — phase-7: meta features — settings, history, card library, achievements
- Git history: clean — no Co-Authored-By in any commit
