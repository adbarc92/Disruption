
export interface Drop {
  // Item
  // Money
  // Experience
}

/**
 *
 */
export interface Combatant {
  // sprite body - a set of combat sprites and animations for various states (striking, blocking, etc.)
  // Traversal Counterpart: Character or Monster
  // Faction of which they are part (used to check for victory conditions)
  // Command[]
  // Drops?: Drop[]
}

/** */
export interface TurnTaken {
  // acting combatant
  // command used and execution details
  // targets: points or other combatants
  // outcome
}

/**
 * @input combantants: Combatant[]
*/
export interface Battle {
  id: number;
  // combatant
  // friendly party
}

export interface CompletedBattle extends Battle {
  turnHistory: TurnTaken[];
}

/** */
export interface Roamer {
  id: number;
  // Sprite information
  // AI traversal should also be contained here
}

export interface Encounter {
  battle: Battle;
  roamer: Roamer;
}