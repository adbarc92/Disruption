import { Component } from 'src/core/component';

/**
 * The entity has a position in the world.
 */
export class Transform extends Component {
  constructor(public x: number, public y: number) {
    super();
  }
}
