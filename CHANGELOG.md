# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.2.0] - 2026-03-02

### Added

- **Tile effects system** — category-slotted effects per hex: one surface (fire, ice_sheet, poison_cloud), one obstacle (stone_pillar, ice_pillar), plus existing soil
- **Element interactions** — data-driven bidirectional rules: fire+ice neutralize (remove_both), fire+poison explode (AoE damage)
- **On-enter tile triggers** — fire deals damage, ice halts movement, poison applies status when a unit steps onto a surface tile
- **On-turn tile triggers** — standing on fire/poison deals damage at turn start
- **Collision mechanics** — forced movement detects wall, obstacle, and unit collisions step-by-step; configurable collision damage; obstacles take damage and can be destroyed
- **Impassable obstacles** — stone/ice pillars block pathfinding for both AI and player movement
- **Encounter starting effects** — encounters can define `starting_tile_effects` to pre-place terrain
- **Enemy death effects** — enemies with `death_tile_effect` leave behind terrain when defeated (e.g., corrupted_caster leaves fire)
- **Test terrain skills** — `ignite_ground` (fire) and `frost_sheet` (ice) added to Phaidros for testing
- **Obstacle HP bars** — visual HP bar rendered on obstacle tiles
- **Surface color overlays** — configurable per-effect-type color and alpha rendering on hex grid
- Config loader getters: `get_tile_effect_type()`, `get_all_tile_effect_types()`, `get_element_interactions()`, `get_collision_config()`
- Tile effects design document and implementation plan

### Changed

- **`the_wall` skill** — now creates `stone_pillar` obstacles instead of placeholder terrain
- **Forced movement** — rewritten with step-by-step collision detection replacing simple position clamping
- **Movement execution** — on-enter effects checked at each step, not just final destination
- **Hot reload** — F5 now re-applies starting tile effects after clearing

## [0.1.0] - 2026-03-01

### Added

- **Burst Mode system** — gauge fills from combat actions, activates a multi-turn transformation with stat boosts (damage multiplier, damage reduction, crit rate bonus, speed bonus), gold border visual, and gauge/turns-remaining display on unit visuals
- **AI burst activation** — enemies with `burst_mode` data auto-activate when gauge reaches threshold
- **Data-driven burst eligibility** — any unit (ally or enemy) with a `burst_mode` field in their data gets burst capabilities; no longer hardcoded to allies
- **Burst config section** in `combat_config.json` with tunable `max_gauge`, `activation_threshold`, `activation_ap_cost`, and `gauge_carry_between_combats`
- **Burst config loader getters** — `get_burst_max_gauge()`, `get_burst_activation_threshold()`, `get_burst_activation_ap_cost()`, `get_burst_gauge_carry()`
- Burst button in combat action panel (allies only, visible when gauge is full)
- Burst Mode design document and implementation plan

### Changed

- **Unit visual sizing** — computes the largest aspect-ratio-matched rectangle inscribed in the hex cell instead of using the hex bounding box; units now fit properly within their hex
- **Name label text wrapping** — uses `AUTOWRAP_WORD_SMART` instead of `clip_text` so long enemy names wrap within the unit rectangle
- **Name label height** — dynamically fills available space above bars instead of fixed single-line height
- Status dots repositioned to sit just above the top bar

### Fixed

- **Combat breakage** — removed duplicate tile bonus/damage reduction code outside the hit loop that referenced an undeclared variable, preventing the entire combat manager script from loading
- **Speed bonus race condition** — burst countdown now saves state before decrementing so the final burst turn still gets the speed bonus for CTB calculation
