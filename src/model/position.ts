import { Point2d, makePoint } from 'src/model/space'

const MIN_POS = 0;
const MAX_POS = 2;

export class Position {
  history: Point2d[];
  currentPosition: Point2d;


  constructor(x: number, y: number) {
    this.currentPosition = makePoint(x,y);
    this.history = [];
  }

  getResult(start: number, end: number) {
    let result = start;
    if(start > end) {
      result = end >= MAX_POS ? MAX_POS : end;
    } else if (start < end) {
      result = end <= MIN_POS ? MIN_POS : end;
    }
    return result;
  }

  changePosition(newX?: number, newY?: number) {
    this.history.push(this.currentPosition);
    let {x: currentX, y: currentY} = this.currentPosition;
    const resultX = newX ? this.getResult(currentX, newX) : currentX;
    const resultY = newY ? this.getResult(currentY, newY) : currentY;
    this.currentPosition = makePoint(resultX, resultY);
  }

  advance(degree:number) {
    this.changePosition(this.currentPosition.x-degree, 0);
  }

  retreat(degree: number) {
    this.changePosition(this.currentPosition.x+degree, 0);
  }

  strafeHigh(degree: number) {
    this.changePosition(0, this.currentPosition.y-degree);
  }

  strafeLow(degree: number) {
    this.changePosition(0, this.currentPosition.y+degree);
  }
}