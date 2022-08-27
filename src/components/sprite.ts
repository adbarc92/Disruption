import { Component } from 'src/core/component';

export interface SpriteType {
  x: number,
  y: number,
  height: number,
  width: number,
  img: HTMLCanvasElement
};

/**
 * The sprite displayed on-screen for an entity.
 */
export class Sprite extends Component {
  constructor(
    public sprite: SpriteType
  ) {
    super();
  }
};

