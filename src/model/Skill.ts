import { BasicInfo } from 'src/model/basic-info';
import { Position } from 'src/model/position';
import { BattleEffect, FieldEffect } from 'src/model/effect';
import { Stat } from 'src/model/stats';

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
  usablePositions: Position[];
  targetPositions: Position[];
  battleEffects: BattleEffect[];
  fieldEffects: FieldEffect[];
  families: number[];
  actionCost: number;
  outcomeStats: OutcomeStats;
  // animation
  // partner requirements

  constructor(
    name: string,
    description: string,
    usablePositions: Position[],
    targetPositions: Position[],
    battleEffects: BattleEffect[],
    fieldEffects: FieldEffect[],
    families: number[],
    actionCost: number,
    outcomeStats: OutcomeStats,
  ) {
    super(name, description)
    this.usablePositions = usablePositions;
    this.targetPositions = targetPositions;
    this.battleEffects = battleEffects;
    this.fieldEffects = fieldEffects;
    this.families = families;
    this.actionCost = actionCost;
    this.outcomeStats = outcomeStats;
  }
}
