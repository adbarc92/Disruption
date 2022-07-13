
/**
 * The collection of field AI.
 */
const enum FieldDirective {
  AGGRESSIVE,
  PASSIVE,
  NEUTRAL,
  FLANKING,
}

/**
 * Defines how an agent traverses the field.
 */
export class FieldAI {
  fieldDirective: FieldDirective;

  constructor(fieldDirective: FieldDirective) {
    this.fieldDirective = fieldDirective;
  }
}

/**
 * Defines how a unit comports itself in combat.
 */
export class BattleAI {

}
