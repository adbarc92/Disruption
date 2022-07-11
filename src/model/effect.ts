import { BasicInfo } from 'src/model/basic-info';
import { StatusEffectName } from 'src/model/status-effect';

export enum FieldEffectTypes {
  HEALTH = 'HEALTH',
  STATUS = 'STATUS',
  COMBO = 'COMBO',
};

export enum BattleEffectTypes {
  HEALTH = 'HEALTH',
  STATUS = 'STATUS',
  COMBO = 'COMBO',
  POSITION = 'POSITION',
};

export interface FieldEffectModifier {
  healthModifier: number;
  statusModifier: StatusEffectName;
};

export interface BattleEffectModifier extends FieldEffectModifier {
  positionModifier: number;
};

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
