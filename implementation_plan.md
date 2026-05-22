# implementation_plan.md — Stack Overflow

**Project:** Stack Overflow — a roguelike deckbuilder where cards are stack operations
**Engine:** Godot 4.4 (Standard build, GDScript)
**Target:** Web (HTML5/WebAssembly + WebGL 2.0); Desktop secondary
**Audience:** Claude Code agent, executing this plan task by task

---

## How to use this file

You (Claude Code) will execute this plan **phase by phase, task by task, in order**.
Rules:

1. **Read `guide.md` first.** Every piece of code you write must conform to it.
2. **Read `do_not_do.md` before writing any code.** It defines what to avoid.
3. **One task at a time.** Do not skip ahead. Do not combine tasks.
4. **At the end of each task**, verify the acceptance criterion. If it doesn't
   pass, debug and fix before moving on.
5. **At the end of each phase**, commit to git with a clear message, then
   stop and report back to the user (Dharm) for review before starting the
   next phase. Do not auto-start the next phase.
6. **If anything is ambiguous, ask Dharm.** Do not invent gameplay rules,
   numerical balance values, or visual styling on your own — those are
   design decisions, not implementation decisions.

---

## The game in one paragraph (so you have full context)

Stack Overflow is a single-player, turn-based roguelike deckbuilder. Each turn
the player draws 5 cards from their deck. Cards represent stack operations
(`PUSH n`, `POP`, `DUP`, `SWAP`, `ADD`, `MUL`, `LOOP n`, `IF`, etc.) and visual
effects (deal damage, gain block, draw, etc.). The player **stacks cards onto
a visual stack** in whatever order they want, then clicks "Execute." The stack
resolves top-down (LIFO): each card runs in order, and the order changes the
outcome. Combat is against one or more enemies. Between fights the player
navigates a Slay-the-Spire-style node map (fight → fight → shop → elite → boss).
Runs are permadeath, 20–30 minutes each. Seeded RNG makes runs reproducible
for debugging.

---

## Phase 0 — Environment & repo setup

### Task 0.0 — Verify manual setup is complete
Before doing anything else:
- Confirm `setup.md` exists in the project folder.
- Ask Dharm to confirm he has completed all REQUIRED items in `setup.md`
  sections 1–5 and 8 (Godot installed, Git working, VS Code Godot extension
  installed, GitHub repo created, project folder ready, Python available
  for local web server).
- Ask Dharm for: (a) the GitHub repo URL, (b) the full path to his Godot
  executable.
- If any required item is missing, STOP and tell Dharm what to install.
  Do not attempt to install Godot or other GUI applications yourself.
- **Acceptance:** Dharm confirms setup is complete and has provided the
  GitHub repo URL and Godot path.

### Task 0.1 — Initialize the Godot project
- Create a new Godot 4.4 project named `stack_overflow`.
- In Project Settings:
  - **Rendering → Renderer → Rendering Method**: `Compatibility` (matches web).
  - **Display → Window → Size**: 1280×720 viewport, **Stretch Mode**: `canvas_items`, **Aspect**: `keep`.
  - **Application → Run → Main Scene**: leave empty for now.
- **Acceptance:** project opens in Godot without errors; pressing F5 prompts for a main scene.

### Task 0.2 — Folder structure
Create the exact folder structure defined in `guide.md` section 1.
- **Acceptance:** all folders exist; commit them with `.gitkeep` files so git tracks empty directories.

### Task 0.3 — Git setup
- Initialize git in the project root if not already.
- Write `.gitignore`:
  ```
  # Godot
  .godot/
  .import/
  export.cfg
  export_presets.cfg
  *.translation
  # Exports
  /exports/
  # OS
  .DS_Store
  Thumbs.db
  # IDE
  .vscode/
  ```
- First commit: `chore: initial project structure`.
- **Acceptance:** `git status` shows clean working tree.

