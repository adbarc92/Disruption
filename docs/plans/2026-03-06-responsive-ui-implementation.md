# Responsive UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the combat UI adapt intelligently to arbitrary window sizes using 3 breakpoint-based layouts (wide/medium/narrow) with collapsible overlay panels and grid detail scaling.

**Architecture:** A new `UILayoutManager` autoload detects viewport breakpoints and emits signals. `CombatManager` listens to these signals to toggle panel visibility, reposition elements, and add an overlay toolbar. `UnitVisual` gains detail-level tiers based on hex size.

**Tech Stack:** Godot 4 / GDScript, no new dependencies

---

### Task 1: UILayoutManager Autoload

**Files:**
- Create: `godot/scripts/autoload/ui_layout_manager.gd`
- Modify: `godot/project.godot`

**Step 1: Create UILayoutManager script**

```gdscript
extends Node
## UILayoutManager - Detects viewport breakpoints and emits layout signals.

enum LayoutBreakpoint { WIDE, MEDIUM, NARROW }

var current_breakpoint: LayoutBreakpoint = LayoutBreakpoint.WIDE

signal breakpoint_changed(new_breakpoint: LayoutBreakpoint)
signal overlay_toggled(panel_name: String, visible: bool)

# Overlay state - only one overlay open at a time
var _active_overlay: String = ""

const WIDE_THRESHOLD = 1280.0
const MEDIUM_THRESHOLD = 800.0


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	# Initial calculation deferred so all nodes are ready
	_on_viewport_resized.call_deferred()


func _on_viewport_resized() -> void:
	var width = get_viewport().get_visible_rect().size.x
	var new_breakpoint = _calculate_breakpoint(width)
	if new_breakpoint != current_breakpoint:
		current_breakpoint = new_breakpoint
		breakpoint_changed.emit(current_breakpoint)
		# Close any open overlay when breakpoint changes
		if _active_overlay != "":
			_close_overlay()


func _calculate_breakpoint(width: float) -> LayoutBreakpoint:
	if width >= WIDE_THRESHOLD:
		return LayoutBreakpoint.WIDE
	elif width >= MEDIUM_THRESHOLD:
		return LayoutBreakpoint.MEDIUM
	else:
		return LayoutBreakpoint.NARROW


func get_viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func toggle_overlay(panel_name: String) -> void:
	if _active_overlay == panel_name:
		_close_overlay()
	else:
		# Close previous overlay first
		if _active_overlay != "":
			overlay_toggled.emit(_active_overlay, false)
		_active_overlay = panel_name
		overlay_toggled.emit(panel_name, true)


func _close_overlay() -> void:
	var was = _active_overlay
	_active_overlay = ""
	overlay_toggled.emit(was, false)


func is_overlay_open(panel_name: String) -> bool:
	return _active_overlay == panel_name
```

**Step 2: Register autoload in project.godot**

Add this line after the SaveManager autoload entry in `godot/project.godot`:

```
UILayoutManager="*res://scripts/autoload/ui_layout_manager.gd"
```

**Step 3: Run the project to verify no errors**

Run: Launch Godot project, check output for "UILayoutManager" errors.
Expected: No errors. Breakpoint calculated on startup.

**Step 4: Commit**

```
git add godot/scripts/autoload/ui_layout_manager.gd godot/project.godot
git commit -m "feat(ui): add UILayoutManager autoload with breakpoint detection"
```

---

### Task 2: UnitVisual Detail Levels

**Files:**
- Modify: `godot/scripts/presentation/combat/unit_visual.gd`

**Step 1: Add detail level enum and method**

Add after the `const FLASH_DURATION = 0.15` line (line 52):

```gdscript
enum DetailLevel { FULL, REDUCED, MINIMAL }
var detail_level: DetailLevel = DetailLevel.FULL
```

Add a new function after `update_scale()` (after line 229):

