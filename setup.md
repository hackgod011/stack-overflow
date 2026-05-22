# setup.md — Manual Setup Before Claude Code Starts

**Audience:** You (Dharm). Do this **before** handing the project to Claude Code.
**Time required:** 60–90 minutes the first time, mostly waiting on downloads.

Some setup steps cannot be done by an AI agent — installing GUI applications,
clicking "Download" on websites that require accounts, generating sound
effects with web-based tools. This file lists exactly what you need to do
manually. Everything else, Claude Code handles.

When you finish each section, check the box. When all boxes are checked,
hand the project to Claude Code with `implementation_plan.md`.

---

## 1. Install Godot 4.4 — REQUIRED

- [ ] Go to https://godotengine.org/download
- [ ] Download **Godot Engine 4.4** for Windows — the **Standard** version
      (NOT the .NET / C# version; web export for .NET is still maturing,
       and GDScript is faster for this project anyway)
- [ ] Extract the `.zip` (Godot is portable; no installer). Move
      `Godot_v4.4-stable_win64.exe` to a permanent location like
      `C:\Tools\Godot\` or `C:\Users\dhyey\Godot\`
- [ ] Double-click the .exe once to confirm it launches. You'll see the
      project manager window. Close it.
- [ ] (Optional but recommended) Pin the Godot .exe to your taskbar or
      create a desktop shortcut

**Why no installer:** Godot ships as a single portable executable. No
admin rights, no install wizard, no PATH changes needed.

**How to verify your version:** Project Manager → top-right corner shows
the version. Should say `v4.4.stable`.

---

## 2. Verify your existing toolchain — REQUIRED

You already have these from your NSE mispricing project setup, but
double-check:

- [ ] **Git** — open PowerShell, run `git --version`. Should print a version.
- [ ] **VS Code** — installed and working
- [ ] **Python 3** — `python --version` should print 3.x (Python is used
      only as a quick local web server for testing the web export. You
      already have 3.13.2)
- [ ] **GitHub account** — you have one (`Bhavya26505`)
- [ ] **Node.js** (optional, only needed if you later add CI/CD) — skip
      for now

---

## 3. Install VS Code Godot extension — REQUIRED

- [ ] Open VS Code
- [ ] Extensions tab (Ctrl+Shift+X)
- [ ] Search: `godot-tools`
- [ ] Install the one by **geequlim** (it's the official one, ~500k+ installs)
- [ ] No further configuration needed at this stage — Claude Code will
      configure the project's `.vscode/` if needed

---

## 4. Create the GitHub repository — REQUIRED

- [ ] Go to https://github.com/new
- [ ] Repository name: `stack-overflow` (or whatever you prefer; keep
      it lowercase and hyphenated)
- [ ] Visibility: **Private** initially. You can flip it public when
      you ship in Phase 8
- [ ] Do **NOT** initialize with README, .gitignore, or license — Claude
      Code will create those
- [ ] After creating, copy the repo URL (looks like
      `https://github.com/Bhavya26505/stack-overflow.git`). You'll give
      this URL to Claude Code in Task 0.3

---

## 5. Create the project folder — REQUIRED

