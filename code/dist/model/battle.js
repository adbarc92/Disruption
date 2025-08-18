"use strict";
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Battle = void 0;
var Battle = /** @class */ (function () {
    function Battle(players, enemies) {
        this.turnOrder = [];
        this.turn = 0;
        this.players = players;
        this.enemies = enemies;
        this.setup();
    }
    Battle.prototype.setup = function () {
        this.turnOrder = __spreadArray(__spreadArray([], this.players, true), this.enemies, true).sort(function (a, b) { return b.initiative - a.initiative; });
    };
    Battle.prototype.isOver = function () {
        return this.players.every(function (p) { return p.stats.health.current <= 0; }) || this.enemies.every(function (e) { return e.stats.health.current <= 0; });
    };
    Object.defineProperty(Battle.prototype, "activeAgent", {
        get: function () {
            return this.turnOrder[this.turn % this.turnOrder.length];
        },
        enumerable: false,
        configurable: true
    });
    Battle.prototype.nextTurn = function () {
        this.turn++;
    };
    return Battle;
}());
exports.Battle = Battle;
//# sourceMappingURL=battle.js.map