# Handoff — Stack Overflow (Godot 4.4 Roguelike Deckbuilder)

## Goal we are working toward

Build "Stack Overflow" — a roguelike deckbuilder in Godot 4.4 where cards are stack operations (PUSH, POP, DUP, etc.). Implementation follows `implementation_plan.md` phase by phase, one task at a time, with a subagent-driven workflow: implementer subagent → spec reviewer → quality reviewer per task.

**Do NOT auto-start the next phase.** The plan says STOP and wait for Dharm's approval at each phase boundary.

---

## Current state of the project

### Branch
`feat/phase-2-graybox` — Phase 5 + post-phase polish committed

### Phase status
| Phase | Status |
|-------|--------|
| Phase 0 — Setup & web export | ✅ COMPLETE, committed to main (SHA `df96ea1`) |
| Phase 1 — Data layer & autoloads | ✅ COMPLETE, committed (SHA `697ea01`) |
| Phase 2 — Graybox core loop | ✅ COMPLETE — browser verified + committed + pushed (SHA `96956fd`) |
| Phase 3 — First juice pass | ✅ COMPLETE — browser verified + committed + pushed (SHA `0f4238c`) |
| Phase 4 — Content depth | ✅ COMPLETE — committed (SHA `a1b18eb`) |
| Phase 5 — Art & polish | ✅ COMPLETE — all tasks done + extended post-phase visual polish (SHA `2d7083f`) |
| Phase 6 — Web optimization | ⏳ **WAITING for Dharm approval** |

### Phase 5 task status
| Task | Description | Status |
|------|-------------|--------|
| 5.1 | Holographic foil shader for RARE cards | ✅ Done — alpha overlay approach; frame boundaries preserved |
| 5.2 | Glow shader on Execute button (pulsing green glow) | ✅ Done |
| 5.3 | Damage flash shader on enemy (white flash on hit) | ✅ Done |
| 5.4 | Screen shake on impacts (4/6/12/20px by context) | ✅ Done |
| 5.5 | Stack execution choreography (rise 62px → flash → fly to enemy → impact) | ✅ Done |
| 5.6 | Typography pass (JetBrains Mono body, PressStart2P title) | ✅ Done |
| 5.7 | Background styling (dot-grid combat bg, map starfield, dark palette) | ✅ Done |
| 5.8 | Card art — marcus_darius pixel-art frames + per-card icons from board-game-icons/Kyrise | ✅ Done |
| 5.9 | Custom cursor (terminal green pixel-art arrow) | ✅ Done |
| 5.10 | Web export check | ✅ Zero errors, verified |
| 5.11 | Commit Phase 5 | ✅ Done (SHA `05df348`) |

### Post-phase 5 polish (committed SHA `97dfadd`, `9aa113f`, `2d7083f`)
| Item | What was done |
|------|---------------|
| Execute button glow | Replaced broken canvas_item shader (white on Button) with modulate-based green pulse tween |
| Combat background | Fixed CombatBg from invisible (Control.size=0) to full-screen using get_viewport_rect(); dot radius 2.5px, alpha 0.30 |
| Card size | Resized to 120×180 (from 180×260); fixed TextureRect expand_mode=1 (EXPAND_IGNORE_SIZE) so high-res frames don't expand the card |
| Card layout | SIZE_SHRINK_CENTER baked into card_view.tscn root; hand alignment=1 (centred); CARD_SCALE 0.62→0.80 in stack_zone |
| Card frames | 5 marcus_darius pixel-art frames copied to assets/card_frames/; frame assigned by card type (blue/green/yellow/red/purple) |
| Card icons | 14 board-game-icons (64px) + Kyrise RPG icons (48px) copied to assets/card_icons/; per-card icon TextureRect in art area |
| Holo foil | Shader refactored to alpha-based transparent overlay on a ColorRect; Background keeps plain FRAME_PURPLE so corner brackets stay crisp |
| Reward screen | Now instantiates CardView (full frame + icon + labels) instead of custom ColorRect panel |
| Description text | JetBrainsMono 10px, bright white, properly positioned in card's description zone |
| Title centering | TitleLabel offset_left=0 so title centres across full card width |

