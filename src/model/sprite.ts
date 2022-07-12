
/**
 * The size of a sprite in tiles.
 */
// export enum Size {
//   SMALL = '1x1',
//   MEDIUM = '1x2',
//   LARGE = '2x2',
//   MASSIVE = '2x3',
//   GARGANTUAN = '3x3'
// }

export type Sprite = {
  img: HTMLCanvasElement | HTMLImageElement,
  x: number,
  y: number,
  w: number,
  h: number,
};

export const createSprite = (
  img: HTMLCanvasElement | HTMLImageElement,
  x?: number,
  y?: number,
  w?: number,
  h?: number,
) => {
  return {
    img,
    x: x ?? 0,
    y: y ?? 0,
    w: w ?? img.width,
    h: h ?? img.height,
  }
};
