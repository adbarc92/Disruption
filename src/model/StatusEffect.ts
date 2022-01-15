enum StatusEffectCategory {
  DOT = 'DAMAGE_OVER_TIME',
  DEBUFF = 'DEBUFF',
  BUFF = 'BUFF',
  ACTION_INHIBITING = 'ACTION_INHIBITING'
}

const enum StatusEffectName {
  // DOT
  POISONED = 'POISONED',
  BURNING = 'BURNING',
  DISRUPTED = 'DISRUPTED',

  // Turn Inhibiting
  PARALYZED = 'PARALYZED',
  STUNNED = 'STUNNED',
  UNCONSCIOUS = 'UNCONSCIOUS',
  DEAD = 'DEAD',
  RESTRAINED = 'RESTRAINED',
  PETRIFIED = 'PETRIFIED',

  // Control Inhibiting
  CHILLED = 'CHILLED',
  CONFUSED = 'CONFUSED',
  EXHAUSTED = 'EXHAUSTED', // Slow
  BLINDED = 'BLINDED',
  CHARMED = 'CHARMED',
  FRIGHTENED = 'FRIGHTENED',
  SILENCED = 'SILENCED',

  // Beneficial
  APOTHEOSIS = 'APOTHEOSIS',
  DESYNCHED = 'DESYNCHED', // Euphen
  QUICKENED = 'QUICKENED', // Haste
  INVISIBLE = 'INVISIBLE',
  IMMUNITY = 'IMMUNITY',

  // Stat Modifying
  STRENGTHENED = 'STRENGTHENED', // Buffed
  WEAKENED = 'WEAKENED', // Debuffed
}

export interface StatusEffect {
  id: number;
  name: StatusEffectName;
  duration: number;
  category: StatusEffectCategory;
}

export interface Debuff extends StatusEffect {
  category: StatusEffectCategory.DEBUFF;
  degree: number;
}
