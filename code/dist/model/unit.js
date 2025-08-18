"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.Unit = void 0;
var basic_info_1 = require("src/model/basic-info");
var ability_score_1 = require("src/model/ability-score");
var stats_1 = require("src/model/stats");
/**
 * @class A combat unit.
 * Accounts for all basic information needed for combat calculations.
 * Starts with no equipment.
 * @param category determines strengths and weaknesses.
 * @param family determines skills and equipment.
 * @param equipment adds to the stats of a unit.
 * @param VIG the vigor of a unit.
 * @param STR the strength of a unit.
 * @param DEX the dexterity of a unit.
 * @param RES the resonance of a unit.
 * @param AGI the agility of a unit.
 * @param challengeRating used for encounter construction.
 * @param ai determines the way a unit acts during combat.
 */
var Unit = /** @class */ (function (_super) {
    __extends(Unit, _super);
    function Unit(name, description, category, family, VIG, STR, DEX, RES, AGI, challengeRating, ai) {
        var _this = _super.call(this, name, description) || this;
        _this.category = category;
        _this.family = family;
        _this.equipment = null;
        _this.abilityScores = new ability_score_1.AbilityScores(VIG, STR, DEX, RES, AGI);
        _this.unitStats = stats_1.Stats.fromAbilityScores(_this.abilityScores);
        _this.challengeRating = challengeRating || 0;
        _this.ai = ai;
        return _this;
    }
    return Unit;
}(basic_info_1.BasicInfo));
exports.Unit = Unit;
//# sourceMappingURL=unit.js.map