```gdscript
func update_detail_level(hex_size: float) -> void:
	var new_level: DetailLevel
	if hex_size >= 40.0:
		new_level = DetailLevel.FULL
	elif hex_size >= 28.0:
		new_level = DetailLevel.REDUCED
	else:
		new_level = DetailLevel.MINIMAL

	if new_level == detail_level:
		return
	detail_level = new_level
	_apply_detail_level()


func _apply_detail_level() -> void:
	match detail_level:
		DetailLevel.FULL:
			if mp_bar_bg: mp_bar_bg.visible = true
			if mp_bar_fill: mp_bar_fill.visible = true
			if burst_bar_bg: burst_bar_bg.visible = true
			if burst_bar_fill: burst_bar_fill.visible = true
			if burst_info_label: burst_info_label.visible = true
			if status_container: status_container.visible = true
			if soil_badge: soil_badge.visible = true
		DetailLevel.REDUCED:
			if mp_bar_bg: mp_bar_bg.visible = true
			if mp_bar_fill: mp_bar_fill.visible = true
			if burst_bar_bg: burst_bar_bg.visible = true
			if burst_bar_fill: burst_bar_fill.visible = true
			if burst_info_label: burst_info_label.visible = false
			if status_container: status_container.visible = true
			if soil_badge: soil_badge.visible = false
		DetailLevel.MINIMAL:
			if mp_bar_bg: mp_bar_bg.visible = false
			if mp_bar_fill: mp_bar_fill.visible = false
			if burst_bar_bg: burst_bar_bg.visible = false
			if burst_bar_fill: burst_bar_fill.visible = false
			if burst_info_label: burst_info_label.visible = false
			if status_container: status_container.visible = false
			if soil_badge: soil_badge.visible = false
```

**Step 2: Call detail level update from `update_scale()`**

Modify `update_scale()` to also update detail level. At the end of the function (after `_apply_layout()` on line 229), add:

```gdscript
	update_detail_level(p_cell_size.y / 2.0)  # Approximate hex_size from cell height
```

**Step 3: Run the project and resize window to verify unit visuals simplify**

Expected: At very small window sizes, units show only name + HP bar.

**Step 4: Commit**

```
git add godot/scripts/presentation/combat/unit_visual.gd
git commit -m "feat(ui): add detail level tiers to UnitVisual based on hex size"
```

---

### Task 3: Refactor Grid Layout to Use Viewport Size

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Replace hardcoded constants in `_calculate_grid_layout()`**

Replace the entire `_calculate_grid_layout()` function (lines 214-243) with:

```gdscript
func _calculate_grid_layout() -> void:
	var vp_size = UILayoutManager.get_viewport_size()
	var breakpoint = UILayoutManager.current_breakpoint

	# Panel widths depend on breakpoint
	var turn_panel_width = 260.0 if breakpoint == UILayoutManager.LayoutBreakpoint.WIDE else 0.0
	var action_log_width = 250.0 if breakpoint == UILayoutManager.LayoutBreakpoint.WIDE else 0.0
	var action_panel_height = 200.0
	var top_margin = 60.0
	var padding = 40.0

	# At medium breakpoint, reserve space for compact turn bar at top
	if breakpoint == UILayoutManager.LayoutBreakpoint.MEDIUM:
		top_margin = 100.0

	var available_width = vp_size.x - turn_panel_width - action_log_width - (padding * 2)
	var available_height = vp_size.y - action_panel_height - top_margin - (padding * 2)

	# For pointy-top hexes:
	var hex_from_width = available_width / (sqrt(3.0) * (GRID_SIZE.x + 0.5))
	var hex_from_height = available_height / (1.5 * (GRID_SIZE.y - 1) + 2.0)

	HEX_SIZE = clamp(min(hex_from_width, hex_from_height), 20.0, 60.0)

	# Calculate actual grid dimensions
	var grid_width = HEX_SIZE * sqrt(3.0) * (GRID_SIZE.x + 0.5)
	var grid_height = HEX_SIZE * (1.5 * (GRID_SIZE.y - 1) + 2.0)

	var grid_x = turn_panel_width + ((available_width - grid_width) / 2.0) + padding
	var grid_y = top_margin + ((available_height - grid_height) / 2.0) + padding

	battle_grid_container.position = Vector2(grid_x, grid_y)

	# Update all unit visual detail levels
	for unit_id in unit_visuals:
		var visual = unit_visuals[unit_id]
		if is_instance_valid(visual):
			visual.update_detail_level(HEX_SIZE)
```

