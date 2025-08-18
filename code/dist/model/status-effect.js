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
exports.StatusEffect = void 0;
var basic_info_1 = require("src/model/basic-info");
/**
 * @class for creation and management of status effects.
 * @param type self-explanatory.
 * @param activationTime when the status effect activates.
 * @param battleEffect the consequence of the status in battle.
 * @param fieldEffect the consequence of the status in the field.
 * @param degree the multiplier for the effect.
 * @param priority the order in which status effects are activated.
 * @param duration the time until the status effect expires.
 */
var StatusEffect = /** @class */ (function (_super) {
    __extends(StatusEffect, _super);
    function StatusEffect(name, description, type, activationTime, battleEffect, fieldEffect, degree, priority, duration) {
        var _this = _super.call(this, name, description) || this;
        _this.type = type;
        _this.activationTime = activationTime;
        _this.battleEffect = battleEffect;
        _this.fieldEffect = fieldEffect;
        _this.degree = degree;
        _this.priority = priority;
        _this.duration = duration;
        return _this;
    }
    return StatusEffect;
}(basic_info_1.BasicInfo));
exports.StatusEffect = StatusEffect;
;
//# sourceMappingURL=status-effect.js.map