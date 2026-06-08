# Handoff — Stack Overflow (Godot 4.4 Roguelike Deckbuilder)

## Goal we are working toward

Build "Stack Overflow" — a roguelike deckbuilder in Godot 4.4 where cards are stack operations (PUSH, POP, DUP, etc.). Implementation follows `implementation_plan.md` phase by phase, one task at a time, with a subagent-driven workflow: implementer subagent → spec reviewer → quality reviewer per task.

**Do NOT auto-start the next phase.** The plan says STOP and wait for Dharm's approval at each phase boundary.

---

## Current state of the project

### Branch
`feat/phase-2-graybox` — Phases 0–6 complete + post-phase gameplay fixes committed

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
| Phase 7 — Meta-features (optional) | ⏳ **WAITING for Dharm approval** |

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

**Web build:**
- Total: 63.58 MB (WASM 50.88 MB fixed + PCK 13.56 MB)
- Baseline was 66.59 MB — saved 3 MB via OGG audio + unused sprite exclusion
- `perf_baseline.md` written with full audit results
- Browser testing (cross-browser) still requires **manual verification by Dharm**:
  - Start server: `Start-Process python -ArgumentList "-m","http.server","8080" -WorkingDirectory "exports/web" -WindowStyle Minimized`
  - Open `http://localhost:8080` in **incognito** tab (Chrome, Firefox, Chrome Android)

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

### Phase 7 — Meta-features (optional, time-permitting) — WAITING FOR DHARM APPROVAL

Per `implementation_plan.md`, Phase 7 tasks:

**Task 7.1 — Settings menu**
- Master/SFX/Music volume sliders
- Toggle: reduce motion (disables screen shake)
- Toggle: show seed input field for replays
- Persist to `user://settings.cfg`

**Task 7.2 — Run history**
- Log to `user://run_history.json` after each run: floor reached, enemies defeated, total damage, seed, duration
- "Run History" screen accessible from main menu, shows last 10 runs

**Task 7.3 — Card library / encyclopedia**
- Screen accessible from main menu showing all 22 cards browsable

**Task 7.4 — Achievements**
- 5–10 achievements (e.g., "First Victory", "Stack of 10", "Win without taking damage")
- Persist to `user://`. Show toast on unlock.

**Task 7.5 — Commit Phase 7**
- `git commit -m "phase-7: meta features — settings, history, achievements"`

**Do NOT start Phase 7 without explicit "go ahead" from Dharm.**

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
- **Browser verify:** always test in incognito to avoid cache issues
- **Godot .gd cache:** if external edits not reflected, close Godot fully and reopen — editor caches scripts in memory
- **VBoxContainer layouts** are more reliable than hand-coded anchor values in .tscn files — prefer them for UI scenes
- **CardView set_card_data():** always add to scene tree first (`add_child(view)`), THEN call `set_card_data()` — @onready vars require the node to be in the tree
- **TextureRect for card frames:** must have `expand_mode = 1` (EXPAND_IGNORE_SIZE) so the high-res frame PNG doesn't force the card size to match the texture's native resolution
- **SIZE_SHRINK_CENTER on cards:** set in the tscn root node, not at runtime after add_child — setting size_flags after add_child can cause 0×0 layout rect
- **EnemyData phase fields:** `phase2_hp_fraction` and `phase3_hp_fraction` default to 0.0 (disabled). Only The Compiler uses phases currently; the fields exist for any future enemy.
- **StackResolver snapshots:** `context["_snapshots"]` is an `Array` of `Array[int]` — one snapshot of `runtime_stack` after each card slot. Read by combat_scene for live DATA display.
- **FloatingNumber.show_popup() / CardBurst.emit_burst():** pool-aware versions; the old `init_popup()` is gone. Always call `show_popup()`.

## Autoloads registered in project.godot
- `RNG` → `scripts/autoloads/rng.gd`
- `GameManager` → `scripts/autoloads/game_manager.gd`
- `AudioManager` → `scripts/autoloads/audio_manager.gd`

## GitHub
- Repo: https://github.com/hackgod011/stack-overflow
- Main branch: `main` (always shippable)
- Active branch: `feat/phase-2-graybox` (all phases on this branch)
- Latest SHA: `92c7db1` — fix: runtime stack display, HP restore, boss phases, CHARGING intent
- Git history: clean — no Co-Authored-By in any commit
