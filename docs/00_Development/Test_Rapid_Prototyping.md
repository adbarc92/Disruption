# Test Procedure: Rapid Prototyping Features

Quick validation tests for hot reload and quick presets.

---

## Test 1: Quick Preset Launch

**Objective:** Verify one-click combat launch works

**Steps:**
1. Open Godot project
2. Open scene: `scenes/combat/combat_configurator.tscn`
3. Click "Play Scene" (F6)
4. Observe: Four preset buttons appear at top ("Default 3v3", "Speed Test", "Tank Test", "Last Config")
5. Click **"Default 3v3"** button
6. **Expected:** Combat scene loads within 1 second with:
   - 3×3 grid
   - Cyrus at front-middle, Vaughn at mid-top, Phaidros at front-bottom
   - 3 enemies (Scout, Brute, Caster)
   - Action log shows "Combat started: 3 allies vs 3 enemies"
   - Action log shows "Tip: Press F5 to hot reload data files"

**✅ Pass Criteria:** Combat loads automatically, no manual configuration needed

---

## Test 2: Hot Reload - Skill Damage Change

**Objective:** Verify F5 reloads skill data during combat

**Setup:**
1. Launch combat using "Default 3v3" preset
2. On Cyrus's turn, click "Attack" button
3. Target an enemy → Observe damage number (should be ~100-150)
4. Note the exact damage value

**Steps:**
1. **Without closing combat scene**, open file in external editor:
   `godot/data/skills/core_skills.json`

2. Find the "basic_attack" skill (near top of file):
   ```json
   {
     "id": "basic_attack",
     "name": "Attack",
     ...
     "damage": {
       "base": 100,
       ...
     }
   }
   ```

3. Change `"base": 100` to `"base": 250`

4. Save the file

5. **Return to Godot** (combat scene should still be running)

6. Press **F5** key

7. **Expected:**
   - Action log shows: "🔄 Data reloaded: X skills updated"
   - Status label briefly shows: "Data reloaded! (X skills changed)"
   - Console shows: "✅ Hot reload complete: X skills changed"

8. On next player turn, use "Attack" again

9. **Expected:** Damage is now ~250 (or higher with stat scaling)

**✅ Pass Criteria:** Damage changes without scene restart

**Cleanup:** Change `"base"` back to 100 and F5 reload to restore

---

## Test 3: Hot Reload - MP Cost Change

**Objective:** Verify skill MP costs update on reload

**Setup:**
1. Launch combat with "Default 3v3"
2. On Vaughn's turn, click "Skill" button
3. Observe "Hamstring" skill - note MP cost

**Steps:**
1. Open `godot/data/skills/core_skills.json`

2. Find "hamstring" skill:
   ```json
   {
     "id": "hamstring",
     "name": "Hamstring",
     "mp_cost": 2,
     ...
   }
   ```

3. Change `"mp_cost": 2` to `"mp_cost": 1`

4. Save file

5. Return to combat, press **F5**

6. Open skill panel again

7. **Expected:** Hamstring now shows MP cost of 1

**✅ Pass Criteria:** MP cost updates immediately

**Cleanup:** Restore `"mp_cost": 2`

---

## Test 4: Hot Reload - Combat Config Values

**Objective:** Verify balance config updates

**Setup:**
1. Launch combat
2. Observe current HP values for all units

**Steps:**
1. Open `godot/data/combat/combat_config.json`

2. Find the balance section:
   ```json
   "balance": {
     "hp_per_vigor": 60,
     ...
   }
   ```

3. Change `"hp_per_vigor": 60` to `"hp_per_vigor": 100`

4. Save file

5. Return to combat, press **F5**

6. **Expected:**
   - Console shows reload message
   - Note: Existing units keep their current HP (not retroactive)
   - To see effect: Need to start new combat

7. Exit combat (Back button)

8. Launch "Default 3v3" again

