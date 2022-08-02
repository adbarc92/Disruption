import { Component } from 'src/core/component';
import { StatSet } from 'src/components/stats'

/**
 * The type of equipment
 */
const enum EquipmentSlot {
  HELM = 'HELM',
  CHEST = 'CHEST',
  GLOVES = 'GLOVES',
  GREAVES = 'GREAVES',
  BOOTS = 'BOOTS',
  ACCESSORY = 'ACCESSORY',
}

/**
 * Equipment serves to boost a unit's stats.
 */
export class Equipment extends Component {
  constructor(
    public name: string,
    public slot: EquipmentSlot,
    public statBonuses: StatSet,
  ){
    super();
  }
};