### Task 0.4 — Web export preset
- Open Project → Export → Add → Web.
- **Important settings:**
  - `Variant: Thread Support` → **OFF** (this gives a single-threaded build that runs on itch.io / GitHub Pages without COOP/COEP headers — Godot 4.3+ reintroduced this).
  - `Export Path`: `exports/web/index.html`.
- Add a small placeholder scene (a `Label` with text "Stack Overflow — coming soon") and set it as Main Scene.
- Export. Verify the `exports/web/` folder contains `index.html`, `.wasm`, `.pck`, etc.
- **Acceptance:** Opening `exports/web/index.html` via a local web server (e.g., `python -m http.server 8000`) loads the placeholder in the browser. **Do not try to open `index.html` directly from the file system — browsers block this.**

### Task 0.5 — Commit Phase 0
- `git add . && git commit -m "phase-0: project scaffold and web export verified"`.
- **STOP. Report to Dharm. Wait for go-ahead.**

---

## Phase 1 — Core data layer & autoloads

### Task 1.1 — `RNG` autoload
File: `scripts/autoloads/rng.gd`.
- Wraps `RandomNumberGenerator`.
- Exposes: `seed_run(s: int)`, `randi_range(a, b)`, `randf()`, `randf_range(a, b)`, `pick(array: Array)`, `shuffle(array: Array)`, `get_seed() -> int`.
- Registered in Project Settings → Autoload as `RNG`.
- **Acceptance:** A throwaway test scene that calls `RNG.seed_run(42); print(RNG.randi_range(1, 100))` twice produces the same number both runs.

### Task 1.2 — `CardEffect` resource (abstract base)
File: `scripts/resources/card_effect.gd`.
```gdscript
class_name CardEffect
extends Resource
## Base class for all card effects. Subclasses override apply().

@export var description: String  # for tooltip generation

func apply(context: Dictionary) -> void:
	push_warning("CardEffect.apply() not implemented in subclass")
```
`context` is the shared dict passed through the stack resolver. Subclasses
will read/write `context.damage_amount`, `context.player`, `context.targets`,
`context.stack`, etc.
- **Acceptance:** Resource compiles; can be subclassed.

### Task 1.3 — Concrete effects (Phase 1 minimum set)
Create these as separate files in `scripts/resources/effects/`:
- `push_value_effect.gd` (`@export var value: int`) — pushes an integer onto the runtime stack.
- `pop_effect.gd` — pops the top of the runtime stack and discards it.
- `dup_effect.gd` — duplicates the top of the runtime stack.
- `deal_damage_effect.gd` (`@export var amount: int`) — deals damage equal to amount + sum of stack values (or just `amount` if no values on stack).
- `gain_block_effect.gd` (`@export var amount: int`) — gives the player N block.
- `draw_cards_effect.gd` (`@export var count: int`) — draws N cards.

**Important:** Effects must be small and composable. A single card can have
multiple effects in sequence. The `CardData.effects: Array[CardEffect]` field
holds them in order.

- **Acceptance:** Each effect file compiles. You can create a `.tres` instance of each via the editor inspector.

### Task 1.4 — `CardData` resource
File: `scripts/resources/card_data.gd`.
```gdscript
class_name CardData
extends Resource

enum CardType { OPERATION, VALUE, FLOW, EFFECT }
enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var title: String
@export_multiline var description: String  # supports {x} placeholders
@export var cost: int = 1                  # energy/CPU cost
@export var card_type: CardType
@export var rarity: Rarity
@export var art: Texture2D                 # nullable; placeholder until art exists
@export var effects: Array[CardEffect]
```
- **Acceptance:** You can create a new `.tres` file, assign effects to it via the inspector, and save it.

