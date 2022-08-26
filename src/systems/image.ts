import { promises as fsPromises } from 'fs';
import { createCanvas } from 'src/systems/canvas';

export const loadImage = async (fileSrc: string): Promise<HTMLImageElement> => {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      resolve(img);
    };
    img.onerror = () => {
      reject(`Failed to load image from: ${fileSrc}`);
    };
    img.src = fileSrc;
  });
};

export const loadImages = async(basePath: string): Promise<HTMLImageElement[]> => {
  console.log("Loading images...");
  const files = fsPromises.readdir(basePath);
  let imagesPromises: Promise<HTMLImageElement>[] = [];
  for(const file in files) {
    imagesPromises.push(loadImage(file))
  }
  return Promise.all(imagesPromises)
    .then((images) => {
      console.log("Images loaded.");
      return images;
    })
    .catch((e) => {
      console.error(`Error loading images: ${e}`);
      throw e;
    })
};

export const reverseImage = (inputCanvas: HTMLCanvasElement): HTMLCanvasElement => {
  const [canvas, ctx, width] = createCanvas(
    inputCanvas.width,
    inputCanvas.height
  );
  ctx.translate(width, 0);
  ctx.scale(-1, 1);
  ctx.drawImage(inputCanvas, 0, 0);
  return canvas;
};
