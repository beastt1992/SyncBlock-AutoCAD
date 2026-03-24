[中文版](README_ZH.md) | **English**

---

# SyncBlock.lsp — AutoCAD Block Synchronization Tool

**Fast, resilient, and intelligent tool to synchronize geometry between multiple blocks in AutoCAD.**

---

## What it does

- Uses one **Master Block** as the source of truth
- Synchronizes only objects on **matching layers** — child blocks stay in control of what they show
- Uses an advanced **Consensus Voting Algorithm** for pixel-perfect alignment. It is highly resilient and ignores deleted lines, added dimensions, or missing boundaries.
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

1. Click to select Master Block A (v22 - Voting Sync)
2. Window-select all target Blocks (B, C, D...)
3. Done

The command line will show results:

Processing: 1F-FIRE
  Consensus Offset: (14989.7, 0.0)
  Done: 152 objects synced perfectly.

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
| Hatch (fill patterns) | Skipped in current version to prevent associativity crashes |
| Block A included in selection | Auto-skipped, no problem |
| Multiple floors | Create one Block group per floor, sync separately |
| Nested blocks | Not recursively updated in current version |

---

## Compatibility

| AutoCAD Version | Status |
|----------------|--------|
| 2014 and above | ✅ Supported (Uses pure English prompts to avoid ANSI/UTF-8 encoding bugs in older versions) |
| Below 2014 | Not tested |

---

## Troubleshooting

**Child Blocks disappear after sync?** Check that layer names in child Blocks exactly match Block A. Open Block Editor to verify.

**Objects end up in wrong position?** The v22 algorithm requires at least *some* original geometry (like a wall or a pipe) to match between Block A and the child blocks to calculate the offset. If you deleted 100% of the original geometry in the child block, it cannot align.

**Need to reload every session?** Add `SyncBlock.lsp` to AutoCAD's Startup Suite for automatic loading.

---

## Version History

| Version | Notes |
|---------|-------|
| v22 | Introduced Consensus Voting Algorithm for zero-offset alignment; Changed all prompts to English to fix AutoCAD 2014 encoding crash bugs |
| v18-v21 | Transitioned from BBox to anchor point registration, improved filtering of dimensions and texts |
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
