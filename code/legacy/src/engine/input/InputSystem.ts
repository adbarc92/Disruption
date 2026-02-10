/**
 * Input Handling System
 * Manages keyboard, mouse, and touch input for the game
 */

import type { GameSystem } from '../core/GameEngine';
import { useGameStore } from '../state/GameStateManager';

export interface InputEvent {
  type: string;
  timestamp: number;
  data: any;
}

export interface KeyboardEvent extends InputEvent {
  type: 'keydown' | 'keyup';
  data: {
    key: string;
    code: string;
    ctrlKey: boolean;
    shiftKey: boolean;
    altKey: boolean;
    metaKey: boolean;
    repeat: boolean;
  };
}

export interface MouseEvent extends InputEvent {
  type: 'mousedown' | 'mouseup' | 'mousemove' | 'wheel';
  data: {
    button?: number;
    buttons?: number;
    clientX: number;
    clientY: number;
    deltaX?: number;
    deltaY?: number;
    deltaZ?: number;
    ctrlKey: boolean;
    shiftKey: boolean;
    altKey: boolean;
    metaKey: boolean;
  };
}

export interface TouchEvent extends InputEvent {
  type: 'touchstart' | 'touchend' | 'touchmove';
  data: {
    touches: Array<{
      identifier: number;
      clientX: number;
      clientY: number;
      force?: number;
    }>;
    changedTouches: Array<{
      identifier: number;
      clientX: number;
      clientY: number;
      force?: number;
    }>;
  };
}

export type GameInputEvent = KeyboardEvent | MouseEvent | TouchEvent;

export interface InputBinding {
  id: string;
  keys: string[];
  mouseButtons?: number[];
  callback: (event: GameInputEvent) => void;
  context?: string;
  enabled: boolean;
}

export interface InputState {
  keys: Map<string, boolean>;
  mouseButtons: Map<number, boolean>;
  mousePosition: { x: number; y: number };
  wheelDelta: { x: number; y: number };
  touches: Map<number, { x: number; y: number; force?: number }>;
}

export class InputSystem implements GameSystem {
  readonly name = 'InputSystem';
  
  private canvas: HTMLCanvasElement | null = null;
  private inputState: InputState = {
    keys: new Map(),
    mouseButtons: new Map(),
    mousePosition: { x: 0, y: 0 },
    wheelDelta: { x: 0, y: 0 },
    touches: new Map()
  };
  
  private bindings: Map<string, InputBinding> = new Map();
  private eventQueue: GameInputEvent[] = [];
  private contexts: Set<string> = new Set(['default']);
  private activeContext: string = 'default';
  
  private keydownHandler = this.handleKeyDown.bind(this);
  private keyupHandler = this.handleKeyUp.bind(this);
  private mousedownHandler = this.handleMouseDown.bind(this);
  private mouseupHandler = this.handleMouseUp.bind(this);
  private mousemoveHandler = this.handleMouseMove.bind(this);
  private wheelHandler = this.handleWheel.bind(this);
  private touchstartHandler = this.handleTouchStart.bind(this);
  private touchendHandler = this.handleTouchEnd.bind(this);
  private touchmoveHandler = this.handleTouchMove.bind(this);
  private contextmenuHandler = this.handleContextMenu.bind(this);

  async initialize(): Promise<void> {
    // Get canvas element
    this.canvas = document.getElementById('gameCanvas') as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error('Canvas element not found');
    }

    // Add event listeners
    this.addEventListeners();

    // Set up default input bindings
    this.setupDefaultBindings();