---

## What the game does right now

**Full run loop works end-to-end:**
- Main menu → "New Run" → Run Map → Floor combat → Reward screen → Map → Shop (floors 6, 11) → Elite (floors 9, 12) → Boss (floor 15) → Game Over

**Visual state:**
- All 22 cards display marcus_darius pixel-art frames (color-coded by type: blue=VALUE, green=OPERATION, yellow=FLOW, red=damage EFFECT, purple=utility EFFECT)
- Each card has a relevant icon in the art area (sword for Strike/Heavy, shield for Defend, stack-high for Push, etc.)
- RARE cards have the plain purple frame PLUS a transparent rainbow shimmer overlay (HoloOverlay ColorRect)
- Reward screen uses the same CardView as in-game (consistent appearance)
- Combat background: animated green dot-grid drifting upward, visible against dark teal background
- Victory/Defeat overlays, floating damage numbers, screen shake, card launch choreography all working

**Run Map:**
- 15 floors: 8 FIGHT, 2 ELITE, 2 SHOP, 1 BOSS (The Compiler), 2 FIGHT
- `►` green arrow marks the one unlocked floor; all future floors show grey "locked"
- Cleared floors show grey "cleared"
- Sequential unlock — must clear current floor to open next

**Combat:**
- Stack mechanic: PUSH values → OPERATE → STRIKE deals 6 + sum(stack) damage
- 3 energy per turn, 5 card draw at turn start
- Status effects: Vulnerable (+50% damage taken), Weak (-25% damage dealt)
- "Flee Floor" button top-right
- Victory overlay → Continue → Reward screen
- Defeat overlay → Continue → Game Over screen

**Reward screen:** 3 random cards (60% COMMON / 30% UNCOMMON / 10% RARE) shown as full CardViews, pick one or skip

**Shop screen:** 3 cards for sale, 2 "Remove a card" slots

**Card library (22 cards):** VALUE (7), OPERATION (5), FLOW (4), EFFECT (6)

**Enemy library (9 enemies):** 6 regular, 2 elite, 1 boss

---

## Files changed in post-Phase-5 polish sessions

| File | Change |
|------|--------|
| `scripts/card/card_view.gd` | Full rewrite — icon system, frame assignment, HoloOverlay, ArtLabel/ArtIcon split, description font |
| `scenes/card/card_view.tscn` | New layout: Background + HoloOverlay + CostLabel + TitleLabel + ArtIcon + ArtLabel + DescriptionLabel; expand_mode=1, SIZE_SHRINK_CENTER |
| `scripts/card/hand.gd` | Reverted bad size_flags runtime assignment; add_card is clean again |
| `scenes/card/hand.tscn` | alignment=1 (centred), custom_minimum_size.y=190 |
| `scripts/combat/stack_zone.gd` | CARD_SCALE 0.62→0.80 |
| `scripts/ui/combat_bg.gd` | get_viewport_rect() instead of size; DOT_RADIUS=2.5, DOT_COLOR alpha=0.30 |
| `scenes/ui/combat_bg.tscn` | CombatBg Control with set_anchors_preset(FULL_RECT) |
| `scripts/ui/reward_screen.gd` | Uses CardView instances; add to tree first so _ready() fires before set_card_data() |
| `assets/shaders/holo_foil.gdshader` | Rewritten: alpha-based transparent overlay (shimmer bands have alpha, gaps are transparent) |
| `assets/card_frames/` | 5 marcus_darius High-Resolution frame PNGs + .import files |
| `assets/card_icons/` | 14 icon PNGs + .import files (board-game-icons + Kyrise 48x48) |
| `data/cards/*.tres` | `art=null` written back by Godot headless export — functionally unchanged |

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
| Holo RARE cards: no visible frame boundaries | holo_foil.gdshader output COLOR = vec4(opaque) ignoring TEXTURE — frame pixel-art replaced entirely | Refactored: Background keeps plain frame; HoloOverlay ColorRect runs alpha-based shimmer shader on top |
| Card symbols invisible under Background | _draw() on parent drawn behind children; Background TextureRect covers symbols | Replaced with ArtIcon TextureRect + ArtLabel Label as children (render above Background) |
| Reward screen cards look plain | _make_card_panel() built custom ColorRect panels, not using CardView | Rewritten to instantiate CardView; add wrapper to scene tree first so _ready() fires correctly |

