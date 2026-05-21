# do_not_do.md — Guardrails for Claude Code

**Audience:** Claude Code (or any AI agent) implementing this project.
**Purpose:** A list of behaviors and code patterns that are explicitly
forbidden during implementation. Read this in full before writing
any code. Re-read it whenever you finish a phase.

This file exists because LLM agents have predictable failure modes
when building game projects. Each rule below addresses a real one.

---

## A. Process rules (how you work)

### A1. Do not skip phases or merge tasks
The implementation plan is ordered for a reason. Phase 2 (graybox)
must work before Phase 3 (juice) begins, because polish on a broken
foundation is wasted work. Do tasks in order, one at a time.

### A2. Do not start the next phase without explicit user approval
At the end of each phase, the plan says "STOP. Report to Dharm. Wait
for go-ahead." Honor this. The user needs to playtest, balance, and
review before you continue. Auto-starting the next phase removes their
ability to course-correct.

### A3. Do not invent gameplay rules or numerical balance
The plan tells you *what* to build (`STRIKE deals 6 damage`). It does
NOT authorize you to invent:
- New cards not in the plan
- Different damage values from those specified
- Additional enemies, statuses, or mechanics
- Difficulty curves

If a numerical value is missing, **ask Dharm**. Do not guess. Game
balance is a design decision, not an implementation detail.

### A4. Do not delete or rewrite `guide.md`, `implementation_plan.md`, or `do_not_do.md`
You may suggest edits in your response, and Dharm may accept or
reject them. You may not modify these files yourself.

### A5. Do not commit without Dharm's approval at phase boundaries
Within a phase, commit freely on a feature branch. At phase boundaries,
the commit message and contents need Dharm's eyes first.

### A6. Do not "fix" the user's design choices
If Dharm says "I want cards to fly in from the right," do not silently
implement them flying in from the left because you think it's better.
Ask if you disagree. Then implement what was decided.

### A7. Do not skip the weekly web export check
Every phase that ends in "Web export check" must actually export and
verify in a browser. Things that work in the Godot editor and silently
break in the browser: audio formats, certain shaders, threading,
filesystem access. Catch these weekly, not at the end.

### A8. Do not leave TODOs without filing them
If you finish a task but leave a `# TODO:` in code, write a corresponding
note in the response to Dharm so he knows it's there. Hidden TODOs
become forgotten bugs.

---

## B. Code structure rules

### B1. Do not put gameplay rules inside view scenes
`CardView` is a scene. It displays a card. It does NOT:
- Calculate damage
- Apply effects
- Modify game state
- Know about enemies

Gameplay rules live in `CardEffect` subclasses and `StackResolver`.
The view receives a `CardData` and renders it. That's all.

This separation is the single most important rule in the project.
Violating it makes the code unscalable and untestable.

### B2. Do not hardcode card or enemy definitions in scripts
All cards and enemies are `.tres` files in `data/`. If you find
yourself writing:
```gdscript
# WRONG
var strike = CardData.new()
strike.title = "Strike"
strike.cost = 1
# ...
```
inside a `.gd` file — stop. Create the `.tres` file in the editor instead.

### B3. Do not use `randi()`, `randf()`, or `randomize()` directly
Always go through the `RNG` autoload. Direct calls break run
reproducibility, which makes bug reports impossible to investigate.

Wrong: `var picked = arr[randi() % arr.size()]`
Right: `var picked = RNG.pick(arr)`

### B4. Do not use `get_node("../../...")` style paths
Cross-tree node access via relative paths is fragile and breaks
when scenes are restructured. Use signals (preferred), or autoloads
for genuinely global state.

### B5. Do not make every system an autoload
Autoloads are for genuinely global state: `GameManager`, `RNG`,
`AudioManager`. Not for: combat logic, card display, enemy AI.
Those are scene-local.

### B6. Do not skip type hints
Function signatures and exported variables must have type hints.
This is non-negotiable per `guide.md`.

Wrong: `func apply(context):`
Right: `func apply(context: Dictionary) -> void:`

### B7. Do not write huge functions
Any function over ~40 lines should be broken into smaller ones.
A function that handles "execute the entire stack" should call
helpers, not contain everything inline.

### B8. Do not skip the data-vs-view separation for "convenience"
The temptation to just "put the damage calculation right here in
CardView for one card, I'll refactor later" is the path to an
unmaintainable codebase. There is no later. Do it right the first time.

---

## C. Web export rules (most projects break here)

### C1. Do not enable threads in the web export
`Thread Support` must be **OFF** in the web export preset. With
threads on, your build requires SharedArrayBuffer + COOP/COEP headers,
which itch.io and most free hosts don't provide. Single-threaded
build is the correct default.

### C2. Do not use WAV audio files
Convert all audio to OGG Vorbis before importing. WAV files are
uncompressed and will bloat the build by 5–10× per file.

### C3. Do not use textures larger than 1024×1024
Web GPU memory is constrained. Atlas your sprites; resize anything
oversized. Card art should be at most 512×768.