**Step 2: Update `_on_window_resized()` to also update unit scales**

Replace `_on_window_resized()` (lines 246-249) with:

```gdscript
func _on_window_resized() -> void:
	_calculate_grid_layout()
	_update_all_unit_scales()
	_draw_grid()
	_highlight_current_unit()
```

**Step 3: Run the project, resize window, verify grid repositions and fills available space**

Expected: Grid centers itself and scales with no hardcoded 1920x1080 assumption.

**Step 4: Commit**

```
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(ui): refactor grid layout to use viewport size and breakpoints"
```

---

### Task 4: Panel Visibility and Overlay Toolbar

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add overlay toolbar and panel management variables**

Add these variables after the `var _highlight_pulse_time` line (line 88):

```gdscript
# Overlay toolbar (for medium/narrow breakpoints)
var _overlay_toolbar: HBoxContainer = null
var _turn_order_overlay: Panel = null
var _action_log_overlay: Panel = null
```

**Step 2: Create the overlay toolbar setup function**

Add this function after `_setup_action_log()`:

```gdscript
func _setup_overlay_toolbar() -> void:
	var ui_layer = $UI

	_overlay_toolbar = HBoxContainer.new()
	_overlay_toolbar.anchors_preset = Control.PRESET_TOP_RIGHT
	_overlay_toolbar.anchor_left = 1.0
	_overlay_toolbar.anchor_right = 1.0
	_overlay_toolbar.offset_left = -110.0
	_overlay_toolbar.offset_top = 10.0
	_overlay_toolbar.offset_right = -10.0
	_overlay_toolbar.offset_bottom = 45.0
	_overlay_toolbar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_overlay_toolbar.add_theme_constant_override("separation", 5)
	_overlay_toolbar.visible = false
	ui_layer.add_child(_overlay_toolbar)

	var turn_btn = Button.new()
	turn_btn.text = "T"
	turn_btn.tooltip_text = "Turn Order"
	turn_btn.custom_minimum_size = Vector2(35, 35)
	turn_btn.pressed.connect(func(): UILayoutManager.toggle_overlay("turn_order"))
	_overlay_toolbar.add_child(turn_btn)

	var log_btn = Button.new()
	log_btn.text = "L"
	log_btn.tooltip_text = "Action Log"
	log_btn.custom_minimum_size = Vector2(35, 35)
	log_btn.pressed.connect(func(): UILayoutManager.toggle_overlay("action_log"))
	_overlay_toolbar.add_child(log_btn)

	# Create overlay versions of panels
	_create_turn_order_overlay(ui_layer)
	_create_action_log_overlay(ui_layer)

	# Connect to layout manager signals
	UILayoutManager.breakpoint_changed.connect(_on_breakpoint_changed)
	UILayoutManager.overlay_toggled.connect(_on_overlay_toggled)


func _create_turn_order_overlay(ui_layer: CanvasLayer) -> void:
	_turn_order_overlay = Panel.new()
	_turn_order_overlay.anchors_preset = Control.PRESET_CENTER_LEFT
	_turn_order_overlay.anchor_top = 0.0
	_turn_order_overlay.anchor_bottom = 0.0
	_turn_order_overlay.offset_left = 10.0
	_turn_order_overlay.offset_top = 50.0
	_turn_order_overlay.offset_right = 270.0
	_turn_order_overlay.offset_bottom = 400.0
	_turn_order_overlay.visible = false
	_turn_order_overlay.modulate = Color(1, 1, 1, 0.92)
	ui_layer.add_child(_turn_order_overlay)

	var title = Label.new()
	title.text = "Turn Order"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 10.0
	title.offset_top = 10.0
	title.offset_right = 250.0
	title.offset_bottom = 30.0
	_turn_order_overlay.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.offset_left = 230.0
	close_btn.offset_top = 5.0
	close_btn.offset_right = 255.0
	close_btn.offset_bottom = 30.0
	close_btn.pressed.connect(func(): UILayoutManager.toggle_overlay("turn_order"))
	_turn_order_overlay.add_child(close_btn)

	var turn_list_overlay = VBoxContainer.new()
	turn_list_overlay.name = "OverlayTurnList"
	turn_list_overlay.offset_left = 10.0
	turn_list_overlay.offset_top = 40.0
	turn_list_overlay.offset_right = 250.0
	turn_list_overlay.offset_bottom = 340.0
	_turn_order_overlay.add_child(turn_list_overlay)


func _create_action_log_overlay(ui_layer: CanvasLayer) -> void:
	_action_log_overlay = Panel.new()
	_action_log_overlay.anchor_left = 1.0
	_action_log_overlay.anchor_right = 1.0
	_action_log_overlay.offset_left = -270.0
	_action_log_overlay.offset_top = 50.0
	_action_log_overlay.offset_right = -10.0
	_action_log_overlay.offset_bottom = 500.0
	_action_log_overlay.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_action_log_overlay.visible = false
	_action_log_overlay.modulate = Color(1, 1, 1, 0.92)
	ui_layer.add_child(_action_log_overlay)

	var title = Label.new()
	title.text = "Action Log"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 10.0
	title.offset_top = 10.0
	title.offset_right = 250.0
	title.offset_bottom = 30.0
	_action_log_overlay.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.offset_left = 230.0
	close_btn.offset_top = 5.0
	close_btn.offset_right = 255.0
	close_btn.offset_bottom = 30.0
	close_btn.pressed.connect(func(): UILayoutManager.toggle_overlay("action_log"))
	_action_log_overlay.add_child(close_btn)

	var log_mirror = TextEdit.new()
	log_mirror.name = "OverlayLogText"
	log_mirror.offset_left = 10.0
	log_mirror.offset_top = 35.0
	log_mirror.offset_right = 250.0
	log_mirror.offset_bottom = 440.0
	log_mirror.editable = false
	log_mirror.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	log_mirror.add_theme_font_size_override("font_size", 11)
	_action_log_overlay.add_child(log_mirror)
```

