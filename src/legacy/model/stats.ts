import { AbilityScores } from 'src/model/ability-score';

/**
 * A collection of unit stats.
 */
export const enum Stat {
  VITALITY = 'VITALITY',
  DEFENSE = 'DEFENSE',
  RESISTANCE = 'RESISTANCE',
  AMPLIFICATION = 'AMPLIFICATION',
  DAMAGE = 'DAMAGE',
  CRIT_DAMAGE = 'CRIT_DAMAGE',
  CRIT_RATE = 'CRIT_RATE',
  ACCURACY = 'ACCURACY',
  INITIATIVE = 'INITIATIVE',
  EVASION = 'EVASION',
}

/**
 * A complete set of unit stats.
 */
export interface StatSet {
  vitality: number;
  defense: number;
  resistance: number;
  amplification: number;
  damage: number;
  critDamage: number;
  critRate: number;
  accuracy: number;
  initiative: number;
  evasion: number;
}

/**
 * @class the stats for a unit and equipment as well as associated utilities for management.
 * @param baseStats a unit's normal stats.
 * @param currentStats a unit's stats after adjustment for status effects.
 */
export class Stats {
  baseStats: StatSet;
  currentStats: StatSet;

  constructor(stats: StatSet) {
    this.currentStats = {
      vitality: stats.vitality,
      defense: stats.defense,
      resistance: stats.resistance,
      amplification: stats.amplification,
      damage: stats.damage,
      critDamage: stats.critDamage,
      critRate: stats.critRate,
      accuracy: stats.accuracy,
      initiative: stats.initiative,
      evasion: stats.evasion,
    }
    this.baseStats = this.currentStats;
  }

  /**
   * @constructor an alternate constructor to be used when creating units.
   */
  static fromAbilityScores(abilityScores: AbilityScores): Stats {
    const { VIG, STR, DEX, RES, AGI } = abilityScores.baseScores;
    return new this(
      {
        vitality: VIG*5,
        defense: VIG*2,
        resistance: RES*5,
        amplification: RES*2,
        damage: STR*2,
        critDamage: STR*0.5,
        critRate: DEX*0.5,
        accuracy: DEX*10,
        initiative: AGI*3,
        evasion: AGI*2,
      }
    )
  }
}
