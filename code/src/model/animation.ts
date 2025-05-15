import { Sound } from 'src/model/sound';
import { Sprite } from 'src/model/sprite';

/**
 * The collection of basic animations shared by all agents.
 */
export const enum BasicAnimations {
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
 * @class An animation to accompany an action or skill.
 * @param sprites the series of images to be displayed.
 * @param spriteDuration the length of time over which each sprite is displayed.
 * @param sounds the sounds to be played.
 * @param soundDuration the length of time over which each sound is played.
 */
export class Animation {
  sprites: Sprite[];
  spriteDuration: number[];
  sounds: Sound[];
  soundDuration: number[];

  constructor(
    sprites: Sprite[],
    spriteDuration: number[],
    sounds: Sound[],
    soundDuration: number[]
  ) {
    this.sprites = sprites;
    this.spriteDuration = spriteDuration;
    this.sounds = sounds;
    this.soundDuration = soundDuration;
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
