# Sprite System - Modding Reference

This document describes how the sprite system works, the decisions behind it, and what modders need to know to add or replace character and enemy art.

---

## Architecture Overview

All sprite configuration lives in a single JSON file:
```
godot/data/sprites/sprite_config.json
```

The game never hardcodes asset paths or frame dimensions in scripts. To change any unit's appearance, you only need to edit this config file and provide the corresponding sprite sheets.

### Party Members (Animated Sprites)

Party members use horizontal sprite sheets — a single row of equally-sized frames.

**Required config fields:**
| Field | Type | Description |
|-------|------|-------------|
| `sprite_folder` | string | `res://` path to the folder containing the animation sheets |
| `frame_width` | int | Width of a single frame in pixels |
| `frame_height` | int | Height of a single frame in pixels |
| `animations` | object | Map of animation name to animation data |

**Per-animation fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sheet` | string | yes | Filename of the sprite sheet PNG within the folder |
| `frames` | int | yes | Number of frames in the sheet |
| `fps` | float | yes | Playback speed in frames per second |
| `content_rect` | array | no | `[x, y, width, height]` — visible content region within each frame (see below) |

**Example:**
```json
{
  "sprite_folder": "res://assets/sprites/characters/my_character",
  "frame_width": 120,
  "frame_height": 80,
  "animations": {
    "idle":   { "sheet": "idle.png",   "frames": 10, "fps": 8 },
    "attack": { "sheet": "attack.png", "frames": 4,  "fps": 10 },
    "hit":    { "sheet": "hit.png",    "frames": 1,  "fps": 1 },
    "death":  { "sheet": "death.png",  "frames": 10, "fps": 8 }
  }
}
```

### Enemies (Static Sprites)

Enemies currently use a single static image per unit.

**Required config fields:**
| Field | Type | Description |
|-------|------|-------------|
| `sprite` | string | `res://` path to the sprite PNG |

**Example:**
```json
{
  "sprite": "res://assets/sprites/enemies/my_enemy.png"
}
```

---

## Sprite Sheet Format

- **Layout**: Horizontal strip — all frames in a single row, left to right
- **Frame size**: Every frame must be exactly `frame_width` x `frame_height` pixels
- **Sheet dimensions**: Total width = `frame_width * frames`, height = `frame_height`
- **Transparency**: Use transparent background (PNG with alpha channel)
- **Orientation**: Characters should face **right** by default. The engine flips enemies automatically.

### Required Animations

The following animation names are recognized by the combat system:

| Name | Purpose | Playback |
|------|---------|----------|
| `idle` | **Required.** Default standing animation. Loops continuously. | Loop |
| `attack` | Played when the unit uses a skill. | Once, then returns to idle |
| `hit` | Played when the unit takes damage. | Once (held briefly), then returns to idle |
| `death` | Played when the unit is defeated. | Once |

Only `idle` is strictly required. Missing animations are skipped gracefully — the unit stays in idle.

---

## Content Rect and Auto-Detection

### The Problem

Sprite sheet frames often contain significant transparent padding around the actual character art. If the engine scales based on the full frame dimensions, the visible character appears much smaller than intended within its combat cell.

### The Solution

The engine uses a **content rect** — the bounding box of visible (non-transparent) pixels within each animation's frames — to determine how to scale and center the sprite.

### Auto-Detection (Default)

**If `content_rect` is omitted from the config, the engine automatically detects it** by scanning the sprite sheet for non-transparent pixels at load time. This means:

- Modders can drop in new sprite sheets without measuring pixel boundaries
- The character will automatically scale to fill the combat cell based on its visible content
- Results are cached per sprite sheet, so detection only runs once

### Manual Override (Optional)

If auto-detection doesn't produce the desired result (e.g., you want to exclude particle effects from the bounding box, or force a specific framing), you can specify `content_rect` explicitly:

```json
"idle": { "sheet": "idle.png", "frames": 10, "fps": 8, "content_rect": [44, 42, 21, 38] }
```

The array is `[x, y, width, height]` in pixel coordinates within a single frame, where (0,0) is the top-left corner.

### Scaling Behavior

- The **idle animation's content rect** is used as the scaling reference for all animations. This keeps the character's body the same apparent size across idle, attack, hit, etc.
- Non-idle animations may extend beyond the combat cell boundary (e.g., a wide sword swing during attack). This is intentional and looks natural.
- Each animation's own content rect is used for **centering offset**, so the character's center stays stable even when the content shifts within the frame.

---

## Design Decisions and Rationale

### Why JSON config instead of embedded metadata?
Portability and moddability. JSON can be edited with any text editor, diffed in version control, and loaded by any engine. No special tools required.

### Why per-animation content rects instead of per-character?
Different animations have wildly different content bounds. An idle pose might be 21x38 pixels while an attack lunge is 82x43. A single bounding box across all animations would be dominated by the widest animation, causing the idle character to render too small.

### Why auto-detect with manual override?
Auto-detection eliminates the most common friction point when adding new art: measuring pixel bounding boxes. The manual override exists for edge cases where the automatic result isn't ideal. This makes the 90% case effortless while preserving full control.

### Why scale all animations relative to idle?
The character's body is the same physical size regardless of pose. Scaling each animation independently would cause the character to visually shrink during attack (wide frames) and grow during idle (narrow frames). Using idle as the reference keeps the body size stable.

---

## File Organization

```
godot/assets/sprites/
  characters/
    character_name/
      idle.png          # Horizontal sprite sheet
      attack.png
      hit.png
      death.png
  enemies/
    enemy_name.png      # Single static image
```

Folder and file names are flexible — the config maps unit IDs to specific paths. The convention above is recommended for consistency.

---

## Checklist: Adding a New Character Sprite

1. Create a folder under `godot/assets/sprites/characters/`
2. Add horizontal sprite sheet PNGs for each animation (at minimum: idle)
3. Add an entry to `sprite_config.json` under `"party"` with:
   - `sprite_folder` pointing to your folder
   - `frame_width` and `frame_height` matching your frame size
   - Animation entries with `sheet`, `frames`, and `fps`
4. Run the game — auto-detection handles content rect
5. If scaling/centering looks off, add manual `content_rect` overrides

## Checklist: Adding a New Enemy Sprite

1. Add a PNG to `godot/assets/sprites/enemies/`
2. Add an entry to `sprite_config.json` under `"enemies"` with the `sprite` path
