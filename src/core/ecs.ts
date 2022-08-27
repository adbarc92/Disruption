import { Entity } from 'src/core/entity';
import { ComponentContainer, ComponentClass } from 'src/core/component';
import { System } from 'src/core/system';
import { Component } from 'src/core/component';

export class ECS {
  private entities = new Map<Entity, ComponentContainer>();
  private systems = new Map<System, Set<Entity>>();

  private nextEntityId = 0;
  private entitiesToDestroy = new Array<Entity>();

  public addEntity(): Entity {
    let entity = this.nextEntityId;
    this.nextEntityId++;
    this.entities.set(entity, new ComponentContainer());
    return entity;
  };

  public removeEntity(entity: Entity): void {
    this.entitiesToDestroy.push(entity);
  }

  public addComponent(entity: Entity, component: Component): void {
    this.entities.get(entity)?.add(component);
    this.checkEntity(entity);
  }
  public getComponents(entity: Entity): ComponentContainer | undefined {
    return this.entities.get(entity);
  }

  public removeComponent(entity: Entity, componentClass: Function): void {
    this.entities.get(entity)?.delete(componentClass);
    this.checkEntity(entity);
}

  private destroyEntity(entity: Entity): void {
    this.entities.delete(entity);
    for (let system of this.systems.keys()) {
      this.checkEntitySystem(entity, system);
    }
  }

  private checkEntity(entity: Entity): void {
    for (let system of this.systems.keys()) {
      this.checkEntitySystem(entity, system);
    }
  }

  private checkEntitySystem(entity: Entity, system: System): void {
    let have = this.entities.get(entity);
    let need = system.componentsRequired;
    if (have?.hasAll(need)) {
      this.systems.get(system)?.add(entity);
    } else {
      this.systems.get(system)?.delete(entity);
    }
  }
};
