import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@/engine': resolve(__dirname, 'src/engine'),
      '@/game': resolve(__dirname, 'src/game'),
      '@/assets': resolve(__dirname, 'src/assets'),
      '@/types': resolve(__dirname, 'src/types')
    }
  },

  build: {
    target: 'esnext',
    sourcemap: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html')
      },
      output: {
        manualChunks: {
          'engine-core': [
            './src/engine/core/GameEngine.ts',
            './src/engine/state/GameStateManager.ts'
          ],
          'engine-systems': [
            './src/engine/rendering/RenderSystem.ts',
            './src/engine/input/InputSystem.ts',
            './src/engine/assets/AssetManager.ts',
            './src/engine/ecs/ECSManager.ts'
          ],
          'vendor': ['react', 'react-dom'],
          'state-management': ['zustand', 'immer']
        }
      }
    },
    // Optimize for web deployment
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },

  // Development server configuration
  server: {
    port: 3000,
    host: true,
    strictPort: true,
    fs: {
      strict: false
    }
  },

  // Preview server configuration
  preview: {
    port: 4173,
    host: true,
    strictPort: true
  },

  // Asset handling
  assetsInclude: [
    '**/*.png',
    '**/*.jpg',
    '**/*.jpeg',
    '**/*.webp',
    '**/*.svg',
    '**/*.mp3',
    '**/*.ogg',
    '**/*.wav',
    '**/*.webm',
    '**/*.json',
    '**/*.atlas'
  ],

  // CSS configuration
  css: {
    devSourcemap: true,
    modules: {
      localsConvention: 'camelCase'
    }
  },

  // Define global constants
  define: {
    __DEV__: JSON.stringify(process.env.NODE_ENV !== 'production'),
    __VERSION__: JSON.stringify(process.env.npm_package_version || '0.1.0'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString())
  },

  // Optimization
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'zustand',
      'immer'
    ],
    exclude: [
      // Exclude any problematic dependencies
    ]
  },

  // Worker configuration for potential multithreading
  worker: {
    format: 'es'
  }
});