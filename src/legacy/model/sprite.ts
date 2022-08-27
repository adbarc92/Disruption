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