### Task 1.5 — Six starter card definitions
Create six `.tres` files in `data/cards/`:
- `push_1.tres` — "PUSH 1", cost 0, type VALUE, has `push_value_effect` with value=1.
- `push_5.tres` — "PUSH 5", cost 1, type VALUE, has `push_value_effect` with value=5.
- `dup.tres` — "DUP", cost 1, type OPERATION, has `dup_effect`.
- `pop.tres` — "POP", cost 0, type OPERATION, has `pop_effect`.
- `strike.tres` — "STRIKE", cost 1, type EFFECT, has `deal_damage_effect` with amount=6.
- `defend.tres` — "DEFEND", cost 1, type EFFECT, has `gain_block_effect` with amount=5.
- **Acceptance:** All six load in the editor without errors.

### Task 1.6 — `GameManager` autoload (skeleton)
File: `scripts/autoloads/game_manager.gd`.
Holds run-wide state. For Phase 1, just declare the fields and a `start_new_run()` method:
```gdscript
extends Node

var current_seed: int
var player_max_hp: int = 80
var player_hp: int = 80
var player_block: int = 0
var gold: int = 0
var current_floor: int = 0
var deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

signal hp_changed(new_hp: int, max_hp: int)
signal block_changed(new_block: int)
signal hand_changed
signal run_started

func start_new_run(seed: int = -1) -> void:
	if seed == -1:
		seed = Time.get_ticks_msec()
	current_seed = seed
	RNG.seed_run(seed)
	# starter deck assembled here in a later task
	run_started.emit()
```
- Registered as autoload `GameManager`.
- **Acceptance:** Calling `GameManager.start_new_run(42)` from any script logs no errors.

### Task 1.7 — `AudioManager` autoload (skeleton)
File: `scripts/autoloads/audio_manager.gd`.
- Single `AudioStreamPlayer` for music + one for SFX (pooled later).
- Methods: `play_sfx(stream: AudioStream)`, `play_music(stream: AudioStream, loop: bool)`.
- For Phase 1, just empty implementations. We'll wire it up in Phase 3.
- **Acceptance:** Autoload registered; no errors.

### Task 1.8 — Commit Phase 1
- `git commit -m "phase-1: data layer, RNG, autoloads, six starter cards"`.
- **STOP. Report to Dharm. Wait for go-ahead.**

---

## Phase 2 — Graybox core loop

**Goal of this phase:** the game is playable end-to-end with grey rectangles
and no animation. Cards stack. Stack executes. Damage happens. Win/lose works.
This is the most important phase — if the design isn't fun here, no amount
of polish will save it.

### Task 2.1 — `CardView` scene (graybox)
- Scene file: `scenes/card/card_view.tscn`. Root: `Control`.
- Children: `ColorRect` (background, 180×260 px), `Label` (title at top), `Label` (cost in a circle top-left), `Label` (description in middle).
- Script: `scripts/card/card_view.gd`.
- Method: `set_card_data(data: CardData)` — populates the labels from data.
- States: `IDLE`, `HOVERED`, `DRAGGING`, `STACKED`.
- For now: no animations, no art — just text on grey rectangles.
- **Acceptance:** Instancing the scene with any of the six starter cards correctly shows title/cost/description.

### Task 2.2 — `Hand` scene
- Scene: `scenes/card/hand.tscn`. Root: `HBoxContainer` or custom layout.
- Script holds an array of `CardView` instances.
- Methods: `add_card(data: CardData)`, `remove_card(view: CardView)`, `clear()`.
- For graybox: cards lined up horizontally, no fan-out, no overlap.
- **Acceptance:** Calling `hand.add_card(strike_data)` five times shows five cards in a row.

### Task 2.3 — `StackZone` scene
- Scene: `scenes/combat/stack_zone.tscn`. Visual: a vertical rectangle in the center-right of the screen.
- When the player clicks a card in `Hand`, it moves to the top of `StackZone` (no animation yet, just instant reparent).
- Shows cards stacked top-down, with the most recently added at the top.
- A button "Execute Stack" sits below.
- **Acceptance:** Clicking cards in hand visibly moves them into the stack zone in the order clicked.

