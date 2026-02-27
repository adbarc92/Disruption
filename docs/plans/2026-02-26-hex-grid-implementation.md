# Hex Grid Pivot Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the square grid combat system with pointy-top hexagonal grid for richer tactical depth (6-directional adjacency).

**Architecture:** Offset coordinates (odd-row stagger) stored as `Vector2i(col, row)`. Internal math converts to axial `(q, r)` for hex distance. The logic layer change is concentrated in `GridPathfinder` (3 functions). The presentation layer changes are in `combat_manager.gd` and `target_selector.gd` (rendering + click handling).

**Tech Stack:** Godot 4 / GDScript. No new dependencies.

**Design doc:** `docs/plans/2026-02-26-hex-grid-pivot-design.md`

---

### Task 1: Update GridPathfinder hex math

**Files:**
- Modify: `godot/scripts/logic/combat/grid_pathfinder.gd`

**Step 1: Replace `_get_neighbors` with hex neighbor offsets**

Replace the 4-directional neighbor function with 6-directional hex neighbors using odd-row offset:

```gdscript
## Get hex neighbors within grid bounds (pointy-top, odd-row offset)
static func _get_neighbors(pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []

	# Offsets differ based on row parity (odd rows shift right)
	var even_row_offsets = [
		Vector2i(+1, 0), Vector2i(-1, 0),   # E, W
		Vector2i(0, -1), Vector2i(+1, -1),  # NW, NE
		Vector2i(0, +1), Vector2i(+1, +1),  # SW, SE
	]
	var odd_row_offsets = [
		Vector2i(+1, 0), Vector2i(-1, 0),   # E, W
		Vector2i(-1, -1), Vector2i(0, -1),  # NW, NE
		Vector2i(-1, +1), Vector2i(0, +1),  # SW, SE
	]

	var offsets = odd_row_offsets if (pos.y & 1) else even_row_offsets

	for offset in offsets:
		var candidate = pos + offset
		if candidate.x >= 0 and candidate.x < grid_size.x and candidate.y >= 0 and candidate.y < grid_size.y:
			neighbors.append(candidate)

	return neighbors
```

**Step 2: Replace `manhattan_distance` with `hex_distance`**

Add offset-to-axial conversion and cube distance:

```gdscript
## Convert offset coordinates (col, row) to axial coordinates (q, r)
static func offset_to_axial(pos: Vector2i) -> Vector2i:
	var q = pos.x - (pos.y - (pos.y & 1)) / 2
	var r = pos.y
	return Vector2i(q, r)


## Calculate hex distance between two offset-coordinate positions
## Uses cube coordinate distance: max(|dq|, |dr|, |dq+dr|)
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ax = offset_to_axial(a)
	var bx = offset_to_axial(b)
	var dq = ax.x - bx.x
	var dr = ax.y - bx.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2
```

**Step 3: Update all callers of `manhattan_distance` within the file**

In `find_path` (lines 27, 56): replace `manhattan_distance` with `hex_distance`.

In `get_range_band_between` (line 113): replace `manhattan_distance` with `hex_distance`.

In `is_adjacent` (line 152): replace `manhattan_distance` with `hex_distance`.

Keep `manhattan_distance` as a deprecated alias for backward compatibility:

```gdscript
## Deprecated: use hex_distance instead. Kept for any external callers.
static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return hex_distance(a, b)
```

**Step 4: Verify the comment on `_get_neighbors` line and `is_adjacent` doc are updated**

Change `## Get orthogonal neighbors` to `## Get hex neighbors`.
Change `## Check if two positions are adjacent (Manhattan distance == 1)` to `## Check if two positions are adjacent (hex distance == 1)`.

**Step 5: Commit**

```
git add godot/scripts/logic/combat/grid_pathfinder.gd
git commit -m "Replace square grid math with hex distance and 6-directional neighbors"
```

---

### Task 2: Update combat config for hex grid

**Files:**
- Modify: `godot/data/combat/combat_config.json`
- Modify: `godot/scripts/logic/combat/combat_config_loader.gd`

**Step 1: Update combat_config.json**

Replace `cell_size` and `cell_gap` with `hex_size`:

```json
{
  "grid": {
    "columns": 7,
    "rows": 5,
    "hex_size": 48,
    "hex_layout": "pointy_top"
  },
  "movement": { ... },
  "balance": { ... },
  "ap": { ... },
  "opportunity_attacks": { ... }
}
```

**Step 2: Add hex getter to combat_config_loader.gd**

Add after `get_cell_gap()`:

```gdscript
## Get hex size (radius from center to vertex)
static func get_hex_size() -> float:
	_ensure_loaded()
	var grid = _config.get("grid", {})
	return grid.get("hex_size", 48.0)
```

Keep `get_cell_size()` and `get_cell_gap()` with fallback values so nothing crashes during transition. They will be unused but harmless.

**Step 3: Commit**

```
git add godot/data/combat/combat_config.json godot/scripts/logic/combat/combat_config_loader.gd
git commit -m "Add hex_size config, replace cell_size/cell_gap in combat config"
```

---

### Task 3: Add hex geometry utility to combat_manager

This task adds helper functions for hex rendering that will be used by Tasks 4-6. All changes are in `combat_manager.gd`.

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Replace grid variables**

Replace these lines at the top of the file:

```gdscript
# OLD:
var CELL_SIZE: Vector2 = Vector2(48, 48)
var CELL_GAP: float = 4.0

# NEW:
var HEX_SIZE: float = 48.0  # Hex radius (center to vertex)
const HEX_INSET: float = 2.0  # Visual gap between hex cells
```

**Step 2: Replace `grid_to_visual_pos` with hex formula**

```gdscript
## Convert grid position to visual pixel position (pointy-top, odd-row offset)
func grid_to_visual_pos(grid_pos: Vector2i) -> Vector2:
	var col = grid_pos.x
	var row = grid_pos.y
	var x = HEX_SIZE * sqrt(3.0) * (col + 0.5 * (row & 1))
	var y = HEX_SIZE * 1.5 * row
	return Vector2(x, y)
```

**Step 3: Add hex polygon helper**

Add a function that generates hex vertices:

```gdscript
## Generate pointy-top hex polygon vertices centered at origin
func _hex_polygon(size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return points
```

**Step 4: Add pixel-to-hex inverse transform**

Add a function for click handling (used later in target_selector):

```gdscript
## Convert pixel position (local to grid_node) to grid offset coordinates
func pixel_to_hex(pixel: Vector2) -> Vector2i:
	var q_frac = (sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / HEX_SIZE
	var r_frac = (2.0 / 3.0 * pixel.y) / HEX_SIZE
	# Cube round
	var s_frac = -q_frac - r_frac
	var q = round(q_frac)
	var r = round(r_frac)
	var s = round(s_frac)
	var q_diff = abs(q - q_frac)
	var r_diff = abs(r - r_frac)
	var s_diff = abs(s - s_frac)
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	# Convert axial (q, r) back to offset (col, row)
	var row = int(r)
	var col = int(q) + (int(r) - (int(r) & 1)) / 2
	return Vector2i(col, row)
```

**Step 5: Update `get_centered_unit_position`**

Replace with hex-aware centering:

```gdscript
## Calculate centered unit position within a hex cell
func get_centered_unit_position(grid_pos: Vector2i) -> Vector2:
	# Hex center is at grid_to_visual_pos (hex vertices are around center)
	return grid_to_visual_pos(grid_pos)
```

Note: `UnitVisual.setup()` and `update_scale()` currently receive `CELL_SIZE`. These will need to receive a size derived from `HEX_SIZE` instead. Pass `Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0)` (hex bounding box) wherever `CELL_SIZE` was passed to `UnitVisual`.

**Step 6: Commit**

```
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Add hex geometry helpers: grid_to_visual_pos, hex_polygon, pixel_to_hex"
```

---

### Task 4: Update grid layout calculation and drawing

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Replace `_calculate_grid_layout`**

