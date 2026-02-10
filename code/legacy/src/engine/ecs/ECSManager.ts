/**
 * Entity-Component-System (ECS) Architecture
 * Provides a flexible, performant system for game object management
 */

import type { GameSystem } from '../core/GameEngine';

// Unique identifier type for entities
export type EntityId = string & { __brand: 'EntityId' };

// Component type identifier
export type ComponentType = string & { __brand: 'ComponentType' };

/**
 * Base interface for all components
 */
export interface Component {
  readonly type: ComponentType;
  entityId: EntityId;
}

/**
 * Base interface for all systems
 */
export interface ECSSystem {
  readonly name: string;
  readonly requiredComponents: ComponentType[];
  readonly priority: number;
  
  initialize?(): Promise<void>;
  update(deltaTime: number, entities: EntityId[]): void;
  cleanup?(): void;
  
  // Optional system lifecycle hooks
  onEntityAdded?(entityId: EntityId): void;
  onEntityRemoved?(entityId: EntityId): void;
  onComponentAdded?(entityId: EntityId, component: Component): void;
  onComponentRemoved?(entityId: EntityId, componentType: ComponentType): void;
}

/**
 * Entity data structure
 */
export interface Entity {
  id: EntityId;
  name: string;
  active: boolean;
  components: Set<ComponentType>;
  tags: Set<string>;
  parent?: EntityId;
  children: Set<EntityId>;
}

/**
 * Query for finding entities with specific components
 */
export interface EntityQuery {
  all?: ComponentType[];
  any?: ComponentType[];
  none?: ComponentType[];
  tags?: string[];
}

/**
 * ECS Manager - Core system that manages entities, components, and systems
 */
export class ECSManager implements GameSystem {
  readonly name = 'ECSManager';

  // Core data structures
  private entities: Map<EntityId, Entity> = new Map();
  private components: Map<ComponentType, Map<EntityId, Component>> = new Map();
  private systems: Map<string, ECSSystem> = new Map();
  
  // Performance optimization caches
  private systemEntityCache: Map<string, EntityId[]> = new Map();
  private queryCache: Map<string, EntityId[]> = new Map();
  private cacheVersion: number = 0;
  
  // Entity creation counter
  private entityCounter: number = 0;

  async initialize(): Promise<void> {
    // Initialize all registered systems
    for (const [name, system] of this.systems) {
      if (system.initialize) {
        await system.initialize();
      }
      console.log(`ECSManager: Initialized system '${name}'`);
    }

    console.log('ECSManager: Initialized');
  }

  update(deltaTime: number): void {
    // Update all systems in priority order
    const sortedSystems = Array.from(this.systems.values())
      .sort((a, b) => a.priority - b.priority);

    for (const system of sortedSystems) {
      const entities = this.getEntitiesForSystem(system);
      system.update(deltaTime, entities);
    }
  }

  cleanup(): void {
    // Cleanup all systems
    for (const [name, system] of this.systems) {
      if (system.cleanup) {
        system.cleanup();
      }
    }

    // Clear all data
    this.entities.clear();
    this.components.clear();
    this.systems.clear();
    this.systemEntityCache.clear();
    this.queryCache.clear();
  }

  // Entity management
  
  /**
   * Create a new entity
   */
  createEntity(name?: string): EntityId {
    const id = `entity_${++this.entityCounter}` as EntityId;
    
    const entity: Entity = {
      id,
      name: name || `Entity_${this.entityCounter}`,
      active: true,
      components: new Set(),
      tags: new Set(),
      children: new Set()
    };

    this.entities.set(id, entity);
    this.invalidateCache();

    return id;
  }

  /**
   * Destroy an entity and all its components
   */
  destroyEntity(entityId: EntityId): boolean {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return false;
    }

    // Remove all components
    for (const componentType of entity.components) {
      this.removeComponent(entityId, componentType);
    }

    // Remove from parent if it has one
    if (entity.parent) {
      const parent = this.entities.get(entity.parent);
      if (parent) {
        parent.children.delete(entityId);
      }
    }

    // Destroy all children
    for (const childId of entity.children) {
      this.destroyEntity(childId);
    }

    // Notify systems
    for (const system of this.systems.values()) {
      if (system.onEntityRemoved) {
        system.onEntityRemoved(entityId);
      }
    }

    this.entities.delete(entityId);
    this.invalidateCache();

