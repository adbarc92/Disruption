# Combat Iteration Roadmap

## Context
This document outlines the iteration path for Disruption's combat system, focusing on rapid prototyping and playtesting to validate core mechanics before building the full vertical slice.

**Design Philosophy**: Playtesting is king. We'll build minimal playable versions, test with real players, and let their experience guide the next iteration.

---

## Current State

### Implemented (TypeScript Models)
- Core data structures: Units, Skills, Stats, Effects, Status Effects
- Position system with 3x3 grid support
- Damage type and resistance framework
- Equipment system foundation
- Effect composition architecture

### Not Yet Implemented
- Battle state machine and turn order management
- AI system
- Combat UI and visualization
- Skill execution and effect application
- Status effect processing
- Progression grid integration

---

## Iteration Path

### Phase 1: Minimal Playable Combat (Week 1-2)
**Goal**: Get a 3v3 battle running with basic attacks only. No polish, just functional.

**Deliverables**:
- [ ] Battle state manager (turn queue, current actor, battle flow)
- [ ] Basic attack action (damage calculation, application)
- [ ] Simple combat UI (grid visualization, health bars, action selection)
- [ ] Manual turn progression (click to advance)
- [ ] Win/loss conditions

**Test Questions**:
- Does the 3x3 grid feel spatially meaningful?
- Is turn order clear and intuitive?
- Do basic attacks feel satisfying?

**Complexity Toggles**: None (everything is off)

---

### Phase 2: Positioning Matters (Week 3-4)
**Goal**: Make position strategically important. Add movement and position-based abilities.

**Deliverables**:
- [ ] Movement actions (advance, retreat, strafe)
- [ ] Position-restricted abilities (front-row only, back-row targeting)
- [ ] Front row protection mechanic
- [ ] Knockback/pull positioning effects

**Test Questions**:
- Do players naturally think about positioning?
- Is it too fiddly to manage 3 units on a grid?
- What positioning patterns emerge?

**Complexity Toggles**: Position restrictions (can be disabled for simpler mode)

---

### Phase 3: Resource Depth (Week 5-6)
**Goal**: Add MP system and Equipment charges. Test resource management decisions.

**Deliverables**:
- [ ] MP regeneration system (2-3 per turn)
- [ ] Role-based abilities (cost MP)
- [ ] Equipment with limited charges
- [ ] Resource display in UI

**Test Questions**:
- Is MP scarcity creating interesting decisions?
- Are Equipment charges exciting or frustrating?
- Do players hoard or spend resources?
- Is the dual resource system too complex?

**Complexity Toggles**:
- MP system (can use cooldowns instead)
- Equipment charges (can make unlimited use)

---

### Phase 4: Status Effects & Combos (Week 7-8)
**Goal**: Add status effects and ability synergies. Test tactical depth.

**Deliverables**:
- [ ] Status effect application and processing
- [ ] Duration tracking and expiration
- [ ] Status-conditional abilities (bonus damage vs Burning, etc.)
- [ ] Buff/debuff stacking rules

**Test Questions**:
- Do status effects create satisfying combo moments?
- Is tracking multiple statuses overwhelming?
- Are there dominant strategies emerging?

**Complexity Toggles**: Status effects (can simplify to just damage/healing)

---

### Phase 5: Action Economy Experimentation (Week 9-10)
**Goal**: Test different action economy models. Find what feels best.

**Deliverables**:
- [ ] Implement Action Point system (3-5 AP variant)
- [ ] Implement Structured system (Move + Action + Bonus variant)
- [ ] Implement current "Free" system (no restrictions)
- [ ] A/B test with playtesters

**Test Questions**:
- Which system creates better decision-making?
- Which feels less restrictive/more fun?
- Does structured action economy slow down combat too much?

**Decision Point**: Pick one system to move forward with.

---

### Phase 6: Burst Mode Prototype (Week 11-12)
**Goal**: Add transformation system. Test if it's exciting or gimmicky.

**Deliverables**:
- [ ] Burst gauge charging (pick one charge method per character)
- [ ] Transformation activation
- [ ] Stat boost application
- [ ] Basic transformed abilities (1-2 per character)
- [ ] Gauge visualization

**Test Questions**:
- Does Burst feel like a game-changer or win-more?
- Is the charge rate too fast/slow?
- Do players save it or use it immediately?
- Is transformation duration right (4-6 turns)?

**Complexity Toggles**: Burst Mode (entire system can be disabled)

---

### Phase 7: Enemy AI & Balance (Week 13-14)
**Goal**: Make enemies challenging and interesting, not just punching bags.

**Deliverables**:
- [ ] Basic AI decision-making (target selection, ability choice)
- [ ] Enemy-specific behavior patterns
- [ ] Difficulty tuning (damage, HP, abilities)
- [ ] 3-5 distinct enemy types

**Test Questions**:
- Do enemies feel threatening or trivial?
- Are there cheap/frustrating enemy tactics?
- Is there sufficient variety in encounters?

