import { v4 as uuidv4 } from 'uuid';

class IComponent {
  id: string;

  constructor() {
    this.id = uuidv4();
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

  updateComponents() {
    this.components.forEach(component => component.update())
  }
}