### Task 2.4 — `StackResolver` system
File: `scripts/systems/stack_resolver.gd`.
- Method: `resolve(stack: Array[CardData], context: Dictionary) -> Dictionary`.
- Iterates the stack from top to bottom (LIFO). For each card, iterates its `effects` array and calls `apply(context)`.
- `context` contains: `runtime_stack: Array[int]` (the data stack the cards manipulate), `player`, `enemies`, `damage_accumulator`, etc.
- **No visuals yet. Pure logic.**
- **Acceptance:** Unit test: a stack of `[PUSH 5, DUP, STRIKE(base=6)]` produces `damage_accumulator = 6 + 5 + 5 = 16` (or whatever your final damage formula is — confirm with Dharm before coding).

### Task 2.5 — `Enemy` scene & data
- `scripts/resources/enemy_data.gd`: `EnemyData` resource with `name`, `max_hp`, `attack_pattern: Array[int]` (cycles through these as damage per turn).
- `scenes/combat/enemy.tscn`: a `ColorRect` + HP label + "intent" label (showing next attack damage).
- One starter enemy `.tres`: "Null Pointer" with 30 HP, pattern `[6, 8, 6]`.
- **Acceptance:** Enemy displays HP and the next attack number.

### Task 2.6 — `CombatScene` and turn loop
- Scene: `scenes/combat/combat_scene.tscn`. Layout:
  - Top: enemy area
  - Middle: stack zone + execute button
  - Bottom-left: player area with HP and block
  - Bottom: hand
  - Side: draw pile count + discard pile count
- Script: full turn loop.
  - `_ready()`: GameManager has a 10-card starter deck (5× Strike, 3× Defend, 2× Push 5). Shuffle. Player has 3 energy/turn.
  - `start_player_turn()`: refill energy, draw 5 cards.
  - Player plays cards (each play costs energy; cards go to stack zone).
  - Player clicks "Execute Stack" → `StackResolver.resolve(...)` runs → damage applied to enemy → block applied to player.
  - Player clicks "End Turn" → remaining hand discards, enemy attacks (deals block-reduced damage), player turn starts.
  - Win when enemy HP ≤ 0 → show "VICTORY" overlay.
  - Lose when player HP ≤ 0 → show "GAME OVER" overlay with the seed (so it can be reproduced).
- **Acceptance:** A full fight can be played from start to win OR loss. **Have Dharm playtest at this point.**

### Task 2.7 — Export to web, verify
- Export the build. Upload to itch.io as **draft / private**.
- Verify the graybox plays in Chrome and Firefox.
- **Acceptance:** Web build is playable. **If anything breaks in browser that worked locally, fix it now, not later.**

### Task 2.8 — Commit Phase 2
- `git commit -m "phase-2: graybox combat loop playable on web"`.
- **STOP. Dharm playtests. Iterate on design only if needed. Wait for go-ahead.**

---

## Phase 3 — First juice pass

**Goal:** the graybox starts to feel like a real game. This is what makes
playtesters' eyes light up and what gives you the energy to continue.

### Task 3.1 — `tween_presets.gd` utility
File: `scripts/utils/tween_presets.gd` (a static helper class, not autoload).
- Constants: `STANDARD_DURATION = 0.18`, `SNAP_DURATION = 0.08`, `SLOW_DURATION = 0.4`.
- Helper: `static func standard_tween(node: Node) -> Tween` — returns a Tween with `EASE_OUT` + `TRANS_CUBIC` already configured.
- **Acceptance:** other scripts can `TweenPresets.standard_tween(self).tween_property(...)`.

### Task 3.2 — Card hover animation
- In `card_view.gd`: on `mouse_entered`, lift 32 px up, scale to 1.08, slight z-index increase.
- On `mouse_exited`, return to original position/scale.
- Smooth — use `TweenPresets.standard_tween`.
- **Acceptance:** Hovering feels responsive (no lag), no glitches when moving cursor across cards quickly.

