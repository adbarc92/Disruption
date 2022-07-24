
const MAX = 10;
const MIN = 1;

/**
 * Entails all ability scores.
 * Includes vigor, strength, dexterity, resonance, and agility.
 */
export enum AbilityName {
  VIG = 'VIG',
  STR = 'STR',
  DEX = 'DEX',
  RES = 'RES',
  AGI = 'AGI',
};

/**
 * A set of all ability scores.
 */
export interface AbilityScoreSet {
  VIG: number,
  STR: number,
  DEX: number,
  RES: number,
  AGI: number,
};

export const makeAbilityScoreSet = (VIG: number, STR: number, DEX: number, RES: number, AGI: number): AbilityScoreSet => {
  return {
    VIG,
    STR,
    DEX,
    RES,
    AGI,
  }
};