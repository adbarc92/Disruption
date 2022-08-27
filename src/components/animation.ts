import { Component } from 'src/core/component';
import { Sprite } from 'src/components/sprite';

const enum Animations {
  STUNNED = 'stunned',
}

/**
 * Prescribes the series of sprites necessary
 * to accompany an action.
 */
export class Animation extends Component {
  constructor(
    public collides: boolean,
    public sprites: Sprite[],
    public spriteDurations: number[],
  ) {
    super();
  }
};

