import { BasicAnimationSet } from 'src/model/animation';
import { Unit } from 'src/model/unit';
import { FieldAI } from 'src/model/ai';

/**
 * @class An agent traverses the field and may be accompanied by a party.
 * @param basicAnimations the set of standard animations.
 * @param party the set of units attached to an agent. Optional.
 * @param traversal_ai defines how an agent navigates the field.
 */
export class Agent {
  basicAnimations: BasicAnimationSet;
  extendedAnimations?: Animation[];
  party?: Unit[];
  traversal_ai?: FieldAI;

  constructor(
    basicAnimations: BasicAnimationSet,
    extendedAnimations?: Animation[],
    party?: Unit[],
    traversal_ai?: FieldAI,
  ) {
    this.basicAnimations = basicAnimations;
    this.extendedAnimations = extendedAnimations;
    this.party = party;
    this.traversal_ai = traversal_ai;
  }
}
