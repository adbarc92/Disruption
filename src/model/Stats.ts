
export interface StatsCore {
	constitution: number;
	strength: number;
	dexterity: number;
	resonance: number;
	agility: number;
}

export interface StatsDerived {
	hitPoints: number;
	exousiaPoints: number;
	physicalDamage: number;
	critDamage: number;
	critRate: number;
	accuracy: number;
	exousiaDefense: number;
	exousiaRecovery: number;
	initiative: number;
	evasion: number;
}
