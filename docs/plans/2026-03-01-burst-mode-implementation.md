# Burst Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement burst mode activation, stat boosts, UI gauge, and duration tracking for the vertical slice combat demo.

**Architecture:** Burst mode is a dedicated state on unit dictionaries (not the status effect system). Three runtime fields (`burst_active`, `burst_turns_remaining`, `burst_effects`) track the state. Stat boosts integrate at four points in the damage pipeline. The burst gauge bar and activation button are added to the existing UI.

**Tech Stack:** Godot 4 / GDScript, JSON config, EventBus signals

---

### Task 1: Add burst config section to combat_config.json

**Files:**
- Modify: `godot/data/combat/combat_config.json`

**Step 1: Add the burst config block**

Add a new `"burst"` key after the existing `"tile_effects"` section in `combat_config.json`:

```json
"burst": {
  "max_gauge": 100,
  "activation_threshold": 100,
  "activation_ap_cost": 0,
  "gauge_carry_between_combats": 0.0
}
```

The full file should look like:
```json
{
  "grid": { ... },
  "movement": { ... },
  "balance": { ... },
  "ap": { ... },
  "opportunity_attacks": { ... },
  "tile_effects": { ... },
  "burst": {
    "max_gauge": 100,
    "activation_threshold": 100,
    "activation_ap_cost": 0,
    "gauge_carry_between_combats": 0.0
  }
}
```

**Step 2: Commit**

```bash
git add godot/data/combat/combat_config.json
git commit -m "feat(burst): add burst config section to combat_config.json"
```

---

### Task 2: Add burst config getters to CombatConfigLoader

**Files:**
- Modify: `godot/scripts/logic/combat/combat_config_loader.gd`

**Step 1: Add getter functions**

Add these four functions at the end of `combat_config_loader.gd` (before the closing of the class), following the existing getter pattern:

```gdscript
## Get the maximum burst gauge value (default 100)
static func get_burst_max_gauge() -> int:
	_ensure_loaded()
	var burst = _config.get("burst", {})
	return burst.get("max_gauge", 100)


## Get the burst activation threshold (default 100)
static func get_burst_activation_threshold() -> int:
	_ensure_loaded()
	var burst = _config.get("burst", {})
	return burst.get("activation_threshold", 100)


## Get the AP cost for burst activation (default 0)
static func get_burst_activation_ap_cost() -> int:
	_ensure_loaded()
	var burst = _config.get("burst", {})
	return burst.get("activation_ap_cost", 0)


## Get the gauge carry percentage between combats (default 0.0)
static func get_burst_gauge_carry() -> float:
	_ensure_loaded()
	var burst = _config.get("burst", {})
	return burst.get("gauge_carry_between_combats", 0.0)
```

**Step 2: Commit**

```bash
git add godot/scripts/logic/combat/combat_config_loader.gd
git commit -m "feat(burst): add burst config getter functions"
```

---

### Task 3: Initialize burst runtime fields on units at combat start

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Find the unit initialization code**

In `combat_manager.gd`, find where ally and enemy units are created and added to `all_units`. Each unit dict already has `burst_gauge` and `burst_mode` from `game_manager.gd`. We need to add three new runtime fields when units enter combat.

Add a helper function after the existing `_apply_stat_modifiers` function (around line 869):

```gdscript
## Initialize burst mode runtime fields on a unit
func _init_burst_fields(unit: Dictionary) -> void:
	unit["burst_active"] = false
	unit["burst_turns_remaining"] = 0
	unit["burst_effects"] = {}
```

**Step 2: Call the helper during unit setup**

Find the section where ally units are added to `all_units` (search for `all_units[` assignments in `_ready()` or the init function). After each unit is added, call `_init_burst_fields(unit)`.

Do the same for enemy units. Enemies don't have burst data, but the fields should still exist so `burst_active` checks don't need null guards.

