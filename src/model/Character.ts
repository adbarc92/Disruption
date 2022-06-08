import { StatsCore, StatsDerived } from './Stats';

export enum CharacterCategory {
	HUMANOID = "humanoid",
	BESTIAL = "bestial",
	INSECT = "insect",
	FLIER = "flier"
}

export enum CharacterSize {
  SMALL = '1x1',
  MEDIUM = '1x2',
  LARGE = '2x2',
  MASSIVE = '2x3',
  GARGANTUAN = '3x3'
}

export interface Character {
  id: number;
	name: string;
	coreStats: StatsCore;
	derivedStats: StatsDerived;
	tempStats: StatsDerived;
	category: CharacterCategory;
}

export interface Enemy extends Character {
	challengeRating: number;
}

export interface PartyMember extends Character {}
