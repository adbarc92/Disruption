import { System } from 'src/core/system';
import { Entity } from 'src/core/entity';
import { Transform } from 'src/components/transform';

export class Locator extends System {
  componentsRequired = new Set<Function>([Transform])
  update(entities: Set<Entity>): void { super(); }
};