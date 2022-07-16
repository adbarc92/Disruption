export type Point2d = {
  x: number;
  y: number;
}

export const makePoint = (x: number, y: number): Point2d => { return { x,y } }

export interface Size {
  width: number;
  height: number;
  depth: number;
}

export const POSITIONS = {
  FRONT_TOP: makePoint(0,0),
  FRONT_MID: makePoint(0,1),
  FRONT_BOTTOM: makePoint(0,2),
  MID_TOP: makePoint(1,0),
  MID_MID: makePoint(1,1),
  MID_BOTTOM: makePoint(1,2),
  BACK_TOP: makePoint(2,0),
  BACK_MID: makePoint(2,1),
  BACK_BOTTOM: makePoint(2,2),
}

export const COLUMNS = {
  FRONT_COLUMN: [POSITIONS.FRONT_TOP, POSITIONS.FRONT_MID, POSITIONS.FRONT_BOTTOM],
  MID_COLUMN: [POSITIONS.MID_TOP, POSITIONS.MID_MID, POSITIONS.MID_BOTTOM],
  BACK_COLUMN: [POSITIONS.BACK_TOP, POSITIONS.BACK_MID, POSITIONS.BACK_BOTTOM],
}

export const ROWS = {
  TOP_ROW: [POSITIONS.FRONT_TOP, POSITIONS.MID_TOP, POSITIONS.BACK_TOP],
  MID_ROW: [POSITIONS.FRONT_MID, POSITIONS.MID_MID, POSITIONS.BACK_MID],
  BOTTOM_ROW: [POSITIONS.FRONT_BOTTOM, POSITIONS.MID_BOTTOM, POSITIONS.BACK_BOTTOM],
}


