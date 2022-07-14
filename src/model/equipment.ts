import { BasicInfo } from 'src/model/basic-info';
import { Stats } from 'src/model/stats';
import { Family } from 'src/model/unit';

/**
 * The slots of equipment.
 */
const enum Slot {
	HELM = 'HELM',
	CHEST = 'CHEST',
	GLOVES = 'GLOVES',
	GREAVES = 'GREAVES',
	BOOTS = 'BOOTS',
	ACCESSORY = 'ACCESSORY',
}

/**
 * @class the equipment of a unit.
 * @param families the families to which the equipment is available.
 * @param slot the slot to which an equipment would be assigned.
 * @param worn whether or not the equipment is worn.
 * @param stats the stat changes of a piece of equipment.
 */
export class Equipment extends BasicInfo {
  families: Family[];
  slot: Slot;
  worn: boolean;
  stats: Stats;

  constructor(
    name: string,
    description: string,
    families: Family[],
    slot: Slot,
    vitality: number,
    defense: number,
    resistance: number,
    amplification: number,
    damage: number,
    critDamage: number,
    critRate: number,
    accuracy: number,
    initiative: number,
    evasion: number,
  ) {
    super(name, description)
    this.families = families;
    this.slot = slot;
    this.worn = false;
    this.stats = new Stats(
      {
        vitality,
        defense,
        resistance,
        amplification,
        damage,
        critDamage,
        critRate,
        accuracy,
        initiative,
        evasion,
      }
    )
  }
};
