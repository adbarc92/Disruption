/**
 * Common Component Definitions
 * Standard components used throughout the game
 */

import type { Component, ComponentType, EntityId } from '../ECSManager';
import { CommonComponentTypes } from '../ECSManager';
import type { Vector2, Color } from '../../rendering/RenderSystem';

/**
 * Transform Component - Position, rotation, scale
 */
export interface TransformComponent extends Component {
  type: typeof CommonComponentTypes.TRANSFORM;
  position: Vector2;
  rotation: number;
  scale: Vector2;
  localPosition: Vector2;
  localRotation: number;
  localScale: Vector2;
  worldMatrix?: Float32Array;
  dirty: boolean;
}

export function createTransformComponent(
  entityId: EntityId,
  position: Vector2 = { x: 0, y: 0 },
  rotation: number = 0,
  scale: Vector2 = { x: 1, y: 1 }
): TransformComponent {
  return {
    type: CommonComponentTypes.TRANSFORM,
    entityId,
    position: { ...position },
    rotation,
    scale: { ...scale },
    localPosition: { ...position },
    localRotation: rotation,
    localScale: { ...scale },
    dirty: true
  };
}

/**
 * Renderable Component - Visual representation
 */
export interface RenderableComponent extends Component {
  type: typeof CommonComponentTypes.RENDERABLE;
  visible: boolean;
  layer: number;
  opacity: number;
  tint: Color;
  spriteId?: string;
  atlasId?: string;
  frameId?: string;
  flipX: boolean;
  flipY: boolean;
  width?: number;
  height?: number;
}

export function createRenderableComponent(
  entityId: EntityId,
  options: Partial<RenderableComponent> = {}
): RenderableComponent {
  return {
    type: CommonComponentTypes.RENDERABLE,
    entityId,
    visible: true,
    layer: 0,
    opacity: 1.0,
    tint: { r: 255, g: 255, b: 255, a: 1.0 },
    flipX: false,
    flipY: false,
    ...options
  };
}

/**
 * Physics Component - Basic physics properties
 */
export interface PhysicsComponent extends Component {
  type: typeof CommonComponentTypes.PHYSICS;
  velocity: Vector2;
  acceleration: Vector2;
  mass: number;
  friction: number;
  bounce: number;
  maxVelocity: Vector2;
  isStatic: boolean;
  gravityScale: number;
}

export function createPhysicsComponent(
  entityId: EntityId,
  options: Partial<PhysicsComponent> = {}
): PhysicsComponent {
  return {
    type: CommonComponentTypes.PHYSICS,
    entityId,
    velocity: { x: 0, y: 0 },
    acceleration: { x: 0, y: 0 },
    mass: 1.0,
    friction: 0.1,
    bounce: 0.0,
    maxVelocity: { x: 1000, y: 1000 },
    isStatic: false,
    gravityScale: 1.0,
    ...options
  };
}

/**
 * Health Component - HP, damage, healing
 */
export interface HealthComponent extends Component {
  type: typeof CommonComponentTypes.HEALTH;
  currentHP: number;
  maxHP: number;
  regeneration: number;
  invulnerable: boolean;
  invulnerabilityDuration: number;
  lastDamageTime: number;
  damageEvents: DamageEvent[];
}

export interface DamageEvent {
  amount: number;
  type: string;
  source: EntityId | null;
  timestamp: number;
}

export function createHealthComponent(
  entityId: EntityId,
  maxHP: number,
  currentHP?: number
): HealthComponent {
  return {
    type: CommonComponentTypes.HEALTH,
    entityId,
    currentHP: currentHP ?? maxHP,
    maxHP,
    regeneration: 0,
    invulnerable: false,
    invulnerabilityDuration: 0,
    lastDamageTime: 0,
    damageEvents: []
  };
}

/**
 * Animation Component - Sprite animation
 */
export interface AnimationComponent extends Component {
  type: typeof CommonComponentTypes.ANIMATION;
  currentAnimation: string;
  currentFrame: number;
  frameTime: number;
  frameDuration: number;
  isPlaying: boolean;
  loop: boolean;
  animations: Map<string, Animation>;
  onComplete?: (animationName: string) => void;
}

export interface Animation {
  name: string;
  frames: AnimationFrame[];
  duration: number;
  loop: boolean;
}

export interface AnimationFrame {
  frameId: string;
  duration: number;
  events?: AnimationEvent[];
}

export interface AnimationEvent {
  name: string;
  data?: any;
}

export function createAnimationComponent(
  entityId: EntityId,
  animations: Animation[] = []
): AnimationComponent {
  const animationMap = new Map<string, Animation>();
  animations.forEach(anim => animationMap.set(anim.name, anim));

  return {
    type: CommonComponentTypes.ANIMATION,
    entityId,
    currentAnimation: animations[0]?.name || '',
    currentFrame: 0,
    frameTime: 0,
    frameDuration: 100, // ms per frame by default
    isPlaying: false,
    loop: true,
    animations: animationMap
  };
}

/**
 * Input Component - Input handling for entities
 */
export interface InputComponent extends Component {
  type: typeof CommonComponentTypes.INPUT;
  inputBindings: Map<string, InputBinding>;
  enabled: boolean;
  priority: number;
}

export interface InputBinding {
  action: string;
  keys: string[];
  mouseButtons?: number[];
  callback: (pressed: boolean) => void;
}