**Step 3: Add breakpoint and overlay signal handlers**

```gdscript
func _on_breakpoint_changed(new_breakpoint: UILayoutManager.LayoutBreakpoint) -> void:
	var turn_panel = $UI/TurnOrderPanel
	var action_log_panel = action_log_text.get_parent() if action_log_text else null

	match new_breakpoint:
		UILayoutManager.LayoutBreakpoint.WIDE:
			turn_panel.visible = true
			if action_log_panel: action_log_panel.visible = true
			_overlay_toolbar.visible = false
			_turn_order_overlay.visible = false
			_action_log_overlay.visible = false
		UILayoutManager.LayoutBreakpoint.MEDIUM:
			turn_panel.visible = false
			if action_log_panel: action_log_panel.visible = false
			_overlay_toolbar.visible = true
			_turn_order_overlay.visible = false
			_action_log_overlay.visible = false
		UILayoutManager.LayoutBreakpoint.NARROW:
			turn_panel.visible = false
			if action_log_panel: action_log_panel.visible = false
			_overlay_toolbar.visible = true
			_turn_order_overlay.visible = false
			_action_log_overlay.visible = false

	# Recalculate grid layout for new available space
	_calculate_grid_layout()
	_update_all_unit_scales()
	_draw_grid()
	_highlight_current_unit()


func _on_overlay_toggled(panel_name: String, is_visible: bool) -> void:
	match panel_name:
		"turn_order":
			_turn_order_overlay.visible = is_visible
			if is_visible:
				_sync_turn_order_overlay()
		"action_log":
			_action_log_overlay.visible = is_visible
			if is_visible:
				_sync_action_log_overlay()


func _sync_turn_order_overlay() -> void:
	var overlay_list = _turn_order_overlay.get_node("OverlayTurnList")
	for child in overlay_list.get_children():
		child.queue_free()

	var preview = _ctb_manager.get_turn_order_preview()
	for i in range(min(preview.size(), 10)):
		var unit_id = preview[i]
		var unit = all_units.get(unit_id, {})
		if unit.is_empty():
			continue
		var label = Label.new()
		var prefix = ">> " if i == 0 else "   "
		var hp_text = ""
		if i == 0 and unit.has("current_hp"):
			hp_text = " [HP:%d/%d]" % [unit.get("current_hp", 0), unit.get("max_hp", 1)]
		label.text = "%s%s%s" % [prefix, unit.get("name", "???"), hp_text]
		label.add_theme_color_override("font_color", Color.CYAN if unit.get("is_ally", false) else Color.RED)
		overlay_list.add_child(label)


func _sync_action_log_overlay() -> void:
	var overlay_log = _action_log_overlay.get_node("OverlayLogText")
	if action_log_text and overlay_log:
		overlay_log.text = action_log_text.text
```

