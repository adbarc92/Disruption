"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BasicInfo = void 0;
var uuid_1 = require("uuid");
/**
 * @class An abstraction for the basic information shared by many classes.
 * This class will generate UUIDs for the new instance.
 * @param name The name to be set.
 * @param description The description to be set.
 */
var BasicInfo = /** @class */ (function () {
    function BasicInfo(name, description) {
        this.id = (0, uuid_1.v4)();
        this.name = name;
        this.description = description;
    }
    return BasicInfo;
}());
exports.BasicInfo = BasicInfo;
//# sourceMappingURL=basic-info.js.map