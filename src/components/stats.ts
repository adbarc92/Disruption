import { Component } from 'src/core/component';
import { AbilityScores } from 'src/components/ability-scores'
/**
 * A collection of unit stats.
 */
export const enum StatName {
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

interface Stat {
  name: StatName;
  value: number;
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

export const makeStat = (name: StatName, value: number): Stat => {
  return {
    name,
    value,
  }
}

export const makeStatSet = (abilityScores: AbilityScoreSet): StatSet => {
  const { VIG, STR, DEX, RES, AGI } = abilityScores;
  return {
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
};

export class StatSet extends Component {
  constructor(
    public vitality: number,
    public defense: number,
    public resistance: number,
    public amplification: number,
    public damage: number,
    public critDamage: number,
    public critRate: number,
    public accuracy: number,
    public initiative: number,
    public evasion: number,
  ) {
    super();
  }
};

