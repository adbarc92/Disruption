import { loadImages } from 'src/systems/image';
import { Sprite } from 'src/components/sprite';

const SHEET_WIDTH = 108;
const SHEET_HEIGHT = 156;
const SPRITE_HEIGHT = 36;
const SPRITE_WIDTH = 22;

export const loadSprites = (basePath: string) => {
  const sprites = [];
  for(const y = 0; y < SHEET_HEIGHT; y + SPRITE_HEIGHT) {
    for(const x = 0; x < SHEET_WIDTH; x + SPRITE_WIDTH) {
      sprites.push(new Sprite(x, y, SPRITE_HEIGHT, SPRITE_WIDTH, new HTMLCanvasElement))
    }
  }
};