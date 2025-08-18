"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Agent = void 0;
/**
 * @class An agent traverses the field and may be accompanied by a party.
 * @param basicAnimations the set of standard animations.
 * @param party the set of units attached to an agent. Optional.
 * @param traversal_ai defines how an agent navigates the field.
 */
var Agent = /** @class */ (function () {
    function Agent(basicAnimations, extendedAnimations, party, traversal_ai) {
        this.basicAnimations = basicAnimations;
        this.extendedAnimations = extendedAnimations;
        this.party = party;
        this.traversal_ai = traversal_ai;
    }
    return Agent;
}());
exports.Agent = Agent;
//# sourceMappingURL=agent.js.map