### Task 3.3 — Card movement tweens
Replace instant reparenting with tweened motion:
- Hand → Stack: 0.25s ease-out, slight scale-down on arrival.
- Hand → Discard: 0.3s ease-in, fade-out at the end.
- Deck → Hand: 0.25s ease-out, scaling up from 0.8 to 1.0.
- **Acceptance:** All card movements feel like a card flying, not teleporting.

### Task 3.4 — HP and block bars tween
- `ProgressBar` value changes should tween over 0.4s, not snap.
- Block icon pops in/scales on gain.
- **Acceptance:** When the enemy takes damage, its HP bar visibly drains; doesn't just jump down.

### Task 3.5 — Damage number popups
- New scene: `scenes/ui/floating_number.tscn`.
- A label that spawns at a position, drifts up 60 px, fades out over 0.8s, then queue_frees.
- Spawn on every damage event, block gain, HP loss.
- **Acceptance:** Visible "-6" floats up off the enemy when hit.

### Task 3.6 — Sound effects
- Generate SFX with jsfxr (Dharm provides these as `.wav`, then converts to `.ogg`).
- Needed: card_hover, card_play, card_draw, card_discard, button_click, enemy_hurt, player_hurt, block_gain, execute_stack, victory, defeat.
- Wire into `AudioManager.play_sfx()`.
- Each `card_view.gd` triggers `card_hover` on entered, `card_play` on click, etc.
- **Acceptance:** Every interaction has audio feedback. No silent clicks.

### Task 3.7 — Background music
- One ambient loop in `assets/audio/music/`. CC0 source.
- `AudioManager.play_music()` called from `CombatScene._ready()`.
- Volume should be lower than SFX (~ -10 dB).
- **Acceptance:** Music plays during combat. Doesn't restart between turns.

### Task 3.8 — Simple particle effects
- `GPUParticles2D` burst when a card resolves on the stack. Use a small white square as the particle texture; tint by card type.
- Limit emit count to 16 particles per burst (web friendly).
- **Acceptance:** Stack execution looks visually punchy.

### Task 3.9 — Web export check
- Re-export. Verify audio plays in browser (sometimes formats fail).
- **Acceptance:** Web build still works, audio and particles included.

### Task 3.10 — Commit Phase 3
- `git commit -m "phase-3: first juice pass — tweens, sfx, particles"`.
- **STOP. Dharm playtests. Wait for go-ahead.**

---

## Phase 4 — Content depth

### Task 4.1 — Expand `CardEffect` library
Add new effect resources (one per file in `scripts/resources/effects/`):
- `swap_effect.gd` — swaps top two values on runtime stack.
- `add_effect.gd` — pops top two values, pushes sum.
- `multiply_effect.gd` — pops top two values, pushes product.
- `loop_effect.gd` (`@export var times: int`) — re-executes the next card on the stack N times.
- `if_positive_effect.gd` — only runs the next card if top of runtime stack > 0.
- `damage_per_stack_value_effect.gd` — deals damage equal to sum of all values currently on the runtime stack.
- `apply_vulnerable_effect.gd` (`@export var stacks: int`) — applies a status effect to enemy.
- **Acceptance:** Each effect file compiles; usable in card definitions.

### Task 4.2 — Status effects system
- `scripts/resources/status_effect.gd` — base class.
- Implementations: `VulnerableStatus` (takes 50% more damage), `WeakStatus` (deals 25% less damage), `BlockStatus` (already exists).
- Both player and enemies have an `Array[StatusEffect]` field.
- Effects tick down at end of turn.
- **Acceptance:** Applying Vulnerable to an enemy makes the next damage dealt visibly higher.

