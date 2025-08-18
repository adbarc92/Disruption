import { Agent, Player, Enemy } from './actor';

export class Battle {
    players: Player[];
    enemies: Enemy[];
    turnOrder: Agent[] = [];
    turn: number = 0;

    constructor(players: Player[], enemies: Enemy[]) {
        this.players = players;
        this.enemies = enemies;
        this.setup();
    }

    private setup(): void {
        this.turnOrder = [...this.players, ...this.enemies].sort((a, b) => b.initiative - a.initiative);
    }

    isOver(): boolean {
        return this.players.every(p => p.stats.health.current <= 0) || this.enemies.every(e => e.stats.health.current <= 0);
    }

    get activeAgent(): Agent {
        return this.turnOrder[this.turn % this.turnOrder.length];
    }

    nextTurn(): void {
        this.turn++;
    }
}