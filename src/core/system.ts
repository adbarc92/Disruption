import { Entity } from 'src/core/entity';
import { ECS } from 'src/core/ecs';

export abstract class System {
    public abstract componentsRequired: Set<Function>;
    public abstract update(entities: Set<Entity>): void

    /**
     * The ECS is given to all Systems. Systems contain most of the game
     * code, so they need to be able to create, mutate, and destroy
     * Entities and Components.
     */
    public ecs: ECS;

    constructor(ecs: ECS) {
      this.ecs = ecs;
    }
}