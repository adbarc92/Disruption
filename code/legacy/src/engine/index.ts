/**
 * Eternal Spiral Game Engine
 * Main engine exports for external use
 */

// Core engine exports
export { GameEngine, GameEngineState } from './core/GameEngine';
export type { GameSystem, GameEngineConfig } from './core/GameEngine';

// State management exports
export { GameStateManager, useGameStore } from './state/GameStateManager';
export type {
  GameStateStore,
  CombatState,
  ProgressionState,
  WorldState,
  UIState,
  GridState,
  GridTile,
  CombatantState,
  CharacterStats,
  StatusEffect,
  TerrainType,
  LoadingProgress
} from './state/GameStateManager';

// Rendering system exports
export { RenderSystem } from './rendering/RenderSystem';
export type {
  RenderableComponent,
  SpriteComponent,
  TextComponent,
  ShapeComponent,
  RenderComponent,
  Vector2,
  Rectangle,
  Color,
  Camera,
  RenderStats
} from './rendering/RenderSystem';

// Input system exports
export { InputSystem } from './input/InputSystem';
export type {
  InputEvent,
  KeyboardEvent,
  MouseEvent,
  TouchEvent,
  GameInputEvent,
  InputBinding,
  InputState
} from './input/InputSystem';

// Asset management exports
export { AssetManager, AssetType } from './assets/AssetManager';
export type {
  AssetDefinition,
  SpriteFrame,
  SpriteAtlas,
  AudioClip,
  Asset,
  AssetCache
} from './assets/AssetManager';

// ECS exports
export { ECSManager, createComponentType, createEntityId, CommonComponentTypes } from './ecs/ECSManager';
export type {
  EntityId,
  ComponentType,
  Component,
  ECSSystem,
  Entity,
  EntityQuery
} from './ecs/ECSManager';

// Common components exports
export {
  createTransformComponent,
  createRenderableComponent,
  createPhysicsComponent,
  createHealthComponent,
  createAnimationComponent,
  createInputComponent,
  createAudioComponent,
  createCollisionComponent,
  createAIComponent,
  createGridPositionComponent,
  createCombatStatsComponent,
  GRID_POSITION_TYPE,
  COMBAT_STATS_TYPE
} from './ecs/components/CommonComponents';

export type {
  TransformComponent,
  RenderableComponent as ECSRenderableComponent,
  PhysicsComponent,
  HealthComponent,
  AnimationComponent,
  InputComponent as ECSInputComponent,
  AudioComponent,
  CollisionComponent,
  AIComponent,
  GridPositionComponent,
  CombatStatsComponent,
  DamageEvent,
  Animation,
  AnimationFrame,
  AnimationEvent,
  InputBinding as ECSInputBinding,
  AudioSource,
  CollisionShape,
  AIState,
  CombatStatusEffect
} from './ecs/components/CommonComponents';

// Version information
export const ENGINE_VERSION = '0.1.0';
export const ENGINE_NAME = 'Eternal Spiral Engine';

// Engine configuration defaults
export const DEFAULT_ENGINE_CONFIG = {
  canvasId: 'gameCanvas',
  targetFPS: 60,
  enableDebug: false,
  autoStart: true
} as const;