### C4. Do not use shader features unavailable in Compatibility renderer
Web export uses the Compatibility renderer (GLES3 / WebGL 2.0). NOT
available:
- Compute shaders
- SDFGI, volumetric fog, certain post-processing
- Some advanced particle features

If a shader works in the editor but not in web export, this is why.
Test in the browser, not the editor.

### C5. Do not write to absolute filesystem paths
Save data goes to `user://`. On web, this maps to IndexedDB.
Never use `/home/...`, `C:\\...`, or `res://` for writes.

### C6. Do not load resources from disk during combat
All combat-needed resources should be `preload()`ed at scene
`_ready()`. Loading mid-combat causes hitches in the browser.

### C7. Do not assume the local build behaves like the web build
The web build is the production target. Test it weekly. Do not
declare a feature "done" without checking the web export.

### C8. Do not use mouse-only event handling
For mobile compatibility, handle both `InputEventMouseButton` and
`InputEventScreenTouch`. Or use Godot's higher-level `gui_input`
which abstracts both.

---

## D. Performance & optimization rules

### D1. Do not optimize before features work
Do not spend time pooling particles, caching node lookups, or
shrinking textures while the core loop isn't finished. Performance
work happens in Phase 6, on stable code.

### D2. Do not do per-frame work that could be event-driven
A `_process()` that recalculates the player's total block every
frame is wrong. Block changes when something happens — emit a signal
and update on that signal. `_process()` is for genuinely continuous
things (smooth interpolation that doesn't use tweens, real-time input).

### D3. Do not instantiate-and-free nodes in a hot path
Floating damage numbers spawn frequently. Don't `instance()` and
`queue_free()` each one — pool them. Same for particle effects.
(Apply this rule starting in Phase 6, not Phase 3.)

### D4. Do not load shaders inside `_process()`
Load shaders at `_ready()` via `preload()`, cache, reuse.

### D5. Do not use `print()` in shipped builds
Use `print()` freely during development. Strip them before each
web export, or wrap in `if OS.is_debug_build()`. Excessive prints
hurt browser console performance.

---

## E. Asset & licensing rules

### E1. Do not use copyrighted assets without verification
Every asset used must have a verifiable license that allows
non-commercial or commercial use. Acceptable sources:
- Kenney.nl (CC0)
- itch.io assets explicitly tagged CC0 or with a permissive license
- Google Fonts (check individual font license — most are SIL OFL)
- freesound.org with CC0 filter
- jsfxr / bfxr generated SFX (yours, by definition)

Not acceptable:
- "Found on Pinterest"
- AI-generated assets you can't track the provenance of (avoid for
  in-game assets; one-off marketing image is okay)
- Anything copied from another game

### E2. Do not skip asset credits
Maintain a `CREDITS.md` listing every asset, its source, its
author, and its license. Required for itch.io and GitHub.

### E3. Do not use unverified-license assets to "speed things up"
If a license is unclear, find a different asset. Recruiters
sometimes check.

---

## F. Communication rules (talking to Dharm)

### F1. Do not silently swallow errors
If a task fails (export breaks, test fails, code doesn't compile),
report it clearly with the error message. Do not "fix" it by
disabling the failing feature.

### F2. Do not produce wall-of-text responses for simple updates
When reporting task completion, keep it brief: what was built, what
was tested, any concerns, next task. Long updates obscure issues.

### F3. Do not ask questions you can answer yourself
If `guide.md` already specifies the answer, follow `guide.md` and
proceed. Only ask Dharm for design decisions, balance, naming, or
ambiguous requirements.

### F4. Do not over-promise
Don't say "this will definitely run at 60 FPS on every phone" —
say "this should run well; we'll verify in Phase 6."

### F5. Do not pretend to have tested when you haven't
If you couldn't actually run the web export (no browser available),
say so. Do not claim "tested in browser — works fine" when you
only verified in the editor.

---

## G. Specific to this game

### G1. Do not change the stack semantics
This is a LIFO stack. Cards added later execute first. Do not
"helpfully" make it a queue, or execute oldest first, because
that seems more intuitive. The mechanic IS the game; changing
it changes the game.

### G2. Do not add real-time elements
This is a turn-based game. The player presses Execute when ready.
Do not add timers, "you must play within 30 seconds" mechanics,
or anything that pressures the player in real-time. That's a
different genre.

### G3. Do not add multiplayer or networking
This is a single-player, single-machine game. No accounts, no
leaderboards-via-server, no save-syncing. Local storage only.
Networking adds enormous complexity for zero gameplay benefit
here.

### G4. Do not make the theme literal-only
The theme is "programming," but every card doesn't need to be a
real CS concept. Some cards should be flavorful jokes that any
player can understand even without a CS background. Aim for
"a game that CS people will love but non-CS people can still play."

---

## H. When in doubt

**Ask Dharm.** No design decision is too small to flag if you're unsure.
The cost of asking is one message. The cost of building the wrong
thing is hours of rework.

End of `do_not_do.md`.
