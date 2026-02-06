/**
 * Asset Loading and Management System
 * Handles loading, caching, and management of game assets
 */

import type { GameSystem } from '../core/GameEngine';

export enum AssetType {
  IMAGE = 'image',
  AUDIO = 'audio',
  JSON = 'json',
  TEXT = 'text',
  FONT = 'font',
  SPRITE_ATLAS = 'sprite_atlas',
  AUDIO_ATLAS = 'audio_atlas'
}

export interface AssetDefinition {
  id: string;
  type: AssetType;
  url: string;
  preload: boolean;
  metadata?: any;
}

export interface SpriteFrame {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
  sourceX?: number;
  sourceY?: number;
  sourceWidth?: number;
  sourceHeight?: number;
}

export interface SpriteAtlas {
  image: HTMLImageElement;
  frames: Map<string, SpriteFrame>;
  metadata: any;
}

export interface AudioClip {
  buffer: AudioBuffer;
  duration: number;
  metadata: any;
}

export interface LoadingProgress {
  loaded: number;
  total: number;
  currentAsset: string;
  percentage: number;
}

export type Asset = HTMLImageElement | AudioBuffer | any | SpriteAtlas | AudioClip;

export interface AssetCache {
  assets: Map<string, Asset>;
  loadingPromises: Map<string, Promise<Asset>>;
  loadedCount: number;
  totalCount: number;
}

export class AssetManager implements GameSystem {
  readonly name = 'AssetManager';
  
  private cache: AssetCache = {
    assets: new Map(),
    loadingPromises: new Map(),
    loadedCount: 0,
    totalCount: 0
  };
  
  private assetDefinitions: Map<string, AssetDefinition> = new Map();
  private audioContext: AudioContext | null = null;
  private loadingCallbacks: Array<(progress: LoadingProgress) => void> = [];
  
  // Default asset configuration
  private config = {
    baseUrl: '/assets/',
    retryAttempts: 3,
    retryDelay: 1000,
    enableCaching: true,
    preloadCritical: true,
    compressionFormats: {
      image: ['webp', 'png', 'jpg'],
      audio: ['webm', 'mp3', 'ogg']
    }
  };

  async initialize(): Promise<void> {
    // Initialize audio context
    try {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    } catch (error) {
      console.warn('AssetManager: AudioContext not available');
    }

    // Load asset manifest
    await this.loadAssetManifest();

    console.log('AssetManager: Initialized');
  }

  private async loadAssetManifest(): Promise<void> {
    try {
      const manifestUrl = `${this.config.baseUrl}manifest.json`;
      const response = await fetch(manifestUrl);
      
      if (!response.ok) {
        console.warn('AssetManager: No asset manifest found, using runtime registration');
        return;
      }
      
      const manifest = await response.json();
      
      // Register assets from manifest
      if (manifest.assets) {
        for (const asset of manifest.assets) {
          this.registerAsset(asset);
        }
      }
      
      // Update configuration if provided
      if (manifest.config) {
        Object.assign(this.config, manifest.config);
      }
      
      console.log(`AssetManager: Loaded manifest with ${manifest.assets?.length || 0} assets`);
    } catch (error) {
      console.warn('AssetManager: Failed to load asset manifest', error);
    }
  }

  /**
   * Register an asset for loading
   */
  registerAsset(definition: AssetDefinition): void {
    this.assetDefinitions.set(definition.id, definition);
    this.cache.totalCount++;
    
    if (definition.preload) {
      // Start loading immediately for preload assets
      this.loadAsset(definition.id);
    }
  }

  /**
   * Register multiple assets
   */
  registerAssets(definitions: AssetDefinition[]): void {
    definitions.forEach(def => this.registerAsset(def));
  }

  /**
   * Load a specific asset by ID
   */
  async loadAsset(id: string): Promise<Asset> {
    // Check if already loaded
    const cached = this.cache.assets.get(id);
    if (cached) {
      return cached;
    }

    // Check if already loading
    const loading = this.cache.loadingPromises.get(id);
    if (loading) {
      return loading;
    }

    // Get asset definition
    const definition = this.assetDefinitions.get(id);
    if (!definition) {
      throw new Error(`Asset definition not found: ${id}`);
    }

    // Start loading
    const loadPromise = this.loadAssetByType(definition);
    this.cache.loadingPromises.set(id, loadPromise);

    try {
      const asset = await loadPromise;
      
      // Cache the loaded asset
      this.cache.assets.set(id, asset);
      this.cache.loadedCount++;
      
      // Remove from loading promises
      this.cache.loadingPromises.delete(id);
      
      // Notify loading progress
      this.notifyProgress(id);
      
      return asset;
    } catch (error) {
      this.cache.loadingPromises.delete(id);
      throw error;
    }
  }