### Task 4.3 — Card library (20+ cards)
Create 20 `.tres` cards across:
- **VALUE cards:** PUSH 1, PUSH 3, PUSH 5, PUSH 10 (rare), PUSH RAND (pushes a random int)
- **OPERATION cards:** DUP, POP, SWAP, ROT, ADD, MUL, NEG
- **FLOW cards:** LOOP 2, LOOP 3 (uncommon), IF_POSITIVE, BREAK
- **EFFECT cards:** STRIKE (6), HEAVY_STRIKE (10), DEFEND (5), DRAW 2, COMPILE (deal damage = sum of stack values), DEBUG (heal 4)

Have Dharm review the list **before** creating all 20 — naming and balance need his input.
- **Acceptance:** 20+ cards exist as `.tres` files. Each is playable. None crash.

### Task 4.4 — Enemy library
Create 6 regular enemies + 2 elites + 1 boss as `.tres`:
- Regular: `null_pointer`, `infinite_loop`, `segfault`, `race_condition`, `memory_leak`, `off_by_one`
- Elite: `kernel_panic`, `stack_overflow_enemy` (yes, named after the game)
- Boss: `the_compiler` (multi-phase, has thematic mechanics like "ignores damage below 5")
- Each has distinct attack patterns and at least one special mechanic (status application, multi-hit, increasing damage, etc.).
- **Acceptance:** Each enemy fight feels different from the others.

### Task 4.5 — Run map
- Scene: `scenes/map/run_map.tscn`. Visual: a vertical grid of nodes connected by lines, Slay-the-Spire style.
- 15 floors. Floor 15 is always the boss. Floor 9 and 12 are elites. Floor 6 and 11 are shops. Rest are random fights.
- Node graph generation: deterministic from current_seed.
- Player picks a node from the available next floor; clicking transitions to combat or shop.
- **Acceptance:** A full run plays from floor 1 to boss to game over screen.

### Task 4.6 — Reward screen
- After winning a fight: show 3 random cards (filtered by rarity probabilities — 60% common, 30% uncommon, 10% rare).
- Player picks one to add to deck or skips.
- Gold reward shown.
- **Acceptance:** After a fight, player picks a card and it's added to their deck for future turns.

### Task 4.7 — Shop screen
- Sells 3 random cards and 2 random "tools" (single-use upgrades, e.g., "Remove a card from your deck").
- Player can buy with gold.
- **Acceptance:** Shop transactions work; gold deducted correctly.

### Task 4.8 — Main menu & game over screen
- Title screen with "NEW RUN" / "CONTINUE" (later) / "QUIT" buttons.
- Game over screen: shows floor reached, enemies defeated, seed (with copy-to-clipboard).
- **Acceptance:** Player can complete a run, see results, return to menu, start a new run.

### Task 4.9 — Web export check, mobile smoke test
- Export, upload to itch.io.
- Test on a phone (Dharm's phone or a friend's).
- Note any issues; report to Dharm. Do not fix mobile-specific issues yet unless trivial — that's Phase 6.
- **Acceptance:** Desktop build is fully playable. Mobile may have UI issues, that's okay for now.

### Task 4.10 — Commit Phase 4
- `git commit -m "phase-4: full content — 20 cards, 9 enemies, map, shop"`.
- **STOP. Dharm playtests. Major balancing pass with Dharm. Wait for go-ahead.**

---

## Phase 5 — Second juice pass ("looks expensive")

### Task 5.1 — Custom card shader: holographic foil for rare cards
- File: `assets/shaders/holo_foil.gdshader`.
- Fragment shader that overlays animated rainbow noise on the card.
- Applied as `material` only on cards with `rarity == RARE`.
- **Acceptance:** Rare cards visibly shimmer with color.

### Task 5.2 — Glow shader on Execute button
- Fragment shader: pulsing outer glow.
- Only when there's at least one card in the stack zone.
- **Acceptance:** Execute button visibly pulses when ready, dim when not.

