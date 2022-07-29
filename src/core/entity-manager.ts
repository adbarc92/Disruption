import { Entity } from 'src/core/entity'


export class EntityManager {
  entities: Entity[];

  constructor(entities?: Entity[]){
    this.entities = entities || [];
  }

  update(type: string){
    this.entities.forEach(entity => entity.updateComponents(type))
  }
}
