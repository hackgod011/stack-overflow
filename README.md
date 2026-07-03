# Stack Overflow

> A roguelike deckbuilder where your cards are stack operations — and the order you stack them changes the math.

**🟢 Live — play it in your browser: <https://hackgod011.github.io/stack-overflow/>**

**Stack Overflow** is a single-player, turn-based roguelike deckbuilder built in **Godot 4.4** (GDScript) and exported to the **web (HTML5 / WebAssembly)**. Cards are programming primitives — `PUSH`, `POP`, `DUP`, `SWAP`, `ADD`, `MUL`, `LOOP`, `IF` — plus combat effects like `STRIKE` and `DEFEND`. Each turn you draw a hand, **stack cards onto a visual LIFO stack in any order**, then hit **Execute**. The stack resolves top-down, and because operations consume and produce values, the *order you stack them in is the puzzle*.

<!-- TODO: add screenshots + gameplay GIF here once the itch.io page assets are finalized (see Phase 8.2) -->
<!-- ![Combat screenshot](docs/screenshot-combat.png) -->
<!-- ![Gameplay GIF](docs/gameplay.gif) -->

---

## ▶ Play

- **Play now (GitHub Pages):** **<https://hackgod011.github.io/stack-overflow/>** — deployed automatically from `main` via GitHub Actions.
- **Run the web build locally:**
  ```bash
  # from the repo root, after exporting to exports/web/
  cd exports/web
  python -m http.server 8080
  # then open http://localhost:8080 in a normal (non-incognito) browser tab
  ```
  > Browsers block Godot web builds opened directly from the filesystem — always serve over HTTP.
  > Use a normal window, not incognito: progress is saved to `user://` and incognito wipes it on close.

---

## How it plays

1. **Draw** 5 cards from your deck each turn; you have a fixed energy budget.
2. **Stack** cards onto the central stack zone in whatever order you like. Value cards (`PUSH 5`) put numbers on a runtime data stack; operation cards (`DUP`, `ADD`, `MUL`) transform what's there; effect cards (`STRIKE`) read it.
3. **Execute.** The stack resolves **top to bottom (LIFO)**. Cards animate as they fire, and the live data stack updates after each one.
4. Damage from a hit like `STRIKE` is `base + sum of all values currently on the runtime stack` — so `PUSH 5 → DUP → STRIKE(6)` deals `6 + 5 + 5 = 16`. Stacking the same cards in a different order does something different.
5. **End your turn**, the enemy telegraphs and lands its attack, and you bleed energy and cards toward a win or a permadeath loss.
6. Between fights you navigate a **Slay-the-Spire-style node map** (fights → elites → shops → boss) generated deterministically from the run seed.

---

## Highlights

- **22 cards** across value / operation / flow-control / effect types, each defined as data (`.tres`), not code.
- **9 enemies** — 6 regular, 2 elites, and a multi-phase boss (`the_compiler`) with stat/pattern shifts on phase transitions.
- **Status effects** (Vulnerable, Weak, Block) that tick down per turn and modify damage.
- **Seeded RNG** — every run is reproducible from its seed for debugging and replays.
- **Full juice pass** — tweened card motion, hover lift, floating damage numbers, particle bursts, screen shake, and step-by-step stack-execution choreography.
- **Custom shaders** — holographic foil on rare cards, a pulsing glow on the Execute button, and a white damage-flash on enemies.
- **Meta systems** — persistent settings, run history, a browsable card library, and achievements, all saved to `user://`.
- **Local-first persistence** — runs, settings, and a discovered-card collection survive page reloads and server restarts.

---

## Architecture

The codebase is built around a **data-driven, composable effect system** that keeps gameplay logic out of hardcoded `if`-chains.

