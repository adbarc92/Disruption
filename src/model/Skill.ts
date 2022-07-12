import { BasicInfo } from 'src/model/basic-info';
import { Animation } from 'src/model/animation';
import { Point2d } from 'src/model/space';
import { BattleEffect, FieldEffect } from 'src/model/effect';
import { Stat } from 'src/model/stats';
import { Family } from 'src/model/unit';

/**
 * The requisites for a skill to be enhanced by a partner.
 */
export interface PartnerRequirements {
  turnProximity: number;
  positionRange: Point2d;
  family: Family;
}

/**
 * The type of damage done by a skill.
 */
enum DamageType {
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
 * The stats determining the outcome of a skill usage.
 */
export interface OutcomeStats {
  user_health_stat: Stat,
  target_health_stat: Stat,
  user_status_stat: Stat,
  target_status_stat: Stat,
  user_accuracy_stat: Stat,
  target_accuracy_stat: Stat,
  user_position_stat: Stat,
  target_position_stat: Stat,
}

/**
 * A skill to be used in combat.
 */
export class Skill extends BasicInfo {
  usablePositions: Point2d[];
  targetPositions: Point2d[];
  battleEffects: BattleEffect[];
  fieldEffects: FieldEffect[];
  families: number[];
  actionCost: number;
  outcomeStats: OutcomeStats;
  sets: string[];
  equipCost: number;
  damageType: DamageType;
  animation: Animation;
  partnerRequirements?: PartnerRequirements;

  constructor(
    name: string,
    description: string,
    usablePositions: Point2d[],
    targetPositions: Point2d[],
    battleEffects: BattleEffect[],
    fieldEffects: FieldEffect[],
    families: number[],
    actionCost: number,
    outcomeStats: OutcomeStats,
    equipCost: number,
    damageType: DamageType,
    animation: Animation,
    partnerRequirements?: PartnerRequirements,
  ) {
    super(name, description)
    this.usablePositions = usablePositions;
    this.targetPositions = targetPositions;
    this.battleEffects = battleEffects;
    this.fieldEffects = fieldEffects;
    this.families = families;
    this.actionCost = actionCost;
    this.outcomeStats = outcomeStats;
    this.equipCost = equipCost;
    this.sets = [];
    this.damageType = damageType;
    this.animation = animation;
    this.partnerRequirements = partnerRequirements;
  }
}
