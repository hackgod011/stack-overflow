# guide.md — Coding & Architecture Guide

**Project:** Stack Overflow (working title) — a roguelike deckbuilder in Godot 4
**Engine:** Godot 4.4 (Standard build, GDScript)
**Target:** Web (HTML5/WebAssembly + WebGL 2.0), Desktop secondary

This file defines how code in this repo is written. It exists so that every
script, scene, and asset follows one consistent pattern, regardless of who
(or what) writes it.

---

## 1. Project structure

```
/
├── project.godot
├── guide.md                       ← this file
├── README.md
├── .gitignore                     ← ignore .godot/, *.import metadata, exports/
├── /assets
│   ├── /fonts                     ← JetBrainsMono.ttf, etc.
│   ├── /sprites                   ← cards, icons, ui frames
│   ├── /audio
│   │   ├── /sfx
│   │   └── /music
│   └── /shaders                   ← .gdshader files
├── /scenes
│   ├── /core                      ← Main.tscn, GameManager autoload
│   ├── /card                      ← card_view.tscn, hand.tscn, deck.tscn
│   ├── /combat                    ← combat_scene.tscn, enemy.tscn
│   ├── /ui                        ← hud.tscn, button.tscn, menus
│   └── /map                       ← run_map.tscn, node.tscn
├── /scripts
│   ├── /resources                 ← CardData.gd, EnemyData.gd (Resource subclasses)
│   ├── /autoloads                 ← GameManager.gd, AudioManager.gd, RNG.gd
│   ├── /systems                   ← turn_manager.gd, stack_resolver.gd
│   └── /utils                     ← helpers (tween presets, math, save/load)
├── /data                          ← .tres files (card definitions, enemy definitions)
│   ├── /cards
│   └── /enemies
└── /exports                       ← gitignored, output goes here
```

**Rules:**
- One scene = one root script. Script filename matches scene filename: `card_view.tscn` ↔ `card_view.gd`.
- All file and folder names use `snake_case`. No spaces, ever.
- Class names in `class_name` declarations use `PascalCase`.
- Card and enemy definitions are `.tres` (text resource) files, not hardcoded in scripts. Adding a new card = adding one `.tres` file.

---

## 2. GDScript style

Godot 4 has an official style guide. Follow it. Highlights:

### Naming
| Thing | Convention | Example |
|---|---|---|
| File / folder | snake_case | `card_view.gd` |
| Class (`class_name`) | PascalCase | `class_name CardView` |
| Function | snake_case | `func draw_card():` |
| Variable | snake_case | `var current_hp` |
| Constant | SCREAMING_SNAKE_CASE | `const MAX_HAND_SIZE = 10` |
| Enum type | PascalCase | `enum CardType {ATTACK, SKILL}` |
| Enum value | SCREAMING_SNAKE_CASE | `CardType.ATTACK` |
| Signal | snake_case, past tense for "happened", present for "happening" | `signal card_played(card)`, `signal turn_ended` |
| Private member (convention only — GDScript has no real privacy) | leading underscore | `var _internal_state` |
| Node in scene tree | PascalCase | `Hand`, `EndTurnButton` |

### Formatting
- **Tabs** for indentation, never spaces.
- One blank line between methods in the same class; two blank lines between top-level declarations.
- Type hints are **mandatory** on function signatures and exported variables. Use type inference (`:=`) for locals when the type is obvious from the right-hand side.
- Lines ≤ 100 chars where reasonable.

