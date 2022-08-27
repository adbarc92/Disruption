import { Component } from 'src/core/component';
import { Entity } from 'src/core/entity';

/**
 * Describes whether an entity should follow another entity.
 */
export class Follow extends Component {
  constructor(
    public follows: boolean,
    public leader: Entity,
  ) {
    super();
  }
};

