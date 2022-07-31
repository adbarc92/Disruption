import { Component } from 'src/core/component';

/**
 * Describes whether an entity should collide with
 * other entities.
 */
export class Collision extends Component {
  constructor(
    public collides: boolean
  ) {
    super();
  }
};

