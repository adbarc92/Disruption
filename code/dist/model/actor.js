"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Enemy = exports.Player = void 0;
var Player = /** @class */ (function () {
    function Player(id, name, stats, position, skills) {
        this.isPlayer = true;
        this.id = id;
        this.name = name;
        this.stats = stats;
        this.position = position;
        this.skills = skills;
    }
    Object.defineProperty(Player.prototype, "initiative", {
        get: function () {
            return this.stats.agility.current;
        },
        enumerable: false,
        configurable: true
    });
    Player.prototype.act = function (battle) {
        // For now, players will just attack the first enemy
        var target = battle.enemies[0];
        if (target) {
            console.log("".concat(this.name, " attacks ").concat(target.name, "!"));
            var damage = this.stats.strength.current;
            target.stats.health.current -= damage;
            console.log("".concat(target.name, " takes ").concat(damage, " damage and has ").concat(target.stats.health.current, " health remaining."));
        }
    };
    return Player;
}());
exports.Player = Player;
var Enemy = /** @class */ (function () {
    function Enemy(id, name, stats, position) {
        this.isPlayer = false;
        this.id = id;
        this.name = name;
        this.stats = stats;
        this.position = position;
    }
    Object.defineProperty(Enemy.prototype, "initiative", {
        get: function () {
            return this.stats.agility.current;
        },
        enumerable: false,
        configurable: true
    });
    Enemy.prototype.act = function (battle) {
        // For now, enemies will just attack the first player
        var target = battle.players[0];
        if (target) {
            console.log("".concat(this.name, " attacks ").concat(target.name, "!"));
            var damage = this.stats.strength.current;
            target.stats.health.current -= damage;
            console.log("".concat(target.name, " takes ").concat(damage, " damage and has ").concat(target.stats.health.current, " health remaining."));
        }
    };
    return Enemy;
}());
exports.Enemy = Enemy;
//# sourceMappingURL=actor.js.map