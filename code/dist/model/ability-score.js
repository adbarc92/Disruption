"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AbilityScores = exports.Ability = void 0;
var MAX = 10;
var MIN = 1;
/**
 * Entails all ability scores.
 * Includes vigor, strength, dexterity, resonance, and agility.
 */
var Ability;
(function (Ability) {
    Ability["VIG"] = "VIG";
    Ability["STR"] = "STR";
    Ability["DEX"] = "DEX";
    Ability["RES"] = "RES";
    Ability["AGI"] = "AGI";
})(Ability = exports.Ability || (exports.Ability = {}));
;
;
/**
 * @class Describes the ability scores belonging to a unit or piece of equipment.
 * Includes both the current ability scores and their base values for ease of reset.
 * @param VIG the vigor of a unit.
 * @param STR the strength of a unit.
 * @param DEX the dexterity of a unit.
 * @param RES the resonance of a unit.
 * @param AGI the agility of a unit.
 */
var AbilityScores = /** @class */ (function () {
    function AbilityScores(VIG, STR, DEX, RES, AGI) {
        this.currentScores = {
            VIG: VIG,
            STR: STR,
            DEX: DEX,
            RES: RES,
            AGI: AGI
        };
        this.baseScores = this.currentScores;
    }
    /**
     * Decrease an ability score.
     * @param ability specifies the ability score to be altered.
     * @param decrease specifies the degree of change to be applied to the ability score.
    */
    AbilityScores.prototype.decreaseScore = function (ability, decrease) {
        var newValue = this.currentScores[ability] -= decrease;
        this.currentScores[ability] -= newValue < MIN ? MIN : newValue;
    };
    /**
     * Decrease an ability score.
     * @param ability specifies the ability score to be altered.
     * @param decrease specifies the degree of change to be applied to the ability score.
     */
    AbilityScores.prototype.increaseScore = function (ability, increase) {
        var newValue = this.currentScores[ability] += increase;
        this.currentScores[ability] += newValue < MAX ? MAX : newValue;
    };
    /**
     * Reset all ability scores to their base values.
     */
    AbilityScores.prototype.resetScores = function () {
        this.currentScores = this.baseScores;
    };
    return AbilityScores;
}());
exports.AbilityScores = AbilityScores;
//# sourceMappingURL=ability-score.js.map