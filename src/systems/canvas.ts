/* Credit: borrowed wholesale from Regem Ludos: https://github.com/benjamin-t-brown/regem-ludos */

export const SCREEN_HEIGHT = 512;
export const SCREEN_WIDTH = 683;
export const CANVAS_ID = 'canv';
export const CANVAS_ID_OUTER = 'canv-outer';

let mainCanvas: HTMLCanvasElement | null = null;
let outerCanvas: HTMLCanvasElement | null = null;
let drawScale = 1;

// Create a canvas element given a width and a height, returning a reference to the
// canvas, the rendering context, width, and height
export const createCanvas = (
  width: number,
  height: number,
  isGL?: boolean
): [HTMLCanvasElement, CanvasRenderingContext2D, number, number] => {
  const canvas =
    mainCanvas && (window as any).OffscreenCanvas
      ? new (window as any).OffscreenCanvas(width || 1, height || 1)
      : document.createElement('canvas');
  canvas.width = width || 1;
  canvas.height = height || 1;

  let context: any;
  if (isGL) {
    // WebGL2D.enable(canvas);
    console.error('WebGL rendering has been removed.');
    context = (canvas as any).getContext('webgl-2d');
  } else {
    context = (canvas as any).getContext('2d');
  }
  context.imageSmoothingEnabled = false;
  return [canvas as any, context as CanvasRenderingContext2D, width, height];
};

// get a reference to the current canvas.  If it has not been made yet, then create it,
// append it to the body, then return a reference to it.
// Also creates an 'outer' canvas, used for debug and text
export const getCanvas = (type?: string): HTMLCanvasElement => {
  if (type === 'outer' && outerCanvas) {
    return outerCanvas;
  }

  if (mainCanvas) {
    return mainCanvas as HTMLCanvasElement;
  } else {
    const [canvas, ctx] = createCanvas(SCREEN_WIDTH, SCREEN_HEIGHT);
    canvas.id = CANVAS_ID;
    ctx.imageSmoothingEnabled = false;
    const div = document.getElementById('canvas-container');
    if (div) {
      const [canvasOuter, ctx] = createCanvas(SCREEN_WIDTH, SCREEN_HEIGHT);
      canvasOuter.id = CANVAS_ID_OUTER;
      ctx.imageSmoothingEnabled = false;

      const fadeDiv = document.createElement('div');
      fadeDiv.style.position = 'absolute';
      fadeDiv.style.width = '100%';
      fadeDiv.style.height = '100%';
      fadeDiv.style.top = '0';
      fadeDiv.id = 'fade';

      const fadeDiv2 = document.createElement('div');
      fadeDiv2.style.position = 'absolute';
      fadeDiv2.style.width = '100%';
      fadeDiv2.style.height = '100%';
      fadeDiv2.style.top = '0';
      fadeDiv2.id = 'fade2';

      div.appendChild(canvas);
      div.appendChild(fadeDiv);
      div.appendChild(fadeDiv2);
      div.appendChild(canvasOuter);
    } else {
      console.warn('Failed to acquire parent div for primary canvas.');
    }
    mainCanvas = canvas;
    return canvas;
  }
};