**Step 3: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(burst): initialize burst runtime fields on combat units"
```

---

### Task 4: Add Burst button to the action panel scene and wire it up

**Files:**
- Modify: `godot/scenes/combat/combat_arena.tscn`
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add BurstButton node to the scene**

In `combat_arena.tscn`, add a new Button node as a child of `UI/ActionPanel/ActionButtons`, placed *before* DefendButton. Copy the pattern of existing buttons:

```
[node name="BurstButton" type="Button" parent="UI/ActionPanel/ActionButtons"]
custom_minimum_size = Vector2(100, 40)
text = "Burst"
```

Insert this block between the MoveButton and DefendButton entries in the `.tscn` file (after line 78, before line 80).

**Step 2: Connect the button in combat_manager.gd `_ready()`**

Find the button connection block (lines 176-181). Add after the MoveButton connection:

```gdscript
$UI/ActionPanel/ActionButtons/BurstButton.pressed.connect(_on_burst_pressed)
```

**Step 3: Add the burst button handler**

Add this function near the other button handlers (after `_on_defend_pressed`, around line 1662):

```gdscript
func _on_burst_pressed() -> void:
	if current_phase != CombatPhase.SELECTING_ACTION:
		return

	if not current_unit.get("is_ally", false):
		return

	var burst_data = current_unit.get("burst_mode", {})
	if burst_data.is_empty():
		return

	# Activate burst mode
	current_unit["burst_active"] = true
	current_unit["burst_turns_remaining"] = burst_data.get("duration", 5)
	current_unit["burst_effects"] = burst_data.get("effects", {}).duplicate()
	current_unit["burst_gauge"] = 0

	var burst_name = burst_data.get("name", "Burst Mode")
	var duration = current_unit["burst_turns_remaining"]
	EventBus.burst_mode_activated.emit(current_unit.get("id", ""))
	EventBus.burst_gauge_changed.emit(current_unit.get("id", ""), 0)

	_log_action("%s activates %s! (%d turns)" % [current_unit.get("name", "?"), burst_name, duration],
		Color(1.0, 0.85, 0.2))
	status_label.text = "%s activates %s!" % [current_unit.get("name", "?"), burst_name]

	_update_unit_visuals()
	_update_action_buttons()
```

**Step 4: Update `_update_action_buttons()` to control Burst button visibility**

In `_update_action_buttons()` (line 590), add after the existing button enable/disable logic:

```gdscript
# Burst button: only visible when gauge is full, burst not already active, and unit is ally
var burst_btn = $UI/ActionPanel/ActionButtons/BurstButton
var threshold = CombatConfigLoaderClass.get_burst_activation_threshold()
var gauge = current_unit.get("burst_gauge", 0)
var already_active = current_unit.get("burst_active", false)
var is_ally = current_unit.get("is_ally", false)
burst_btn.visible = is_ally and gauge >= threshold and not already_active
```

**Step 5: Commit**

```bash
git add godot/scenes/combat/combat_arena.tscn godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(burst): add Burst button with activation logic"
```

---

### Task 5: Integrate burst stat boosts into damage pipeline

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`
- Modify: `godot/scripts/logic/combat/damage_calculator.gd`

**Step 1: Add burst `damage_multiplier` in `_execute_skill()`**

In `combat_manager.gd`'s `_execute_skill()` function, inside the hit loop (after the stance multiplier is applied at line 1013), add:

```gdscript
# Apply burst mode damage multiplier
if user.get("burst_active", false):
	var burst_dmg_mult = user.get("burst_effects", {}).get("damage_multiplier", 1.0)
	if burst_dmg_mult != 1.0:
		result.damage = int(ceil(result.damage * burst_dmg_mult))
```

**Step 2: Add burst `damage_reduction` in `_execute_skill()`**

In the same hit loop, after the status-effect damage reduction block (around line 1032), add:

```gdscript
# Apply burst mode damage reduction (defender)
if target.get("burst_active", false):
	var burst_dr = target.get("burst_effects", {}).get("damage_reduction", 0.0)
	if burst_dr > 0.0:
		result.damage = int(floor(result.damage * (1.0 - burst_dr)))
```

**Step 3: Add burst `crit_rate_bonus` in `damage_calculator.gd`**

In `damage_calculator.gd`'s `calculate_damage()` function, modify the crit chance calculation (lines 51-53). Change from:

