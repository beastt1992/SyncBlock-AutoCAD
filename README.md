# SyncBlock — AutoCAD Block Synchronization Tool

**Fast and intelligent tool to synchronize geometry, colors, and attributes between multiple blocks in AutoCAD.**

---

## What it does

- Uses one **Master Block** as the source
- Synchronizes only objects on matching layers
- Automatically remembers and restores original colors of target blocks (Color Inheritance)
- Fully synchronizes **Attribute Definitions** + runs automatic `ATTSYNC` (v12-AttSync)
- Calculates precise position offset using bounding box
- Supports blocks with different names
- Batch process multiple target blocks at once
- Safe Undo support

---

## Installation

1. Download the latest `SyncBlock.lsp`
2. In AutoCAD, type `APPLOAD`
3. Select and load the LSP file
4. Commands `SyncNow` or `SFM` will be available

**Tip:** Add it to AutoCAD Startup Suite for automatic loading every time.

---

## How to Use

1. Type `SyncNow` or `SFM` in the command line
2. Select the **Master Block A** (the one you just edited)
3. Window-select all **Target Blocks** you want to update
4. Wait for the process to finish

The tool will:
- Clear old content in target blocks
- Copy geometry and attributes from master
- Restore original colors
- Automatically run ATTSYNC
- Show completion message

---

## Features

- Smart layer-based synchronization
- Color inheritance system (keeps your original layer colors)
- Complete attribute definition sync with ATTSYNC
- High-performance optimized code
- Works with Dynamic Blocks (EffectiveName)
- Compatible with AutoCAD 2014 and newer

---

## Changelog

**v12-AttSync** (Latest)  
- Added full attribute definition synchronization  
- Automatic ATTSYNC after each block  
- Improved performance

**v12-Opt**  
- Major performance optimization (reduced loops)

**v12**  
- Introduced color memory and inheritance

---

## Important Notes

- Current version only synchronizes the **top-level** block content.  
  Nested blocks (blocks inside blocks) are **not** recursively updated yet.
- Attribute sync replaces definitions but tries to preserve existing attribute values with matching tags.
- Always save your drawing before running the tool.

---

## Support This Project

If SyncBlock has saved you time and made your workflow easier, consider buying me a coffee ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)

---

## License

MIT License — Free to use, modify, and distribute.

---

**Thank you for using SyncBlock!**  
Made with ❤️ for AutoCAD users who want faster and smarter block management.

---

**Author:** Beastt1992 (Taiwan)