```gdscript
func _calculate_grid_layout() -> void:
	const SCREEN_WIDTH = 1920.0
	const SCREEN_HEIGHT = 1080.0
	const TURN_PANEL_WIDTH = 260.0
	const ACTION_LOG_WIDTH = 250.0
	const ACTION_PANEL_HEIGHT = 200.0
	const TOP_MARGIN = 60.0
	const PADDING = 40.0

	var available_width = SCREEN_WIDTH - TURN_PANEL_WIDTH - ACTION_LOG_WIDTH - (PADDING * 2)
	var available_height = SCREEN_HEIGHT - ACTION_PANEL_HEIGHT - TOP_MARGIN - (PADDING * 2)

	# For pointy-top hexes:
	# grid_width = hex_size * sqrt(3) * (cols + 0.5)
	# grid_height = hex_size * 1.5 * (rows - 1) + hex_size * 2
	var hex_from_width = available_width / (sqrt(3.0) * (GRID_SIZE.x + 0.5))
	var hex_from_height = available_height / (1.5 * (GRID_SIZE.y - 1) + 2.0)

	HEX_SIZE = clamp(min(hex_from_width, hex_from_height), 20.0, 60.0)

	# Calculate actual grid dimensions
	var grid_width = HEX_SIZE * sqrt(3.0) * (GRID_SIZE.x + 0.5)
	var grid_height = HEX_SIZE * (1.5 * (GRID_SIZE.y - 1) + 2.0)

	var grid_x = TURN_PANEL_WIDTH + ((available_width - grid_width) / 2.0) + PADDING
	var grid_y = TOP_MARGIN + ((available_height - grid_height) / 2.0) + PADDING

	battle_grid_container.position = Vector2(grid_x, grid_y)

	print("Hex grid layout: size=%.1f, pos=(%.1f, %.1f)" % [HEX_SIZE, grid_x, grid_y])
```

**Step 2: Replace `_draw_grid_background`**

```gdscript
func _draw_grid_background() -> void:
	for child in grid_node.get_children():
		if not child is UnitVisualClass:
			child.queue_free()

	var inset_size = HEX_SIZE - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell = Polygon2D.new()
			cell.polygon = hex_poly
			cell.position = grid_to_visual_pos(Vector2i(x, y))

			if x < 2:
				cell.color = Color(0.2, 0.3, 0.5, 0.4)
			elif x >= GRID_SIZE.x - 2:
				cell.color = Color(0.5, 0.2, 0.2, 0.4)
			else:
				cell.color = Color(0.25, 0.25, 0.3, 0.35)

			grid_node.add_child(cell)
```

**Step 3: Replace `_highlight_current_unit` polygon**

```gdscript
func _highlight_current_unit() -> void:
	_clear_turn_highlight()

	if current_unit.is_empty():
		return

	var grid_pos = current_unit.get("grid_position", Vector2i(1, 1))
	var inset_size = HEX_SIZE - HEX_INSET

	turn_highlight = Polygon2D.new()
	turn_highlight.polygon = _hex_polygon(inset_size)
	turn_highlight.position = grid_to_visual_pos(grid_pos)
	turn_highlight.color = Color(1.0, 1.0, 0.0, 0.2)
	_highlight_pulse_time = 0.0

	grid_node.add_child(turn_highlight)
```

**Step 4: Update all remaining references to `CELL_SIZE` and `CELL_GAP`**

Search combat_manager.gd for remaining `CELL_SIZE` references. Each one should be replaced:
- Where `CELL_SIZE` was passed to `UnitVisual.setup()` or `update_scale()`: pass `Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0)` instead
- Where `CELL_SIZE` was passed to `target_selector.start_targeting()` or `start_move_targeting()`: pass `HEX_SIZE` instead (see Task 5)
- Where `CELL_GAP` was referenced: remove or replace with `HEX_INSET` where appropriate

Also update `_on_window_resized`:
```gdscript
func _on_window_resized() -> void:
	_calculate_grid_layout()
	_draw_grid()
```
This should already work since `_calculate_grid_layout` recalculates `HEX_SIZE`.

**Step 5: Update `_ready` config loading**

Replace:
```gdscript
CELL_GAP = CombatConfigLoaderClass.get_cell_gap()
```
With:
```gdscript
HEX_SIZE = CombatConfigLoaderClass.get_hex_size()
```

