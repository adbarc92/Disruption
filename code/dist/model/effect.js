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
exports.BattleEffect = exports.FieldEffect = exports.BattleEffectTypes = exports.FieldEffectTypes = void 0;
var basic_info_1 = require("src/model/basic-info");
/**
 * The collection of field effect types.
 */
var FieldEffectTypes;
(function (FieldEffectTypes) {
    FieldEffectTypes["HEALTH"] = "HEALTH";
    FieldEffectTypes["STATUS"] = "STATUS";
    FieldEffectTypes["COMBO"] = "COMBO";
})(FieldEffectTypes = exports.FieldEffectTypes || (exports.FieldEffectTypes = {}));
;
/**
 * The collection of battle effect types.
 */
var BattleEffectTypes;
(function (BattleEffectTypes) {
    BattleEffectTypes["HEALTH"] = "HEALTH";
    BattleEffectTypes["STATUS"] = "STATUS";
    BattleEffectTypes["COMBO"] = "COMBO";
    BattleEffectTypes["POSITION"] = "POSITION";
})(BattleEffectTypes = exports.BattleEffectTypes || (exports.BattleEffectTypes = {}));
;
;
;
/**
 * @class the outcome of using an item or skill in the field.
 * @param type the type of field effect.
 * @param targetModifier the effect imparted onto the target.
 */
var FieldEffect = /** @class */ (function (_super) {
    __extends(FieldEffect, _super);
    function FieldEffect(name, description, type, targetModifier) {
        var _this = _super.call(this, name, description) || this;
        _this.type = type;
        _this.targetModifier = targetModifier;
        return _this;
    }
    return FieldEffect;
}(basic_info_1.BasicInfo));
exports.FieldEffect = FieldEffect;
;
/**
 * @class the outcome of using an item or skill in combat.
 * @param type the type of field effect.
 * @param targetModifier the effect imparted onto the user.
 * @param targetModifier the effect imparted onto the target.
 */
var BattleEffect = /** @class */ (function (_super) {
    __extends(BattleEffect, _super);
    function BattleEffect(name, description, type, userModifier, targetModifier) {
        var _this = _super.call(this, name, description) || this;
        _this.type = type;
        _this.userModifier = userModifier;
        _this.targetModifier = targetModifier;
        return _this;
    }
    return BattleEffect;
}(basic_info_1.BasicInfo));
exports.BattleEffect = BattleEffect;
;
//# sourceMappingURL=effect.js.map