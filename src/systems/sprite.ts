import { loadImages } from 'src/systems/image';
import { Sprite, SpriteType } from 'src/components/sprite';

const SHEET_WIDTH = 108;
const SHEET_HEIGHT = 156;
const SPRITE_HEIGHT = 36;
const SPRITE_WIDTH = 22;

export const loadSprites = async (basePath: string): Promise<Sprite[]> => {
  const spriteSheets = await loadSpriteSheets(basePath);
  const sprites = [];
  for(const y = 0; y < SHEET_HEIGHT; y + SPRITE_HEIGHT) {
    for(const x = 0; x < SHEET_WIDTH; x + SPRITE_WIDTH) {
      sprites.push(
        new Sprite(
          {
            x,
            y,
            height: SPRITE_HEIGHT,
            width: SPRITE_WIDTH,
            img: new HTMLCanvasElement
          }
        )
      )
    }
  }
  return sprites;
};

const loadSpriteSheets = async (basePath: string) => {
  return await loadImages(basePath);
};