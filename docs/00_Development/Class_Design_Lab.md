# Class Design Lab

A living document for exploring character customization systems, from fixed classes to full compositional design. This tracks our iteration on how players build and customize characters.

---

## The Core Question

**How much character customization do we want, and what's the cost?**

Original vision: Compositional tag system where players build characters from granular components.

Reality check: This could explode complexity and make balance unfeasible.

**This document exists to find the right balance through testing.**

---

## The Complexity Problem

### Current Design Scope

Our combat system has:
- **Damage types**: 12+ (slash, pierce, blunt, fire, ice, lightning, earth, wind, water, arcane, divine, occult, psychic, necrotic, radiant)
- **Position mechanics**: 3x3 grid per side (36 possible positions)
- **Resource systems**: MP + Equipment Charges + Burst Gauge (3 separate systems)
- **Turn order**: CTB system (speed-based turn frequency)
- **Action economy**: AP system (multiple actions per turn)
- **Status effects**: 20+ different effects

### The Math of Compositional Design

If we have:
- 10 tags across 3 categories
- ~5 meaningful tag combinations per character
- Each combination unlocks 1-3 unique skills

**Testing requirements:**
- Hundreds to thousands of skill interactions
- Each new tag combination needs testing against ALL existing content
- Each new enemy needs testing against ALL character builds
- Every balance change cascades unpredictably

**Example:** 100 skills with potential interactions = ~10,000 interaction pairs to consider

### Why This Is Hard

**Exponential growth:**
- 3 tags, 2 choices each = 8 combinations (manageable)
- 5 tags, 3 choices each = 243 combinations (terrifying)
- 10 tags, variable choices = thousands of combinations (impossible)

**Each combination needs:**
- Unique skills designed and implemented
- Balanced against all enemies
- Tested in all party compositions
- Validated as "viable but not broken"

**For a small team:** This is 2-5 years of balance iteration, minimum.

---

## Case Studies: Who's Done This?

### ✅ Successes (with heavy caveats)

#### Path of Exile - Skill Gem Combinations
- **Team size**: 100+ developers
- **Balance approach**: Constant rebalancing, seasonal wipes, accept meta shifts
- **Reality**: Even with huge team, balance is never "solved"
- **Takeaway**: Requires massive team and live-service model

#### Guild Wars 1 - 1,000+ Skills, 8-Skill Builds
- **Team size**: ArenaNet (~50-100 people)
- **Balance approach**: PvP/PvE split balancing, frequent nerfs, some skills obsolete
- **Reality**: Beloved despite chaos, but had dedicated balance team
- **Takeaway**: Cult classic, but required AAA resources

#### Divinity: Original Sin - Elemental Combinations
- **Team size**: Larian Studios (~100+)
- **Balance approach**: **Limited scope** - only ~20 elements, clear interaction rules
- **Reality**: Interactions are physics-based and predictable, not hand-crafted
- **Takeaway**: Works because interactions are **emergent from rules**, not manually designed

#### Deep Rock Galactic - Weapon Mod Combinations
- **Team size**: ~30-50 people
- **Balance approach**: **Tight constraints** - 5 tiers, 2-3 choices per tier
- **Reality**: ~20 combinations per weapon, math-based trade-offs (damage vs fire rate)
- **Takeaway**: Constrained choice space + clear trade-offs = manageable

#### Wildermyth - Class + Personality Trait Combos
- **Team size**: 3-5 people (indie!)
- **Balance approach**: **Procedural + narrative focus** - balance is looser
- **Reality**: Single-player story game. "Broken" builds are fun, not competitive
- **Takeaway**: Works because story > balance, no PvP, no "correct" builds

### ❌ Warnings / Failures

#### Kingdoms of Amalur - Talent Tree Freedom
- Too much freedom → bland builds
- Everything viable → nothing special
- Players confused about optimal builds

#### Too Human - Complex Skill/Build System
- Overwhelming complexity
- Unclear optimal paths
- Players bounced off, never engaged

#### Artifact (Valve) - Complex Card Interactions
- Dead on arrival
- Too complex, no clear strategies
- Even Valve couldn't balance it

---

## Three Viable Approaches

### Option 1: Hybrid System (Recommended for Indie)

**Fixed archetypes with limited tag customization**

```
Cyrus (Fixed Base: "Entropic Blade")
├─ Tag Slot 1: [Elemental] or [Shadow] or [Psychic]
├─ Tag Slot 2: [Offensive] or [Technical] or [Defensive]
└─ Unlocks: 1 unique skill per combination (3×3 = 9 skills total)

Each character: 9 possible builds
3 characters: 27 total builds to balance
Party compositions: 27³ = 19,683 possible (but only ~50-100 viable)
```

**Pros:**
- Predictable scope (can test all builds)
- Each character retains identity
- Meaningful customization without chaos
- Similar to FFX Sphere Grid: guided paths, not total freedom

**Cons:**
- Less dramatic than "build anything" fantasy
- Requires designing 9 skills × 8 characters = 72 unique skills
- Still significant work, but manageable