    return true;
  }

  /**
   * Get entity by ID
   */
  getEntity(entityId: EntityId): Entity | undefined {
    return this.entities.get(entityId);
  }

  /**
   * Check if entity exists and is active
   */
  isEntityActive(entityId: EntityId): boolean {
    const entity = this.entities.get(entityId);
    return entity ? entity.active : false;
  }

  /**
   * Set entity active state
   */
  setEntityActive(entityId: EntityId, active: boolean): boolean {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return false;
    }

    entity.active = active;
    this.invalidateCache();
    return true;
  }

  /**
   * Add tag to entity
   */
  addTag(entityId: EntityId, tag: string): boolean {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return false;
    }

    entity.tags.add(tag);
    this.invalidateCache();
    return true;
  }

  /**
   * Remove tag from entity
   */
  removeTag(entityId: EntityId, tag: string): boolean {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return false;
    }

    const removed = entity.tags.delete(tag);
    if (removed) {
      this.invalidateCache();
    }
    return removed;
  }

  /**
   * Check if entity has tag
   */
  hasTag(entityId: EntityId, tag: string): boolean {
    const entity = this.entities.get(entityId);
    return entity ? entity.tags.has(tag) : false;
  }

  /**
   * Set parent-child relationship
   */
  setParent(childId: EntityId, parentId: EntityId): boolean {
    const child = this.entities.get(childId);
    const parent = this.entities.get(parentId);
    
    if (!child || !parent || childId === parentId) {
      return false;
    }

    // Remove from old parent if it exists
    if (child.parent) {
      const oldParent = this.entities.get(child.parent);
      if (oldParent) {
        oldParent.children.delete(childId);
      }
    }

    // Set new parent
    child.parent = parentId;
    parent.children.add(childId);

    return true;
  }

  // Component management

  /**
   * Add component to entity
   */
  addComponent<T extends Component>(entityId: EntityId, component: T): boolean {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return false;
    }

    // Ensure component type storage exists
    if (!this.components.has(component.type)) {
      this.components.set(component.type, new Map());
    }

    // Set entity reference
    component.entityId = entityId;

    // Store component
    this.components.get(component.type)!.set(entityId, component);
    entity.components.add(component.type);

    // Notify systems
    for (const system of this.systems.values()) {
      if (system.onComponentAdded) {
        system.onComponentAdded(entityId, component);
      }
    }

    this.invalidateCache();
    return true;
  }

  /**
   * Remove component from entity
   */
  removeComponent(entityId: EntityId, componentType: ComponentType): boolean {
    const entity = this.entities.get(entityId);
    if (!entity || !entity.components.has(componentType)) {
      return false;
    }

    const componentMap = this.components.get(componentType);
    if (!componentMap) {
      return false;
    }

    componentMap.delete(entityId);
    entity.components.delete(componentType);

    // Notify systems
    for (const system of this.systems.values()) {
      if (system.onComponentRemoved) {
        system.onComponentRemoved(entityId, componentType);
      }
    }

    this.invalidateCache();
    return true;
  }

  /**
   * Get component from entity
   */
  getComponent<T extends Component>(entityId: EntityId, componentType: ComponentType): T | undefined {
    const componentMap = this.components.get(componentType);
    if (!componentMap) {
      return undefined;
    }

    return componentMap.get(entityId) as T;
  }

  /**
   * Check if entity has component
   */
  hasComponent(entityId: EntityId, componentType: ComponentType): boolean {
    const entity = this.entities.get(entityId);
    return entity ? entity.components.has(componentType) : false;
  }

  /**
   * Get all components of a specific type
   */
  getComponentsOfType<T extends Component>(componentType: ComponentType): T[] {
    const componentMap = this.components.get(componentType);
    if (!componentMap) {
      return [];
    }

    return Array.from(componentMap.values()) as T[];
  }

  /**
   * Get all components for an entity
   */
  getEntityComponents(entityId: EntityId): Component[] {
    const entity = this.entities.get(entityId);
    if (!entity) {
      return [];
    }

    const components: Component[] = [];
    for (const componentType of entity.components) {
      const component = this.getComponent(entityId, componentType);
      if (component) {
        components.push(component);
      }
    }

    return components;
  }

  // System management

  /**
   * Register a system
   */
  registerSystem(system: ECSSystem): void {
    if (this.systems.has(system.name)) {
      throw new Error(`System '${system.name}' is already registered`);
    }

    this.systems.set(system.name, system);
    this.invalidateCache();
  }

  /**
   * Unregister a system
   */
  unregisterSystem(systemName: string): boolean {
    const system = this.systems.get(systemName);
    if (!system) {
      return false;
    }

    if (system.cleanup) {
      system.cleanup();
    }

    this.systems.delete(systemName);
    this.systemEntityCache.delete(systemName);
    return true;
  }

  /**
   * Get system by name
   */
  getSystem<T extends ECSSystem>(systemName: string): T | undefined {
    return this.systems.get(systemName) as T;
  }

  // Entity queries

  /**
   * Query entities based on component requirements
   */
  queryEntities(query: EntityQuery): EntityId[] {
    const queryKey = this.getQueryKey(query);
    
    // Check cache
    const cached = this.queryCache.get(queryKey);
    if (cached) {
      return cached;
    }

    const result: EntityId[] = [];

    for (const [entityId, entity] of this.entities) {
      if (!entity.active) {
        continue;
      }

      // Check 'all' components requirement
      if (query.all && !query.all.every(type => entity.components.has(type))) {
        continue;
      }

      // Check 'any' components requirement
      if (query.any && !query.any.some(type => entity.components.has(type))) {
        continue;
      }

      // Check 'none' components requirement
      if (query.none && query.none.some(type => entity.components.has(type))) {
        continue;
      }

      // Check tags requirement
      if (query.tags && !query.tags.every(tag => entity.tags.has(tag))) {
        continue;
      }

      result.push(entityId);
    }

    // Cache result
    this.queryCache.set(queryKey, result);
    return result;
  }

  /**
   * Get entities for a specific system (optimized)
   */
  private getEntitiesForSystem(system: ECSSystem): EntityId[] {
    const cached = this.systemEntityCache.get(system.name);
    if (cached) {
      return cached;
    }

    const query: EntityQuery = {
      all: system.requiredComponents
    };

    const entities = this.queryEntities(query);
    this.systemEntityCache.set(system.name, entities);
    return entities;
  }

  /**
   * Get all entities
   */
  getAllEntities(): EntityId[] {
    return Array.from(this.entities.keys()).filter(id => {
      const entity = this.entities.get(id);
      return entity && entity.active;
    });
  }

  /**
   * Get entities by tag
   */
  getEntitiesByTag(tag: string): EntityId[] {
    return this.queryEntities({ tags: [tag] });
  }

  // Performance and utility methods

  /**
   * Invalidate all caches when entities/components change
   */
  private invalidateCache(): void {
    this.systemEntityCache.clear();
    this.queryCache.clear();
    this.cacheVersion++;
  }

  /**
   * Generate a cache key for entity queries
   */
  private getQueryKey(query: EntityQuery): string {
    const parts: string[] = [this.cacheVersion.toString()];
    
    if (query.all) {
      parts.push('all:' + query.all.join(','));
    }
    if (query.any) {
      parts.push('any:' + query.any.join(','));
    }
    if (query.none) {
      parts.push('none:' + query.none.join(','));
    }
    if (query.tags) {
      parts.push('tags:' + query.tags.join(','));
    }

    return parts.join('|');
  }

  /**
   * Get ECS statistics for debugging
   */
  getStats(): {
    entities: number;
    activeEntities: number;
    components: number;
    systems: number;
    cacheVersion: number;
  } {
    const activeEntities = Array.from(this.entities.values())
      .filter(entity => entity.active).length;

    const totalComponents = Array.from(this.components.values())
      .reduce((sum, componentMap) => sum + componentMap.size, 0);

    return {
      entities: this.entities.size,
      activeEntities,
      components: totalComponents,
      systems: this.systems.size,
      cacheVersion: this.cacheVersion
    };
  }
}

// Helper functions for creating component types

let componentTypeCounter = 0;

/**
 * Create a unique component type identifier
 */
export function createComponentType(name: string): ComponentType {
  return `${name}_${++componentTypeCounter}` as ComponentType;
}

/**
 * Type-safe entity ID creation
 */
export function createEntityId(id: string): EntityId {
  return id as EntityId;
}

// Common component types that can be used across the game

export const CommonComponentTypes = {
  TRANSFORM: createComponentType('Transform'),
  RENDERABLE: createComponentType('Renderable'),
  PHYSICS: createComponentType('Physics'),
  HEALTH: createComponentType('Health'),
  INVENTORY: createComponentType('Inventory'),
  AI: createComponentType('AI'),
  INPUT: createComponentType('Input'),
  AUDIO: createComponentType('Audio'),
  ANIMATION: createComponentType('Animation'),
  COLLISION: createComponentType('Collision')
} as const;