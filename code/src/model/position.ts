
export class Position {
    constructor(public x: number, public y: number) {}

    equals(other: Position): boolean {
        return this.x === other.x && this.y === other.y;
    }
}
