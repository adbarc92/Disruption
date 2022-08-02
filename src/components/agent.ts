import { Component } from 'src/core/component';
import { Unit } from 'src/components/unit';

/**
 * Agents populate the field.
 * Interacting with them may or may
 * not initiate a battle.
 */
export class Agent extends Component {
  constructor(
    public animations: Animation[],
    public party?: Unit[],
    public traversalAi?: unknown
  ) {
    super();
  }
};