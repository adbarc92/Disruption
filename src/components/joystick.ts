import { Component } from 'src/core/component';

/**
 * Describes whether an entity should respond to arrow key inputs.
 */
export class Joystick extends Component {
  constructor(
    public joystick: boolean,
  ) {
    super();
  }
};

