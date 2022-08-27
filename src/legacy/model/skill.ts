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
 * @class A skill to be used in combat.
 * @param usablePositions the positions from which the skill can be used.
 * @param targetPositions the positions targetable by the skill.
 * @param battleEffects consequences associated with use of the skill in combat.
 * @param fieldEffects consequences associated with use of the skill in the field.
 * @param families the groups to which the skill is available.
 * @param actionCost the cost of using the skill.
 * @param outcomeStats the stats on which the skill outcome is dependent.
 * @param sets the custom sets to which players have assigned the skill.
 * @param equipCost the cost of equipping the skill.
 * @param damageType the damage type associated with the skill.
 * @param animation the animation associated with the position.
 * @param partnerRequirements the requirements of teammates to enhance the skill.
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
