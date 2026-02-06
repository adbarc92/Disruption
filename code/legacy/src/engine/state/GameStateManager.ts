/**
 * Game State Management System using Zustand with Immer
 * Manages all game state including combat, progression, and world state
 */

import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { subscribeWithSelector } from 'zustand/middleware';
import type { GameSystem } from '../core/GameEngine';

// Core game state types
export interface GameStateStore {
  // Game engine state
  isInitialized: boolean;
  isPaused: boolean;
  currentScene: string;
  
  // Combat state
  combat: CombatState;
  
  // Character progression state
  progression: ProgressionState;
  
  // World state
  world: WorldState;
  
  // UI state
  ui: UIState;

  // Actions
  setInitialized: (initialized: boolean) => void;
  setPaused: (paused: boolean) => void;
  setCurrentScene: (scene: string) => void;
  updateCombatState: (updater: (combat: CombatState) => void) => void;
  updateProgressionState: (updater: (progression: ProgressionState) => void) => void;
  updateWorldState: (updater: (world: WorldState) => void) => void;
  updateUIState: (updater: (ui: UIState) => void) => void;
  resetState: () => void;
}

export interface CombatState {
  isActive: boolean;
  currentTurn: number;
  activeCharacterId: string | null;
  turnOrder: string[];
  grid: GridState;
  combatants: Map<string, CombatantState>;
}

export interface GridState {
  width: number;
  height: number;
  tiles: GridTile[][];
}

export interface GridTile {
  x: number;
  y: number;
  terrain: TerrainType;
  occupantId: string | null;
  effects: TileEffect[];
}

export enum TerrainType {
  NORMAL = 'normal',
  ELEVATED = 'elevated',
  HAZARD = 'hazard',
  BLESSED = 'blessed',
  CORRUPTED = 'corrupted'
}

export interface TileEffect {
  id: string;
  type: string;
  duration: number;
  intensity: number;
}

export interface CombatantState {
  id: string;
  name: string;
  position: { x: number; y: number };
  stats: CharacterStats;
  currentHP: number;
  currentWill: number;
  actionPoints: number;
  bankedActionPoints: number;
  statusEffects: StatusEffect[];
}

export interface CharacterStats {
  maxHP: number;
  maxWill: number;
  attack: number;
  defense: number;
  agility: number;
  amplitude: number;
  frequency: number;
  rotation: number;
}

export interface StatusEffect {
  id: string;
  type: string;
  duration: number;
  intensity: number;
}

export interface ProgressionState {
  characters: Map<string, CharacterProgression>;
  globalFlags: Map<string, boolean>;
  unlockedContent: string[];
}

export interface CharacterProgression {
  id: string;
  level: number;
  experience: number;
  spiralEssence: number;
  activatedNodes: string[];
  equippedRelics: string[];
  corruptionPoints: number;
}

export interface WorldState {
  currentRegion: string;
  exploredAreas: string[];
  worldFlags: Map<string, any>;
  woundLevel: number;
  aspectResonance: Map<string, number>;
}

export interface UIState {
  activeMenu: string | null;
  selectedCharacterId: string | null;
  hoveredTile: { x: number; y: number } | null;
  showDebugInfo: boolean;
  notifications: Notification[];
}

export interface Notification {
  id: string;
  type: 'info' | 'warning' | 'error' | 'success';
  message: string;
  duration?: number;
}

// Default state values
const createDefaultCombatState = (): CombatState => ({
  isActive: false,
  currentTurn: 0,
  activeCharacterId: null,
  turnOrder: [],
  grid: {
    width: 7,
    height: 7,
    tiles: Array(7).fill(null).map((_, y) =>
      Array(7).fill(null).map((_, x) => ({
        x,
        y,
        terrain: TerrainType.NORMAL,
        occupantId: null,
        effects: []
      }))
    )
  },
  combatants: new Map()
});

const createDefaultProgressionState = (): ProgressionState => ({
  characters: new Map(),
  globalFlags: new Map(),
  unlockedContent: []
});

const createDefaultWorldState = (): WorldState => ({
  currentRegion: 'starting_village',
  exploredAreas: ['starting_village'],
  worldFlags: new Map(),
  woundLevel: 0,
  aspectResonance: new Map()
});

const createDefaultUIState = (): UIState => ({
  activeMenu: null,
  selectedCharacterId: null,
  hoveredTile: null,
  showDebugInfo: false,
  notifications: []
});

