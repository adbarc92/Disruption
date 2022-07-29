import { v4 as uuidv4 } from 'uuid';

class IComponent {
  id: string;
  type: string;

  constructor(type: string) {
    this.id = uuidv4();
    this.type = type;
  }

  update() {}
}

export class Entity {
  components: IComponent[];

  constructor(components?: IComponent[]) {
    this.components = components || [];
  }

  addComponent(component: IComponent): void {
    this.components.push(component);
  }

  removeComponent(component: IComponent): IComponent | null {
    const index = this.components.indexOf(component);
    return index > -1 ? this.components.splice(index, 1)[0] : null;
  }

  updateComponents(type: string) {
    this.components.forEach((component) => {
      component.type === type ? component.update() : null;
    })
  }
}

