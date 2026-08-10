<div align="center">

# ⚜️ Premium Liquid Gold

**The Gold Standard in Roblox Execution Suites & Interface Design.**

![Language](https://img.shields.io/badge/Language-Lua-blue?style=for-the-badge&logo=lua)
![License](https://img.shields.io/badge/License-MIT-gold?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

*A lightweight, unified LocalScript with a luxury feature-rich hub.*

</div>

---

## 🌟 Overview

**Premium Liquid Gold** is engineered to combine gold-plated aesthetics with raw execution performance. Designed with zero-frame-drop UI rendering, raycast occlusion checks, dynamic FOV indicators, and clean memory handling, it sets a new benchmark for interface utility.

---

## ✨ Features

### 🎯 Combat & Precision Aiming
- **Raycast Visibility Engine:** Filters targets based on obstruction line-of-sight.
- **Configurable Lock:** Toggle targeting between `Head` or `Torso`.
- **Dynamic FOV Indicator:** On-screen gold targeting radius overlay.
  
### 👁️ Visuals & Custom ESP
- **Chams (Glow):** Highlights enemy character models through geometry with visible-only mode.
- **Adaptive Health Tracking:** Dynamic color-shifting health bars (`Green` ➔ `Yellow` ➔ `Red`).
- **Target Billboards:** High-visibility display names and usernames.
- **Color Engine:** Switchable presets (`Gold`, `Cyan`, `Red`, `Green`, `Purple`, `White`) plus live **Rainbow RGB** cycling.

### ⚡ Mobility & Movement
- **Interactive Speed Slider:** Real-time WalkSpeed adjustments (1 to 100).
- **Flex-Input Modes:** Toggle or Hold modes for speed keybinds.
- **Click-To-TP:** Hold `Left Alt` + Click to teleport directly to world surfaces.
- **Infinite Jump:** Continuous airborne jump capability.

### ✈️ Flight Control
- **3D Aerial Flight Engine:** Camera-relative directional movement (`WASD` + `Space`/`Shift`).
- **Noclip Phasing:** Toggle collision bypass while flying.

### ✈️ Enviromental overrides locally
- **Fullbright:** Overrides ambient light and shadows for maximum clarity.
- **Fog Eraser:** Instantly wipes atmosphere particles and fog distance limits.

### 🛡️ Clean Terminate & Memory Recovery
- **1-Click Safety Unload:** Disconnects all active event connections (`RenderStepped`, `InputBegan`), destroys GUI instances, resets physics collisions, and restores default game environment lighting.

---

## 🚀 Quick Start

To execute **Premium Liquid Gold** into your game client, use Xeno executor for the smoothest experience and paste in the string to the executor after attaching:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/laszis/premiumliquidgold/main/client.lua"))()
