# Handoff — Stack Overflow (Godot 4.4 Roguelike Deckbuilder)

## Goal we are working toward

Build "Stack Overflow" — a roguelike deckbuilder in Godot 4.4 where cards are stack operations (PUSH, POP, DUP, etc.). Implementation follows `implementation_plan.md` phase by phase, one task at a time, with a subagent-driven workflow: implementer subagent → spec reviewer → quality reviewer per task.

**Do NOT auto-start the next phase.** The plan says STOP and wait for Dharm's approval at each phase boundary.

---

## Current state of the project

### Branch
`feat/phase-2-graybox` — Phase 5 committed

### Phase status
| Phase | Status |
|-------|--------|
| Phase 0 — Setup & web export | ✅ COMPLETE, committed to main (SHA `df96ea1`) |
| Phase 1 — Data layer & autoloads | ✅ COMPLETE, committed (SHA `697ea01`) |
| Phase 2 — Graybox core loop | ✅ COMPLETE — browser verified + committed + pushed (SHA `96956fd`) |
| Phase 3 — First juice pass | ✅ COMPLETE — browser verified + committed + pushed (SHA `0f4238c`) |
| Phase 4 — Content depth | ✅ **COMPLETE — committed (SHA `a1b18eb`) + post-phase UI fixes applied** |
| Phase 5 — Art & polish | ✅ **COMPLETE — committed, web export verified** |
| Phase 6 — Web optimization | ⏳ **WAITING for Dharm approval** |

### Phase 5 task status
| Task | Description | Status |
|------|-------------|--------|
| 5.1 | Holographic foil shader for RARE cards | ✅ Done |
| 5.2 | Glow shader on Execute button (pulsing green glow) | ✅ Done |
| 5.3 | Damage flash shader on enemy (white flash on hit) | ✅ Done |
| 5.4 | Screen shake on impacts (4/6/12/20px by context) | ✅ Done |
| 5.5 | Stack execution choreography (0.25s per card, highlight+burst) | ✅ Done |
| 5.6 | Typography pass (JetBrains Mono body, PressStart2P title) | ✅ Done |
| 5.7 | Background styling (terminal code rain, map starfield, dark palette) | ✅ Done |
| 5.8 | Card art (kerenel_Cards.png pack, 22 cards assigned via runtime loader) | ✅ Done |
| 5.9 | Custom cursor (terminal green pixel-art arrow) | ✅ Done |
| 5.10 | Web export check | ✅ Zero errors, verified |
| 5.11 | Commit Phase 5 | ✅ Done |

### Phase 4 task status
| Task | Description | Status |
|------|-------------|--------|
| 4.1 | CardEffect library — 12 new effects | ✅ Done |
| 4.2 | Status effects: VulnerableStatus, WeakStatus | ✅ Done |
| 4.3 | 22-card library (.tres files) | ✅ Done |
| 4.4 | 9-enemy library (.tres files) | ✅ Done |
| 4.5 | Run map (15 floors, sequential, seeded) | ✅ Done |
| 4.6 | Reward screen (pick 1 of 3 cards) | ✅ Done |
| 4.7 | Shop screen (buy cards / remove cards) | ✅ Done |
| 4.8 | Main menu + game over screen | ✅ Done |
| 4.9 | Web export check | ✅ Preset configured, browser verified |
| 4.10 | Commit Phase 4 | ✅ Done |

### What the game does right now

**Full run loop works end-to-end:**
- Main menu → "New Run" → Run Map → Floor combat → Reward screen → Map → Shop (floors 6, 11) → Elite (floors 9, 12) → Boss (floor 15) → Game Over

**Run Map:**
- 15 floors: 8 FIGHT, 2 ELITE, 2 SHOP, 1 BOSS (The Compiler), 2 FIGHT
- `►` green arrow marks the one unlocked floor; all future floors show grey "locked"
- Cleared floors show grey "cleared"
- "Quit to Menu" button top-right in title bar
- Sequential unlock — must clear current floor to open next

**Combat:**
- Stack mechanic: PUSH values → OPERATE → STRIKE deals 6 + sum(stack) damage
- 3 energy per turn, 5 card draw at turn start
- Status effects: Vulnerable (+50% damage taken), Weak (-25% damage dealt), tick down per turn
- Enemy patterns: escalating damage, healing, status infliction, min-damage threshold (boss)
- "Flee Floor" button top-right — abandons fight, saves HP, returns to map
- Victory overlay → Continue → Reward screen
- Defeat overlay → Continue → Game Over screen