And in `_hot_reload_data`:
```gdscript
# Remove:  CELL_GAP = CombatConfigLoaderClass.get_cell_gap()
# The _calculate_grid_layout call already sets HEX_SIZE
```

**Step 6: Commit**

```
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Replace square grid rendering with hex polygon drawing and layout"
```

---

### Task 5: Update target_selector for hex grid

**Files:**
- Modify: `godot/scripts/presentation/combat/target_selector.gd`

**Step 1: Replace grid variables and coordinate function**

Replace:
```gdscript
var CELL_SIZE: Vector2 = Vector2(48, 48)
var CELL_GAP: float = 4.0

func _grid_to_visual(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x, grid_pos.y) * (CELL_SIZE + Vector2(CELL_GAP, CELL_GAP))
```

With:
```gdscript
var hex_size: float = 48.0
const HEX_INSET: float = 2.0

func _grid_to_visual(grid_pos: Vector2i) -> Vector2:
	var col = grid_pos.x
	var row = grid_pos.y
	var x = hex_size * sqrt(3.0) * (col + 0.5 * (row & 1))
	var y = hex_size * 1.5 * row
	return Vector2(x, y)


func _hex_polygon(size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i - 30.0
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return points


func _pixel_to_hex(pixel: Vector2) -> Vector2i:
	var q_frac = (sqrt(3.0) / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / hex_size
	var r_frac = (2.0 / 3.0 * pixel.y) / hex_size
	var s_frac = -q_frac - r_frac
	var q = round(q_frac)
	var r = round(r_frac)
	var s = round(s_frac)
	var q_diff = abs(q - q_frac)
	var r_diff = abs(r - r_frac)
	var s_diff = abs(s - s_frac)
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	var row = int(r)
	var col = int(q) + (int(r) - (int(r) & 1)) / 2
	return Vector2i(col, row)
```

**Step 2: Update `start_targeting` and `start_move_targeting` signatures**

These currently accept `p_cell_size: Vector2` and `p_cell_gap: float`. Change to accept `p_hex_size: float`:

```gdscript
func start_targeting(skill: Dictionary, user: Dictionary, p_all_units: Dictionary, p_grid: Dictionary, p_grid_size: Vector2i, p_grid_node: Node2D, p_status_manager = null, p_hex_size: float = 0.0) -> void:
	# ...existing setup...
	if p_hex_size > 0.0:
		hex_size = p_hex_size
	else:
		hex_size = CombatConfigLoaderClass.get_hex_size()
	# ...rest of function...

func start_move_targeting(unit: Dictionary, p_grid: Dictionary, p_grid_size: Vector2i, p_grid_node: Node2D, p_hex_size: float = 0.0) -> void:
	# ...existing setup...
	if p_hex_size > 0.0:
		hex_size = p_hex_size
	else:
		hex_size = CombatConfigLoaderClass.get_hex_size()
	# ...rest of function...
```

Update all callers in `combat_manager.gd` that pass `CELL_SIZE, CELL_GAP` to pass `HEX_SIZE` instead.

**Step 3: Replace click hit testing with pixel-to-hex**

Replace `_check_target_click`:
```gdscript
func _check_target_click(click_pos: Vector2) -> void:
	if grid_node_ref == null:
		return
	var local_pos = click_pos - grid_node_ref.global_position
	var hex_pos = _pixel_to_hex(local_pos)

	for target in valid_targets:
		var target_grid_pos = target.get("grid_position", Vector2i(-1, -1))
		if hex_pos == target_grid_pos:
			_select_target(target)
			return
```

Replace `_check_move_click`:
```gdscript
func _check_move_click(click_pos: Vector2) -> void:
	if grid_node_ref == null:
		return
	var local_pos = click_pos - grid_node_ref.global_position
	var hex_pos = _pixel_to_hex(local_pos)

	if hex_pos in valid_move_positions:
		_select_move_position(hex_pos)
```

Remove `_get_target_rect` (no longer needed).

**Step 4: Replace highlight rendering with hex polygons**

