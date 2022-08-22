import { Component } from 'src/core/component';

export const MAX = 10;
export const MIN = 1;

/**
 * A set of ability scores used to derive stats.
 */
export class AbilityScores extends Component {
  constructor(
    public vig: number,
    public str: number,
    public dex: number,
    public res: number,
    public agi: number,
  ) {
    super();
  }
}