---

### Phase 8: Polish & Integration (Week 15-16)
**Goal**: Make combat feel good. Add juice, feedback, and integrate with vertical slice.

**Deliverables**:
- [ ] Animation and VFX for abilities
- [ ] Sound effects and hit feedback
- [ ] Turn transition polish
- [ ] Combat to exploration flow
- [ ] Combat encounter triggers (Chrono Trigger style)

**Test Questions**:
- Does combat feel punchy and responsive?
- Are ability effects clear and readable?
- Is the transition in/out of combat smooth?

---

## Playtesting Strategy

### Internal Testing (Rapid Iteration)
- **Frequency**: After each phase
- **Format**: Solo testing + 2-3 close collaborators
- **Focus**: Core mechanics, game-breaking bugs
- **Feedback Method**: Direct conversation, quick notes

### External Testing (Validation)
- **Frequency**: After Phases 3, 6, 8
- **Format**: 5-10 external playtesters
- **Focus**: Fun factor, clarity, pacing
- **Feedback Method**: Structured survey + recorded sessions

### Key Metrics to Track
- Average combat duration (target: 5-10 minutes)
- Decision points per turn (target: 2-4 meaningful choices)
- Win rate vs AI (target: 60-70% for balanced difficulty)
- Player-reported fun score (1-10 scale)
- "I'd want to play more" percentage

---

## Complexity Management

Throughout iteration, maintain toggles for:
- Position restrictions (ON/OFF)
- MP system vs Cooldowns
- Equipment charges (LIMITED/UNLIMITED)
- Status effects (FULL/SIMPLE/OFF)
- Burst Mode (ON/OFF)
- Action economy model (AP/STRUCTURED/FREE)

**Tabletop Mode**: All complexity OFF = pure tactical grid combat
**Full Digital Mode**: All complexity ON = deep strategic RPG

---

## Decision Points & Risks

### Major Decision: Action Economy (Phase 5)
- **Risk**: Committing to wrong system wastes iteration time
- **Mitigation**: Test all three variants with same combat scenarios
- **Criteria**: Pick based on playtest fun scores, not designer preference

### Major Decision: Burst Mode Necessity (Phase 6)
- **Risk**: System adds complexity without sufficient payoff
- **Mitigation**: Have kill switch ready; compare battles with/without
- **Criteria**: If <70% of testers say it's "exciting," consider cutting

### Major Risk: Combat Duration
- **Risk**: Battles take too long, hurt pacing
- **Mitigation**: Track time throughout; if >12min average, reduce HP/complexity
- **Target**: 5-10 minutes per encounter

### Major Risk: Analysis Paralysis
- **Risk**: Too many options overwhelm players
- **Mitigation**: Limit active abilities to 4-8 per character max
- **Warning Signs**: Players taking >30sec per turn consistently

---

## Success Criteria for Vertical Slice Combat

The combat system is ready for vertical slice when:
- ✅ Average playtester fun rating ≥ 7/10
- ✅ Win rate vs AI between 60-70% (not too easy/hard)
- ✅ Average combat duration 5-10 minutes
- ✅ Players can explain core mechanics without re-reading rules
- ✅ At least 2 emergent strategies/tactics observed in testing
- ✅ Zero game-breaking bugs in 10 consecutive test battles
- ✅ All 3 party members (Cyrus, Vaughn, Phaidros) feel distinct and viable

---

## Beyond Vertical Slice

Once vertical slice combat is validated, future iterations will add:
- Full character progression grid integration
- Ability mastery and permutation system
- Role mastery bonuses
- Additional party members (Paidi, Lione, Euphen, etc.)
- Party composition strategies
- Advanced enemy types and boss mechanics
- Environmental hazards and special tiles
- Combo system refinement

---

## Timeline Summary

| Week | Phase | Deliverable | Playtest |
|------|-------|-------------|----------|
| 1-2 | Phase 1 | Minimal playable combat | Internal |
| 3-4 | Phase 2 | Positioning mechanics | Internal |
| 5-6 | Phase 3 | Resource management | **External** |
| 7-8 | Phase 4 | Status effects | Internal |
| 9-10 | Phase 5 | Action economy test | Internal |
| 11-12 | Phase 6 | Burst mode prototype | **External** |
| 13-14 | Phase 7 | Enemy AI | Internal |
| 15-16 | Phase 8 | Polish & integration | **External** |

**Total Duration**: ~4 months of focused iteration

---

## Next Immediate Steps

1. **Godot Implementation**: Start Phase 1 - build battle state manager in Godot
2. **UI Mockup**: Sketch combat UI layout (grid, health bars, action buttons)
3. **Test Data**: Create simple combat scenario JSON (3 heroes vs 3 enemies)
4. **Playtester Recruitment**: Line up 5-10 people for Phase 3 external test

---

*Remember: Design documents are hypotheses. Playtesting reveals truth. Be ready to pivot based on player feedback.*
