/**
 * Different creatures have different strengths and weaknesses.
 */
enum DamageType {
	fire = 'FIRE',
	water = 'WATER',
	air = 'AIR',
	metal = 'METAL',
	wood = 'WOOD',
	piercing = 'PIERCING',
	blunt = 'BLUNT',
	divine = 'DIVINE',
	cursed = 'CURSED'
}

/**
 * The type of unit that owns the skill.
 */
export interface OwnerCategory {
	name: string;
	friendly: boolean;
}

/**
 * Meta-data associated with the skill.
 */
export interface SkillMeta {
	animDuration: number;
	// sound loop
	// anim loop
}

/**
 * A technique to be used in combat.
 */
export interface Skill {
	name: string;
	id: number;
	ownerCategory: OwnerCategory;
	use: () => void;
	metaData: SkillMeta;
	damageType: DamageType;
}