**Testing time:** ~50-100 hours to validate all builds

---

### Option 2: Emergent Interactions (Divinity Model)

**Rule-based compositional system**

```
Base Tags (5): Fire, Ice, Lightning, Earth, Shadow
Interaction Rules:
  Fire + Ice = Steam (blocks vision, -50% accuracy)
  Ice + Blunt damage = Shatter (+50% damage to frozen)
  Lightning + Water surface = Chain Lightning (AOE)
  Earth + Fire = Lava (persistent damage zone)
  Shadow + Psychic = Dread (fear effect)
```

**Pros:**
- Interactions are **emergent**, not hand-crafted
- Players discover combos organically
- Clear, testable rules (like physics)
- Scales well (new tags just need interaction rules)

**Cons:**
- Requires upfront rules design (hard to get right)
- Emergent chaos can still break balance
- Harder to make each character feel unique

**Testing time:** Test ~20 base effects, ~50 interaction rules

**Key insight:** You balance the **rules**, not every combination

---

### Option 3: Full Compositional (High Risk, High Reward)

**Pure tag-based character building**

**If you commit to this, you MUST:**

1. **Cut damage types to 5 max** (Physical, Fire, Ice, Lightning, Arcane)
   - Drop: slash/pierce/blunt, all other elementals, occult, psychic, necrotic, radiant
   - Reason: Each damage type multiplies balance complexity

2. **Cut resources to 1** (Just MP)
   - Drop: Equipment Charges, Burst Gauge (add later if needed)
   - Reason: Each resource system multiplies decision space

3. **Start with 3 tags total**
   - Example: Offensive, Defensive, Technical
   - Test exhaustively before adding more

4. **Add 1 tag at a time**
   - Add tag → Design 3-5 new skills → Test vs all enemies → Balance
   - Repeat for 2-3 years

5. **Accept 2+ years of balance patches**
   - Path of Exile releases major balance patches every 3 months
   - Guild Wars 1 had balance patches for 7+ years

6. **Budget for constant iteration**
   - Assume 20-30% of dev time is balance testing
   - Need player testing infrastructure (beta, feedback loops)

**Pros:**
- Ultimate player expression
- Endless build variety
- Strong modding potential
- "Build your way" marketing appeal

**Cons:**
- 3-5 year dev cycle
- Constant balance crises
- Some builds will be trash (unavoidable)
- Requires live-service model or accept broken builds

**Testing time:** Literally never done (ongoing forever)

---

## Recommended Iteration Path

### Phase 1: Vertical Slice (Current - 2-3 months)

**Focus:** Is positioning-based combat fun?

**Characters:** Fixed 3 characters (Cyrus, Vaughn, Phaidros)
- Fixed abilities per character (4-6 skills each)
- No customization yet

**Goal:** Validate core combat loop
- Is the grid interesting?
- Do abilities feel impactful?
- Is turn order clear and strategic?
- Does resource management create decisions?

**Decision Point:**
- ✅ Combat is fun → Proceed to Phase 2
- ❌ Combat isn't fun → **No amount of customization fixes this**

---

### Phase 2: Limited Customization (3-4 months)

**Focus:** Does build choice create meaningful decisions?

**Add:** 1-2 ability choices per character
- Example: Cyrus chooses between "Heavy Swing" or "Cleave" at level 3
- Example: Vaughn chooses "Hamstring" or "Poison Strike" specialization

**Implementation:** FFX Sphere Grid style - branching paths, not open field

**Goal:** Test if choice matters
- Do builds feel different?
- Are choices hard (good) or obvious (bad)?
- Do players understand trade-offs?

**Testing Questions:**
- Can players articulate why they chose build A over B?
- Do different builds perform similarly (balanced) or wildly different (broken)?
- Are "trap" builds obvious or hidden?

**Decision Point:**
- ✅ Builds feel distinct and balanced → Consider expanding (Phase 3)
- ⚠️ Builds feel same-y → Keep it simple, polish fixed classes
- ❌ Builds are broken/confusing → Revert to fixed classes

---

### Phase 3A: Expand Customization (if Phase 2 succeeds)

**Add:** Tag slot system (Hybrid Option 1)
- Each character: 2 tag slots, 3 choices each = 9 builds per character
- Design 1 unique skill per tag combo

**Timeline:** 6-12 months
- 3 characters × 9 builds = 27 builds to design and balance
- Estimate 2-4 weeks per build (design, implement, test, balance)

**Scope check:** Can you design 27 interesting, balanced builds?

---

### Phase 3B: Pivot to Emergent (if complexity is too high)

**Redesign:** Rule-based interactions (Option 2)
- Cut tags to 5 elemental types
- Design ~20 interaction rules
- Let combinations emerge

**Timeline:** 4-6 months
- Front-loaded design work (rules need to be airtight)
- Less ongoing balance (rules scale better than hand-crafted)

---

### Phase 3C: Abandon Customization (if Phase 2 fails)

**Pivot:** Fixed classes with deep progression
- 8 characters, each with 8-12 unique skills
- Unlock skills via story/progression
- Polish the hell out of each character's identity

