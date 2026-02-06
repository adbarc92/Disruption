/**
 * Rendering System with Canvas 2D and WebGL support
 * Handles all visual rendering for the 2.5D game
 */

import type { GameSystem } from '../core/GameEngine';
import { useGameStore } from '../state/GameStateManager';

export interface RenderableComponent {
  id: string;
  layer: number;
  visible: boolean;
  position: Vector2;
  rotation: number;
  scale: Vector2;
  opacity: number;
}

export interface SpriteComponent extends RenderableComponent {
  type: 'sprite';
  textureId: string;
  sourceRect?: Rectangle;
  tint?: Color;
}

export interface TextComponent extends RenderableComponent {
  type: 'text';
  text: string;
  font: string;
  fontSize: number;
  color: Color;
  align: 'left' | 'center' | 'right';
}

export interface ShapeComponent extends RenderableComponent {
  type: 'shape';
  shape: 'rectangle' | 'circle' | 'line';
  size: Vector2;
  color: Color;
  strokeColor?: Color;
  strokeWidth?: number;
}

export type RenderComponent = SpriteComponent | TextComponent | ShapeComponent;

export interface Vector2 {
  x: number;
  y: number;
}

export interface Rectangle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface Color {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface Camera {
  position: Vector2;
  zoom: number;
  rotation: number;
  viewport: Rectangle;
}

export interface RenderStats {
  drawCalls: number;
  triangles: number;
  fps: number;
  frameTime: number;
}

/**
 * Abstract base renderer
 */
abstract class BaseRenderer {
  protected canvas: HTMLCanvasElement;
  protected camera: Camera;
  protected renderables: Map<string, RenderComponent> = new Map();
  protected stats: RenderStats = {
    drawCalls: 0,
    triangles: 0,
    fps: 0,
    frameTime: 0
  };

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.camera = {
      position: { x: 0, y: 0 },
      zoom: 1.0,
      rotation: 0,
      viewport: { x: 0, y: 0, width: canvas.width, height: canvas.height }
    };
  }

  abstract initialize(): Promise<void>;
  abstract render(deltaTime: number): void;
  abstract cleanup(): void;

  addRenderable(component: RenderComponent): void {
    this.renderables.set(component.id, component);
  }

  removeRenderable(id: string): void {
    this.renderables.delete(id);
  }

  updateRenderable(id: string, updates: Partial<RenderComponent>): void {
    const component = this.renderables.get(id);
    if (component) {
      Object.assign(component, updates);
    }
  }

  setCamera(camera: Partial<Camera>): void {
    Object.assign(this.camera, camera);
  }

  getStats(): RenderStats {
    return { ...this.stats };
  }

  protected worldToScreen(worldPos: Vector2): Vector2 {
    const { position, zoom } = this.camera;
    return {
      x: (worldPos.x - position.x) * zoom + this.canvas.width / 2,
      y: (worldPos.y - position.y) * zoom + this.canvas.height / 2
    };
  }

  protected screenToWorld(screenPos: Vector2): Vector2 {
    const { position, zoom } = this.camera;
    return {
      x: (screenPos.x - this.canvas.width / 2) / zoom + position.x,
      y: (screenPos.y - this.canvas.height / 2) / zoom + position.y
    };
  }
}

/**
 * Canvas 2D Renderer
 */
class Canvas2DRenderer extends BaseRenderer {
  private context: CanvasRenderingContext2D;
  private imageCache: Map<string, HTMLImageElement> = new Map();

  constructor(canvas: HTMLCanvasElement, context: CanvasRenderingContext2D) {
    super(canvas);
    this.context = context;
  }

  async initialize(): Promise<void> {
    // Set up canvas properties
    this.context.imageSmoothingEnabled = true;
    this.context.imageSmoothingQuality = 'high';
  }

  render(deltaTime: number): void {
    const startTime = performance.now();
    this.stats.drawCalls = 0;

    // Clear canvas
    this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Save context state
    this.context.save();

    // Apply camera transform
    this.context.translate(this.canvas.width / 2, this.canvas.height / 2);
    this.context.scale(this.camera.zoom, this.camera.zoom);
    this.context.rotate(this.camera.rotation);
    this.context.translate(-this.camera.position.x, -this.camera.position.y);

    // Sort renderables by layer
    const sortedRenderables = Array.from(this.renderables.values())
      .filter(r => r.visible)
      .sort((a, b) => a.layer - b.layer);

    // Render each component
    for (const component of sortedRenderables) {
      this.renderComponent(component);
    }

    // Restore context state
    this.context.restore();

    // Update stats
    this.stats.frameTime = performance.now() - startTime;
    this.stats.fps = 1000 / deltaTime;
  }