  /**
   * Load multiple assets
   */
  async loadAssets(ids: string[]): Promise<Asset[]> {
    const loadPromises = ids.map(id => this.loadAsset(id));
    return Promise.all(loadPromises);
  }

  /**
   * Load all registered assets
   */
  async loadAllAssets(): Promise<void> {
    const allIds = Array.from(this.assetDefinitions.keys());
    await this.loadAssets(allIds);
  }

  /**
   * Load all preload assets
   */
  async loadPreloadAssets(): Promise<void> {
    const preloadIds = Array.from(this.assetDefinitions.values())
      .filter(def => def.preload)
      .map(def => def.id);
    
    await this.loadAssets(preloadIds);
  }

  private async loadAssetByType(definition: AssetDefinition): Promise<Asset> {
    const url = this.resolveAssetUrl(definition.url);
    
    switch (definition.type) {
      case AssetType.IMAGE:
        return this.loadImage(url);
      
      case AssetType.AUDIO:
        return this.loadAudio(url);
      
      case AssetType.JSON:
        return this.loadJSON(url);
      
      case AssetType.TEXT:
        return this.loadText(url);
      
      case AssetType.FONT:
        return this.loadFont(definition.id, url);
      
      case AssetType.SPRITE_ATLAS:
        return this.loadSpriteAtlas(url, definition.metadata);
      
      case AssetType.AUDIO_ATLAS:
        return this.loadAudioAtlas(url, definition.metadata);
      
      default:
        throw new Error(`Unsupported asset type: ${definition.type}`);
    }
  }

  private resolveAssetUrl(url: string): string {
    if (url.startsWith('http') || url.startsWith('/')) {
      return url;
    }
    return `${this.config.baseUrl}${url}`;
  }