**Step 4: Wire up overlay toolbar in `_ready()`**

Add this call in `_ready()` after `_setup_action_log()` (line 208):

```gdscript
	_setup_overlay_toolbar()
```

**Step 5: Remove the old `get_tree().root.size_changed.connect(_on_window_resized)` from `_ready()`**

The old line (164) can stay as-is since `_on_window_resized` handles grid-level resize. The breakpoint-level changes are handled by `UILayoutManager`. However, update `_on_window_resized` to not duplicate breakpoint work:

```gdscript
func _on_window_resized() -> void:
	if UILayoutManager.current_breakpoint == UILayoutManager.LayoutBreakpoint.WIDE:
		# Only recalculate if breakpoint handler didn't already do it
		_calculate_grid_layout()
		_update_all_unit_scales()
		_draw_grid()
		_highlight_current_unit()
```

Wait -- this introduces a subtle bug. The `_on_breakpoint_changed` only fires when breakpoint changes, but window resize within the same breakpoint still needs grid recalculation. Better approach: keep `_on_window_resized` doing full recalculation always, and have `_on_breakpoint_changed` handle only panel visibility toggling (without re-triggering layout since the resize signal fires at the same time):

```gdscript
func _on_window_resized() -> void:
	_calculate_grid_layout()
	_update_all_unit_scales()
	_draw_grid()
	_highlight_current_unit()


func _on_breakpoint_changed(new_breakpoint: UILayoutManager.LayoutBreakpoint) -> void:
	var turn_panel = $UI/TurnOrderPanel
	var action_log_panel = action_log_text.get_parent() if action_log_text else null

	match new_breakpoint:
		UILayoutManager.LayoutBreakpoint.WIDE:
			turn_panel.visible = true
			if action_log_panel: action_log_panel.visible = true
			_overlay_toolbar.visible = false
			_turn_order_overlay.visible = false
			_action_log_overlay.visible = false
		_:
			turn_panel.visible = false
			if action_log_panel: action_log_panel.visible = false
			_overlay_toolbar.visible = true
			_turn_order_overlay.visible = false
			_action_log_overlay.visible = false
```

**Step 6: Update `_log_action()` to also sync overlay log**

After line 938 (`_scroll_log_to_bottom.call_deferred()`), add:

```gdscript
	if _action_log_overlay and _action_log_overlay.visible:
		_sync_action_log_overlay()
```

**Step 7: Update `_update_turn_order_ui()` to also sync overlay**

After the existing function body (line 615), add:

