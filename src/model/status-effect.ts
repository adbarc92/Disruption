import { BasicInfo } from 'src/model/basic-info';
import { BattleEffectModifier, FieldEffectModifier } from 'src/model/effect';

export const enum StatusEffectName {
  /* Health */
  REGENERATING = 'regenerating',
  POISONED = 'poisoned',
  BURNING = 'burning',
  /* Beneficial */
  STRENGTHENED = 'strengthened',
  ENERGIZED = 'energized',
  INVISIBLE = 'invisible',
  IMMUNE = 'immune',
  /* Detrimental */
  WEAKENED = 'weakened',
  DISRUPTED = 'disrupted',
  /* Control */
  PARALYZED = 'paralyzed',
  STUNNED = 'stunned',
  UNCONSCIOUS = 'unconscious',
  DEAD = 'dead',
  RESTRAINED = 'restrained',
  PETRIFIED = 'petrified',
  CHILLED = 'chilled',
  CONFUSED = 'confused',
  EXHAUSTED = 'exhausted',
  BLINDED = 'blinded',
  CHARMED = 'charmed',
  FRIGHTENED = 'frightened',
  SILENCED = 'silenced',
  /* Unique */
  APOTHEOSIS = 'apotheosis',
  UNRAVELING = 'unraveling',
  QUICKENED = 'quickened',
}

export const enum StatusEffectType {
  HEALTH = 'HEALTH',
  BENEFICIAL = 'BENEFICIAL',
  DETRIMENTAL = 'DETRIMENTAL',
  CONTROL = 'CONTROL',
  UNIQUE = 'UNIQUE',
}

/**
 * The time during which a status effect activates.
 */
export const enum ActivationTime {
  PRE_TURN = 'pre-turn',
  POST_TURN = 'post-turn',
}

/**
 * A class for the creation and management of status effects.
 */
export class StatusEffect extends BasicInfo {
  type: StatusEffectType;
  activationTime: ActivationTime;
  battleEffect: BattleEffectModifier;
  fieldEffect: FieldEffectModifier;
  degree: number;
  priority: number;
  duration: number;

  constructor(
    name: StatusEffectName,
    description: string,
    type: StatusEffectType,
    activationTime: ActivationTime,
    battleEffect: BattleEffectModifier,
    fieldEffect: FieldEffectModifier,
    degree: number,
    priority: number,
    duration: number,
  ) {
    super(name, description)
    this.type = type;
    this.activationTime = activationTime;
    this.battleEffect = battleEffect;
    this.fieldEffect = fieldEffect;
    this.degree = degree;
    this.priority = priority;
    this.duration = duration;
  }
};