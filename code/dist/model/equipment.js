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
exports.Equipment = void 0;
var basic_info_1 = require("src/model/basic-info");
var stats_1 = require("src/model/stats");
/**
 * @class the equipment of a unit.
 * @param families the families to which the equipment is available.
 * @param slot the slot to which an equipment would be assigned.
 * @param worn whether or not the equipment is worn.
 * @param stats the stat changes of a piece of equipment.
 */
var Equipment = /** @class */ (function (_super) {
    __extends(Equipment, _super);
    function Equipment(name, description, families, slot, vitality, defense, resistance, amplification, damage, critDamage, critRate, accuracy, initiative, evasion) {
        var _this = _super.call(this, name, description) || this;
        _this.families = families;
        _this.slot = slot;
        _this.worn = false;
        _this.stats = new stats_1.Stats({
            vitality: vitality,
            defense: defense,
            resistance: resistance,
            amplification: amplification,
            damage: damage,
            critDamage: critDamage,
            critRate: critRate,
            accuracy: accuracy,
            initiative: initiative,
            evasion: evasion,
        });
        return _this;
    }
    return Equipment;
}(basic_info_1.BasicInfo));
exports.Equipment = Equipment;
;
//# sourceMappingURL=equipment.js.map