import { Component } from 'src/core/component';

/**
 * The sprite displayed on-screen for an entity.
 */
export class Sprite extends Component {
  constructor(
    public x: number,
    public y: number,
    public height: number,
    public width: number,
    public img: HTMLCanvasElement | HTMLImageElement
  ) {
    super();
  }
};