9. **Expected:** All units have higher max HP (~40% more)

**✅ Pass Criteria:** New combats use updated config values

**Cleanup:** Restore `"hp_per_vigor": 60`

---

## Test 5: Last Config Memory

**Objective:** Verify configurator remembers last setup

**Setup:**
1. Open `combat_configurator.tscn`
2. Manually configure:
   - Grid: 2×2
   - Ally positions: Place Cyrus in top-left
   - Encounter: Select "Two Scouts"
3. Click "Start Combat"
4. Play a few turns (or immediately quit)
5. Exit combat (Back button)

**Steps:**
1. You should be back at configurator
2. Click **"Last Config"** preset button

3. **Expected:**
   - Grid changes to 2×2
   - Cyrus appears in top-left
   - "Two Scouts" encounter selected
   - Combat launches with exact same setup

**✅ Pass Criteria:** Exact configuration restored and launched

---

## Test 6: All Presets Work

**Objective:** Verify each preset launches correctly

**Steps:**

### Default 3v3
- Click button
- **Expected:** 3×3 grid, 3 allies vs 3 enemies (Full Squad)

### Speed Test
- Exit combat, return to configurator
- Click "Speed Test"
- **Expected:** 3×3 grid, facing two Scouts (fast enemies)
- Observe: Turn order should cycle quickly

### Tank Test
- Exit combat, return to configurator
- Click "Tank Test"
- **Expected:** 3×3 grid, facing two Brutes (high HP)
- Observe: Enemies have ~400+ HP

**✅ Pass Criteria:** All presets launch with correct configs

---

## Test 7: Rapid Iteration Workflow

**Objective:** Test realistic iteration cycle

**Scenario:** "Make basic attacks feel more impactful"

**Steps:**
1. Launch "Default 3v3"
2. Use basic attack → note damage (~120)
3. Think: "Too weak, needs 50% more"
4. Open `core_skills.json`
5. Change basic_attack damage from 100 → 150
6. Save, F5
7. Use attack → see ~180 damage
8. Think: "Better, but maybe too much?"
9. Change 150 → 130
10. Save, F5
11. Use attack → see ~156 damage
12. Think: "Perfect!"

**Measure:** Time from step 1 to step 12

**✅ Pass Criteria:** Complete in < 3 minutes

---

## Common Issues & Solutions

**Issue:** F5 does nothing
- **Check:** Console for JSON parse errors
- **Fix:** Validate JSON syntax (online validator)
- **Check:** Correct file saved (godot/data/..., not docs/...)

**Issue:** "Skills changed: 0" after F5
- **Check:** File actually saved?
- **Check:** Editing correct file (not a backup)?
- **Try:** Make an obvious change (damage: 100 → 9999) to verify

**Issue:** Combat crashes after F5
- **Check:** Console for error messages
- **Common:** Removed a skill that a character has equipped
- **Fix:** Restore the skill or edit party.json to remove reference

**Issue:** Quick preset buttons not visible
- **Check:** Playing combat_configurator.tscn, not combat_arena.tscn
- **Try:** Restart Godot editor, reopen scene

---

## Success Indicators

✅ All 7 tests pass
✅ Hot reload works in < 5 seconds
✅ Quick presets launch in < 2 seconds
✅ Full iteration cycle (edit → test → adjust) in < 1 minute
✅ No scene restarts needed for balance changes

**If all tests pass:** You can now iterate on combat balance 10-20x faster! 🎉

---

## Next: Start Tuning!

With these tools working, you can now rapidly answer questions like:

- "Are 3 AP per turn enough?" → Edit config, F5, test
- "Is Hamstring worth 2 MP?" → Change cost, F5, try it
- "Do enemies need more HP?" → Edit test_enemies.json, F5, play
- "Is CTB speed formula too swingy?" → Adjust multiplier, F5, observe

See `Rapid_Prototyping_Guide.md` for workflow recommendations.
