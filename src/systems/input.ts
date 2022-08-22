import { Command } from 'src/systems/command';

const enum Button {
  buttonX = 'buttonX',
  buttonY = 'buttonY',
  buttonA = 'buttonA',
  buttonB = 'buttonB',
  dPadUp = 'dPadUp',
  dPadDown = 'dPadDown',
  dPadRight = 'dPadRight',
  dPadLeft = 'dPadLeft',
  rightBumper = 'rightBumper',
  leftBumper = 'leftBumper',
  rightTrigger = 'rightTrigger',
  leftTrigger = 'leftTrigger',
  leftStickLeft = 'leftStickLeft',
  leftStickRight = 'leftStickRight',
  leftStickUp = 'leftStickUp',
  leftStickDown = 'leftStickDown',
  rightStickLeft = 'rightStickLeft',
  rightStickRight = 'rightStickRight',
  rightStickUp = 'rightStickUp',
  rightStickDown = 'rightStickDown',
  buttonStart = 'buttonStart',
  buttonSelect = 'buttonSelect',
}

interface Inputs {
  buttonX: Command | null;
  buttonY: Command | null;
  buttonA: Command | null;
  buttonB: Command | null;
  dPadUp: Command | null;
  dPadDown: Command | null;
  dPadRight: Command | null;
  dPadLeft: Command | null;
  rightBumper: Command | null;
  leftBumper: Command | null;
  rightTrigger: Command | null;
  leftTrigger: Command | null;
  leftStickLeft: Command | null;
  leftStickRight: Command | null;
  leftStickUp: Command | null;
  leftStickDown: Command | null;
  rightStickLeft: Command | null;
  rightStickRight: Command | null;
  rightStickUp: Command | null;
  rightStickDown: Command | null;
  buttonStart: Command | null;
  buttonSelect: Command | null;
};

/**
 * Used for transmuting inputs into commands.
 */
export class InputHandler {
  handleInput(input: Button): Command | null {
    return this.commands[input];
  };

  changeCommand(input: Button, command: Command) {
    this.commands[input] = command;
  }

  commands: Inputs = {
    buttonX: null,
    buttonY: null,
    buttonA: null,
    buttonB: null,
    dPadUp: null,
    dPadDown: null,
    dPadRight: null,
    dPadLeft: null,
    rightBumper: null,
    leftBumper: null,
    rightTrigger: null,
    leftTrigger: null,
    leftStickLeft: null,
    leftStickRight: null,
    leftStickUp: null,
    leftStickDown: null,
    rightStickLeft: null,
    rightStickRight: null,
    rightStickUp: null,
    rightStickDown: null,
    buttonStart: null,
    buttonSelect: null,
  };
};
