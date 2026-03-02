# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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
