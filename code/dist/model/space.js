"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROWS = exports.COLUMNS = exports.POSITIONS = exports.makePoint = void 0;
var makePoint = function (x, y) { return { x: x, y: y }; };
exports.makePoint = makePoint;
exports.POSITIONS = {
    FRONT_TOP: (0, exports.makePoint)(0, 0),
    FRONT_MID: (0, exports.makePoint)(0, 1),
    FRONT_BOTTOM: (0, exports.makePoint)(0, 2),
    MID_TOP: (0, exports.makePoint)(1, 0),
    MID_MID: (0, exports.makePoint)(1, 1),
    MID_BOTTOM: (0, exports.makePoint)(1, 2),
    BACK_TOP: (0, exports.makePoint)(2, 0),
    BACK_MID: (0, exports.makePoint)(2, 1),
    BACK_BOTTOM: (0, exports.makePoint)(2, 2),
};
exports.COLUMNS = {
    FRONT_COLUMN: [exports.POSITIONS.FRONT_TOP, exports.POSITIONS.FRONT_MID, exports.POSITIONS.FRONT_BOTTOM],
    MID_COLUMN: [exports.POSITIONS.MID_TOP, exports.POSITIONS.MID_MID, exports.POSITIONS.MID_BOTTOM],
    BACK_COLUMN: [exports.POSITIONS.BACK_TOP, exports.POSITIONS.BACK_MID, exports.POSITIONS.BACK_BOTTOM],
};
exports.ROWS = {
    TOP_ROW: [exports.POSITIONS.FRONT_TOP, exports.POSITIONS.MID_TOP, exports.POSITIONS.BACK_TOP],
    MID_ROW: [exports.POSITIONS.FRONT_MID, exports.POSITIONS.MID_MID, exports.POSITIONS.BACK_MID],
    BOTTOM_ROW: [exports.POSITIONS.FRONT_BOTTOM, exports.POSITIONS.MID_BOTTOM, exports.POSITIONS.BACK_BOTTOM],
};
//# sourceMappingURL=space.js.map