import { Point2d, makePoint } from 'src/model/space'

const MIN_POS = 0;
const MAX_POS = 2;

/**
 * @class combat positions and associated utilities.
 * @param history the set of previous positions. Used for easy reversion.
 * @param currentPosition the currently-occupied position.
 */
export class Position {
  history: Point2d[];
  currentPosition: Point2d;

  constructor(x: number, y: number) {
    this.currentPosition = makePoint(x,y);
    this.history = [];
  }

  /**
   * Helper function to get the result position changes.
   */
  getResult(start: number, end: number) {
    let result = start;
    if(start > end) {
      result = end >= MAX_POS ? MAX_POS : end;
    } else if (start < end) {
      result = end <= MIN_POS ? MIN_POS : end;
    }
    return result;
  }

  /**
   * A general-purpose position change function.
   */
  changePosition(newX?: number, newY?: number) {
    this.history.push(this.currentPosition);
    let {x: currentX, y: currentY} = this.currentPosition;
    const resultX = newX ? this.getResult(currentX, newX) : currentX;
    const resultY = newY ? this.getResult(currentY, newY) : currentY;
    this.currentPosition = makePoint(resultX, resultY);
  }

  /**
   * A wrapper function for moving toward the opposing side.
   * @param degree the number of steps forward.
   */
  advance(degree:number) {
    this.changePosition(this.currentPosition.x-degree, 0);
  }

  /**
   * A wrapper function for moving away from the opposing side.
   * @param degree the number of steps backward.
   */
  retreat(degree: number) {
    this.changePosition(this.currentPosition.x+degree, 0);
  }

  /**
   * A wrapper function for moving upward around the opposing side.
   * @param degree the number of steps around.
   */
  strafeHigh(degree: number) {
    this.changePosition(0, this.currentPosition.y-degree);
  }

  /**
   * A wrapper function for moving downward around the opposing side.
   * @param degree the number of steps around.
   */
  strafeLow(degree: number) {
    this.changePosition(0, this.currentPosition.y+degree);
  }
}