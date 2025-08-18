"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createSprite = void 0;
var createSprite = function (img, x, y, w, h) {
    return {
        img: img,
        x: x !== null && x !== void 0 ? x : 0,
        y: y !== null && y !== void 0 ? y : 0,
        w: w !== null && w !== void 0 ? w : img.width,
        h: h !== null && h !== void 0 ? h : img.height,
    };
};
exports.createSprite = createSprite;
//# sourceMappingURL=sprite.js.map