```gdscript
var crit_rate = CombatConfigLoaderClass.get_balance("crit_rate_per_dexterity", 0.05)
var crit_chance = _get_stat_value(attacker_stats, "dexterity") * crit_rate
result.is_critical = randf() < crit_chance
```

To:

```gdscript
var crit_rate = CombatConfigLoaderClass.get_balance("crit_rate_per_dexterity", 0.05)
var crit_chance = _get_stat_value(attacker_stats, "dexterity") * crit_rate
# Add burst mode crit rate bonus
var burst_crit_bonus = attacker_stats.get("burst_crit_rate_bonus", 0.0)
crit_chance += burst_crit_bonus
result.is_critical = randf() < crit_chance
```

This requires the caller to pass `burst_crit_rate_bonus` in the attacker_stats dict. In `_execute_skill()`, before calling `calculate_damage()`, add the burst crit bonus to the user dict temporarily:

```gdscript
# Pass burst crit bonus to damage calculator
if user.get("burst_active", false):
	user["burst_crit_rate_bonus"] = user.get("burst_effects", {}).get("crit_rate_bonus", 0.0)
else:
	user["burst_crit_rate_bonus"] = 0.0
```

**Step 4: Add burst `speed_bonus` in `_end_turn()`**

In `combat_manager.gd`, find the `_end_turn()` function where `_ctb_manager.end_turn()` is called (line 1374). Modify the speed calculation to include burst speed bonus:

Change from:
```gdscript
var speed = current_unit.get("speed", 5)
_ctb_manager.end_turn(current_unit.id, speed, remaining_ap)
```

To:
```gdscript
var speed = current_unit.get("speed", 5)
# Burst speed bonus reduces effective ticks (applied via increased speed)
if current_unit.get("burst_active", false):
	var speed_bonus = current_unit.get("burst_effects", {}).get("speed_bonus", 0.0)
	if speed_bonus > 0.0:
		# Increase effective speed so ticks = BASE_TICKS - (speed * MULT) is lower
		speed = int(ceil(speed * (1.0 + speed_bonus)))
_ctb_manager.end_turn(current_unit.id, speed, remaining_ap)
```

**Step 5: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd godot/scripts/logic/combat/damage_calculator.gd
git commit -m "feat(burst): integrate stat boosts into damage, crit, DR, and speed"
```

---

### Task 6: Add burst turn countdown at turn end

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Add burst countdown logic**

In `_end_turn()` (the function that handles end-of-turn processing), add burst countdown logic before the status effect tick (before line 1356). Insert after the DOT processing block:

```gdscript
# Burst mode turn countdown
if current_unit.get("burst_active", false):
	current_unit["burst_turns_remaining"] -= 1
	if current_unit["burst_turns_remaining"] <= 0:
		current_unit["burst_active"] = false
		current_unit["burst_effects"] = {}
		current_unit["burst_turns_remaining"] = 0
		var burst_name = current_unit.get("burst_mode", {}).get("name", "Burst Mode")
		EventBus.burst_mode_ended.emit(current_unit.get("id", ""))
		_log_action("%s's %s fades." % [current_unit.get("name", "?"), burst_name],
			Color(0.6, 0.6, 0.6))
```

**Step 2: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(burst): add burst turn countdown at end of turn"
```

---

### Task 7: Add burst gauge bar to unit_visual.gd

**Files:**
- Modify: `godot/scripts/presentation/combat/unit_visual.gd`

**Step 1: Add burst bar member variables**

Add after the `mp_bar_fill` declaration (line 33):

```gdscript
var burst_bar_bg: Polygon2D
var burst_bar_fill: Polygon2D
var burst_turns_label: Label
```

**Step 2: Create burst gauge bar in `setup()`**

Add after the MP bar creation (after line 98), before the flash overlay:

