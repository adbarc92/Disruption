
interface Stat {
  base: number;
  current: number;
};

interface StatBlock {
  strength: Stat;
  vigor: Stat;
  dexterity: Stat;
  agility: Stat;
  resonance: Stat;
};

interface AbilityBlock {
  damage: Stat;
  critBonus: Stat;
  health: Stat;
  actions: Stat;
  critRate: Stat;
  accuracy: Stat;
  exousiaBonus: Stat;
  exousiaCapacity: Stat;
  initiative: Stat;
  evasion: Stat;
};

interface StatSet {
  stats: StatBlock;
  abilityScores: AbilityBlock;
};