- [ ] Decide where the project will live. Recommended:
      `C:\Users\dhyey\Downloads\stack_overflow\` (sibling of your
      `nse_mispricing` project)
- [ ] Create an empty folder there. Leave it empty.
- [ ] Open PowerShell, `cd` into the folder
- [ ] This is where you'll launch Claude Code from

---

## 6. itch.io account — REQUIRED before Phase 2 (not Phase 0)

You don't need this on day one, but you'll need it by the end of
Phase 2 to test the web export on actual itch.io.

- [ ] Create account at https://itch.io
- [ ] Verify your email
- [ ] (Don't create the game page yet — wait until you have something
      to upload)

---

## 7. Download free assets — REQUIRED before Phase 3

You can skip this for Phase 0–2 (which uses placeholder grey
rectangles). Do this section before starting Phase 3 (first juice pass).

### 7a. Fonts (5 min)

- [ ] Go to https://fonts.google.com
- [ ] Search: `JetBrains Mono`. Click "Download family" (top-right)
- [ ] Search: `Press Start 2P` (for the chunky title font). Download
- [ ] Extract both `.zip` files. You'll move the `.ttf` files into
      `assets/fonts/` after Phase 0 is done

### 7b. UI elements & icons (10 min)

- [ ] Go to https://kenney.nl/assets
- [ ] Download these packs (all free, all CC0):
      - **UI Pack** — buttons, panels, frames
      - **Game Icons** — generic icons (sword, shield, heart, etc.)
      - **1-Bit Pack** (optional) — fits the terminal aesthetic well
- [ ] You don't need an account; click "Download" on each pack page
- [ ] Keep the downloaded `.zip` files somewhere; you'll extract the
      specific files you need in Phase 3

### 7c. Pixel card pack (optional, 2 min)

- [ ] Go to https://kerenel.itch.io/pixelart-cards
- [ ] Click "Download Now" → "No thanks, just take me to the
      downloads" → download the `.zip`
- [ ] This gives you a card-back template even if you go with the
      "no illustrative art" route

### 7d. Audio — Phase 3 only (15 min)

**For sound effects:**

- [ ] Go to https://sfxr.me (this is jsfxr in your browser; nothing to
      install)
- [ ] You'll generate these in Phase 3, not now. The plan tells Claude
      Code which SFX are needed:
      `card_hover, card_play, card_draw, card_discard, button_click,
      enemy_hurt, player_hurt, block_gain, execute_stack, victory, defeat`
- [ ] For each, click a preset (e.g., "Pickup/Coin" for card_draw,
      "Hit/Hurt" for enemy_hurt) → tweak sliders until you like it →
      click "Export Wav"
- [ ] Save each as `card_hover.wav`, `card_play.wav`, etc., in a folder
- [ ] Convert WAV → OGG using https://convertio.co/wav-ogg/ (drag and
      drop, 10 seconds per file) **OR** install Audacity and batch-export

**For music:**

- [ ] Go to https://freesound.org and create a free account
- [ ] Search: `ambient loop` or `synthwave loop` or `terminal ambient`
- [ ] Filter: License → **Creative Commons 0**
- [ ] Download one 30–60 second loop you like
- [ ] Note the URL and author for `CREDITS.md`

---

## 8. Install a local web server — REQUIRED for testing web exports

You need this to test the web build locally before uploading. You
already have Python, so you already have one:

- [ ] In PowerShell, `cd` into any folder, run:
      `python -m http.server 8000`
- [ ] Open http://localhost:8000 in your browser. You should see a file
      listing
- [ ] Press Ctrl+C to stop it

**Why:** Browsers block running `index.html` from `file:///` paths for
security. You must serve it via HTTP, even locally.

---

## 9. (Optional) Aseprite or LibreSprite — for pixel art editing

Skip unless you specifically want to edit pixel art:

- [ ] **LibreSprite** (free): https://libresprite.github.io — download
      the Windows build
- [ ] OR **Piskel** (free, browser-based): https://www.piskelapp.com — no
      install needed
- [ ] OR **Aseprite** ($20 on Steam) — only if you have budget; the free
      options above cover this project's needs

---

## 10. (Optional) OBS for recording gameplay GIFs — Phase 8 only

For making screenshots and GIFs for the itch.io page:

- [ ] Skip this until Phase 8
- [ ] OBS Studio (free): https://obsproject.com
- [ ] Or use Windows Game Bar (Win + G) for quick clips — built into Windows

---

## 11. Pre-flight checklist before launching Claude Code

Before you run Claude Code for the first time, confirm:

- [ ] Godot 4.4 is installed and you can launch the editor
- [ ] An empty project folder exists at your chosen path
- [ ] Git is installed (`git --version` works)
- [ ] The GitHub repo URL is copied to your clipboard or saved somewhere
- [ ] These four files are in the empty project folder:
      - `setup.md` (this file)
      - `implementation_plan.md`
      - `guide.md`
      - `do_not_do.md`
- [ ] You've read all four files at least once so you understand the flow

---

## 12. How to start Claude Code

From the project folder in PowerShell:

```
claude
```

Then give Claude Code this opening prompt:

> Read `setup.md` to understand what I've already set up manually.
> Then read `implementation_plan.md`, `guide.md`, and `do_not_do.md`
> in full. Confirm you understand the rules. Then start with Task 0.1
> from `implementation_plan.md`. Proceed one task at a time and stop
> at every "STOP" instruction.
>
> My GitHub repo URL is: <paste your URL here>
> My Godot path is: <paste path to Godot exe here, e.g. C:\Tools\Godot\Godot_v4.4-stable_win64.exe>

---

## Troubleshooting

**"Godot won't launch / crashes immediately"**
You might have downloaded the wrong architecture. On modern Windows
(64-bit), use the file named `_win64.exe`. If you're on a 32-bit
Windows (very rare), use `_win32.exe`.

**"Git asks for credentials when I push"**
Use a Personal Access Token, not your password. GitHub → Settings →
Developer settings → Personal access tokens → Generate new. Give it
`repo` scope. Use the token as your password when prompted.

**"Web export doesn't run in the browser when I double-click index.html"**
This is expected. Run `python -m http.server 8000` in the `exports/web/`
folder and open `http://localhost:8000` instead.

**"I downloaded a Kenney asset pack but the files are huge / there are
thousands of files"**
That's normal. Each pack has many variants. Pick one or two folders that
match your aesthetic, ignore the rest. You don't need to use everything.

---

End of setup.md.
