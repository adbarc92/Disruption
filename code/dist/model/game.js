"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Game = void 0;
var battle_1 = require("./battle");
var actor_1 = require("./actor");
var position_1 = require("./position");
var Game = /** @class */ (function () {
    function Game() {
        var player1Stats = {
            strength: { base: 10, current: 10 },
            vigor: { base: 10, current: 10 },
            dexterity: { base: 10, current: 10 },
            agility: { base: 12, current: 12 },
            resonance: { base: 10, current: 10 },
            health: { base: 100, current: 100 },
            mana: { base: 50, current: 50 },
        };
        var player1 = new actor_1.Player('p1', 'Hero', player1Stats, new position_1.Position(0, 0), []);
        var enemy1Stats = {
            strength: { base: 8, current: 8 },
            vigor: { base: 8, current: 8 },
            dexterity: { base: 8, current: 8 },
            agility: { base: 10, current: 10 },
            resonance: { base: 8, current: 8 },
            health: { base: 80, current: 80 },
            mana: { base: 0, current: 0 },
        };
        var enemy1 = new actor_1.Enemy('e1', 'Goblin', enemy1Stats, new position_1.Position(0, 0));
        this.battle = new battle_1.Battle([player1], [enemy1]);
    }
    Game.prototype.start = function () {
        console.log('Battle starts!');
        while (!this.battle.isOver()) {
            var activeAgent = this.battle.activeAgent;
            console.log("\n--- ".concat(activeAgent.name, "'s turn ---"));
            activeAgent.act(this.battle);
            this.battle.nextTurn();
        }
        if (this.battle.players.some(function (p) { return p.stats.health.current > 0; })) {
            console.log('\n--- Victory! ---');
        }
        else {
            console.log('\n--- Defeat! ---');
        }
    };
    return Game;
}());
exports.Game = Game;
//# sourceMappingURL=game.js.map