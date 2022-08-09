import { ECS } from 'src/core/ecs';

const main = async (): Promise<void> => {
  loadImages();
  loadSprites();
  loadSkills();
  loadSounds();
  loadRoom();
  await initConsole();
  await initScene();

  const world = new World();

  const currentScene = getCurrentScene();
  const ecs = new ECS();

};