export function createInputComponent(
  entityId: EntityId,
  bindings: InputBinding[] = []
): InputComponent {
  const bindingMap = new Map<string, InputBinding>();
  bindings.forEach(binding => bindingMap.set(binding.action, binding));

  return {
    type: CommonComponentTypes.INPUT,
    entityId,
    inputBindings: bindingMap,
    enabled: true,
    priority: 0
  };
}

/**
 * Audio Component - Sound effects and music
 */
export interface AudioComponent extends Component {
  type: typeof CommonComponentTypes.AUDIO;
  sounds: Map<string, AudioSource>;
  volume: number;
  is3D: boolean;
  position3D?: Vector2;
  minDistance: number;
  maxDistance: number;
}

export interface AudioSource {
  id: string;
  clipId: string;
  volume: number;
  pitch: number;
  loop: boolean;
  isPlaying: boolean;
  audioNode?: AudioBufferSourceNode;
}

export function createAudioComponent(
  entityId: EntityId,
  options: Partial<AudioComponent> = {}
): AudioComponent {
  return {
    type: CommonComponentTypes.AUDIO,
    entityId,
    sounds: new Map(),
    volume: 1.0,
    is3D: false,
    minDistance: 100,
    maxDistance: 1000,
    ...options
  };
}

/**
 * Collision Component - Collision detection
 */
export interface CollisionComponent extends Component {
  type: typeof CommonComponentTypes.COLLISION;
  shape: CollisionShape;
  isTrigger: boolean;
  layer: number;
  mask: number;
  onCollisionEnter?: (other: EntityId) => void;
  onCollisionExit?: (other: EntityId) => void;
  onTriggerEnter?: (other: EntityId) => void;
  onTriggerExit?: (other: EntityId) => void;
}

export type CollisionShape = 
  | { type: 'circle'; radius: number }
  | { type: 'rectangle'; width: number; height: number }
  | { type: 'point' };

export function createCollisionComponent(
  entityId: EntityId,
  shape: CollisionShape,
  options: Partial<CollisionComponent> = {}
): CollisionComponent {
  return {
    type: CommonComponentTypes.COLLISION,
    entityId,
    shape,
    isTrigger: false,
    layer: 0,
    mask: 0xFFFFFFFF,
    ...options
  };
}

/**
 * AI Component - Basic AI behavior
 */
export interface AIComponent extends Component {
  type: typeof CommonComponentTypes.AI;
  currentState: string;
  states: Map<string, AIState>;
  blackboard: Map<string, any>;
  updateInterval: number;
  lastUpdate: number;
}

export interface AIState {
  name: string;
  enter?: (ai: AIComponent) => void;
  update?: (ai: AIComponent, deltaTime: number) => string | null; // return next state
  exit?: (ai: AIComponent) => void;
}

export function createAIComponent(
  entityId: EntityId,
  states: AIState[] = [],
  initialState?: string
): AIComponent {
  const stateMap = new Map<string, AIState>();
  states.forEach(state => stateMap.set(state.name, state));

  return {
    type: CommonComponentTypes.AI,
    entityId,
    currentState: initialState || states[0]?.name || '',
    states: stateMap,
    blackboard: new Map(),
    updateInterval: 100, // ms
    lastUpdate: 0
  };
}

/**
 * Grid Position Component - For turn-based grid positioning
 */
export const GRID_POSITION_TYPE = 'GridPosition' as ComponentType;

export interface GridPositionComponent extends Component {
  type: typeof GRID_POSITION_TYPE;
  gridX: number;
  gridY: number;
  previousGridX: number;
  previousGridY: number;
  isMoving: boolean;
  moveProgress: number;
  moveDuration: number;
}

export function createGridPositionComponent(
  entityId: EntityId,
  gridX: number,
  gridY: number
): GridPositionComponent {
  return {
    type: GRID_POSITION_TYPE,
    entityId,
    gridX,
    gridY,
    previousGridX: gridX,
    previousGridY: gridY,
    isMoving: false,
    moveProgress: 0,
    moveDuration: 500 // ms
  };
}

/**
 * Combat Stats Component - For RPG combat
 */
export const COMBAT_STATS_TYPE = 'CombatStats' as ComponentType;

export interface CombatStatsComponent extends Component {
  type: typeof COMBAT_STATS_TYPE;
  level: number;
  experience: number;
  actionPoints: number;
  maxActionPoints: number;
  will: number;
  maxWill: number;
  attack: number;
  defense: number;
  agility: number;
  amplitude: number;
  frequency: number;
  rotation: number;
  statusEffects: CombatStatusEffect[];
}

export interface CombatStatusEffect {
  id: string;
  name: string;
  type: string;
  duration: number;
  intensity: number;
  tickInterval?: number;
  lastTick?: number;
  onApply?: (target: EntityId) => void;
  onTick?: (target: EntityId) => void;
  onRemove?: (target: EntityId) => void;
}

export function createCombatStatsComponent(
  entityId: EntityId,
  stats: Partial<CombatStatsComponent>
): CombatStatsComponent {
  return {
    type: COMBAT_STATS_TYPE,
    entityId,
    level: 1,
    experience: 0,
    actionPoints: 4,
    maxActionPoints: 4,
    will: 20,
    maxWill: 20,
    attack: 10,
    defense: 10,
    agility: 10,
    amplitude: 10,
    frequency: 10,
    rotation: 10,
    statusEffects: [],
    ...stats
  };
}