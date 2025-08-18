import { Battle } from './battle';
import { Player, Enemy } from './actor';
import { Position } from './position';
import { StatBlock } from './stat';

export class Game {
    battle: Battle;

    constructor() {
        const player1Stats: StatBlock = {
            strength: { base: 10, current: 10 },
            vigor: { base: 10, current: 10 },
            dexterity: { base: 10, current: 10 },
            agility: { base: 12, current: 12 },
            resonance: { base: 10, current: 10 },
            health: { base: 100, current: 100 },
            mana: { base: 50, current: 50 },
        };
        const player1 = new Player('p1', 'Hero', player1Stats, new Position(0, 0), []);

        const enemy1Stats: StatBlock = {
            strength: { base: 8, current: 8 },
            vigor: { base: 8, current: 8 },
            dexterity: { base: 8, current: 8 },
            agility: { base: 10, current: 10 },
            resonance: { base: 8, current: 8 },
            health: { base: 80, current: 80 },
            mana: { base: 0, current: 0 },
        };
        const enemy1 = new Enemy('e1', 'Goblin', enemy1Stats, new Position(0, 0));

        this.battle = new Battle([player1], [enemy1]);
    }

    start(): void {
        console.log('Battle starts!');
        while (!this.battle.isOver()) {
            const activeAgent = this.battle.activeAgent;
            console.log(`\n--- ${activeAgent.name}'s turn ---`);
            activeAgent.act(this.battle);
            this.battle.nextTurn();
        }

        if (this.battle.players.some(p => p.stats.health.current > 0)) {
            console.log('\n--- Victory! ---');
        } else {
            console.log('\n--- Defeat! ---');
        }
    }
}
