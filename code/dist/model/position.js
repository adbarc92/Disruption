"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Position = void 0;
var Position = /** @class */ (function () {
    function Position(x, y) {
        this.x = x;
        this.y = y;
    }
    Position.prototype.equals = function (other) {
        return this.x === other.x && this.y === other.y;
    };
    return Position;
}());
exports.Position = Position;
//# sourceMappingURL=position.js.map