    console.log('InputSystem: Initialized');
  }

  private addEventListeners(): void {
    // Keyboard events (document level)
    document.addEventListener('keydown', this.keydownHandler);
    document.addEventListener('keyup', this.keyupHandler);

    if (this.canvas) {
      // Mouse events (canvas level)
      this.canvas.addEventListener('mousedown', this.mousedownHandler);
      this.canvas.addEventListener('mouseup', this.mouseupHandler);
      this.canvas.addEventListener('mousemove', this.mousemoveHandler);
      this.canvas.addEventListener('wheel', this.wheelHandler);
      this.canvas.addEventListener('contextmenu', this.contextmenuHandler);

      // Touch events (canvas level)
      this.canvas.addEventListener('touchstart', this.touchstartHandler, { passive: false });
      this.canvas.addEventListener('touchend', this.touchendHandler, { passive: false });
      this.canvas.addEventListener('touchmove', this.touchmoveHandler, { passive: false });

      // Make canvas focusable
      this.canvas.tabIndex = 0;
      this.canvas.focus();
    }
  }

  private removeEventListeners(): void {
    // Remove keyboard events
    document.removeEventListener('keydown', this.keydownHandler);
    document.removeEventListener('keyup', this.keyupHandler);

    if (this.canvas) {
      // Remove mouse events
      this.canvas.removeEventListener('mousedown', this.mousedownHandler);
      this.canvas.removeEventListener('mouseup', this.mouseupHandler);
      this.canvas.removeEventListener('mousemove', this.mousemoveHandler);
      this.canvas.removeEventListener('wheel', this.wheelHandler);
      this.canvas.removeEventListener('contextmenu', this.contextmenuHandler);

      // Remove touch events
      this.canvas.removeEventListener('touchstart', this.touchstartHandler);
      this.canvas.removeEventListener('touchend', this.touchendHandler);
      this.canvas.removeEventListener('touchmove', this.touchmoveHandler);
    }
  }

  private setupDefaultBindings(): void {
    // Default game bindings
    this.addBinding({
      id: 'pause',
      keys: ['Escape'],
      callback: () => {
        const store = useGameStore.getState();
        store.setPaused(!store.isPaused);
      },
      context: 'default',
      enabled: true
    });

    this.addBinding({
      id: 'debug_toggle',
      keys: ['F3'],
      callback: () => {
        const store = useGameStore.getState();
        store.updateUIState((ui) => {
          ui.showDebugInfo = !ui.showDebugInfo;
        });
      },
      context: 'default',
      enabled: true
    });

    // Combat-specific bindings
    this.addBinding({
      id: 'end_turn',
      keys: ['Space', 'Enter'],
      callback: () => {
        // This would trigger end turn logic
        console.log('End turn pressed');
      },
      context: 'combat',
      enabled: true
    });

    // Grid navigation bindings
    this.addBinding({
      id: 'move_up',
      keys: ['ArrowUp', 'w', 'W'],
      callback: () => this.handleGridMovement(0, -1),
      context: 'combat',
      enabled: true
    });

    this.addBinding({
      id: 'move_down',
      keys: ['ArrowDown', 's', 'S'],
      callback: () => this.handleGridMovement(0, 1),
      context: 'combat',
      enabled: true
    });

    this.addBinding({
      id: 'move_left',
      keys: ['ArrowLeft', 'a', 'A'],
      callback: () => this.handleGridMovement(-1, 0),
      context: 'combat',
      enabled: true
    });

    this.addBinding({
      id: 'move_right',
      keys: ['ArrowRight', 'd', 'D'],
      callback: () => this.handleGridMovement(1, 0),
      context: 'combat',
      enabled: true
    });
  }

  private handleGridMovement(deltaX: number, deltaY: number): void {
    const store = useGameStore.getState();
    if (!store.combat.isActive) return;

    const currentTile = store.ui.hoveredTile;
    if (currentTile) {
      const newX = Math.max(0, Math.min(store.combat.grid.width - 1, currentTile.x + deltaX));
      const newY = Math.max(0, Math.min(store.combat.grid.height - 1, currentTile.y + deltaY));
      
      store.updateUIState((ui) => {
        ui.hoveredTile = { x: newX, y: newY };
      });
    }
  }

  // Event handlers
  private handleKeyDown(event: Event): void {
    const keyEvent = event as KeyboardEvent;
    
    this.inputState.keys.set(keyEvent.code, true);
    
    const gameEvent: GameInputEvent = {
      type: 'keydown',
      timestamp: performance.now(),
      data: {
        key: keyEvent.key,
        code: keyEvent.code,
        ctrlKey: keyEvent.ctrlKey,
        shiftKey: keyEvent.shiftKey,
        altKey: keyEvent.altKey,
        metaKey: keyEvent.metaKey,
        repeat: keyEvent.repeat
      }
    };

    this.eventQueue.push(gameEvent);
    this.processBindings(gameEvent);
  }

  private handleKeyUp(event: Event): void {
    const keyEvent = event as KeyboardEvent;
    
    this.inputState.keys.set(keyEvent.code, false);
    
    const gameEvent: GameInputEvent = {
      type: 'keyup',
      timestamp: performance.now(),
      data: {
        key: keyEvent.key,
        code: keyEvent.code,
        ctrlKey: keyEvent.ctrlKey,
        shiftKey: keyEvent.shiftKey,
        altKey: keyEvent.altKey,
        metaKey: keyEvent.metaKey,
        repeat: keyEvent.repeat
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleMouseDown(event: Event): void {
    const mouseEvent = event as globalThis.MouseEvent;
    
    this.inputState.mouseButtons.set(mouseEvent.button, true);
    this.updateMousePosition(mouseEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'mousedown',
      timestamp: performance.now(),
      data: {
        button: mouseEvent.button,
        buttons: mouseEvent.buttons,
        clientX: mouseEvent.clientX,
        clientY: mouseEvent.clientY,
        ctrlKey: mouseEvent.ctrlKey,
        shiftKey: mouseEvent.shiftKey,
        altKey: mouseEvent.altKey,
        metaKey: mouseEvent.metaKey
      }
    };

    this.eventQueue.push(gameEvent);
    this.processBindings(gameEvent);
  }

  private handleMouseUp(event: Event): void {
    const mouseEvent = event as globalThis.MouseEvent;
    
    this.inputState.mouseButtons.set(mouseEvent.button, false);
    this.updateMousePosition(mouseEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'mouseup',
      timestamp: performance.now(),
      data: {
        button: mouseEvent.button,
        buttons: mouseEvent.buttons,
        clientX: mouseEvent.clientX,
        clientY: mouseEvent.clientY,
        ctrlKey: mouseEvent.ctrlKey,
        shiftKey: mouseEvent.shiftKey,
        altKey: mouseEvent.altKey,
        metaKey: mouseEvent.metaKey
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleMouseMove(event: Event): void {
    const mouseEvent = event as globalThis.MouseEvent;
    
    this.updateMousePosition(mouseEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'mousemove',
      timestamp: performance.now(),
      data: {
        buttons: mouseEvent.buttons,
        clientX: mouseEvent.clientX,
        clientY: mouseEvent.clientY,
        ctrlKey: mouseEvent.ctrlKey,
        shiftKey: mouseEvent.shiftKey,
        altKey: mouseEvent.altKey,
        metaKey: mouseEvent.metaKey
      }
    };

    this.eventQueue.push(gameEvent);
    this.updateHoveredTile(mouseEvent);
  }

  private handleWheel(event: Event): void {
    const wheelEvent = event as WheelEvent;
    wheelEvent.preventDefault();
    
    this.inputState.wheelDelta = {
      x: wheelEvent.deltaX,
      y: wheelEvent.deltaY
    };
    
    const gameEvent: GameInputEvent = {
      type: 'wheel',
      timestamp: performance.now(),
      data: {
        clientX: wheelEvent.clientX,
        clientY: wheelEvent.clientY,
        deltaX: wheelEvent.deltaX,
        deltaY: wheelEvent.deltaY,
        deltaZ: wheelEvent.deltaZ,
        ctrlKey: wheelEvent.ctrlKey,
        shiftKey: wheelEvent.shiftKey,
        altKey: wheelEvent.altKey,
        metaKey: wheelEvent.metaKey
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleTouchStart(event: Event): void {
    const touchEvent = event as globalThis.TouchEvent;
    touchEvent.preventDefault();
    
    this.updateTouches(touchEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'touchstart',
      timestamp: performance.now(),
      data: {
        touches: Array.from(touchEvent.touches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        })),
        changedTouches: Array.from(touchEvent.changedTouches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        }))
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleTouchEnd(event: Event): void {
    const touchEvent = event as globalThis.TouchEvent;
    touchEvent.preventDefault();
    
    this.updateTouches(touchEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'touchend',
      timestamp: performance.now(),
      data: {
        touches: Array.from(touchEvent.touches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        })),
        changedTouches: Array.from(touchEvent.changedTouches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        }))
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleTouchMove(event: Event): void {
    const touchEvent = event as globalThis.TouchEvent;
    touchEvent.preventDefault();
    
    this.updateTouches(touchEvent);
    
    const gameEvent: GameInputEvent = {
      type: 'touchmove',
      timestamp: performance.now(),
      data: {
        touches: Array.from(touchEvent.touches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        })),
        changedTouches: Array.from(touchEvent.changedTouches).map(touch => ({
          identifier: touch.identifier,
          clientX: touch.clientX,
          clientY: touch.clientY,
          force: touch.force
        }))
      }
    };

    this.eventQueue.push(gameEvent);
  }

  private handleContextMenu(event: Event): void {
    event.preventDefault(); // Prevent right-click context menu
  }

  // Helper methods
  private updateMousePosition(event: globalThis.MouseEvent): void {
    if (!this.canvas) return;
    
    const rect = this.canvas.getBoundingClientRect();
    this.inputState.mousePosition = {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    };
  }

  private updateTouches(event: globalThis.TouchEvent): void {
    if (!this.canvas) return;
    
    const rect = this.canvas.getBoundingClientRect();
    this.inputState.touches.clear();
    
    for (const touch of Array.from(event.touches)) {
      this.inputState.touches.set(touch.identifier, {
        x: touch.clientX - rect.left,
        y: touch.clientY - rect.top,
        force: touch.force
      });
    }
  }

  private updateHoveredTile(event: globalThis.MouseEvent): void {
    if (!this.canvas) return;
    
    const store = useGameStore.getState();
    if (!store.combat.isActive) return;

    const rect = this.canvas.getBoundingClientRect();
    const mouseX = event.clientX - rect.left;
    const mouseY = event.clientY - rect.top;

    // Convert mouse position to grid coordinates
    // This is a simplified calculation - you'd need proper world-to-grid conversion
    const tileSize = 64; // Assuming 64px tiles
    const gridOffsetX = (this.canvas.width - store.combat.grid.width * tileSize) / 2;
    const gridOffsetY = (this.canvas.height - store.combat.grid.height * tileSize) / 2;

    const gridX = Math.floor((mouseX - gridOffsetX) / tileSize);
    const gridY = Math.floor((mouseY - gridOffsetY) / tileSize);

    if (gridX >= 0 && gridX < store.combat.grid.width && 
        gridY >= 0 && gridY < store.combat.grid.height) {
      store.updateUIState((ui) => {
        ui.hoveredTile = { x: gridX, y: gridY };
      });
    }
  }

  private processBindings(event: GameInputEvent): void {
    for (const binding of this.bindings.values()) {
      if (!binding.enabled) continue;
      if (binding.context !== this.activeContext && binding.context !== 'default') continue;

      let matches = false;

      if (event.type === 'keydown' && binding.keys) {
        matches = binding.keys.includes(event.data.key) || binding.keys.includes(event.data.code);
      } else if (event.type === 'mousedown' && binding.mouseButtons) {
        matches = binding.mouseButtons.includes(event.data.button);
      }

      if (matches) {
        binding.callback(event);
      }
    }
  }

  // Public API methods
  addBinding(binding: InputBinding): void {
    this.bindings.set(binding.id, binding);
    
    if (binding.context) {
      this.contexts.add(binding.context);
    }
  }

  removeBinding(id: string): void {
    this.bindings.delete(id);
  }

  setBindingEnabled(id: string, enabled: boolean): void {
    const binding = this.bindings.get(id);
    if (binding) {
      binding.enabled = enabled;
    }
  }

  setActiveContext(context: string): void {
    this.activeContext = context;
    this.contexts.add(context);
  }

  getActiveContext(): string {
    return this.activeContext;
  }

  isKeyPressed(key: string): boolean {
    return this.inputState.keys.get(key) || false;
  }

  isMouseButtonPressed(button: number): boolean {
    return this.inputState.mouseButtons.get(button) || false;
  }

  getMousePosition(): { x: number; y: number } {
    return { ...this.inputState.mousePosition };
  }

  getWheelDelta(): { x: number; y: number } {
    return { ...this.inputState.wheelDelta };
  }

  getTouches(): Map<number, { x: number; y: number; force?: number }> {
    return new Map(this.inputState.touches);
  }

  update(deltaTime: number): void {
    // Reset wheel delta each frame
    this.inputState.wheelDelta = { x: 0, y: 0 };
    
    // Clear processed events (keep last 100 for debugging)
    if (this.eventQueue.length > 100) {
      this.eventQueue = this.eventQueue.slice(-50);
    }
  }

  cleanup(): void {
    this.removeEventListeners();
    this.bindings.clear();
    this.eventQueue = [];
    this.inputState.keys.clear();
    this.inputState.mouseButtons.clear();
    this.inputState.touches.clear();
  }
}