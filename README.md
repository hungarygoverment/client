<div align="center">

# ⚜️ Premium Liquid Gold

**Feature-rich, high-performance, premium Roblox Lua script written by laszi.**

</div>

---

### ⚔️ Combat
* **Raycast Aimbot Engine:** Dynamically calculates line-of-sight using raycasting to filter out obscured targets behind walls or geometry.
* **Target Bone Selector:** Swap lock-on priorities on the fly between `Head` and `Torso`.

### 👁️ Visuals & ESP
* **Through-Wall Chams:** Applies a highlight effect to target character models, allowing visibility through map geometry.
* **Visible-Only Toggle:** Configurable mode to render enemy highlights only when they step into direct line-of-sight.
* **Adaptive Health Bars:** Dynamic color-shifting display tracking enemy health percentages (`Green` ➔ `Yellow` ➔ `Red`).
* **Name & Distance Tags:** Overhead BillboardGuis displaying real-time target DisplayNames, Usernames, and exact stud distances.
* **Color Engine & Themes:** Instant color-swapping with built-in presets (`Gold`, `Cyan`, `Red`, `Green`, `Purple`, `White`) alongside a live continuous **Rainbow RGB** cycle.

### 🏃 Movement
* **Precision Speed Controller:** Fine-tune character WalkSpeed with a real-time slider (1 to 100 studs/sec).
* **Surface Click-Teleport:** Hold `Left Alt` + Click anywhere in the game world to immediately move your character to that raycast surface position.
* **Infinite Jump:** Hijacks jump input to grant continuous mid-air jumps without falling.

### 🚁 Aerial Flight & Noclip
* **Camera-Oriented 3D Flight:** Smooth directional flight (`WASD` + `Space` for ascent / `Left Shift` for descent) relative to your current camera direction.
* **Integrated Noclip:** Bypasses local character collision bounds allowing seamless flight through solid walls, floors, and obstacles.

### 🌆 Lighting & Environmental Modifiers
* **Fullbright Override:** Disables map shadows, overrides ambient lighting values, and forces global illumination for total darkness visibility.
* **Fog Eraser:** Clears atmosphere particles, density fog, and map blur parameters to maximize rendering distance and clarity.

### 🛡️ Safety & Lifecycle Management
* **Complete Memory Unload:** Safely terminates the script with a single click by disconnecting all active render loops (`RenderStepped`, `Stepped`, `Heartbeat`), destroying all instances, clearing keybind listeners, and restoring default game lighting.

---


## 🚀 Execution
* Recommended Executor: **Xeno**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/laszis/premiumliquidgold/main/client.lua"))()  

