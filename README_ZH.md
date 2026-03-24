**中文版** | [English](README.md)

---

# SyncBlock.lsp — AutoCAD 圖塊同步工具

**快速、智慧地將主底圖的內容同步到多個子圖塊。**

---

## 功能說明

- 以一個**主底圖 Block A** 作為唯一維護來源
- 根據**圖層名稱比對**，只複製子 Block 裡有的圖層
- 使用 Bounding Box 精準計算座標位移，位置永遠正確
- 支援圖面上任意位置的 Block
- 一次同步多個目標 Block
- 支援 **Undo**（`Ctrl+Z` 可還原）

---

## 安裝方式

1. 下載 `SyncBlock.lsp`
2. 在 AutoCAD 輸入指令：`APPLOAD`
3. 載入檔案
4. 指令 `SyncNow` 或 `SFM` 即可使用

**小技巧：** 將檔案加入 AutoCAD Startup Suite，每次開啟自動載入。

---

## 使用方式

### 第一步 — 準備圖塊

**主底圖 Block A** — 包含所有圖層與物件，只維護這一個。

**子 Block B、C、D...** — 從 Block A 複製出來，進入 Block Editor 刪掉不需要的圖層物件。

> 子 Block 的圖層名稱**必須與 Block A 相同**，腳本才能正確比對。

### 第二步 — 執行同步

輸入 `SyncNow` 或 `SFM`：

```
1. 點選主底圖 Block A
2. 框選所有目標 Block（B、C、D...）
3. 完成
```

指令列會顯示結果：

```
處理：1F-FIRE
  28 個圖層，156 個物件
  位移：(14989.7, 0.0)
  ✔ 152 個完成（Hatch 略過）
```

---

## 指令總覽

| 指令 | 說明 |
|------|------|
| `SyncNow` | 執行同步 |
| `SFM` | SyncNow 的縮寫 |

---

## 注意事項

| 項目 | 說明 |
|------|------|
| Hatch（填充） | 目前版本略過，後續版本加入 |
| 框選時包含 Block A | 自動跳過，不影響結果 |
| 多個樓層 | 每層各建一組 Block，分開執行 |
| 巢狀 Block | 目前不遞迴更新內部 Block |

---

## 相容性

| AutoCAD 版本 | 狀態 |
|-------------|------|
| 2014 以上 | ✅ 支援 |
| 2014 以下 | 未測試 |

---

## 常見問題

**執行後子 Block 不見了？**  
確認子 Block 的圖層名稱是否與 Block A 完全相同，可進入 Block Editor 檢查。

**物件位置跑掉？**  
確認所有 Block 都是在相同的世界座標系下繪製的。

**每次開 AutoCAD 都要重新載入？**  
將 `SyncBlock.lsp` 加入 AutoCAD Startup Suite 即可自動載入。

---

## 版本紀錄

| 版本 | 說明 |
|------|------|
| v18 | 逐一複製物件、跳過 Hatch、修正位移補償、相容 AutoCAD 2014 |
| v12 | BBox 位移計算、顏色繼承、屬性同步 |
| v1–v11 | 開發測試版本 |

---

## 支持這個專案

如果 SyncBlock 幫你節省了時間，歡迎請我喝杯咖啡 ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/beastt1992)

---

## 授權

MIT License — 免費使用、修改、散佈。

---

**為所有 AutoCAD 使用者而做。**
