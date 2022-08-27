
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
 * @class Defines how an agent traverses the field.
 * @param fieldDirective determines how an agent navigates the field.
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