```gdscript
# Burst gauge bar (only for allies)
if is_ally:
	var burst_y = UNIT_HEIGHT - BAR_HEIGHT * 3 - 6
	burst_bar_bg = _create_bar(BAR_OFFSET_X, burst_y, BAR_WIDTH, BAR_HEIGHT, Color(0.2, 0.2, 0.2))
	add_child(burst_bar_bg)

	burst_bar_fill = _create_bar(BAR_OFFSET_X, burst_y, 0, BAR_HEIGHT, Color(0.9, 0.75, 0.1))
	add_child(burst_bar_fill)

	# Burst turns remaining label (hidden by default)
	burst_turns_label = Label.new()
	burst_turns_label.text = ""
	burst_turns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_turns_label.add_theme_font_size_override("font_size", 9)
	burst_turns_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	burst_turns_label.size = Vector2(UNIT_WIDTH, 12)
	burst_turns_label.position = Vector2(0, burst_y - 13)
	burst_turns_label.visible = false
	add_child(burst_turns_label)
```

Adjust the HP and MP bar positions upward to make room. Change the HP bar y-offset from `UNIT_HEIGHT - BAR_HEIGHT * 2 - 4` to `UNIT_HEIGHT - BAR_HEIGHT * 3 - 6` won't work since we want burst below MP. Instead, place burst bar *below* the MP bar:

```gdscript
# Burst gauge bar (only for allies) - below MP bar
if is_ally:
	var burst_y = UNIT_HEIGHT - BAR_HEIGHT - 2  # Same position as MP currently
	# Move MP bar up to make room
	# Actually, let's place burst ABOVE HP and MP - at the top area
```

Simpler approach — place the burst bar *above* the unit body, near the name label:

```gdscript
# Burst gauge bar (only for allies) - above the unit body
if is_ally:
	var burst_y = -4 - BAR_HEIGHT  # Above the unit, below the name
	burst_bar_bg = _create_bar(BAR_OFFSET_X, burst_y, BAR_WIDTH, BAR_HEIGHT, Color(0.15, 0.15, 0.15))
	add_child(burst_bar_bg)

	burst_bar_fill = _create_bar(BAR_OFFSET_X, burst_y, 0, BAR_HEIGHT, Color(0.9, 0.75, 0.1))
	add_child(burst_bar_fill)

	burst_turns_label = Label.new()
	burst_turns_label.text = ""
	burst_turns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_turns_label.add_theme_font_size_override("font_size", 9)
	burst_turns_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	burst_turns_label.size = Vector2(UNIT_WIDTH, 12)
	burst_turns_label.position = Vector2(0, burst_y - 13)
	burst_turns_label.visible = false
	add_child(burst_turns_label)
```

**Step 3: Add `update_burst()` function**

Add after `update_soil()`:

```gdscript
func update_burst(unit: Dictionary) -> void:
	if not is_ally:
		return

	var gauge = unit.get("burst_gauge", 0)
	var max_gauge = 100  # From config, but UnitVisual doesn't have config access
	var burst_active = unit.get("burst_active", false)
	var turns_remaining = unit.get("burst_turns_remaining", 0)

	# Update burst gauge bar fill
	if burst_bar_fill:
		var ratio = float(gauge) / float(max(max_gauge, 1))
		_update_bar_fill(burst_bar_fill, ratio, BAR_OFFSET_X, burst_bar_bg.position.y)

		# Pulse gold when full and not yet activated
		if gauge >= max_gauge and not burst_active:
			burst_bar_fill.color = Color(1.0, 0.9, 0.3)  # Bright gold pulse
		else:
			burst_bar_fill.color = Color(0.9, 0.75, 0.1)  # Normal amber

	# Show burst turns remaining when active
	if burst_turns_label:
		if burst_active:
			burst_turns_label.text = "B:%d" % turns_remaining
			burst_turns_label.visible = true
		else:
			burst_turns_label.visible = false

	# Gold border tint when burst is active
	if border_rect:
		if burst_active:
			border_rect.color = Color(1.0, 0.85, 0.2)  # Gold
		else:
			border_rect.color = Color(0.3, 0.5, 0.8) if is_ally else Color(0.8, 0.2, 0.2)
```

**Step 4: Call `update_burst()` from `update_stats()`**

At the end of `update_stats()` (after the MP bar update, line 221), add:

```gdscript
update_burst(unit)
```

**Step 5: Update `update_scale()` to handle burst bar**

In `update_scale()`, add repositioning for burst bar elements (after the MP bar section):

