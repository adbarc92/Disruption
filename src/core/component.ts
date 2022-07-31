import { v4 as uuidv4 } from 'uuid';

export abstract class Component {};

type ComponentClass<T extends Component> = new (...args: unknown[]) => T;

export class ComponentContainer {
  private map = new Map<Function, Component>()

  public add(component: Component): void {
    this.map.set(component.constructor, component)
  }

  public get<T extends Component>(
    componentClass: ComponentClass<T>
  ): T {
    return this.map.get(componentClass) as T;
  }

  public has(componentClass: Function): boolean {
    return this.map.has(componentClass);
  }

  public hasAll(componentClasses: Iterable<Function>): boolean {
    for(let cls of componentClasses) {
      if(!this.map.has(cls)) {
        return false;
      }
    }
    return true;
  }

  public delete(componentClass: Function): void {
    this.map.delete(componentClass);
  }
}