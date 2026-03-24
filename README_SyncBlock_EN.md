# SyncBlock.lsp — AutoCAD Block Synchronization Tool

**Fast and intelligent tool to synchronize geometry between multiple blocks in AutoCAD.**

---

## What it does

- Uses one **Master Block** as the source of truth
- Synchronizes only objects on **matching layers** — child blocks stay in control of what they show
- Calculates precise position offset using bounding box comparison
- Supports blocks at any position in the drawing
- Batch process multiple target blocks in one run
- Safe **Undo** support (`Ctrl+Z`)

---

## Installation

1. Download `SyncBlock.lsp`
2. In AutoCAD, type `APPLOAD`
3. Select and load the file
4. Commands `SyncNow` or `SFM` are now available

**Tip:** Add it to AutoCAD's Startup Suite for automatic loading every session.

---

## How to Use

### Step 1 — Prepare your Blocks

**Master Block A** — contains all layers and all geometry. This is the only block you maintain.

**Child Blocks B, C, D...** — copied from Block A, with unwanted layer objects deleted inside the Block Editor.

> Layer names in child blocks **must match** layer names in Block A exactly.

### Step 2 — Run the sync

Type `SyncNow` or `SFM`:

```
1. Click to select Master Block A
2. Window-select all target Blocks (B, C, D...)
3. Done
```

The command line will show results:

```
Processing: 1F-FIRE
  28 layers, 156 objects
  Offset: (14989.7, 0.0)
  ✔ 152 objects synced (Hatch skipped)
```

---

## Commands

| Command | Description |
|---------|-------------|
| `SyncNow` | Run the sync |
| `SFM` | Shortcut for SyncNow |

---

## Notes

| Item | Details |
|------|---------|
| Hatch (fill patterns) | Skipped in current version, coming soon |
| Block A included in selection | Auto-skipped, no problem |
| Multiple floors | Create one Block group per floor, sync separately |
| Nested blocks | Not recursively updated in current version |

---

## Compatibility

| AutoCAD Version | Status |
|----------------|--------|
| 2014 and above | ✅ Supported |
| Below 2014 | Not tested |

---

## Troubleshooting

**Child Blocks disappear after sync?**  
Check that layer names in child Blocks exactly match Block A. Open Block Editor to verify.

**Objects end up in wrong position?**  
Make sure all Blocks were drawn in the same world coordinate system.

**Need to reload every session?**  
Add `SyncBlock.lsp` to AutoCAD's Startup Suite for automatic loading.

---

## Version History

| Version | Notes |
|---------|-------|
| v18 | Per-object copy, Hatch skipped, offset compensation fixed, AutoCAD 2014 compatible |
| v12 | BBox-based offset, color inheritance, attribute sync |
| v1–v11 | Development and testing |

---

## Support This Project

If SyncBlock has saved you time, consider buying me a coffee ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)

---

## License

MIT License — Free to use, modify, and distribute.

---

**Made with ❤️ for AutoCAD users.**
