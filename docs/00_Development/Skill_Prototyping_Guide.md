# Skill Prototyping Guide

Quick reference for testing new skills and enemy compositions in combat.

---

## Damage Baseline (Current)

**Target TTK**: 3-5 rounds to kill standard enemy with focused fire

| Ability Type | Base Damage | Notes |
|--------------|-------------|-------|
| Basic Attack | 20 | Free, unlimited use |
| Standard Ability | 25-35 | 2 MP cost |
| Heavy Ability | 40-45 | 2-3 MP cost |
| DOT (per turn) | 6-10 | Over 3 turns = 18-30 total |
| AOE | 30 | Hits multiple targets |

**Enemy HP Ranges:**
- Swarm (Imp): 35 HP → Dies in ~2 attacks
- Glass Cannon (Scout, Caster): 50-60 HP → Dies in ~3 attacks
- Standard (Hexer, Brawler): 70-90 HP → Dies in ~4 attacks
- Tank (Brute, Leech): 100-140 HP → Dies in ~5-7 attacks
- Boss (Champion): 200 HP → Dies in ~10 attacks

---

## Player Character Loadouts

### Cyrus - High Damage Striker
**Stats**: STR 7, DEX 6, VIG 6, AGI 6
**Role**: Front-line DPS, cleave damage
**Skills**:
- Basic Attack (20 damage)
- True Strike (40 damage, can't dodge, lunges to target)
- Heavy Swing (45 damage, blunt)
- Cleave (30 damage to all adjacent enemies)

**Strategy**: Cleave when surrounded, True Strike for single target burst, Heavy Swing for armor breaking

### Vaughn - Debuffer / Support
**Stats**: DEX 8, STR 6, AGI 7, VIG 5
**Role**: Debuff enemies, buff allies
**Skills**:
- Basic Attack (20 damage)
- Hamstring (25 damage + reduce Agility 50% for 3 turns)
- Poison Strike (20 damage + 8/turn for 3 turns = 44 total)
- Leadership (Buff all allies: +15% STR/DEX for 3 turns)

**Strategy**: Open with Leadership, then Hamstring priority targets, Poison Strike tanks

### Phaidros - Tank / Disruptor
**Stats**: VIG 9, STR 7, DEX 4, AGI 4
**Role**: Control positioning, protect allies
**Skills**:
- Basic Attack (20 damage)
- Shield Bash (20 damage + stun 1 turn)
- Ironflesh (Grant ally 30% physical DR for 3 turns)
- Grapple (10 damage + pull enemy 2 spaces toward you)

**Strategy**: Grapple backline enemies forward, Shield Bash to interrupt, Ironflesh on Cyrus before he dives

---

## Enemy Archetypes

### Glass Cannon (Scout, Caster)
**Threat**: High damage output
**Weakness**: Dies fast
**Priority**: KILL FIRST
**Abilities**: Frenzy (2x hits), Lightning Bolt, Ignite (DOT)
**Counter**: Focus fire, burst them down before they stack damage

### Tank (Brute, Leech)
**Threat**: Soaks damage, slows combat
**Weakness**: Slow, predictable
**Priority**: Last
**Abilities**: Heavy Swing, Shield Bash, Heal Self
**Counter**: Ignore unless isolated, use DOTs, Hamstring to slow further

### Debuffer (Hexer)
**Threat**: Weakens your party over time
**Weakness**: Moderate HP
**Priority**: Second
**Abilities**: Weaken (-30% STR), Corrupting Aura (AOE debuff), Venom Spit
**Counter**: Kill before they stack debuffs, use Cleave if grouped

### Disruptor (Brawler)
**Threat**: Messes up your positioning
**Weakness**: Linear tactics
**Priority**: Second/Third
**Abilities**: Shove, Grapple Pull, Heavy Swing
**Counter**: Position carefully, use Grapple to pull them out of formation

### Regenerator (Leech)
**Threat**: Heals itself, extends combat
**Weakness**: Moderate damage
**Priority**: First or Second
**Abilities**: Venom Spit, Heal Self (30 HP)
**Counter**: Burst damage when low, prevent heal with stuns/kills

### Swarm (Imp)
**Threat**: Chip damage, action economy
**Weakness**: 1-shots from abilities
**Priority**: AOE them
**Abilities**: Basic Attack, Dark Bolt
**Counter**: Cleave to hit multiple, or ignore and focus priority targets

### Boss (Champion)
**Threat**: Everything
**Weakness**: None (balanced stats)
**Priority**: Focus fire with debuffs
**Abilities**: Heavy Swing, Cleave, Shield Bash, Frenzy
**Counter**: Hamstring, Leadership buff, Ironflesh on tank, coordinate burst

---

## Interesting Encounter Compositions

### "Glass Cannon Rush"
- 2x Corrupted Scout
- 1x Corrupted Caster
**Test**: Can you survive turn 1-2? Prioritization under pressure.

### "Tank and Spank"
- 1x Corrupted Brute (front)
- 2x Corrupted Hexer (back)
**Test**: Do you ignore the tank? How annoying are debuffs?

### "Swarm"
- 4x Corrupted Imp
**Test**: Is AOE valuable? Does swarm feel threatening or trivial?

### "Mixed Tactics"
- 1x Corrupted Brawler (disruptor)
- 1x Corrupted Leech (regen)
- 1x Corrupted Hexer (debuff)
**Test**: Multiple threats, requires tactical decisions

### "Boss Fight"
- 1x Corrupted Champion
- 2x Corrupted Scout (adds)
**Test**: TTK on boss, do adds create urgency?

### "Positioning Hell"
- 2x Corrupted Brawler
- 1x Corrupted Caster (back)
**Test**: How frustrating is constant shoving/pulling?

---

## Testing Questions

### Time to Kill
- Does combat feel too fast? Too slow?
- Are tanks annoying or strategic?
- Do glass cannons die satisfyingly fast?

### Skill Balance
- Is Basic Attack ever worth using over abilities?
- Are 2 MP abilities worth the cost?
- Do DOTs feel impactful or ignorable?

### Enemy Asymmetry
- Can you tell enemies apart by behavior?
- Do different archetypes demand different tactics?
- Are any enemies "boring" (just HP sponges)?

### Positioning
- Do Grapple/Shove create interesting moments?
- Is repositioning worth the AP cost?
- Does the grid size feel right?

### Player Agency
- Do you have meaningful choices each turn?
- Are there "correct" and "trap" builds?
- Is MP scarcity creating tough decisions?

---

## Hot Reload Testing

**Press F5 in combat** to reload skills.json and enemies.json without restarting combat.

### Quick Damage Tweaks
Edit `data/skills/core_skills.json`:
```json
"damage": {
  "base": 30  // ← Change this number, press F5
}
```

### Quick Enemy HP Tweaks
Edit `data/enemies/test_enemies.json`:
```json
"hp": 80  // ← Change this number, start new combat
```

### Add New Skill
1. Copy existing skill in skills.json
2. Change id, name, description, damage
3. Press F5 (or restart combat)
4. Add skill id to enemy's "abilities" array

---

## Balance Iteration Workflow

1. **Fight an encounter**
2. **Note pain points**: "Scout dies too fast", "Caster too weak", "Combat drags"
3. **Make 1 change**: Increase Scout HP by 20, or increase Caster damage by 10
4. **Press F5** (skills) or **restart combat** (enemies)
5. **Test again** - does it feel better?
6. **Repeat**

**Goal**: Find the fun. Numbers are just starting points.

---

## Current Known Issues

- **Positioning skills (Shove, Grapple)**: Not yet implemented
- **DOT damage**: Not yet implemented
- **AOE targeting**: May not work correctly
- **Stun effect**: Not yet implemented
- **Multi-hit (Frenzy)**: Not yet implemented

**These will be implemented as we test and validate they're worth the dev time.**

---

## Next Skills to Prototype

Once core balance feels good, consider adding:
- **Combo skills**: "Deal bonus damage to Poisoned enemies"
- **Reactive skills**: "Counter-attack when hit"
- **Movement skills**: "Dash 2 spaces and attack"
- **Terrain skills**: "Create hazard zones"
- **Sacrifice skills**: "Spend HP to deal massive damage"

**But first**: Get basic damage/TTK feeling good with current skill set.