**Reward screen:** 3 random cards (60% COMMON / 30% UNCOMMON / 10% RARE), pick one or skip

**Shop screen:** 3 cards for sale (COMMON 50g / UNCOMMON 75g / RARE 100g), 2 "Remove a card" slots (75g each)

**Game Over screen:** shows floors cleared, enemies defeated, gold, deck size, seed; "Main Menu" button

**Card library (22 cards):**
- VALUE: Push 1, Push 3, Push 5, Push 10, Push Rand, Dup, Pop
- OPERATION: Swap, Rot, Add, Mul, Neg
- FLOW: Loop 2, Loop 3, If Positive, Break
- EFFECT: Strike, Heavy Strike, Defend, Draw 2, Compile, Debug

**Enemy library (9 enemies):**
- Regular (6): Null Pointer, Segfault, Infinite Loop, Race Condition, Memory Leak, Off-by-One
- Elite (2): Kernel Panic, Stack Overflow Enemy
- Boss (1): The Compiler (120 HP, min damage threshold, inflicts Vulnerable)

---

## Files changed in Phase 4

| File | Purpose |
|------|---------|
| `scripts/resources/effects/add_effect.gd` | NEW — pops two, pushes sum |
| `scripts/resources/effects/multiply_effect.gd` | NEW — pops two, pushes product |
| `scripts/resources/effects/swap_effect.gd` | NEW — swaps top two values |
| `scripts/resources/effects/rot_effect.gd` | NEW — Forth ROT: a b c → b c a |
| `scripts/resources/effects/neg_effect.gd` | NEW — negates top value |
| `scripts/resources/effects/loop_effect.gd` | NEW — sets _loop_times context key |
| `scripts/resources/effects/if_positive_effect.gd` | NEW — sets _skip_next if top ≤ 0 |
| `scripts/resources/effects/break_effect.gd` | NEW — sets _break context key |
| `scripts/resources/effects/heal_effect.gd` | NEW — adds heal_amount to context |
| `scripts/resources/effects/push_rand_effect.gd` | NEW — pushes RNG 1–6 |
| `scripts/resources/effects/apply_vulnerable_effect.gd` | NEW — adds vulnerable_stacks to context |
| `scripts/resources/effects/damage_per_stack_value_effect.gd` | NEW — sums all stack values into damage |
| `scripts/resources/status_effect.gd` | NEW — base class: stacks, tick(), is_expired(), multipliers |
| `scripts/resources/statuses/vulnerable_status.gd` | NEW — get_damage_taken_multiplier → 1.5 |
| `scripts/resources/statuses/weak_status.gd` | NEW — get_damage_dealt_multiplier → 0.75 |
| `scripts/systems/stack_resolver.gd` | MODIFIED — flow control: _loop_times, _skip_next, _break |
| `scripts/resources/enemy_data.gd` | MODIFIED — added inflicts_vulnerable/weak, min_damage_threshold, heal_per_turn |
| `scripts/combat/enemy.gd` | MODIFIED — setup(), add_status(), multipliers, tick_statuses(), heal() |
| `scenes/combat/enemy.tscn` | MODIFIED — added StatusLabel node |
| `scripts/combat/combat_scene.gd` | REWRITTEN — full run-state integration, status pipeline, victory/defeat flow |
| `scenes/combat/combat_scene.tscn` | MODIFIED — VictoryGold, Continue buttons, PlayerStatusLabel, FleeButton |
| `scripts/autoloads/game_manager.gd` | REWRITTEN — scene constants, card/enemy pools, gold, floor types, reward/shop pickers |
| `scripts/map/run_map.gd` | NEW — 15-floor map, sequential unlock, ► indicator, grey locked/cleared |
| `scenes/map/run_map.tscn` | NEW — VBoxContainer layout with TopBar + ScrollContainer |
| `scripts/ui/reward_screen.gd` | NEW — 3-card offer, pick or skip |
| `scenes/ui/reward_screen.tscn` | NEW |
| `scripts/ui/shop_screen.gd` | NEW — buy cards, remove cards, gold deduction |
| `scenes/ui/shop_screen.tscn` | NEW |
| `scripts/core/main_menu.gd` | NEW — New Run → map, Quit |
| `scenes/core/main_menu.tscn` | NEW |
| `scripts/ui/game_over_screen.gd` | NEW — win/lose result, stats, seed |
| `scenes/ui/game_over_screen.tscn` | NEW |
| `data/cards/*.tres` | 16 NEW card resource files |
| `data/enemies/*.tres` | 8 NEW enemy resource files |
| `project.godot` | MODIFIED — main scene → main_menu.tscn |