### Task 5.3 — Damage flash shader
- Fragment shader for enemy sprite: blend toward white based on a uniform `flash_amount`.
- Triggered on each damage instance: tween `flash_amount` from 1.0 → 0.0 over 0.15s.
- **Acceptance:** Enemy flashes white on each hit.

### Task 5.4 — Screen shake
- Camera2D autoload or static helper: `Camera.shake(intensity, duration)`.
- Subtle shake (4 px) on small hits, larger (12 px) on boss hits, big shake (20 px) on player death.
- **Acceptance:** Big damage events feel impactful.

### Task 5.5 — Stack execution choreography
- When player presses Execute, cards in stack resolve **one at a time with a 0.25s pause between**, each card flashing/scaling as it triggers.
- Active card is visually highlighted while resolving.
- **Acceptance:** Player can see the stack executing in order; understands what each card did.

### Task 5.6 — Typography pass
- Body font: `JetBrains Mono` (Google Fonts) or similar monospace.
- Display font: a chunkier programmer font for titles.
- Apply via a `Theme` resource in `scenes/ui/`.
- **Acceptance:** All text uses the chosen fonts; no remaining default Godot font visible.

### Task 5.7 — Background / scene styling
- Combat scene background: animated subtle gradient or terminal-style scrolling code text in the background (greatly faded).
- Map scene: dark background, animated star/dot field.
- Consistent dark palette across all scenes (define color constants in a `colors.gd` file).
- **Acceptance:** Game has a coherent visual identity. No scene looks "default Godot."

### Task 5.8 — Card art (or thoughtful art-less design)
Decision point — discuss with Dharm:
- **Option A:** Source/buy a card-icon pack from itch.io CC0 for the 20 cards.
- **Option B (recommended for the theme):** No illustrative art — each card has a large stylized ASCII glyph + monospace text. Fits the programmer theme, costs zero art time, looks intentional.
- **Acceptance:** Every card has a distinct, readable visual identity.

### Task 5.9 — Custom cursor
- Pixel-art cursor in the terminal aesthetic.
- Different cursor when hovering a playable card vs. unplayable (insufficient energy).
- **Acceptance:** Custom cursor visible at all times during gameplay.

### Task 5.10 — Web export, polish check
- Export. Take 5+ screenshots for the itch.io page.
- Record a 30-second GIF of gameplay (use OBS + ezgif).
- **Acceptance:** Screenshots look genuinely impressive. Game is recognizable from a thumbnail.

### Task 5.11 — Commit Phase 5
- `git commit -m "phase-5: visual polish — shaders, screen shake, typography"`.
- **STOP. Dharm reviews. This is the major checkpoint for portfolio-readiness. Wait for go-ahead.**

---

## Phase 6 — Web optimization & cross-browser pass

### Task 6.1 — Measure baseline
- Build the web export.
- Measure: total size of `exports/web/` folder, breakdown by file.
- Open browser DevTools → Network → record a cold load. Measure time to playable.
- Open Performance tab → record a 30-second gameplay session. Note frame drops.
- **Acceptance:** Baseline metrics written to a file `perf_baseline.md`.

### Task 6.2 — Asset audit
- Find any audio in WAV → convert to OGG.
- Find any texture > 1024×1024 → resize.
- Find unused assets in the project → remove from export (or move out of `res://`).
- Find any duplicated textures → consolidate.
- **Acceptance:** Total build size reduced. Target: under 25 MB. Re-measure.

### Task 6.3 — Code optimization
- Search for any `_process()` doing work that should be event-driven. Convert.
- Pool any frequently spawned/freed nodes (floating numbers, particles).
- Cache `get_node()` lookups in `@onready` vars instead of repeated calls.
- **Acceptance:** No `_process()` does measurable work when the game is idle. Frame time during combat under 16ms on desktop.

