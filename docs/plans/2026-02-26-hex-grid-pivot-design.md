# Hex Grid Pivot Design

**Date**: 2026-02-26
**Motivation**: Better tactical depth (6-directional adjacency vs 4)

## Decisions

- **Orientation**: Pointy-top hexes
- **Coordinates**: Offset (odd-row stagger), stored as `Vector2i(col, row)`
- **Grid size**: 7x5 (unchanged, retune via config after playtesting)
- **Internal math**: Convert offset to axial `(q, r)` for distance/neighbor calculations

## Coordinate System

External representation stays `Vector2i(col, row)`. Odd rows shift right by half a hex width visually. All existing position data (JSON, defaults, configurator) remains valid.

Axial conversion (used internally by GridPathfinder):
```
q = col - (row - (row & 1)) / 2
r = row
```

## Logic Layer (GridPathfinder)

Three functions change, everything else (A*, BFS, range bands) delegates to them:

### `_get_neighbors(pos, grid_size)` -> 6 hex neighbors
Offsets differ by row parity:
- Even rows: `(-1,0), (+1,0), (0,-1), (+1,-1), (0,+1), (+1,+1)`
- Odd rows: `(-1,0), (+1,0), (-1,-1), (0,-1), (-1,+1), (0,+1)`

### `hex_distance(a, b)` (replaces `manhattan_distance`)
Convert both to axial, use cube distance:
```
dq = qa - qb
dr = ra - rb
distance = max(abs(dq), abs(dr), abs(dq + dr))
```

### `is_adjacent(a, b)`
Returns `hex_distance(a, b) == 1`. No logic change needed.

### Range Band Breakpoints
Keep at `<=1` (melee), `<=3` (close), `4+` (distant). Retune after playtesting. Hex distance-3 covers ~36 cells vs ~24 on a square grid.

## Presentation Layer

### Shared `grid_to_visual_pos(col, row)` utility
Currently duplicated in combat_manager and target_selector. Extract to one source. Pointy-top odd-row formula:
```
x = hex_size * sqrt(3) * (col + 0.5 * (row & 1))
y = hex_size * 1.5 * row
```

### Cell drawing
Replace 4-vertex rectangle `Polygon2D` with 6-vertex pointy-top hex:
```
for i in 6: vertex = (hex_size * cos(60*i - 30), hex_size * sin(60*i - 30))
```
Apply a small inset (e.g. 2px) for visual separation between cells.

### Click hit testing
Replace `Rect2.has_point()` with pixel-to-hex inverse transform:
```
q_frac = (sqrt(3)/3 * local_x - 1/3 * local_y) / hex_size
r_frac = (2/3 * local_y) / hex_size
```
Round to nearest hex using cube rounding, then convert back to offset.

### Highlights
Replace `ColorRect` with `Polygon2D` using hex polygon.

### Layout calculation
Total pixel dimensions for pointy-top hex grid:
```
grid_width  = hex_size * sqrt(3) * (cols + 0.5)
grid_height = hex_size * 1.5 * rows + hex_size * 0.5
```
Solve for `hex_size` to fill available screen space.

### Zone coloring
Column-based logic unchanged: `col < N` = ally side (blue), `col >= GRID_SIZE.x - N` = enemy side (red).

## Config Changes

### `combat_config.json`
```json
{
  "grid": {
    "columns": 7,
    "rows": 5,
    "hex_size": 32,
    "hex_layout": "pointy_top"
  }
}
```
Remove `cell_size` and `cell_gap`.

### `combat_config_loader.gd`
Add `get_hex_size() -> float`. Keep old getters with fallback defaults for transition safety.

## No Changes Required

- `position_validator.gd` - delegates to GridPathfinder
- `combat_ai.gd` - no direct grid math
- `ap_system.gd`, `ctb_turn_manager.gd`, `damage_calculator.gd` - grid-independent
- `status_effect_manager.gd` - grid-independent
- `combat_configurator.gd` - debug UI, rectangular layout acceptable
- All skill/character/enemy JSON - positions and ranges are abstract

## Touch Point Summary

| Layer | Files | Scope |
|-------|-------|-------|
| Logic | `grid_pathfinder.gd` | 3 functions |
| Config | `combat_config.json`, `combat_config_loader.gd` | Add hex_size, remove cell_size/gap |
| Presentation | `combat_manager.gd`, `target_selector.gd` | Rendering, click handling, layout |
| Data | None | Zero changes |