Replace `_show_target_highlights`:
```gdscript
func _show_target_highlights() -> void:
	_clear_highlights()
	if grid_node_ref == null:
		return

	var inset_size = hex_size - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for target in valid_targets:
		var grid_pos = target.get("grid_position", Vector2i(0, 0))
		var pos = _grid_to_visual(grid_pos)

		var highlight = Polygon2D.new()
		highlight.polygon = hex_poly
		highlight.position = pos
		highlight.color = Color(1.0, 1.0, 0.0, 0.3)
		highlight.name = "highlight_%s" % target.get("id", "")

		grid_node_ref.add_child(highlight)
		highlight_nodes.append(highlight)
```

Replace `_show_move_highlights`:
```gdscript
func _show_move_highlights() -> void:
	_clear_highlights()
	if grid_node_ref == null:
		return

	var inset_size = hex_size - HEX_INSET
	var hex_poly = _hex_polygon(inset_size)

	for pos in valid_move_positions:
		var cell_pos = _grid_to_visual(pos)

		var highlight = Polygon2D.new()
		highlight.polygon = hex_poly
		highlight.position = cell_pos
		highlight.color = Color(0.0, 1.0, 0.0, 0.3)
		highlight.name = "move_highlight_%d_%d" % [pos.x, pos.y]

		grid_node_ref.add_child(highlight)
		highlight_nodes.append(highlight)
```

Note: The highlights are now `Polygon2D` instead of `ColorRect`, so the old `gui_input` click handling on highlights is removed. Click detection is now fully handled by `_pixel_to_hex` in the `_input` method, which is more robust.

Remove `_on_highlight_input` and `_on_move_highlight_input` since we no longer use `gui_input` on highlights. The `_input` handler already processes all clicks via `_check_target_click` / `_check_move_click`.

**Step 5: Commit**

```
git add godot/scripts/presentation/combat/target_selector.gd godot/scripts/presentation/combat/combat_manager.gd
git commit -m "Update target selector for hex: pixel-to-hex clicks, hex polygon highlights"
```

---

### Task 6: Update callers and fix remaining CELL_SIZE/CELL_GAP references

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`
- Modify: `godot/scripts/presentation/combat/unit_visual.gd`

**Step 1: Search for remaining CELL_SIZE and CELL_GAP references**

Run grep across all `.gd` files for `CELL_SIZE` and `CELL_GAP`. Fix each occurrence:
- In `combat_manager.gd`: any remaining `CELL_SIZE` passed to functions should become the hex bounding box `Vector2(HEX_SIZE * sqrt(3.0), HEX_SIZE * 2.0)`
- In `unit_visual.gd`: the `setup(unit, is_ally, cell_size)` and `update_scale(cell_size)` functions receive a `Vector2`. Pass the hex bounding box from the caller. The internal scaling logic should still work since it uses the vector to compute proportional sizes.

**Step 2: Update `_ai_move_toward_enemies` distance call**

In `combat_manager.gd`, the AI movement function calls `GridPathfinderClass.manhattan_distance()`. This already works because we kept `manhattan_distance` as an alias for `hex_distance`, but rename the call for clarity:

```gdscript
var dist = GridPathfinderClass.hex_distance(cell, enemy_pos)
```

**Step 3: Test the full flow**

Launch the combat configurator, start a battle, and verify:
- Hex grid renders with pointy-top hexagons
- Clicking on hex cells selects the correct target
- Movement highlights show reachable hex cells
- AI enemies move and attack correctly
- Turn order and AP system work unchanged

**Step 4: Commit**

```
git add -A
git commit -m "Fix remaining square grid references, update unit visual sizing for hexes"
```

---

### Task 7: Update combat demo guidestone

**Files:**
- Modify: `C:\Users\barclay\.claude\projects\D--MajorProjects-GAME-DEVELOPMENT-Disruption\memory\combat-demo.md`

Update the guidestone to reflect:
- Grid is now hex (pointy-top, odd-row offset)
- `HEX_SIZE` replaces `CELL_SIZE` / `CELL_GAP`
- `GridPathfinder.hex_distance()` replaces `manhattan_distance()`
- 6-directional neighbors
- `pixel_to_hex()` for click handling
- `_hex_polygon()` for rendering
- Remove/update any square-specific notes

**Step 1: Commit**

No git commit needed (memory file is outside the repo).