```gdscript
	if _turn_order_overlay and _turn_order_overlay.visible:
		_sync_turn_order_overlay()
```

**Step 8: Run the project, resize to <1280px width, verify panels hide and toolbar appears**

Expected: Turn order and action log panels disappear. "T" and "L" buttons appear top-right. Clicking them toggles overlay panels.

**Step 9: Commit**

```
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(ui): add overlay toolbar and breakpoint-driven panel visibility"
```

---

### Task 5: Action Panel Responsiveness

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`
- Modify: `godot/scenes/combat/combat_arena.tscn`

**Step 1: Update action panel anchors in the .tscn to be fully responsive**

The ActionPanel already uses `anchors_preset = 7` (bottom-center). Update it to use full-width anchoring instead of fixed 600px:

In `combat_arena.tscn`, change the ActionPanel node (lines 46-54) to:

```
[node name="ActionPanel" type="Panel" parent="UI"]
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = -200.0
offset_right = -10.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 0
```

**Step 2: Update ActionButtons container to fill available width**

Change the ActionButtons HBoxContainer (lines 58-60) to use anchors:

```
[node name="ActionButtons" type="HBoxContainer" parent="UI/ActionPanel"]
anchors_preset = 10
anchor_right = 1.0
offset_left = 20.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = 60.0
```

**Step 3: Run the project, resize window, verify action panel stretches properly**

Expected: Action panel spans the bottom of the screen at any width. Buttons reflow within the container.

**Step 4: Commit**

```
git add godot/scenes/combat/combat_arena.tscn
git commit -m "feat(ui): make action panel responsive with full-width anchoring"
```

---

### Task 6: Background ColorRect Responsiveness

**Files:**
- Modify: `godot/scenes/combat/combat_arena.tscn`

**Step 1: Update Background node to fill viewport**

Change the Background ColorRect (lines 10-13) from fixed 1920x1080 to anchor-based:

```
[node name="Background" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.15, 0.12, 0.2, 1)
```

Note: The Background is a child of a Node2D, so anchors won't work directly. Instead, move the background to be a child of the UI CanvasLayer, or keep the fixed size large enough (it's already 1920x1080 which covers most cases). For now, keep it as-is since the stretch mode handles scaling. Skip this task if the background already covers the viewport at all sizes.

**Step 2: Verify background covers viewport at all sizes**

Run the project at various sizes. If gray space appears around the background, address it then.

**Step 3: Commit (if changes were needed)**

```
git add godot/scenes/combat/combat_arena.tscn
git commit -m "fix(ui): ensure background covers viewport at all sizes"
```

---

### Task 7: Integration Testing

**Files:**
- No new files

**Step 1: Test wide layout (>= 1280px)**

- Launch project at 1920x1080 (or larger)
- Verify: Turn order panel visible on left, action log on right, grid centered between them
- Verify: No overlay toolbar visible
- Verify: Unit visuals show full detail

**Step 2: Test medium layout (800-1279px)**

- Resize window to ~1000px wide
- Verify: Turn order panel and action log hidden
- Verify: Overlay toolbar appears top-right with "T" and "L" buttons
- Verify: Grid expands to use freed horizontal space
- Verify: Clicking "T" shows turn order overlay, clicking again hides it
- Verify: Clicking "L" shows action log overlay with current log content
- Verify: Opening one overlay closes the other

**Step 3: Test narrow layout (< 800px)**

- Resize window to ~600px wide
- Verify: Same overlay behavior as medium
- Verify: Grid scales down, unit visuals simplify (reduced/minimal detail)
- Verify: Action panel still usable at bottom

**Step 4: Test transitions**

- Resize from wide to narrow and back
- Verify: Panels show/hide correctly at each breakpoint
- Verify: No errors in output log
- Verify: Combat remains playable (buttons work, turns progress)

**Step 5: Commit final verification**

```
git commit --allow-empty -m "test: verify responsive UI at all breakpoints"
```
