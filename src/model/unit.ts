import { BasicInfo } from 'src/model/basic-info';
import { AbilityScores } from 'src/model/ability-score';
import { Stats } from 'src/model/stats';
import { Equipment } from 'src/model/equipment';

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
 * A combat unit.
 * Accounts for all basic information needed for combat calculations.
 * Starts with no equipment.
 */
export class Unit extends BasicInfo {
  category: Category;
  family: Family;
  equipment: Equipment[] | null;
  abilityScores: AbilityScores;
  unitStats: Stats;
  challengeRating: number | null;

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
  ) {
    super(name, description)
    this.category = category;
    this.family = family;
    this.equipment = null;
    this.abilityScores = new AbilityScores(VIG, STR, DEX, RES, AGI);
    this.unitStats = Stats.fromAbilityScores(this.abilityScores);
    this.challengeRating = challengeRating || 0;
  }
}
