# Responsive UI Design

## Problem

The combat UI uses hardcoded 1920x1080 pixel positions. When the window is resized (half-screen snap, small windowed mode), most of the screen becomes unused gray space. UI panels and grid don't adapt to available space.

## Approach

Breakpoint-based layouts with 3 discrete tiers. Panels collapse to toggleable overlays at smaller sizes. Grid scales with detail simplification.

## Breakpoints

| Breakpoint | Viewport Width | Layout |
|---|---|---|
| Wide | >= 1280px | Current layout: turn order panel left, action log right, grid centered between them |
| Medium | 800-1279px | Turn order becomes compact horizontal bar above grid. Action log becomes toggleable overlay. Grid and action panel take full width. |
| Narrow | < 800px | Grid fills screen. All panels (turn order, action log, skill panel) become toggleable overlays via icon buttons. |

## Overlay Toggle System

- Small toolbar of icon buttons pinned to top-right corner (visible at medium/narrow breakpoints)
- Buttons: Turn Order (clock icon), Action Log (scroll icon)
- Clicking toggles a floating panel overlay on top of the grid
- Only one overlay open at a time (opening one closes others)
- Overlays have semi-transparent background so grid remains partially visible

## Grid Scaling with Detail Levels

UnitVisual gets detail tiers based on hex size:

| Hex Size | Detail Level | Visible Elements |
|---|---|---|
| >= 40px | Full | All bars, text, status dots, burst info |
| 28-39px | Reduced | Hide burst info label, smaller status dots |
| < 28px | Minimal | Name + HP bar only, no MP/burst/status |

## Layout Calculation Changes

`_calculate_grid_layout()` reads actual viewport size instead of hardcoded 1920x1080 constants. Side panel widths become 0 when panels are hidden (medium/narrow), giving the grid more room.

## Files Changed

| File | Change |
|---|---|
| `scripts/autoload/ui_layout_manager.gd` | New: breakpoint detection, signals, overlay state |
| `scripts/presentation/combat/combat_manager.gd` | Refactor `_calculate_grid_layout()` to use viewport size + breakpoint. Toggle panel visibility. Add overlay toolbar. |
| `scripts/presentation/combat/unit_visual.gd` | Add detail level method that hides/shows elements based on hex size |
| `project.godot` | Register UILayoutManager autoload |

## Out of Scope

- Game logic layer (untouched)
- Data layer (untouched)
- Main menu scene (already uses anchors correctly)
- Touch/swipe gestures (future iPad work)
- Exploration scene responsive layout (separate task)
