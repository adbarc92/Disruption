import { Transform } from 'src/components/transform';
import { Collision } from 'src/components/collision';

export type FighterArchetype = {
  transform: Transform[];
  collider: Collision[];
}