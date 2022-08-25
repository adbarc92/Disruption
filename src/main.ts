import { ECS } from 'src/core/ecs';
import { loadImages } from 'src/systems/image';

const IMAGES_SRC = 'assets/images';

const main = async (): Promise<void> => {
  const images = await loadImages(IMAGES_SRC);
  // loadSprites();
  // loadSkills();
  // loadSounds();
  // loadRoom();
  // await initConsole();
  // await initScene();

  // const world = new World();

  // const currentScene = getCurrentScene();
  const ecs = new ECS();
  console.log('Hello world');
};

main();