---

## Next step to take

### Phase 6 — Web optimization & cross-browser pass (WAITING FOR DHARM APPROVAL)

Per `implementation_plan.md`:

**Task 6.1 — Measure baseline**
- Build size of `exports/web/` folder
- Cold-load time in browser DevTools → Network
- Frame time in Performance tab during 30s gameplay
- Write results to `perf_baseline.md`

**Task 6.2 — Asset audit**
- WAV → OGG conversion for all audio
- Textures > 1024×1024 → resize
- Unused assets removed from export
- Target: under 25 MB total build

**Task 6.3 — Code optimization**
- Convert _process() polling to event-driven where possible
- Pool frequently spawned/freed nodes (floating numbers, particles)
- Confirm all get_node() calls already use @onready

**Task 6.4 — Mobile UI pass**
- All clickable elements ≥ 44×44 px
- Hand layout verified in 16:9 landscape on phone
- Disable card hover-lift on touch devices

**Task 6.5 — Cross-browser test**
- Chrome desktop, Firefox desktop, Safari desktop (if available)
- Chrome Android, Safari iOS (if available)
- Fix any critical failures

**Task 6.6 — Custom HTML shell**
- Custom index.html template via Project → Export → Web → Custom HTML Shell
- Branded loading screen with progress bar
- og:image, og:title, og:description meta tags

**Task 6.7 — Commit Phase 6**
- `git commit -m "phase-6: web optimization and cross-browser support"`
- STOP. Wait for Dharm approval.

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
- **Headless export:** `cd` to project root first, then `& "C:\Users\DHARM\Godot\Godot_v4.4-stable_win64.exe" --headless --export-debug "Web" "exports/web/index.html"`
- **Thread support:** must be OFF in export_presets.cfg (`variant/thread_support=false`)
- **Python server:** start via PowerShell (`Start-Process python -ArgumentList "-m","http.server","8080" -WorkingDirectory "exports/web" -WindowStyle Minimized`), NOT Bash
- **Browser verify:** always test in incognito to avoid cache issues
- **Godot .gd cache:** if external edits not reflected, close Godot fully and reopen — editor caches scripts in memory
- **VBoxContainer layouts** are more reliable than hand-coded anchor values in .tscn files — prefer them for UI scenes
- **CardView set_card_data():** always add to scene tree first (`add_child(view)`), THEN call `set_card_data()` — @onready vars require the node to be in the tree
- **TextureRect for card frames:** must have `expand_mode = 1` (EXPAND_IGNORE_SIZE) so the high-res frame PNG doesn't force the card size to match the texture's native resolution
- **SIZE_SHRINK_CENTER on cards:** set in the tscn root node, not at runtime after add_child — setting size_flags after add_child can cause 0×0 layout rect

## Autoloads registered in project.godot
- `RNG` → `scripts/autoloads/rng.gd`
- `GameManager` → `scripts/autoloads/game_manager.gd`
- `AudioManager` → `scripts/autoloads/audio_manager.gd`

## GitHub
- Repo: https://github.com/hackgod011/stack-overflow
- Main branch: `main` (always shippable)
- Active branch: `feat/phase-2-graybox` (Phase 2 through Phase 5 + polish)
- Latest SHA: `2d7083f` — polish: card art overhaul, icons, holo fix, reward screen frames
- Git history: clean — no Co-Authored-By in any commit
