import { AbilityScores } from 'src/components/ability-scores';
import { Component } from 'src/core/component';
import { BattleAI } from 'src/legacy/model/ai';
import { Stats } from 'src/legacy/model/stats';
import { Equipment } from 'src/components/equipment';

/**
 * The category of a unit. This is used for damage-effectiveness.
 */
export const enum Category {
  HUMANOID = "humanoid",
  BESTIAL = "bestial",
  INSECT = "insect",
  FLIER = "flier"
}

/**
 * The family of a unit. Used for assigning skills and equipment.
 */
export const enum FamilyName {
  STRIKER = 'STRIKER',
  BREAKER = 'BREAKER',
  HEALER = 'HEALER',
  LANCER = 'LANCER',
  ENTROPIST = 'ENTROPIST',
  STUNNER = 'STUNNER',
  MOVER = 'MOVER',
  GUARDIAN = 'GUARDIAN',
}

/**
 * The type of damage done by a skill.
 */
export const enum DamageType {
  FLAME = 'FLAME',
  RAIN = 'RAIN',
  WIND = 'WIND',
  STONE = 'STONE',
  LIGHTNING = 'LIGHTNING',
  PIERCING = 'PIERCING',
  BLUDGEONING = 'BLUDGEONING',
  HOLY = 'HOLY',
  ENTROPIC = 'ENTROPIC',
}

/**
 * The family of a unit determines its weaknesses
 * and resistances as well as which skills and
 * equipment it can use.
 */
export interface Family {
  name: FamilyName,
  resistances: DamageType[];
  weaknesses: DamageType[];
}

/**
 * A unit acts in combat.
 */
export class Unit extends Component {
  constructor(
    public category: Category,
    public family: Family,
    public stats: Stats,
    public equipment: Equipment[] | null,
    public abilityScores: AbilityScores,
    public challengeRating: number | null,
    public ai?: BattleAI,
  ){
    super();
  }
};