  private renderComponent(component: RenderComponent): void {
    this.context.save();

    // Apply component transform
    this.context.translate(component.position.x, component.position.y);
    this.context.rotate(component.rotation);
    this.context.scale(component.scale.x, component.scale.y);
    this.context.globalAlpha = component.opacity;

    switch (component.type) {
      case 'sprite':
        this.renderSprite(component);
        break;
      case 'text':
        this.renderText(component);
        break;
      case 'shape':
        this.renderShape(component);
        break;
    }

    this.context.restore();
    this.stats.drawCalls++;
  }

  private renderSprite(sprite: SpriteComponent): void {
    const image = this.imageCache.get(sprite.textureId);
    if (!image) return;

    const sourceRect = sprite.sourceRect || {
      x: 0, y: 0, width: image.width, height: image.height
    };

    if (sprite.tint) {
      // Apply tint (simplified implementation)
      this.context.globalCompositeOperation = 'multiply';
      this.context.fillStyle = `rgba(${sprite.tint.r}, ${sprite.tint.g}, ${sprite.tint.b}, ${sprite.tint.a})`;
    }

    this.context.drawImage(
      image,
      sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height,
      -sourceRect.width / 2, -sourceRect.height / 2, sourceRect.width, sourceRect.height
    );

    if (sprite.tint) {
      this.context.globalCompositeOperation = 'source-over';
    }
  }

  private renderText(text: TextComponent): void {
    this.context.font = `${text.fontSize}px ${text.font}`;
    this.context.fillStyle = `rgba(${text.color.r}, ${text.color.g}, ${text.color.b}, ${text.color.a})`;
    this.context.textAlign = text.align;
    this.context.textBaseline = 'middle';
    
    this.context.fillText(text.text, 0, 0);
  }

  private renderShape(shape: ShapeComponent): void {
    this.context.fillStyle = `rgba(${shape.color.r}, ${shape.color.g}, ${shape.color.b}, ${shape.color.a})`;
    
    if (shape.strokeColor) {
      this.context.strokeStyle = `rgba(${shape.strokeColor.r}, ${shape.strokeColor.g}, ${shape.strokeColor.b}, ${shape.strokeColor.a})`;
      this.context.lineWidth = shape.strokeWidth || 1;
    }

    switch (shape.shape) {
      case 'rectangle':
        this.context.fillRect(-shape.size.x / 2, -shape.size.y / 2, shape.size.x, shape.size.y);
        if (shape.strokeColor) {
          this.context.strokeRect(-shape.size.x / 2, -shape.size.y / 2, shape.size.x, shape.size.y);
        }
        break;
      case 'circle':
        this.context.beginPath();
        this.context.arc(0, 0, shape.size.x / 2, 0, Math.PI * 2);
        this.context.fill();
        if (shape.strokeColor) {
          this.context.stroke();
        }
        break;
      case 'line':
        this.context.beginPath();
        this.context.moveTo(-shape.size.x / 2, 0);
        this.context.lineTo(shape.size.x / 2, 0);
        this.context.stroke();
        break;
    }
  }

  cleanup(): void {
    this.renderables.clear();
    this.imageCache.clear();
  }

  loadTexture(id: string, imageSrc: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = () => {
        this.imageCache.set(id, image);
        resolve();
      };
      image.onerror = reject;
      image.src = imageSrc;
    });
  }
}

/**
 * WebGL Renderer (basic implementation)
 */
class WebGLRenderer extends BaseRenderer {
  private gl: WebGLRenderingContext;
  private shaderProgram: WebGLProgram | null = null;
  private vertexBuffer: WebGLBuffer | null = null;
  private textureCache: Map<string, WebGLTexture> = new Map();

  constructor(canvas: HTMLCanvasElement, context: WebGLRenderingContext) {
    super(canvas);
    this.gl = context;
  }

  async initialize(): Promise<void> {
    const gl = this.gl;

    // Basic vertex shader
    const vertexShaderSource = `
      attribute vec2 a_position;
      attribute vec2 a_texCoord;
      uniform mat3 u_transform;
      varying vec2 v_texCoord;
      
      void main() {
        vec3 position = u_transform * vec3(a_position, 1.0);
        gl_Position = vec4(position.xy, 0.0, 1.0);
        v_texCoord = a_texCoord;
      }
    `;

    // Basic fragment shader
    const fragmentShaderSource = `
      precision mediump float;
      uniform sampler2D u_texture;
      uniform vec4 u_color;
      varying vec2 v_texCoord;
      
      void main() {
        gl_FragColor = texture2D(u_texture, v_texCoord) * u_color;
      }
    `;

    // Create and compile shaders
    const vertexShader = this.createShader(gl.VERTEX_SHADER, vertexShaderSource);
    const fragmentShader = this.createShader(gl.FRAGMENT_SHADER, fragmentShaderSource);

    if (!vertexShader || !fragmentShader) {
      throw new Error('Failed to create shaders');
    }

    // Create shader program
    this.shaderProgram = gl.createProgram();
    if (!this.shaderProgram) {
      throw new Error('Failed to create shader program');
    }

    gl.attachShader(this.shaderProgram, vertexShader);
    gl.attachShader(this.shaderProgram, fragmentShader);
    gl.linkProgram(this.shaderProgram);

    if (!gl.getProgramParameter(this.shaderProgram, gl.LINK_STATUS)) {
      const error = gl.getProgramInfoLog(this.shaderProgram);
      throw new Error(`Failed to link shader program: ${error}`);
    }

    // Create vertex buffer
    this.vertexBuffer = gl.createBuffer();

    // Enable alpha blending
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
  }