### Script layout order (top to bottom in every file)
```gdscript
# 1. @tool, @icon (if any)
@tool

# 2. class_name + extends
class_name CardView
extends Control

# 3. Doc comment (## triple hash)
## A visual representation of a single Card in the player's hand.
## Handles drag, hover, and the play animation.

# 4. Signals
signal card_clicked(card_data: CardData)
signal card_dragged(card_data: CardData, target_position: Vector2)

# 5. Enums
enum State { IDLE, HOVERED, DRAGGING, PLAYED }

# 6. Constants
const HOVER_LIFT_PIXELS := 32.0
const TWEEN_DURATION := 0.18

# 7. Exported variables (@export)
@export var card_data: CardData
@export var hover_sound: AudioStream

# 8. Public variables
var current_state: State = State.IDLE

# 9. Private variables (leading _)
var _tween: Tween
var _original_position: Vector2

# 10. @onready variables (last in variable block — they need scene tree ready)
@onready var _title_label: Label = $TitleLabel
@onready var _art_rect: TextureRect = $ArtRect

# 11. Built-in virtual methods (in order: _init, _enter_tree, _ready, _process, _input, etc.)
func _ready() -> void:
	_original_position = position

func _process(delta: float) -> void:
	pass

# 12. Public methods
func play() -> void:
	current_state = State.PLAYED
	_animate_play()

# 13. Private methods (leading _)
func _animate_play() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.2, 1.2), TWEEN_DURATION)

# 14. Signal handlers (always prefixed _on_)
func _on_button_pressed() -> void:
	card_clicked.emit(card_data)
```

---

## 3. Architecture rules

### 3.1 Data vs. View — non-negotiable
**Card data lives in `.tres` Resource files. Card visuals live in scenes.**

This is the single most important pattern in the project. Lifted from the
deckbuilder tutorial community standard:

```gdscript
# scripts/resources/card_data.gd
class_name CardData
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var cost: int = 1
@export var card_type: CardType.Type
@export var art: Texture2D
@export var effects: Array[CardEffect]  # composable effect resources
```

Adding 50 cards = creating 50 `.tres` files in `/data/cards/`. Zero code
changes. This is what makes the game scalable for a solo dev.

`CardView` (the scene) takes a `CardData` and renders it. The view never
contains gameplay rules. The data never contains visuals.

### 3.2 Signals over direct calls
Nodes should not reach across the tree to call each other's methods.
A `CardView` emits `card_clicked`; the `Hand` (its parent) listens and
decides what to do. The `Hand` emits `card_play_requested`; the
`CombatScene` listens and applies it.

Rule of thumb: **a child knows nothing about its parent. A parent connects
to its children's signals.**

### 3.3 Autoloads (singletons) — sparingly
Only for genuinely global state. In this project:
- `GameManager` — current run state, current floor, player HP, gold, deck
- `AudioManager` — wraps SFX/music playback; one bus
- `RNG` — wraps `RandomNumberGenerator` with a seed so runs are reproducible
- `EventBus` *(optional)* — global signals when point-to-point gets ugly

Do NOT make every system an autoload. Autoloads make tests harder and
state-tracking opaque.

### 3.4 RNG and reproducibility
Never call `randi()` or `randf()` directly. Always go through `RNG`:

```gdscript
# In RNG.gd autoload
var _rng := RandomNumberGenerator.new()

func seed_run(s: int) -> void:
	_rng.seed = s

func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)
```

When a run starts, `GameManager` generates one seed, passes it to `RNG`,
and stores it. Bugs reported as "the boss did X" can then be reproduced
exactly by replaying with the same seed.

### 3.5 State machines for combat flow
Combat flow has clear phases: `PLAYER_TURN_START → PLAYER_ACTING →
PLAYER_TURN_END → ENEMY_TURN → CHECK_WIN_LOSS → back to PLAYER_TURN_START`.

Use an explicit state machine (enum + match statement, or a Node-based
state machine). Do NOT scatter `if turn_phase == "..."` checks across
ten files.

---

## 4. Animation, juice, and visual polish

This is where most of the "looks expensive" comes from. Patterns to use:

### 4.1 Tweens for everything that moves
```gdscript
func animate_to_position(target: Vector2, duration := 0.2) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target, duration)
```

Every card movement, every HP bar change, every score number — tween it.
A linearly snapped value feels broken; a cubic-eased value feels alive.

### 4.2 Standard tween presets — define once, reuse
Create `scripts/utils/tween_presets.gd` with the project's standard easing
and durations so card movements feel consistent across the game.

### 4.3 Particles are cheap — use them
`GPUParticles2D` for play effects, damage bursts, card-shimmer. Limit
emit count on web (CPU particles can be heavy in the browser).

