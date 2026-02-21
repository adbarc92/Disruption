# Rapid Prototyping Guide

Quick reference for fast combat iteration and playtesting.

---

## Quick Launch Presets

**Location:** Combat Configurator scene (`combat_configurator.tscn`)

### Available Presets

| Preset | Grid | Encounter | Purpose |
|--------|------|-----------|---------|
| **Default 3v3** | 3×3 | Full Squad | Balanced test combat (Cyrus/Vaughn/Phaidros vs Scout/Brute/Caster) |
| **Speed Test** | 3×3 | Two Scouts | Test turn order with high-speed units |
| **Tank Test** | 3×3 | Twin Brutes | Test sustained damage against high HP enemies |
| **Last Config** | (saved) | (saved) | Resume your previous setup |

### How to Use

1. Open `combat_configurator.tscn` in Godot
2. Click any preset button (e.g., "Default 3v3")
3. Combat launches automatically in ~1 second

**No manual configuration needed!** Presets auto-configure grid, positions, and encounter.

---

## Hot Reload System

**Location:** Combat scene (during active combat)

### What It Does

Press **F5** during combat to reload all JSON data files **without restarting the scene**:
- Skills (`core_skills.json`)
- Characters (`party.json`)
- Enemies (`test_enemies.json`)
- Combat config (`combat_config.json`)

**Current combat state preserved:** HP, MP, positions, turn order, AP all stay intact.

### Iteration Workflow

```
1. Start combat (use quick preset)
2. Notice: "Hamstring does 60 damage, feels weak"
3. Alt+Tab to editor
4. Open godot/data/skills/core_skills.json
5. Find "hamstring" skill, change damage.base from 60 to 85
6. Save file
7. Alt+Tab back to game
8. Press F5
9. Use Hamstring again → see 85 damage
10. Adjust again if needed → F5 → test
```

**Typical iteration time:** ~30 seconds (vs. 5-10 minutes with scene restart)

---

## Fast Playtest Cycle

### Recommended Flow

**Testing Skills:**
1. Launch with "Default 3v3" preset
2. Play 2-3 turns to try the skill
3. F5 reload with adjusted values
4. Continue same combat to test immediately
5. Repeat until it feels right

**Testing Turn Order (CTB/AP):**
1. Launch with "Speed Test" preset
2. Edit `combat_config.json` → change `speed_multiplier` or `base_ap`
3. F5 reload
4. Observe turn order changes in UI

**Testing Enemy Balance:**
1. Launch preset
2. Edit `test_enemies.json` → adjust HP, stats, resistances
3. F5 reload
4. Existing enemies update with new stats

---

## What Hot Reload Updates

✅ **Automatically Updated:**
- Skill damage, MP costs, effects
- Character base stats (Vigor, Strength, etc.)
- Enemy base stats
- Combat config values (HP per Vigor, MP regen, etc.)
- Grid size and cell dimensions

❌ **Not Updated (requires scene restart):**
- Number of units in combat
- Unit positions on grid
- Current HP/MP values
- Status effect durations already applied

**Tip:** For big structural changes (adding/removing units), use quick presets to restart fast.

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **F5** | Hot reload all JSON data |
| `` ` `` (backtick) | Toggle debug panel (planned, not yet implemented) |

---

## Example: Tuning a Skill in 2 Minutes

**Goal:** Make "True Strike" feel more impactful

```
1. Click "Default 3v3" preset → Combat starts
2. Use True Strike on enemy → "130 damage, doesn't feel like a finisher"
3. Open core_skills.json
4. Find true_strike, change:
     "base": 130  →  "base": 180
     "mp_cost": 2  →  "mp_cost": 3
5. Save
6. F5 in game
7. Use True Strike again → "180 damage, better! But too cheap at 3 MP"
8. Change mp_cost: 3 → 4
9. Save, F5
10. Use again → "Perfect! High impact, high cost"
```

**Time:** ~2 minutes
**Iterations:** 3
**Scene restarts:** 0

---

## Tips for Effective Iteration

**Start with Extremes:**
- Try damage at 50, then 500 → find the range
- Narrow down: 200, then 150, then 175
- Faster than guessing middle values

**Use Action Log:**
- Combat logs every action with damage numbers
- Scroll up to compare old vs. new values after F5
- No need to memorize previous results

**Test in Context:**
- Don't test skills in isolation
- Play 3-5 turns to feel the flow
- Better feedback than single-action tests

**Save Good Configs:**
- When combat feels good, copy the JSON files
- Name them: `core_skills_v2_good_balance.json`
- Easy rollback if you break something

---

## Troubleshooting

**F5 does nothing:**
- Check console for error messages
- Verify JSON syntax is valid (use online JSON validator)
- Look for "Hot reload complete" message in action log

**Changes not applying:**
- Make sure you saved the JSON file
- Check you edited the right file (godot/data/..., not docs/...)
- Some changes require scene restart (see "What Hot Reload Updates" above)

**Combat breaks after reload:**
- Syntax error in JSON (check console)
- Invalid skill reference (e.g., deleted a skill that's equipped)
- Reload scene and try again with valid JSON

---

## Next Steps

Once you've iterated on combat feel, consider:

1. **Playtest Logging** (coming soon) - Auto-save combat results for analysis
2. **In-Game Tuning Panel** (planned) - Edit values with sliders during combat
3. **Debug Panel** (planned) - `` ` `` to toggle stat inspector and skill tester

For now, enjoy **sub-minute iteration cycles** with F5 hot reload and quick presets!

---

## File Locations Quick Reference

```
godot/data/
├── skills/
│   └── core_skills.json        ← Edit skill damage, MP costs, effects
├── characters/
│   └── party.json              ← Edit Cyrus/Vaughn/Phaidros stats
├── enemies/
│   └── test_enemies.json       ← Edit enemy stats, resistances
└── combat/
    ├── combat_config.json      ← Edit HP scaling, MP regen, damage formulas
    └── encounters.json         ← Edit encounter presets
```

**Godot Scenes:**
- `scenes/combat/combat_configurator.tscn` - Quick launch presets
- `scenes/combat/combat_arena.tscn` - The combat scene (F5 reload works here)
