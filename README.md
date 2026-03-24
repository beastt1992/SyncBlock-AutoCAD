# SyncBlock - Powerful AutoCAD Block Synchronization Tool

![AutoCAD](https://img.shields.io/badge/AutoCAD-2020%2B-blue)
![AutoLISP](https://img.shields.io/badge/Language-AutoLISP-orange)
![Version](https://img.shields.io/badge/Version-v12--AttSync-green)

**SyncBlock** is a fast and intelligent AutoLISP tool designed to synchronize the internal content of multiple blocks in AutoCAD with a master block.

It allows you to use one "Master Block A" as a template and instantly update geometry, colors, and attribute definitions across any number of target blocks — ideal for MEP, equipment, factory layouts, architectural symbols, and large projects with repetitive blocks.

### ✨ Key Features

- **Smart Layer-Based Sync**: Only synchronizes objects on matching layers
- **Automatic Color Inheritance**: Remembers original colors per layer in target blocks and restores them after sync (solves the common "colors go wrong" issue)
- **Full Attribute Definition Sync** (New in v12-AttSync): Copies all AttDefs (tags, prompts, default values, positions, styles, visibility, etc.) and automatically runs `ATTSYNC`
- **Intelligent Position Compensation**: Uses bounding box calculation to ensure perfect alignment after copying
- **Supports Different Block Names**: Works even if target blocks have different names
- **Batch Processing**: Select multiple target blocks at once with a window selection
- **Undo Safe**: Entire operation is wrapped in a single undo mark
- **High Performance**: Optimized loops for faster execution with large numbers of blocks

### 📋 How to Use

1. Load `SyncBlock.lsp` into AutoCAD using `APPLOAD`
2. Type one of the following commands:
   - `SyncNow` or `SFM`
3. Follow the prompts:
   - Select the **Master Block A** (the one you want to copy from)
   - Select all **Target Blocks** (window selection supported)
4. The tool will automatically:
   - Clear existing content in target blocks
   - Copy geometry + attributes from master
   - Adjust position using bounding box offset
   - Restore original colors
   - Run `ATTSYNC` for attributes

### 🛠️ Version History

- **v12-AttSync** (Latest) – Added full attribute definition synchronization + automatic ATTSYNC
- **v12-Opt** – Major performance optimization (reduced vlax-for loops)
- **v12** – Introduced color memory and inheritance system

### ⚠️ Important Notes

- Current version synchronizes **only the top-level block** (Nested / Nested Block content is **not** recursively synced yet)
- Attribute sync uses **Replace mode**: All AttDefs in the target block are replaced by the master, but existing attribute values with matching tags are preserved where possible
- Always save your drawing before running the tool

### 🚀 Future Plans (Contributions Welcome)

- Recursive Nested Block synchronization support
- Progress bar for large selections
- DCL dialog interface (select layers to sync)
- Attribute value merge mode (instead of full replace)
- Layer blacklist (ignore specific layers)
- Batch processing across multiple drawings

### 📄 License

MIT License – Free to use, modify, and distribute for both personal and commercial projects.

### 🙋‍♂️ Author

Developed and optimized for real-world CAD workflows in Taiwan.

If you find any bugs, have feature requests, or want to contribute improvements, feel free to open an **Issue** or submit a **Pull Request**!

---

**Made with ❤️ for AutoCAD users who want faster and smarter block management.**

Thank you for using SyncBlock!
