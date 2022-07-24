import { StatSet } from 'src/components/stats'

const enum EquipmentSlot {
  HELM = 'HELM',
  CHEST = 'CHEST',
  GLOVES = 'GLOVES',
  GREAVES = 'GREAVES',
  BOOTS = 'BOOTS',
  ACCESSORY = 'ACCESSORY',
}

interface EquipmentType {
  name: string;
  slot: EquipmentSlot;
  statBonuses: StatSet;
}

export const makeEquipment = (name: string, slot: EquipmentSlot, statBonuses: StatSet): EquipmentType => {
  return {
    name,
    slot,
    statBonuses,
  }
};
