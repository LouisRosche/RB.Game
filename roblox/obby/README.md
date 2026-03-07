# Publish-Practice Obby

A minimal obstacle course used to complete the full Roblox publish cycle
(the **Skill Building** Phase 0 checkpoint in `docs/roadmap.md`).

Publishing even a trivial game end-to-end de-risks the real launch:
icons, thumbnails, description, privacy settings, and the Rojo → Studio
workflow all get exercised on a throwaway project.

---

## Step 1 — Build the map in Roblox Studio

1. Open a new Baseplate place in Studio.
2. Create a `Folder` named **Checkpoints** directly in `Workspace`.
3. Add `Part` children. For each part:
   - Set a `NumberValue` attribute named `CheckpointNumber` (1 = spawn platform, 2, 3 … N = finish).
   - Set `Anchored = true`, `CanCollide = false`, `Transparency = 0.5`.
   - Resize and colour them however you like — they're invisible "trigger" regions.
4. Build at least 5 platforms with jump gaps between checkpoints. Keep it
   simple — this is a workflow test, not a real game.
5. Update `TOTAL_CHECKPOINTS` in `src/client/Main.client.luau` to match
   your highest checkpoint number.

## Step 2 — Sync with Rojo

```sh
cd roblox/obby/
rojo serve default.project.json
```

In Studio → Rojo plugin → Connect → Play to test checkpoint respawn.

## Step 3 — Publish as Private (unlisted)

1. File → Publish to Roblox As…
2. Name: "Obby Test (internal)"
3. Genre: All; Playable Devices: PC
4. Privacy: **Friends** or **Private** (not public yet)
5. Upload a placeholder 512×512 icon (any coloured square).
6. Publish.

## Step 4 — Configure the game page

In the Creator Dashboard (create.roblox.com):
- Add 3 screenshots (screenshots of the Studio viewport are fine).
- Write a short description ("Internal publish-cycle test.").
- Enable **Age Recommendations** (set to "All Ages").
- Leave monetization off.

## Step 5 — Invite 2–3 friends to test

Share the private link. Confirm:
- Checkpoint respawn works.
- HUD label updates correctly.
- No script errors in the Output panel.

## Step 6 — Mark the checklist item done

Once published, check off in `docs/roadmap.md`:
- `✅ Publish a trivial game (obby) to complete the full publish cycle`

You now know the full publish workflow. Delete or archive this game
after testing — it doesn't need to stay live.

---

## Files

```
obby/
├── default.project.json          Rojo config
└── src/
    ├── server/Main.server.luau   Checkpoint tracking + respawn
    └── client/Main.client.luau   Checkpoint HUD (TextLabel)
```
