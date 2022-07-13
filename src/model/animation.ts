import { Sound } from 'src/model/sound';
import { Sprite } from 'src/model/sprite';

const enum Animations {
  RUNNING,
  WALKING,
  STRIKING,
  CHARGING,
  CASTING,
  USING_ITEM,
  TAKING_DAMAGE,
  OPENING_CHEST,
  JUMPING,
}

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

/**
 * An animation to accompany an action or skill.
 */
export type BasicAnimationSet = {
  WALKING: Animation,
  RUNNING: Animation,
  STRIKING: Animation,
  CHARGING: Animation,
  DEFENDING: Animation,
  USING_ITEM: Animation,
};
