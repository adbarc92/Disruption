import { Point } from './Space';

export interface Item {
  name: string;
  id: number;
  description: string;
}

export interface WorldItem extends Item {
  areaId: number;
  position: Point;
}

export interface InventoryItem extends WorldItem {
	quantity: number;
	tooltip: string;
}

export interface FieldItem extends InventoryItem {
	use: () => void;
}