```gdscript
if burst_bar_bg:
	var burst_y = -4 - BAR_HEIGHT
	burst_bar_bg.position = Vector2(BAR_OFFSET_X, burst_y)
	burst_bar_bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(BAR_WIDTH, 0), Vector2(BAR_WIDTH, BAR_HEIGHT), Vector2(0, BAR_HEIGHT)
	])
if burst_bar_fill:
	burst_bar_fill.position = Vector2(BAR_OFFSET_X, -4 - BAR_HEIGHT)
if burst_turns_label:
	burst_turns_label.position = Vector2(0, -4 - BAR_HEIGHT - 13)
```

**Step 6: Commit**

```bash
git add godot/scripts/presentation/combat/unit_visual.gd
git commit -m "feat(burst): add burst gauge bar and active indicators to unit visual"
```

---

### Task 8: Add burst status to turn label and cap gauge gain

**Files:**
- Modify: `godot/scripts/presentation/combat/combat_manager.gd`

**Step 1: Update status label to show [BURST]**

In `_return_to_action_selection()` (line 1460), change the status label format to include burst indicator:

```gdscript
var burst_tag = " [BURST]" if current_unit.get("burst_active", false) else ""
status_label.text = "%s's turn (AP: %d)%s" % [current_unit.get("name", "?"), remaining_ap, burst_tag]
```

Do the same in `_start_turn()` where the status label is set (line ~845-846):

```gdscript
var burst_tag = " [BURST]" if current_unit.get("burst_active", false) else ""
status_label.text = "%s's turn (AP: %d)%s" % [current_unit.get("name", "?"), remaining_ap, burst_tag]
```

**Step 2: Use config max_gauge instead of hardcoded 100**

Find the burst gauge gain line (line 1093):

```gdscript
user["burst_gauge"] = min(100, user.get("burst_gauge", 0) + burst_gain)
```

Change to:

```gdscript
var max_gauge = CombatConfigLoaderClass.get_burst_max_gauge()
user["burst_gauge"] = min(max_gauge, user.get("burst_gauge", 0) + burst_gain)
```

**Step 3: Skip burst gauge gain while burst is active**

Wrap the burst gauge gain block (lines 1091-1094) in a check:

```gdscript
# Add burst gauge (only when burst is not active and unit is ally)
if not user.get("burst_active", false) and user.get("is_ally", false):
	var burst_gain = skill.get("burst_gauge_gain", 5)
	var max_gauge = CombatConfigLoaderClass.get_burst_max_gauge()
	user["burst_gauge"] = min(max_gauge, user.get("burst_gauge", 0) + burst_gain)
	EventBus.burst_gauge_changed.emit(user.get("id", ""), user["burst_gauge"])
```

**Step 4: Commit**

```bash
git add godot/scripts/presentation/combat/combat_manager.gd
git commit -m "feat(burst): add BURST label, config-driven gauge cap, skip gain while active"
```

---

### Task 9: Smoke test and verify

**Step 1: Run the game**

Launch the Godot project and start a combat encounter.

**Step 2: Verify burst gauge fills**

Use skills repeatedly. Watch the amber burst bar fill on ally units. Confirm enemies don't show a burst bar.

**Step 3: Verify burst activation**

Once gauge reaches 100, confirm:
- Burst button appears in action panel
- Clicking it sets the gold border on the unit
- "B:X" turns counter shows on the unit
- Status label shows "[BURST]"
- Action log shows activation message
- Burst button disappears after activation
- Player can still act (0 AP cost, doesn't end turn)

**Step 4: Verify stat boosts work**

- Cyrus: Damage should be ~1.5x during burst
- Vaughn: Crit rate should increase noticeably
- Phaidros: Should take much less damage (70% DR), deal ~1.4x damage

**Step 5: Verify deactivation**

- Count turns — burst should end after the duration (5 or 6 turns)
- Border returns to blue
- "B:X" label disappears
- Action log shows deactivation message
- Gauge is at 0 and starts refilling

**Step 6: Final commit if any fixes were needed**

```bash
git add -u
git commit -m "fix(burst): smoke test fixes"
```
