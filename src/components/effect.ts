import { Component } from 'src/core/component';

/**
 * The consequence of using an item or skill.
 */
export class Effect extends Component {
  constructor(
    public name: string,
    public effect: Function
  ) {
    super();
  }
};