### Data-driven cards
A `CardData` resource holds metadata (`id`, `title`, `cost`, `type`, `rarity`) and an ordered `Array[CardEffect]`. Each `CardEffect` is its own small `Resource` subclass that overrides a single `apply(context)` method — `PushValueEffect`, `DupEffect`, `DealDamageEffect`, `LoopEffect`, `IfPositiveEffect`, and so on. A card is just a list of effects, so new cards are authored as `.tres` files in the editor with **zero new code**, and complex cards are composed from primitive effects.

### The stack resolver
[`StackResolver`](scripts/systems/stack_resolver.gd) is **pure logic** — no scene/visual dependencies, so it's trivially testable. It iterates the played cards top-to-bottom, runs each card's effects against a shared `context` dictionary (which carries the `runtime_stack`, the damage accumulator, the player, and the enemies), and supports flow control via context flags: `LoopEffect` re-runs the next card N times, `IfPositiveEffect` skips the next card unless the stack top is positive, and `BreakEffect` halts resolution. It records a snapshot of the data stack after each card so the combat scene can animate execution step by step.

### Seeded RNG
A single [`RNG`](scripts/autoloads/rng.gd) autoload wraps Godot's `RandomNumberGenerator`. Seeding once with `seed_run(seed)` makes the entire run — shuffles, rewards, map layout, random-value cards — deterministic and reproducible, which is what makes bugs filable and runs shareable.

### Autoloads (global state & services)
`RNG`, `GameManager` (run-wide HP / gold / deck / piles + signals), `SettingsManager`, `CollectionManager`, `AudioManager`, `HistoryManager`, and `AchievementManager`.

### Layout
```
scripts/
  autoloads/    RNG, GameManager, AudioManager, Settings/History/Achievement/Collection managers
  resources/    CardData, CardEffect base, EnemyData, StatusEffect + concrete effects/ and statuses/
  systems/      StackResolver (pure logic)
  card/         CardView, Hand
  combat/       CombatScene, StackZone, Enemy
  map/          RunMap
  ui/           reward / shop / settings / library / history / game-over screens, FX
  core/         MainMenu
data/
  cards/        22 card definitions (.tres)
  enemies/      9 enemy definitions (.tres)
assets/
  shaders/      holo_foil, execute_glow, damage_flash
  audio/        music loop + SFX (.ogg)
  sprites/      enemy art, card frames/icons
scenes/         .tscn scenes mirroring the script layout
exports/web/    HTML5 / WASM build output
```

---

## Built with

- **[Godot 4.4](https://godotengine.org/)** (Standard build) — Compatibility renderer for broad web/WebGL 2.0 support.
- **GDScript.**
- **WebAssembly / HTML5** export — single-threaded variant (no COOP/COEP headers required, runs on itch.io / GitHub Pages).
- **Python** `http.server` for local web testing.

### Credits

- Audio: CC0 SFX and ambient music loop (`.ogg`).
- Enemy sprite art: themed single-frame sprites processed from a provided asset pack.

> Full per-asset attribution for CC0 sources will accompany the public itch.io release (Phase 8.2).

---

## Project status

Built phase by phase from a written implementation plan (`implementation_plan.md`):

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project scaffold + web export | ✅ |
| 1 | Data layer, RNG, autoloads, starter cards | ✅ |
| 2 | Graybox core combat loop (playable on web) | ✅ |
| 3 | First juice pass — tweens, SFX, particles | ✅ |
| 4 | Content depth — full card/enemy library, map, shop, rewards | ✅ |
| 5 | Visual polish — shaders, screen shake, typography, art | ✅ |
| 6 | Web optimization & cross-browser pass | ✅ |
| 7 | Meta-features — settings, run history, card library, achievements | ✅ |
| 8 | Ship & share — QA, README, portfolio | ✅ (**live on [GitHub Pages](https://hackgod011.github.io/stack-overflow/)**) |

> Note: the Compatibility renderer's WASM binary (~51 MB) is engine-fixed; the gameplay payload (`.pck`) is ~14–17 MB. See [`perf_baseline.md`](perf_baseline.md).

---

## Repository

<https://github.com/hackgod011/stack-overflow>