  private async loadImage(url: string): Promise<HTMLImageElement> {
    return new Promise((resolve, reject) => {
      const image = new Image();
      
      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error(`Failed to load image: ${url}`));
      
      // Enable CORS if needed
      image.crossOrigin = 'anonymous';
      image.src = url;
    });
  }

  private async loadAudio(url: string): Promise<AudioBuffer> {
    if (!this.audioContext) {
      throw new Error('AudioContext not available');
    }

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch audio: ${url}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    return this.audioContext.decodeAudioData(arrayBuffer);
  }

  private async loadJSON(url: string): Promise<any> {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch JSON: ${url}`);
    }
    return response.json();
  }

  private async loadText(url: string): Promise<string> {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch text: ${url}`);
    }
    return response.text();
  }

  private async loadFont(id: string, url: string): Promise<FontFace> {
    const font = new FontFace(id, `url(${url})`);
    await font.load();
    document.fonts.add(font);
    return font;
  }

  private async loadSpriteAtlas(url: string, metadata: any): Promise<SpriteAtlas> {
    // Load the image
    const image = await this.loadImage(url);
    
    // Load the atlas data (JSON)
    const atlasDataUrl = url.replace(/\.(png|jpg|jpeg|webp)$/i, '.json');
    const atlasData = await this.loadJSON(atlasDataUrl);
    
    // Parse frames
    const frames = new Map<string, SpriteFrame>();
    
    if (atlasData.frames) {
      for (const [frameId, frameData] of Object.entries(atlasData.frames as any)) {
        frames.set(frameId, {
          id: frameId,
          x: frameData.frame.x,
          y: frameData.frame.y,
          width: frameData.frame.w,
          height: frameData.frame.h,
          sourceX: frameData.sourceSize?.x || 0,
          sourceY: frameData.sourceSize?.y || 0,
          sourceWidth: frameData.sourceSize?.w || frameData.frame.w,
          sourceHeight: frameData.sourceSize?.h || frameData.frame.h
        });
      }
    }
    
    return {
      image,
      frames,
      metadata: { ...metadata, ...atlasData.meta }
    };
  }

  private async loadAudioAtlas(url: string, metadata: any): Promise<any> {
    // Load the atlas definition
    const atlasData = await this.loadJSON(url);
    
    // Load individual audio files
    const audioClips = new Map<string, AudioClip>();
    
    if (atlasData.clips) {
      for (const [clipId, clipData] of Object.entries(atlasData.clips as any)) {
        const audioBuffer = await this.loadAudio(clipData.url);
        audioClips.set(clipId, {
          buffer: audioBuffer,
          duration: audioBuffer.duration,
          metadata: clipData
        });
      }
    }
    
    return {
      clips: audioClips,
      metadata: { ...metadata, ...atlasData.meta }
    };
  }

  private notifyProgress(currentAsset: string): void {
    const progress: LoadingProgress = {
      loaded: this.cache.loadedCount,
      total: this.cache.totalCount,
      currentAsset,
      percentage: this.cache.totalCount > 0 ? (this.cache.loadedCount / this.cache.totalCount) * 100 : 0
    };

    this.loadingCallbacks.forEach(callback => {
      try {
        callback(progress);
      } catch (error) {
        console.error('AssetManager: Error in loading callback', error);
      }
    });
  }

  // Public API methods
  
  /**
   * Get a loaded asset
   */
  getAsset<T extends Asset>(id: string): T | null {
    return this.cache.assets.get(id) as T || null;
  }

  /**
   * Check if an asset is loaded
   */
  isAssetLoaded(id: string): boolean {
    return this.cache.assets.has(id);
  }

  /**
   * Check if an asset is currently loading
   */
  isAssetLoading(id: string): boolean {
    return this.cache.loadingPromises.has(id);
  }

  /**
   * Get loading progress
   */
  getLoadingProgress(): LoadingProgress {
    return {
      loaded: this.cache.loadedCount,
      total: this.cache.totalCount,
      currentAsset: '',
      percentage: this.cache.totalCount > 0 ? (this.cache.loadedCount / this.cache.totalCount) * 100 : 0
    };
  }

  /**
   * Add a loading progress callback
   */
  onLoadingProgress(callback: (progress: LoadingProgress) => void): void {
    this.loadingCallbacks.push(callback);
  }

  /**
   * Remove a loading progress callback
   */
  offLoadingProgress(callback: (progress: LoadingProgress) => void): void {
    const index = this.loadingCallbacks.indexOf(callback);
    if (index !== -1) {
      this.loadingCallbacks.splice(index, 1);
    }
  }

  /**
   * Unload an asset from cache
   */
  unloadAsset(id: string): void {
    const asset = this.cache.assets.get(id);
    if (asset) {
      // Clean up asset if needed
      if (asset instanceof HTMLImageElement) {
        asset.src = '';
      }
      
      this.cache.assets.delete(id);
      this.cache.loadedCount--;
    }
  }

  /**
   * Clear all cached assets
   */
  clearCache(): void {
    // Clean up assets
    for (const [id, asset] of this.cache.assets) {
      if (asset instanceof HTMLImageElement) {
        asset.src = '';
      }
    }
    
    this.cache.assets.clear();
    this.cache.loadingPromises.clear();
    this.cache.loadedCount = 0;
  }

  /**
   * Get sprite frame from atlas
   */
  getSpriteFrame(atlasId: string, frameId: string): SpriteFrame | null {
    const atlas = this.getAsset<SpriteAtlas>(atlasId);
    if (!atlas || !atlas.frames) {
      return null;
    }
    
    return atlas.frames.get(frameId) || null;
  }

  /**
   * Get audio clip from atlas
   */
  getAudioClip(atlasId: string, clipId: string): AudioClip | null {
    const atlas = this.getAsset<any>(atlasId);
    if (!atlas || !atlas.clips) {
      return null;
    }
    
    return atlas.clips.get(clipId) || null;
  }

  update(deltaTime: number): void {
    // Asset manager doesn't need regular updates
    // Could be used for asset streaming or garbage collection
  }

  cleanup(): void {
    this.clearCache();
    this.assetDefinitions.clear();
    this.loadingCallbacks = [];
    
    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close();
    }
  }

  // Static helper methods for common asset operations
  
  static createImageAsset(id: string, url: string, preload = false): AssetDefinition {
    return {
      id,
      type: AssetType.IMAGE,
      url,
      preload
    };
  }

  static createAudioAsset(id: string, url: string, preload = false): AssetDefinition {
    return {
      id,
      type: AssetType.AUDIO,
      url,
      preload
    };
  }

  static createSpriteAtlas(id: string, imageUrl: string, preload = false, metadata?: any): AssetDefinition {
    return {
      id,
      type: AssetType.SPRITE_ATLAS,
      url: imageUrl,
      preload,
      metadata
    };
  }

  static createJSONAsset(id: string, url: string, preload = false): AssetDefinition {
    return {
      id,
      type: AssetType.JSON,
      url,
      preload
    };
  }
}