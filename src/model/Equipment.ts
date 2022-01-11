import { StatsDerived } from './Stats';
import { InventoryItem } from './Item';

const enum EquipSlot {
	'HELM'=0,
	'CHEST'=1,
	'GLOVES'=2,
	'PANTS'=3,
	'SHOES'=4,
	'NECKLACE'=5,
	'BRACELET'=6
}

export interface Equipment extends InventoryItem {
  stats: StatsDerived;
  defense: number;
	worn: boolean;
	enchanted: boolean;
	slot: EquipSlot;
}
