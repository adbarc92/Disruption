"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Stats = void 0;
/**
 * @class the stats for a unit and equipment as well as associated utilities for management.
 * @param baseStats a unit's normal stats.
 * @param currentStats a unit's stats after adjustment for status effects.
 */
var Stats = /** @class */ (function () {
    function Stats(stats) {
        this.currentStats = {
            vitality: stats.vitality,
            defense: stats.defense,
            resistance: stats.resistance,
            amplification: stats.amplification,
            damage: stats.damage,
            critDamage: stats.critDamage,
            critRate: stats.critRate,
            accuracy: stats.accuracy,
            initiative: stats.initiative,
            evasion: stats.evasion,
        };
        this.baseStats = this.currentStats;
    }
    /**
     * @constructor an alternate constructor to be used when creating units.
     */
    Stats.fromAbilityScores = function (abilityScores) {
        var _a = abilityScores.baseScores, VIG = _a.VIG, STR = _a.STR, DEX = _a.DEX, RES = _a.RES, AGI = _a.AGI;
        return new this({
            vitality: VIG * 5,
            defense: VIG * 2,
            resistance: RES * 5,
            amplification: RES * 2,
            damage: STR * 2,
            critDamage: STR * 0.5,
            critRate: DEX * 0.5,
            accuracy: DEX * 10,
            initiative: AGI * 3,
            evasion: AGI * 2,
        });
    };
    return Stats;
}());
exports.Stats = Stats;
//# sourceMappingURL=stats.js.map