import { Sound } from 'src/model/sound';
import { Sprite } from 'src/model/sprite';

/**
 * An animation to accompany an action or skill.
 */
export class Animation {
  sprites: Sprite[];
  duration: number[];
  sounds: Sound[];

  constructor(sprites: Sprite[], duration: number[], sounds: Sound[]) {
    this.sprites = sprites;
    this.duration = duration;
    this.sounds = sounds;
  }
}
