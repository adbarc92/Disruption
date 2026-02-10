/**
 * Core Game Engine - Main orchestrator for all game systems
 * Follows the approved layered architecture pattern
 */

export interface GameSystem {
  readonly name: string;
  initialize(): Promise<void>;
  update(deltaTime: number): void;
  render?(deltaTime: number): void;
  cleanup(): void;
}

export interface GameEngineConfig {
  canvasId: string;
  targetFPS: number;
  enableDebug: boolean;
  autoStart: boolean;
}

export enum GameEngineState {
  INITIALIZING = 'initializing',
  RUNNING = 'running',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

export class GameEngine {
  private systems: Map<string, GameSystem> = new Map();
  private state: GameEngineState = GameEngineState.INITIALIZING;
  private lastFrameTime: number = 0;
  private animationFrameId: number = 0;
  private readonly config: GameEngineConfig;
  private canvas: HTMLCanvasElement | null = null;
  private context: CanvasRenderingContext2D | WebGLRenderingContext | null = null;

  constructor(config: GameEngineConfig) {
    this.config = { ...config };
    this.setupCanvas();
  }

  private setupCanvas(): void {
    this.canvas = document.getElementById(this.config.canvasId) as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error(`Canvas element with id '${this.config.canvasId}' not found`);
    }

    // Try WebGL first, fallback to 2D
    try {
      this.context = this.canvas.getContext('webgl2') || this.canvas.getContext('webgl');
      if (this.config.enableDebug) {
        console.log('GameEngine: Using WebGL context');
      }
    } catch (error) {
      this.context = this.canvas.getContext('2d');
      if (this.config.enableDebug) {
        console.log('GameEngine: Falling back to 2D context');
      }
    }

    if (!this.context) {
      throw new Error('Unable to get canvas rendering context');
    }
  }

  /**
   * Register a system with the engine
   */
  registerSystem(system: GameSystem): void {
    if (this.systems.has(system.name)) {
      throw new Error(`System '${system.name}' is already registered`);
    }
    this.systems.set(system.name, system);
    
    if (this.config.enableDebug) {
      console.log(`GameEngine: Registered system '${system.name}'`);
    }
  }

  /**
   * Get a registered system by name
   */
  getSystem<T extends GameSystem>(name: string): T | undefined {
    return this.systems.get(name) as T;
  }

  /**
   * Initialize all registered systems
   */
  async initialize(): Promise<void> {
    try {
      this.state = GameEngineState.INITIALIZING;
      
      if (this.config.enableDebug) {
        console.log('GameEngine: Initializing systems...');
      }

      // Initialize systems in registration order
      for (const [name, system] of this.systems) {
        if (this.config.enableDebug) {
          console.log(`GameEngine: Initializing system '${name}'`);
        }
        await system.initialize();
      }

      this.state = GameEngineState.STOPPED;
      
      if (this.config.autoStart) {
        this.start();
      }

      if (this.config.enableDebug) {
        console.log('GameEngine: Initialization complete');
      }
    } catch (error) {
      this.state = GameEngineState.ERROR;
      console.error('GameEngine: Initialization failed', error);
      throw error;
    }
  }

  /**
   * Start the game loop
   */
  start(): void {
    if (this.state === GameEngineState.RUNNING) {
      return;
    }

    this.state = GameEngineState.RUNNING;
    this.lastFrameTime = performance.now();
    this.gameLoop();

    if (this.config.enableDebug) {
      console.log('GameEngine: Started');
    }
  }

  /**
   * Pause the game loop
   */
  pause(): void {
    if (this.state === GameEngineState.RUNNING) {
      this.state = GameEngineState.PAUSED;
      if (this.animationFrameId) {
        cancelAnimationFrame(this.animationFrameId);
      }
      
      if (this.config.enableDebug) {
        console.log('GameEngine: Paused');
      }
    }
  }

  /**
   * Resume the game loop
   */
  resume(): void {
    if (this.state === GameEngineState.PAUSED) {
      this.state = GameEngineState.RUNNING;
      this.lastFrameTime = performance.now();
      this.gameLoop();
      
      if (this.config.enableDebug) {
        console.log('GameEngine: Resumed');
      }
    }
  }

  /**
   * Stop the game loop and cleanup
   */
  stop(): void {
    this.state = GameEngineState.STOPPED;
    
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
    }

    // Cleanup systems in reverse order
    const systemEntries = Array.from(this.systems.entries()).reverse();
    for (const [name, system] of systemEntries) {
      try {
        system.cleanup();
        if (this.config.enableDebug) {
          console.log(`GameEngine: Cleaned up system '${name}'`);
        }
      } catch (error) {
        console.error(`GameEngine: Error cleaning up system '${name}'`, error);
      }
    }

    if (this.config.enableDebug) {
      console.log('GameEngine: Stopped');
    }
  }

  /**
   * Main game loop
   */
  private gameLoop = (): void => {
    if (this.state !== GameEngineState.RUNNING) {
      return;
    }

    const currentTime = performance.now();
    const deltaTime = currentTime - this.lastFrameTime;
    this.lastFrameTime = currentTime;

    // Cap delta time to prevent spiral of death
    const cappedDeltaTime = Math.min(deltaTime, 1000 / 30); // 30 FPS minimum

    try {
      // Update all systems
      for (const system of this.systems.values()) {
        system.update(cappedDeltaTime);
      }

      // Render systems that support it
      for (const system of this.systems.values()) {
        if (system.render) {
          system.render(cappedDeltaTime);
        }
      }
    } catch (error) {
      console.error('GameEngine: Error in game loop', error);
      this.state = GameEngineState.ERROR;
      return;
    }

    this.animationFrameId = requestAnimationFrame(this.gameLoop);
  };

  /**
   * Get current engine state
   */
  getState(): GameEngineState {
    return this.state;
  }

  /**
   * Get canvas element
   */
  getCanvas(): HTMLCanvasElement | null {
    return this.canvas;
  }

  /**
   * Get rendering context
   */
  getContext(): CanvasRenderingContext2D | WebGLRenderingContext | null {
    return this.context;
  }

  /**
   * Get engine configuration
   */
  getConfig(): Readonly<GameEngineConfig> {
    return this.config;
  }
}