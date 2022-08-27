import { BasicInfo } from 'src/model/basic-info';
import { BattleEffectModifier, FieldEffectModifier } from 'src/model/effect';

/**
 * A collection of all status effect names.
 */
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

/**
 * A collection of all status effect types.
 */
export const enum StatusEffectType {
  HEALTH = 'HEALTH',
  BENEFICIAL = 'BENEFICIAL',
  DETRIMENTAL = 'DETRIMENTAL',
  CONTROL = 'CONTROL',
  UNIQUE = 'UNIQUE',
}

/**
 * The time during which a status effect activates.
 * TODO ROUNDS?
 */
export const enum ActivationTime {
  COMBAT_START = 'combat-start',
  COMBAT_END = 'combat-end',
  PRE_TURN = 'pre-turn',
  POST_TURN = 'post-turn',
}

/**
 * @class for creation and management of status effects.
 * @param type self-explanatory.
 * @param activationTime when the status effect activates.
 * @param battleEffect the consequence of the status in battle.
 * @param fieldEffect the consequence of the status in the field.
 * @param degree the multiplier for the effect.
 * @param priority the order in which status effects are activated.
 * @param duration the time until the status effect expires.
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