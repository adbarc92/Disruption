"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Animation = void 0;
/**
 * @class An animation to accompany an action or skill.
 * @param sprites the series of images to be displayed.
 * @param spriteDuration the length of time over which each sprite is displayed.
 * @param sounds the sounds to be played.
 * @param soundDuration the length of time over which each sound is played.
 */
var Animation = /** @class */ (function () {
    function Animation(sprites, spriteDuration, sounds, soundDuration) {
        this.sprites = sprites;
        this.spriteDuration = spriteDuration;
        this.sounds = sounds;
        this.soundDuration = soundDuration;
    }
    return Animation;
}());
exports.Animation = Animation;
//# sourceMappingURL=animation.js.map