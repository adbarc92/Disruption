import { ECS } from 'src/core/ecs';
import { loadImages } from 'src/systems/image';
import { SpriteType } from 'src/components/sprite';

const IMAGES_SRC = 'assets/images';

// const loadAssets = async ():
//   [Promise<HTMLImageElement>[], Promise<SpriteType>[], Promise<any>[], Promise<any>[]] => {
//   return [images, sprites, skills, sounds]
// };

const main = async (): Promise<void> => {
  const images = loadImages(IMAGES_SRC);
  const sprites: SpriteType[] = []; // loadSprites();
  const skills: any[] = []; // loadSkills();
  const sounds: any[] = []; // loadSounds();
  // loadRoom();
  // await initConsole();
  // await initScene();
  // const world = new World();
  // const currentScene = getCurrentScene();

  const ecs = new ECS();
  console.log('Hello world');
};

main();