### 4.4 Screen shake on impact
Camera2D + a `shake(intensity, duration)` function on a Camera autoload.
Shake on every meaningful hit. Don't overshake — 4–8 pixels for normal,
12–16 for big.

### 4.5 Shaders — start with these three
- **Card hover glow** — fragment shader that adds a colored rim. 20 lines.
- **Damage flash** — multiply enemy sprite by white for 0.1s.
- **Holographic foil for rare cards** — sample a noise texture with UV
  offset by time. The "expensive looking" effect, ~40 lines.

Keep all shaders in `assets/shaders/`. Web export is **Compatibility renderer
+ WebGL 2.0** — avoid features that don't exist there:
- No compute shaders
- No SDFGI, no volumetric fog
- Dynamic loops in shaders work in WebGL 2.0 but not WebGL 1.0 — Godot 4
  uses WebGL 2.0 by default, so this is fine

---

## 5. Web export rules (this is where most projects break)

The web build is the *production* target. Local desktop is for development
only. These rules exist because the browser is more constrained:

1. **Test the web export weekly, from week 1.** Don't wait until the end.
   Things that work locally and break in the browser: file I/O, threading,
   certain shader features, audio formats.
2. **Audio:** Use OGG Vorbis, not WAV. WAV is uncompressed and bloats the build.
3. **Textures:** Stay under 1024×1024 per texture. Use atlases where possible.
4. **Build target setting:** in Project Settings → Rendering → Renderer →
   set `Rendering Method` to `Compatibility` (this is web's only option anyway;
   set it locally so what you see is what users see).
5. **Threads option in HTML5 export:** Disable threads (`Thread Support: off`)
   unless you specifically need them. This produces a build that runs on
   itch.io and GitHub Pages without SharedArrayBuffer/COOP/COEP headers.
6. **Total build size goal:** Under 25 MB for the WASM + assets combined.
   Initial load time should be under 5 seconds on typical 4G/home wifi.
7. **No filesystem writes** — for save data, use `user://` which on web
   maps to IndexedDB. Save small (JSON serialization of GameManager state).
8. **Mobile browsers:** Test on a real phone monthly. Touch input needs
   explicit handling (`_input(event)` with `InputEventScreenTouch`).

---

## 6. Performance defaults for web

- Target 60 FPS on desktop browsers, 30+ on mid-range mobile.
- Never do work in `_process` that could be event-driven. If something
  only changes when the player acts, update it on the action, not every
  frame.
- Reuse particle nodes; don't instantiate-and-free per-effect in a hot
  path. Pool them.
- Avoid loading resources from disk during combat. Preload everything in
  the scene's `_ready()`.

---

## 7. Git workflow

- `main` is always shippable (web build must always export cleanly).
- One feature per branch: `feat/hand-layout`, `feat/stack-resolver`,
  `fix/draw-pile-overflow`.
- Commit messages: `<scope>: <summary>` — e.g. `card: add hover lift animation`.
- Tag versions when you ship to itch.io: `v0.1.0`, `v0.2.0`, etc.

---

## 8. Testing

GDScript has the **GUT** (Godot Unit Test) framework. For this project,
unit-test the pure logic only:
- `CardEffect.apply()` — does damage math work correctly?
- `StackResolver.resolve()` — does the right execution order happen?
- `RNG` — does seeding produce reproducible sequences?

Don't try to unit-test scene/visual code. Test it by playing it.

---

## 9. Anti-patterns — don't do these

- ❌ Putting gameplay rules inside `CardView` (the visual). Rules belong in `CardData` + `CardEffect` + `StackResolver`.
- ❌ Calling `get_node("../../../GameManager")` — use autoloads or signals.
- ❌ Storing card definitions in a giant dictionary inside a script. Use `.tres` resources.
- ❌ `randi()` outside the `RNG` autoload.
- ❌ Skipping the web export test for "just one more feature." It always breaks.
- ❌ Optimizing before the feature works. Make it run, make it right, then make it fast — in that order.

---

End of guide.md. Update this file when patterns evolve.
