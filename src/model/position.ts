// DIRECTIONS = %w[UP RIGHT DOWN LEFT].freeze
// POSITIONS = {
//   SPOT_FRONT_TOP: Position.new(x: 0, y: 0),
//   SPOT_FRONT_MID: Position.new(x: 0, y: 1),
//   SPOT_FRONT_BOTTOM: Position.new(x: 0, y: 2),
//   SPOT_MID_TOP: Position.new(x: 1, y: 0),
//   SPOT_MID_MID: Position.new(x: 1, y: 1),
//   SPOT_MID_BOTTOM: Position.new(x: 1, y: 2),
//   SPOT_BACK_TOP: Position.new(x: 2, y: 0),
//   SPOT_BACK_MID: Position.new(x: 2, y: 1),
//   SPOT_BACK_BOTTOM: Position.new(x: 2, y: 2),
// }.freeze

// ROWS = {
//   TOP: [SPOT_FRONT_TOP, SPOT_MID_TOP, SPOT_BACK_TOP],
//   MID: [SPOT_FRONT_MID, SPOT_MID_MID, SPOT_BACK_MID],
//   BOTTOM: [SPOT_FRONT_BOTTOM, SPOT_MID_BOTTOM, SPOT_BACK_BOTTOM],
// }.freeze

// COLUMNS = {
//   FRONT: [SPOT_FRONT_TOP, SPOT_FRONT_MID, SPOT_FRONT_BOTTOM],
//   MID: [SPOT_MID_TOP, SPOT_MID_MID, SPOT_MID_BOTTOM],
//   BACK: [SPOT_BACK_TOP, SPOT_BACK_MID, SPOT_BACK_BOTTOM],
// }.freeze

export class Position {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}