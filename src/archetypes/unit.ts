import { Transform } from 'src/components/transform';
import { Collision } from 'src/components/collision';

export type UnitArchetype = {
  transform: Transform[];
  collider: Collision[];
}