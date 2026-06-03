# perf_baseline.md — Stack Overflow Web Export Baseline

Measured: 2026-06-04, before Phase 6 optimisation work.

---

## Build Size (exports/web/)

| File | Size |
|------|------|
| index.wasm | 50.88 MB |
| index.pck | 16.96 MB |
| index.js | 279 KB |
| index.html + icons + worklets | ~35 KB |
| **TOTAL** | **68.16 MB** |

**Note on the 25 MB target:** Godot 4.4's Compatibility renderer WASM binary is ~50 MB and cannot be meaningfully reduced without a custom engine build. The realistic target for Phase 6 is to minimise the PCK (currently 16.96 MB) as much as possible. Expected post-optimisation PCK: ~12–14 MB.

---

## Browser Cold-Load Time

*Cannot measure programmatically — requires manual browser testing.*

**Manual test procedure:**
1. Start Python server: `Start-Process python -ArgumentList "-m","http.server","8080" -WorkingDirectory "exports/web"`
2. Open `http://localhost:8080` in incognito Chrome
3. DevTools → Network tab → Hard reload (Ctrl+Shift+R)
4. Record: Time to first byte, time to "Playable" (main menu visible)

Baseline reading: **TODO (Dharm to fill in)**

---

## Frame Time During Gameplay

*Cannot measure programmatically — requires manual browser testing.*

**Manual test procedure:**
1. DevTools → Performance tab → Record
2. Play a full combat turn (draw, play 5 cards, Execute Stack, End Turn)
3. Stop recording. Note: worst frame time in ms, average frame time.

Baseline reading: **TODO (Dharm to fill in)**

---

## Asset Audit Findings

### Audio
| File | Disk Size | PCK Size (imported) | Format | Action |
|------|-----------|---------------------|--------|--------|
| bgm_loop.wav | 20.27 MB | 4.09 MB (QOA compressed) | WAV/QOA | Convert to OGG → ~2 MB |
| button_click.mp3 | 20 KB | ~20 KB | MP3 | Convert to OGG |
| defeat.mp3 | 269 KB | ~250 KB | MP3 | Convert to OGG |
| victory.mp3 | 315 KB | ~300 KB | MP3 | Convert to OGG |
| 8× SFX .ogg files | 97 KB total | ~80 KB | OGG | Already optimal ✅ |

Audio optimisation requires ffmpeg (not installed). Converting bgm_loop.wav → OGG saves ~2 MB from PCK.

### Textures
- No textures > 1024×1024 found. ✅
- All card frames (~48 KB each, 5 files) and card icons (~1 KB each, 14 used) are within limits.

### Unused Assets (imported but not referenced in any script/scene)
| Directory | Import Count | Disk Size | Action |
|-----------|-------------|-----------|--------|
| assets/sprites/ui/ | 36 imports | 0.37 MB | Exclude from export |
| assets/sprites/icons/ | 255 imports | 0.13 MB | Exclude from export |
| assets/sprites/cards/ (22–83) | ~63 imports | ~0.06 MB | Exclude cards beyond index 21 |

These are imported asset-pack sprites that were included during development but are not referenced in any script or scene. Adding export exclude filters removes them from the PCK.

### Export Preset State
- `export_filter = "all_resources"` — includes everything (no whitelist/blacklist)
- `exclude_filter = ""` — no exclusions currently set → unused assets get packed
- `variant/thread_support = false` ✅
- `vram_texture_compression/for_desktop = true` ✅
- `html/custom_html_shell = ""` → needs custom shell (Task 6.6)

---

## Projected Post-Optimisation Sizes

| Action | PCK Saving |
|--------|-----------|
| bgm_loop.wav → OGG | ~2.1 MB |
| Exclude sprites/ui, sprites/icons, unused cards | ~0.5 MB |
| MP3 → OGG (3 files) | ~0.05 MB |
| **Total PCK reduction** | **~2.6 MB** |
| **Projected PCK** | **~14.4 MB** |
| **Projected total build** | **~65.5 MB** |

WASM size (50.88 MB) is engine-fixed and cannot be reduced in Phase 6.
