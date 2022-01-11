import { StatsCore, StatsDerived } from './Stats';

export interface Character {
  id: number;
	name: string;
	coreStats: StatsCore;
	derivedStats: StatsDerived;
	tempStats: StatsDerived;
}
