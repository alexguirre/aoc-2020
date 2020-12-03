const std = @import("std");
const input = @embedFile("data/input03");
usingnamespace @import("util.zig");

pub fn main() !void {
    print("[Part1] Encountered {} trees", .{calculateEncounteredTrees(3, 1)});

    const a = calculateEncounteredTrees(1, 1);
    const b = calculateEncounteredTrees(3, 1);
    const c = calculateEncounteredTrees(5, 1);
    const d = calculateEncounteredTrees(7, 1);
    const e = calculateEncounteredTrees(1, 2);
    const result = a * b * c * d * e;
    print("[Part2] {} * {} * {} * {} * {} = {}", .{a, b, c, d, e, result});
}

pub fn calculateEncounteredTrees(slope_right: usize, slope_down: usize) usize {
    const tree = '#';

    var column: usize = 0;
    var row: usize = 0;
    var num_trees: usize = 0;

    var curr_row: usize = 0;
    var reader = LineIterator.init(input);
    while (reader.next()) |line| : (curr_row += 1) {
        if (curr_row != row) {
            continue;
        }

        const index = column % line.len;
        if (line[index] == tree) {
            num_trees += 1;
        }

        column += slope_right;
        row += slope_down;
    }

    return num_trees;
}