// Create Zustand store with Immer middleware
export const useGameStore = create<GameStateStore>()(
  subscribeWithSelector(
    immer((set, get) => ({
      // Initial state
      isInitialized: false,
      isPaused: false,
      currentScene: 'menu',
      combat: createDefaultCombatState(),
      progression: createDefaultProgressionState(),
      world: createDefaultWorldState(),
      ui: createDefaultUIState(),

      // Actions
      setInitialized: (initialized: boolean) =>
        set((state) => {
          state.isInitialized = initialized;
        }),

      setPaused: (paused: boolean) =>
        set((state) => {
          state.isPaused = paused;
        }),

      setCurrentScene: (scene: string) =>
        set((state) => {
          state.currentScene = scene;
        }),

      updateCombatState: (updater) =>
        set((state) => {
          updater(state.combat);
        }),

      updateProgressionState: (updater) =>
        set((state) => {
          updater(state.progression);
        }),

      updateWorldState: (updater) =>
        set((state) => {
          updater(state.world);
        }),

      updateUIState: (updater) =>
        set((state) => {
          updater(state.ui);
        }),

      resetState: () =>
        set((state) => {
          state.combat = createDefaultCombatState();
          state.progression = createDefaultProgressionState();
          state.world = createDefaultWorldState();
          state.ui = createDefaultUIState();
          state.currentScene = 'menu';
          state.isPaused = false;
        })
    }))
  )
);

/**
 * Game State Manager System
 * Integrates with the game engine to provide centralized state management
 */
export class GameStateManager implements GameSystem {
  readonly name = 'GameStateManager';
  private subscriptions: Array<() => void> = [];

  async initialize(): Promise<void> {
    // Set up state subscriptions for debugging or persistence
    this.subscriptions.push(
      useGameStore.subscribe(
        (state) => state.currentScene,
        (scene) => {
          console.log(`Scene changed to: ${scene}`);
        }
      )
    );

    // Subscribe to combat state changes
    this.subscriptions.push(
      useGameStore.subscribe(
        (state) => state.combat.isActive,
        (isActive) => {
          console.log(`Combat ${isActive ? 'started' : 'ended'}`);
        }
      )
    );

    useGameStore.getState().setInitialized(true);
  }

  update(deltaTime: number): void {
    const state = useGameStore.getState();
    
    // Update UI notifications (remove expired ones)
    if (state.ui.notifications.length > 0) {
      state.updateUIState((ui) => {
        ui.notifications = ui.notifications.filter((notification) => {
          if (notification.duration !== undefined) {
            notification.duration -= deltaTime;
            return notification.duration > 0;
          }
          return true;
        });
      });
    }

    // Update status effects in combat
    if (state.combat.isActive) {
      state.updateCombatState((combat) => {
        combat.combatants.forEach((combatant) => {
          combatant.statusEffects = combatant.statusEffects.filter((effect) => {
            effect.duration -= deltaTime;
            return effect.duration > 0;
          });
        });

        // Update tile effects
        for (let y = 0; y < combat.grid.height; y++) {
          for (let x = 0; x < combat.grid.width; x++) {
            const tile = combat.grid.tiles[y][x];
            tile.effects = tile.effects.filter((effect) => {
              effect.duration -= deltaTime;
              return effect.duration > 0;
            });
          }
        }
      });
    }
  }

  cleanup(): void {
    // Clean up subscriptions
    this.subscriptions.forEach(unsubscribe => unsubscribe());
    this.subscriptions = [];
    
    // Reset state
    useGameStore.getState().resetState();
  }

  // Utility methods for common state operations
  static addNotification(notification: Omit<Notification, 'id'>): void {
    useGameStore.getState().updateUIState((ui) => {
      ui.notifications.push({
        id: `notification_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        ...notification
      });
    });
  }

  static initializeCombat(combatants: CombatantState[], gridConfig?: { width: number; height: number }): void {
    useGameStore.getState().updateCombatState((combat) => {
      combat.isActive = true;
      combat.currentTurn = 0;
      combat.activeCharacterId = combatants[0]?.id || null;
      combat.turnOrder = combatants
        .sort((a, b) => b.stats.agility - a.stats.agility)
        .map(c => c.id);
      
      // Set up grid
      if (gridConfig) {
        combat.grid.width = gridConfig.width;
        combat.grid.height = gridConfig.height;
        combat.grid.tiles = Array(gridConfig.height).fill(null).map((_, y) =>
          Array(gridConfig.width).fill(null).map((_, x) => ({
            x,
            y,
            terrain: TerrainType.NORMAL,
            occupantId: null,
            effects: []
          }))
        );
      }

      // Add combatants to the combat state
      combat.combatants.clear();
      combatants.forEach(combatant => {
        combat.combatants.set(combatant.id, combatant);
      });
    });
  }

  static endCombat(): void {
    useGameStore.getState().updateCombatState((combat) => {
      combat.isActive = false;
      combat.combatants.clear();
      combat.turnOrder = [];
      combat.activeCharacterId = null;
      combat.currentTurn = 0;
    });
  }
}