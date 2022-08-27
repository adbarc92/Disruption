import { ECS } from 'src/core/ecs';
import { loadImages } from 'src/systems/image';
import { loadSprites } from 'src/systems/sprite';
import { SpriteType } from 'src/components/sprite';

const IMAGES_SRC = './assets/images';
const SPRITES_SRC = './assets/spritesheets';

// const loadAssets = async ():
//   [Promise<HTMLImageElement>[], Promise<SpriteType>[], Promise<any>[], Promise<any>[]] => {
//   return [images, sprites, skills, sounds]
// };

const main = () => {
  let images;
  (async () => {
    images = await loadImages(IMAGES_SRC);
  })();
  const sprites: SpriteType[] = await loadSprites(SPRITES_SRC);
  const skills: any[] = []; // loadSkills();
  const sounds: any[] = []; // loadSounds();
  // loadRoom();
  // await initConsole();
  // await initScene();
  // const world = new World();
  // const currentScene = getCurrentScene();

  const ecs = new ECS();
  console.log(`images: ${images}`);
  const e1 = ecs.addEntity();
};

main();
