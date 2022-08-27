function spiralOrder(matrix: number[][]): number[] {
  const travelDir = {
      right: [1, 0],
      down: [0, 1],
      left: [-1, 0],
      up: [0, -1],
  };
  const l = matrix.flat().length;
  let current = [0, 0];
  const output = [];
  let dir = travelDir.right;
  let xMax = matrix[0].length - 1;
  let yMax = matrix.length - 1;
  let xMin = 0;
  let yMin = 0;
  let i = 0;
  while(i < l) {
      output.push(matrix[current[1]][current[0]]);
      if (dir == travelDir.right && current[0] == xMax) {
          dir = travelDir.down;
          xMax--;
      } else if (dir == travelDir.down && current[1] == yMax) {
          dir = travelDir.left;
          yMax--;
      } else if (dir == travelDir.left && current[0] == xMin) {
          dir = travelDir.up;
          yMin++;
      } else if (dir == travelDir.up && current[1] == yMin) {
          dir = travelDir.right;
          xMin++;
      }
      current[0] += dir[0];
      current[1] += dir[1];
      i++;
  }
  return output;
};
