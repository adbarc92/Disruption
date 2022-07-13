import { BasicInfo } from 'src/model/basic-info';
import { AbilityScores } from 'src/model/ability-score';
import { Stats } from 'src/model/stats';
import { Equipment } from 'src/model/equipment';
import { BattleAI } from 'src/model/ai';

/**
 * The category of a unit. This is used for damage-effectiveness.
 */
export enum Category {
	HUMANOID = "humanoid",
	BESTIAL = "bestial",
	INSECT = "insect",
	FLIER = "flier"
}

/**
 * The family of a unit. Used for assigning skills and equipment.
 */
export enum Family {
  STRIKER = 'STRIKER',
  BREAKER = 'BREAKER',
  HEALER = 'HEALER',
  LANCER = 'LANCER',
  ENTROPIST = 'ENTROPIST',
  STUNNER = 'STUNNER',
  MOVER = 'MOVER',
}

/**
 * @class A combat unit.
 * Accounts for all basic information needed for combat calculations.
 * Starts with no equipment.
 * @param category determines strengths and weaknesses.
 * @param family determines skills and equipment.
 * @param equipment adds to the stats of a unit.
 * @param VIG the vigor of a unit.
 * @param STR the strength of a unit.
 * @param DEX the dexterity of a unit.
 * @param RES the resonance of a unit.
 * @param AGI the agility of a unit.
 * @param challengeRating used for encounter construction.
 * @param ai determines the way a unit acts during combat.
 */
export class Unit extends BasicInfo {
  category: Category;
  family: Family;
  unitStats: Stats;
  equipment: Equipment[] | null;
  abilityScores: AbilityScores;
  challengeRating: number | null;
  ai?: BattleAI;

  /** @constructor
   *
   */
  constructor(
    name: string,
    description: string,
    category: Category,
    family: Family,
    VIG: number,
    STR: number,
    DEX: number,
    RES: number,
    AGI: number,
    challengeRating?: number,
    ai?: BattleAI,
  ) {
    super(name, description)
    this.category = category;
    this.family = family;
    this.equipment = null;
    this.abilityScores = new AbilityScores(VIG, STR, DEX, RES, AGI);
    this.unitStats = Stats.fromAbilityScores(this.abilityScores);
    this.challengeRating = challengeRating || 0;
    this.ai = ai;
  }
}
