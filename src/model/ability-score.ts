
const MAX = 10;
const MIN = 1;

/**
 * Entails all ability scores.
 * Includes vigor, strength, dexterity, resonance, and agility.
 */
export enum Ability {
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

/**
 * Describes the ability scores belonging to a unit or piece of equipment.
 * Includes both the current ability scores and their base values for ease of reset.
 */
export class AbilityScores {
  currentScores: AbilityScoreSet;
  baseScores: AbilityScoreSet;

  constructor(VIG: number, STR: number, DEX: number, RES: number, AGI: number) {
    this.currentScores = {
      VIG,
      STR,
      DEX,
      RES,
      AGI
    }
    this.baseScores = this.currentScores;
  }

  /**
   * Decrease an ability score.
   * @param ability specifies the ability score to be altered.
   * @param decrease specifies the degree of change to be applied to the ability score.
  */
  decreaseScore(ability: Ability, decrease: number) {
    const newValue = this.currentScores[ability] -= decrease;
    this.currentScores[ability] -= newValue < MIN ? MIN : newValue;
  }

  /**
   * Decrease an ability score.
   * @param ability specifies the ability score to be altered.
   * @param decrease specifies the degree of change to be applied to the ability score.
   */
  increaseScore(ability: Ability, increase: number) {
    const newValue = this.currentScores[ability] += increase;
    this.currentScores[ability] += newValue < MAX ? MAX : newValue;
  }

  /**
   * Reset all ability scores to their base values.
   */
  resetScores() {
    this.currentScores = this.baseScores;
  }
}