---

## Deviations from spec (Phase 4)

| Spec item | Deviation | Reason |
|-----------|-----------|--------|
| Task 4.3: card cost design | Costs assigned by Claude (Dharm: "use your judgment") | COMMON VALUE free/1, OPERATION 0-2, FLOW 0-3, EFFECT 1-2; MUL UNCOMMON cost 2 |
| Task 4.4: enemy designs | HP/patterns/mechanics designed by Claude (Dharm: "use your judgment") | Each enemy given a thematic mechanic matching its bug metaphor |
| Shop "remove" tool | Removes last card in deck | Simplified; no card-picker UI |

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
| Stack cards going out of bounds | `view.size` doesn't shrink Control below scene dimensions | Use `view.scale = Vector2(0.62, 0.62)` + `clip_contents = true` |
| Stack direction inverted | Depth formula put newest card at wrong corner | Changed to `depth = i` |
| Execute Stack fires SFX with empty stack | No guard | Added `if _stack.is_empty(): return` |
| `Array.filter()` crashes on typed Array[StatusEffect] | Godot 4 typed array limitation | Replaced with explicit `for` loop + typed `kept` array |
| `get_class()` returns "Resource" not class name | Godot's `get_class()` returns internal type | Added `get_status_name() -> String` virtual to StatusEffect base |
| Enemy outgoing damage multiplier not applied | Missing in attack calculation | Applied `_enemy.get_outgoing_damage_multiplier()` in `_on_end_turn_pressed()` |
| `combat_scene.tscn` load_steps mismatch | Removed null_pointer ext_resource but didn't decrement count | Reduced load_steps from 6 to 5 |
| `_loop_times` not always cleared from context | `context.erase()` inside `if extra_runs > 0` guard | Moved erase outside guard — always clears |
| Skip branch leaks `_loop_times` | `_skip_next` branch continued without erasing `_loop_times` | Added `context.erase("_loop_times")` before `continue` |
| QuitButton appearing in screen center | `anchor_top=0` with `offset_top=-52` places top edge at -52px (above viewport) | Set `anchor_top=1.0`; then switched to VBoxContainer layout (more reliable) |
| Godot ignores external .gd edits | Editor caches in-memory script version | Close Godot fully and reopen, OR right-click file in Script tab → Reload |
| Locked floors visually indistinguishable | Future floors showed full color with no button | Added grey "locked" label + dim color for all floors above current+1 |

---

## Next step to take

### Phase 6 — Web optimization & cross-browser pass (WAITING FOR DHARM APPROVAL)

Per `implementation_plan.md`, Phase 6 covers:
- Measure baseline (build size, load time, frame drops)
- Asset audit (WAV → OGG, large textures, unused assets)
- Code optimization (event-driven over _process, node pooling)
- Mobile UI pass (44×44 touch targets, landscape layout)
- Cross-browser test (Chrome, Firefox, Safari, Android Chrome)
- Custom HTML shell (branded loading screen, OG tags)

**Do NOT start Phase 6 without explicit "go ahead" from Dharm.**

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
- **Godot .gd cache:** if external edits not reflected, close Godot fully and reopen — editor caches scripts in memory
- **VBoxContainer layouts** are more reliable than hand-coded anchor values in .tscn files — prefer them for UI scenes

## Autoloads registered in project.godot
- `RNG` → `scripts/autoloads/rng.gd`
- `GameManager` → `scripts/autoloads/game_manager.gd`
- `AudioManager` → `scripts/autoloads/audio_manager.gd`

## GitHub
- Repo: https://github.com/hackgod011/stack-overflow
- Main branch: `main` (always shippable)
- Active branch: `feat/phase-2-graybox` (contains Phase 2 through Phase 4)
- Git history: clean — no Co-Authored-By in any commit
