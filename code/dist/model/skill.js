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
exports.Skill = void 0;
var basic_info_1 = require("src/model/basic-info");
/**
 * @class A skill to be used in combat.
 * @param usablePositions the positions from which the skill can be used.
 * @param targetPositions the positions targetable by the skill.
 * @param battleEffects consequences associated with use of the skill in combat.
 * @param fieldEffects consequences associated with use of the skill in the field.
 * @param families the groups to which the skill is available.
 * @param actionCost the cost of using the skill.
 * @param outcomeStats the stats on which the skill outcome is dependent.
 * @param sets the custom sets to which players have assigned the skill.
 * @param equipCost the cost of equipping the skill.
 * @param damageType the damage type associated with the skill.
 * @param animation the animation associated with the position.
 * @param partnerRequirements the requirements of teammates to enhance the skill.
 */
var Skill = /** @class */ (function (_super) {
    __extends(Skill, _super);
    function Skill(name, description, usablePositions, targetPositions, battleEffects, fieldEffects, families, actionCost, outcomeStats, equipCost, damageType, animation, partnerRequirements) {
        var _this = _super.call(this, name, description) || this;
        _this.usablePositions = usablePositions;
        _this.targetPositions = targetPositions;
        _this.battleEffects = battleEffects;
        _this.fieldEffects = fieldEffects;
        _this.families = families;
        _this.actionCost = actionCost;
        _this.outcomeStats = outcomeStats;
        _this.equipCost = equipCost;
        _this.sets = [];
        _this.damageType = damageType;
        _this.animation = animation;
        _this.partnerRequirements = partnerRequirements;
        return _this;
    }
    return Skill;
}(basic_info_1.BasicInfo));
exports.Skill = Skill;
//# sourceMappingURL=skill.js.map