### Task 6.4 — Mobile UI pass
- Make all clickable elements at least 44×44 px (Apple's touch target standard).
- Verify hand layout works on a 16:9 phone in landscape.
- Add explicit touch input handling where mouse-only events don't cover it.
- Disable card hover-lift on touch devices (it's confusing without a cursor).
- **Acceptance:** Game is playable on a real Android or iOS phone in browser, landscape orientation.

### Task 6.5 — Cross-browser test
Test the web build on:
- Chrome (desktop)
- Firefox (desktop)
- Safari (desktop, if possible)
- Chrome (Android)
- Safari (iOS, if possible — borrow a friend's phone)
- Any failures → file as bugs, fix the critical ones.
- **Acceptance:** Game loads and plays on all four major browser/OS combos.

### Task 6.6 — Custom HTML shell
- Provide a custom `index.html` template via Project → Export → Web → Custom HTML Shell.
- Add a branded loading screen (logo / title, animated progress bar).
- Set meta tags for social previews (og:image, og:title, og:description).
- **Acceptance:** Game opening URL looks branded, not like a Godot default page.

### Task 6.7 — Commit Phase 6
- `git commit -m "phase-6: web optimization and cross-browser support"`.
- **STOP. Dharm tests across devices. Wait for go-ahead.**

---

## Phase 7 — Meta-features (optional, time-permitting)

### Task 7.1 — Settings menu
- Master/SFX/Music volume sliders.
- Toggle: reduce motion (disables screen shake — accessibility).
- Toggle: show seed input field for replays.
- Persist settings to `user://settings.cfg`.
- **Acceptance:** Settings persist between sessions.

### Task 7.2 — Run history
- After each run, log to `user://run_history.json`: floor reached, enemies defeated, total damage, seed, duration.
- "Run History" screen accessible from main menu, shows last 10 runs.
- **Acceptance:** Completing runs adds entries to history.

### Task 7.3 — Card library / encyclopedia
- A screen accessible from main menu showing all cards in the game, viewable for reference.
- **Acceptance:** All 20+ cards are browsable.

### Task 7.4 — Achievements
- 5–10 achievements (e.g., "First Victory", "Stack of 10", "Win without taking damage").
- Persist to `user://`. Show toast on unlock.
- **Acceptance:** Achievements track and display correctly.

### Task 7.5 — Commit Phase 7
- `git commit -m "phase-7: meta features — settings, history, achievements"`.

---

## Phase 8 — Ship and share

### Task 8.1 — Final QA pass
- Play 5 full runs from start to boss without crashes.
- Verify all 20 cards work.
- Verify all 9 enemies work.
- **Acceptance:** No crashes, no obvious bugs.

### Task 8.2 — itch.io page
- Cover image (1280×720) — Dharm provides or generates via AI tool one-time.
- 5+ screenshots from Phase 5.
- 1 gameplay GIF.
- Description: pitch, mechanics, controls, credits to CC0 asset creators.
- Set page to public.
- **Acceptance:** itch.io page looks professional; game is publicly playable.

### Task 8.3 — GitHub README
- Project description, screenshots, gameplay GIF.
- Architecture section explaining the data-driven card system, the stack resolver, the seeded RNG.
- "Built with" section listing Godot 4, GDScript, asset credits.
- Link to live demo.
- **Acceptance:** README is comprehensive enough to be read by a recruiter cold.

### Task 8.4 — Resume/portfolio entry
- One-line pitch.
- Three bullet points: tech stack, mechanic innovation, deployment.
- Links to play and to source.
- **Acceptance:** Entry ready to paste into resume.

---

## Summary checklist

- [ ] Phase 0 — Setup
- [ ] Phase 1 — Data layer
- [ ] Phase 2 — Graybox loop
- [ ] Phase 3 — Juice pass 1
- [ ] Phase 4 — Content
- [ ] Phase 5 — Juice pass 2
- [ ] Phase 6 — Web optimization
- [ ] Phase 7 — Meta (optional)
- [ ] Phase 8 — Ship

End of `implementation_plan.md`. Dharm: review before handing to Claude Code.
