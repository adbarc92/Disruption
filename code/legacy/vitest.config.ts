import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    include: [
      'src/**/*.{test,spec}.{js,ts,tsx}',
      'tests/**/*.{test,spec}.{js,ts,tsx}'
    ],
    exclude: [
      'node_modules',
      'dist',
      'build',
      'coverage'
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        'src/**/*.d.ts',
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
        'dist/',
        'coverage/',
        '*.config.ts',
        '*.config.js'
      ],
      thresholds: {
        global: {
          branches: 70,
          functions: 70,
          lines: 70,
          statements: 70
        }
      }
    },
    // Test timeout
    testTimeout: 10000,
    hookTimeout: 10000,
    
    // Reporter configuration
    reporter: ['verbose', 'json', 'html'],
    
    // Mock configuration
    deps: {
      inline: ['zustand']
    }
  },
  
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@/engine': resolve(__dirname, 'src/engine'),
      '@/game': resolve(__dirname, 'src/game'),
      '@/assets': resolve(__dirname, 'src/assets'),
      '@/types': resolve(__dirname, 'src/types')
    }
  },

  define: {
    __DEV__: true,
    __VERSION__: '"test"',
    __BUILD_TIME__: '"test-time"'
  }
});