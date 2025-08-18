export interface Stat {
    base: number;
    current: number;
};

export interface StatBlock {
    strength: Stat;
    vigor: Stat;
    dexterity: Stat;
    agility: Stat;
    resonance: Stat;
    health: Stat;
    mana: Stat;
};