**Timeline:** 3-6 months
- 8 characters × 10 skills = 80 total skills (similar workload to hybrid)
- Easier to balance (no combinations)
- Can focus on narrative integration

**Examples:**
- Hades: Fixed weapons, upgrade choices create variety
- Into the Breach: Fixed mechs, positioning is the depth
- Darkest Dungeon: Fixed classes, mastery is the progression

---

## Current Status & Next Steps

### Where We Are Now (Phase 1)
- ✅ Combat prototyping underway
- ✅ 3 fixed characters with test abilities
- ✅ 8 enemy archetypes with diverse skills
- ⏳ Testing TTK and combat pacing
- ⏳ Validating positioning mechanics

### Immediate Testing Questions
1. **Is combat fun with zero customization?**
   - Play 10 combats with current fixed builds
   - Note: Are you bored? Excited? Confused?

2. **Do the 3 characters feel distinct?**
   - Cyrus (striker), Vaughn (debuffer), Phaidros (tank)
   - Can you tell them apart by playstyle alone?

3. **Do you wish you had more options?**
   - If yes: What kind? (More damage? More positioning? More support?)
   - If no: Fixed classes might be enough

### Decision Timeline

**Week 4-6:** Phase 1 complete
- Decision: Is core combat fun enough to build on?

**Week 8-12:** Phase 2 (if proceeding)
- Add 1-2 ability choices per character
- Decision: Do choices matter? Are they balanced?

**Week 14-20:** Phase 3 direction chosen
- Expand (Hybrid), Pivot (Emergent), or Simplify (Fixed)

---

## Key Principles

### 1. Playtesting is King
**Design documents are hypotheses. Playtesting reveals truth.**

You can't know if tags are necessary until you test combat without them.

### 2. Scope Ruthlessly
Every system multiplies complexity:
- 3 resource systems × 12 damage types × compositional builds = **nightmare**
- 1 resource system × 5 damage types × limited builds = **manageable**

Cut early, cut often. Add later if players demand it.

### 3. Identity > Customization
Players remember **Geralt** (fixed, strong identity), not **Skyrim Stealth Archer #47** (customizable, bland).

Distinctive fixed characters > infinite bland combinations

### 4. Embrace Constraints
- FFX: Linear progression, still beloved
- Hades: Fixed weapons, infinite replayability
- Into the Breach: 3 mechs, perfect balance

Tight constraints force creativity.

---

## Warning Signs

**If you see these, cut scope immediately:**

🚨 **"This skill is hard to balance"**
- If you say this about >30% of skills, system is too complex

🚨 **"We'll balance it later"**
- Later never comes. Balance now or cut it.

🚨 **"Players will figure out the meta"**
- If you can't balance it, players won't enjoy it

🚨 **"We need more testing"**
- If >100 hours of testing haven't revealed balance, system is too opaque

🚨 **"Just one more tag/system/feature"**
- Feature creep kills projects. Cut, don't add.

---

## Success Criteria

### Phase 1 Success (Combat is Fun)
- ✅ 10 consecutive combats without boredom
- ✅ Players can explain why they won/lost
- ✅ Clear strategic decisions every 2-3 turns
- ✅ Positioning matters in >50% of turns
- ✅ Characters feel distinct

### Phase 2 Success (Choices Matter)
- ✅ Build choices are non-obvious (takes thought)
- ✅ Different builds perform within 20% of each other
- ✅ Players can defend their build choices
- ✅ No "trap" builds (all viable)
- ✅ Builds enable different playstyles

### Phase 3 Success (System Scales)
- ✅ New content doesn't break old balance
- ✅ Testing new builds takes <2 weeks each
- ✅ Players discover emergent strategies
- ✅ Balance patches needed <monthly
- ✅ Community discusses builds (engagement)

---

## The Brutal Truth

**You probably don't need compositional tags.**

Most beloved tactical games have:
- **Fixed classes** (Fire Emblem, Advance Wars, Into the Breach)
- **Limited customization** (Final Fantasy Tactics, XCOM)
- **Deep mastery** (positioning, resource management, team composition)

Very few have **full compositional freedom** (Guild Wars 1, Path of Exile), and those that do:
- Had massive teams
- Took years to balance
- Still have broken builds

**The fun is in the tactics, not the spreadsheet.**

---

## Recommendation

**Start with fixed classes. Add customization only if playtesting demands it.**

1. Make 8 amazing, distinctive characters with fixed kits
2. Playtest for 50-100 hours
3. If players say "I wish I could customize more" → Add limited choices
4. If players say "This is perfect" → Ship it

**You can always add more. You can rarely take away.**

---

## Next Review

After Phase 1 complete (~Week 6):
- **Update this document** with playtesting results
- **Make Phase 2 decision**: Customize or polish?
- **Set Phase 3 direction** based on data, not hopes

**Remember:** The goal is a fun game, not a complex system. Complexity is a cost, not a feature.

---

*Last updated: 2026-02-21*
*Status: Phase 1 - Combat Prototyping*
*Decision pending: Week 6*