  render(deltaTime: number): void {
    const startTime = performance.now();
    const gl = this.gl;
    
    this.stats.drawCalls = 0;

    // Clear canvas
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    if (!this.shaderProgram) return;

    gl.useProgram(this.shaderProgram);

    // Set viewport
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);

    // Sort and render components (simplified)
    const sortedRenderables = Array.from(this.renderables.values())
      .filter(r => r.visible && r.type === 'sprite')
      .sort((a, b) => a.layer - b.layer);

    for (const component of sortedRenderables) {
      this.renderWebGLSprite(component as SpriteComponent);
    }

    // Update stats
    this.stats.frameTime = performance.now() - startTime;
    this.stats.fps = 1000 / deltaTime;
  }

  private createShader(type: number, source: string): WebGLShader | null {
    const gl = this.gl;
    const shader = gl.createShader(type);
    if (!shader) return null;

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const error = gl.getShaderInfoLog(shader);
      console.error(`Shader compilation error: ${error}`);
      gl.deleteShader(shader);
      return null;
    }

    return shader;
  }

  private renderWebGLSprite(sprite: SpriteComponent): void {
    const gl = this.gl;
    if (!this.shaderProgram) return;

    // This is a simplified WebGL sprite rendering
    // In a full implementation, you'd batch sprites and use more efficient rendering
    
    this.stats.drawCalls++;
  }

  cleanup(): void {
    const gl = this.gl;
    
    if (this.shaderProgram) {
      gl.deleteProgram(this.shaderProgram);
      this.shaderProgram = null;
    }
    
    if (this.vertexBuffer) {
      gl.deleteBuffer(this.vertexBuffer);
      this.vertexBuffer = null;
    }

    this.textureCache.forEach(texture => gl.deleteTexture(texture));
    this.textureCache.clear();
    this.renderables.clear();
  }
}

/**
 * Main Render System
 */
export class RenderSystem implements GameSystem {
  readonly name = 'RenderSystem';
  private renderer: BaseRenderer | null = null;
  private canvas: HTMLCanvasElement | null = null;
  private context: CanvasRenderingContext2D | WebGLRenderingContext | null = null;

  async initialize(): Promise<void> {
    // Get canvas and context from game engine
    const gameStore = useGameStore.getState();
    
    // This would typically be passed from the GameEngine
    this.canvas = document.getElementById('gameCanvas') as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error('Canvas element not found');
    }

    // Try WebGL first, fallback to 2D
    try {
      this.context = this.canvas.getContext('webgl') || this.canvas.getContext('webgl2');
      if (this.context) {
        this.renderer = new WebGLRenderer(this.canvas, this.context as WebGLRenderingContext);
        console.log('RenderSystem: Using WebGL renderer');
      }
    } catch (error) {
      console.warn('WebGL not available, falling back to Canvas 2D');
    }

    if (!this.renderer) {
      this.context = this.canvas.getContext('2d');
      if (this.context) {
        this.renderer = new Canvas2DRenderer(this.canvas, this.context as CanvasRenderingContext2D);
        console.log('RenderSystem: Using Canvas 2D renderer');
      }
    }

    if (!this.renderer) {
      throw new Error('No rendering context available');
    }

    await this.renderer.initialize();
  }

  update(deltaTime: number): void {
    // Update logic (if needed)
  }

  render(deltaTime: number): void {
    if (this.renderer) {
      this.renderer.render(deltaTime);
    }
  }

  cleanup(): void {
    if (this.renderer) {
      this.renderer.cleanup();
      this.renderer = null;
    }
  }

  // Public API methods
  addRenderable(component: RenderComponent): void {
    this.renderer?.addRenderable(component);
  }

  removeRenderable(id: string): void {
    this.renderer?.removeRenderable(id);
  }

  updateRenderable(id: string, updates: Partial<RenderComponent>): void {
    this.renderer?.updateRenderable(id, updates);
  }

  setCamera(camera: Partial<Camera>): void {
    this.renderer?.setCamera(camera);
  }

  getRenderStats(): RenderStats | null {
    return this.renderer?.getStats() || null;
  }

  // Texture loading (for Canvas 2D renderer)
  async loadTexture(id: string, imageSrc: string): Promise<void> {
    if (this.renderer instanceof Canvas2DRenderer) {
      await this.renderer.loadTexture(id, imageSrc);
    }
  }
}