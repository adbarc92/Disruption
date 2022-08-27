import { jump } from 'src/systems/action';

/**
 * Commands call corresponding actions.
 */
export class Command {
  execute(): void {};
};

export class JumpCommand extends Command {
  execute() {
    jump();
  }
};
