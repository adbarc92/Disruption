import { BasicInfo } from 'src/model/basic-info';
import { StatusEffectName } from 'src/model/status-effect';

/**
 * The collection of field effect types.
 */
export enum FieldEffectTypes {
  HEALTH = 'HEALTH',
  STATUS = 'STATUS',
  COMBO = 'COMBO',
};

/**
 * The collection of battle effect types.
 */
export enum BattleEffectTypes {
  HEALTH = 'HEALTH',
  STATUS = 'STATUS',
  COMBO = 'COMBO',
  POSITION = 'POSITION',
};

/**
 * The modifiers available to a field effect.
 */
export interface FieldEffectModifier {
  healthModifier: number;
  statusModifier: StatusEffectName;
};

/**
 * The modifiers available to a battle effect.
 */
export interface BattleEffectModifier extends FieldEffectModifier {
  positionModifier: number;
};

/**
 * @class the outcome of using an item or skill in the field.
 * @param type the type of field effect.
 * @param targetModifier the effect imparted onto the target.
 */
export class FieldEffect extends BasicInfo {
  type: FieldEffectTypes;
  targetModifier: FieldEffectModifier;

  constructor(
    name: string,
    description: string,
    type: FieldEffectTypes,
    targetModifier: FieldEffectModifier,
  ) {
    super(name, description)
    this.type = type;
    this.targetModifier = targetModifier;
  }
};

/**
 * @class the outcome of using an item or skill in combat.
 * @param type the type of field effect.
 * @param targetModifier the effect imparted onto the user.
 * @param targetModifier the effect imparted onto the target.
 */
export class BattleEffect extends BasicInfo {
  type: BattleEffectTypes;
  userModifier: BattleEffectModifier;
  targetModifier: BattleEffectModifier;

  constructor(
    name: string,
    description: string,
    type: BattleEffectTypes,
    userModifier: BattleEffectModifier,
    targetModifier: BattleEffectModifier,
    ) {
      super(name, description)
      this.type = type;
      this.userModifier = userModifier;
      this.targetModifier = targetModifier;
    }
};
