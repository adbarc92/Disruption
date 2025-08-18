"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BattleAI = exports.FieldAI = void 0;
/**
 * @class Defines how an agent traverses the field.
 * @param fieldDirective determines how an agent navigates the field.
 */
var FieldAI = /** @class */ (function () {
    function FieldAI(fieldDirective) {
        this.fieldDirective = fieldDirective;
    }
    return FieldAI;
}());
exports.FieldAI = FieldAI;
/**
 * Defines how a unit comports itself in combat.
 */
var BattleAI = /** @class */ (function () {
    function BattleAI() {
    }
    return BattleAI;
}());
exports.BattleAI = BattleAI;
//# sourceMappingURL=ai.js.map