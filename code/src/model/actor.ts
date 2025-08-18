import { StatBlock } from './stat';
import { Position } from './position';
import { Skill } from './skill';

export interface Agent {
    id: string;
    name: string;
    stats: StatBlock;
    position: Position;
    isPlayer: boolean;
    get initiative(): number;
    act(battle: Battle): void;
}

export class Player implements Agent {
    id: string;
    name: string;
    stats: StatBlock;
    position: Position;
    skills: Skill[];
    isPlayer: true = true;

    constructor(id: string, name: string, stats: StatBlock, position: Position, skills: Skill[]) {
        this.id = id;
        this.name = name;
        this.stats = stats;
        this.position = position;
        this.skills = skills;
    }

    get initiative(): number {
        return this.stats.agility.current;
    }

    act(battle: Battle): void {
        // For now, players will just attack the first enemy
        const target = battle.enemies[0];
        if (target) {
            console.log(`${this.name} attacks ${target.name}!`);
            const damage = this.stats.strength.current;
            target.stats.health.current -= damage;
            console.log(`${target.name} takes ${damage} damage and has ${target.stats.health.current} health remaining.`);
        }
    }
}

export class Enemy implements Agent {
    id: string;
    name: string;
    stats: StatBlock;
    position: Position;
    isPlayer: false = false;

    constructor(id: string, name: string, stats: StatBlock, position: Position) {
        this.id = id;
        this.name = name;
        this.stats = stats;
        this.position = position;
    }

    get initiative(): number {
        return this.stats.agility.current;
    }

    act(battle: Battle): void {
        // For now, enemies will just attack the first player
        const target = battle.players[0];
        if (target) {
            console.log(`${this.name} attacks ${target.name}!`);
            const damage = this.stats.strength.current;
            target.stats.health.current -= damage;
            console.log(`${target.name} takes ${damage} damage and has ${target.stats.health.current} health remaining.`);
        }
    }
}

// Forward declaration of Battle to avoid circular dependency
import { Battle } from './battle';