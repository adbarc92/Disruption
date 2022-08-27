import { Component } from 'src/core/component';

/**
 * Describes how an entity is moving.
 */
export class Motion extends Component {
  constructor(
    public velocity: [number, number],
    public acceleration: [number, number]
  ) {
    super();
  }
}